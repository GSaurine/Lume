import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:lume_launcher/app.dart';
import 'package:lume_launcher/core/providers/core_providers.dart';
import 'package:lume_launcher/data/models/installed_app.dart';
import 'package:lume_launcher/data/services/platform_launcher_service.dart';
import 'package:lume_launcher/data/services/preferences_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Substitui o canal com o Kotlin. Nenhum teste deve tocar no MethodChannel.
class FakePlatformLauncherService extends PlatformLauncherService {
  FakePlatformLauncherService({
    this.apps = const <InstalledApp>[],
    this.defaultLauncher = true,
  });

  final List<InstalledApp> apps;
  final bool defaultLauncher;
  final List<String> launched = <String>[];

  /// Para o teste fingir que o Android mandou um evento (ex.: Home premido).
  final StreamController<LauncherPlatformEvent> androidEvents =
      StreamController<LauncherPlatformEvent>.broadcast();

  @override
  Future<List<InstalledApp>> getInstalledApps() async => apps;

  @override
  Future<Uint8List?> getAppIcon(String packageName, {int size = 0}) async => null;

  @override
  Stream<LauncherPlatformEvent> events() => androidEvents.stream;

  Future<void> dispose() => androidEvents.close();

  @override
  Future<bool> isDefaultLauncher() async => defaultLauncher;

  @override
  Future<bool> launchApp(InstalledApp app, {Rect? sourceBounds}) async {
    launched.add(app.packageName);
    return true;
  }
}

/// Um ecrã de telemóvel: tamanho lógico e as margens do sistema (barra de
/// estado, barra de navegação, recorte da câmara).
class DeviceShape {
  const DeviceShape(this.name, this.size, this.padding);

  final String name;
  final Size size;
  final EdgeInsets padding;

  bool get isLandscape => size.width > size.height;

  /// Um Galaxy A16 5G: 1080×2340 píxeis, densidade 2,625.
  static const double pixelRatio = 2.625;

  static const DeviceShape portrait = DeviceShape(
    'retrato',
    Size(411, 891),
    EdgeInsets.only(top: 32, bottom: 48),
  );

  /// Deitado com a barra de navegação de três botões, que o Android passa
  /// para o lado. O recorte da câmara fica do lado oposto.
  static const DeviceShape landscape = DeviceShape(
    'paisagem',
    Size(891, 411),
    EdgeInsets.only(left: 32, top: 24, right: 48),
  );
}

/// Apps falsas que cobrem o alfabeto todo, para a barra A–Z estar cheia como
/// num telemóvel real.
List<InstalledApp> sampleApps() {
  const List<String> names = <String>[
    'Alexa', 'AliExpress', 'Autenticação Gov', 'Banco', 'Bleach', 'Bolt',
    'Calculadora', 'Calendário', 'Câmera', 'Chrome', 'Discord', 'Duolingo',
    'Email', 'Facebook', 'Fotos', 'Galeria', 'Gmail', 'Hotmail', 'Instagram',
    'Jogos', 'Keep', 'LinkedIn', 'Maps', 'Mensagens', 'Navegador brave',
    'Netflix', 'Outlook', 'Phone', 'Play Store', 'Quizlet', 'Revolut',
    'Spotify', 'Telegram', 'Uber', 'Vinted', 'WhatsApp', 'Xbox', 'YouTube',
    'Zoom', '7DS',
  ];
  return <InstalledApp>[
    for (final String name in names)
      InstalledApp(
        name: name,
        packageName: 'com.teste.${name.toLowerCase().replaceAll(RegExp('[^a-z0-9]'), '')}',
        activityName: 'Main',
      ),
  ];
}

String packageOf(String name) =>
    sampleApps().firstWhere((InstalledApp a) => a.name == name).packageName;

/// Carrega as fontes reais, para os renders se lerem. Sem isto o Flutter usa
/// uma fonte de teste em que cada letra é um quadrado.
Future<void> loadRealFonts() async {
  const String materialFonts = 'C:/Flutter/flutter/bin/cache/artifacts/material_fonts';

  Future<void> load(String family, List<String> paths) async {
    final FontLoader loader = FontLoader(family);
    for (final String path in paths) {
      final Uint8List bytes = File(path).readAsBytesSync();
      loader.addFont(Future<ByteData>.value(ByteData.view(bytes.buffer)));
    }
    await loader.load();
  }

  await load('Roboto', <String>[
    for (final String w in <String>['thin', 'light', 'regular', 'medium', 'bold'])
      '$materialFonts/roboto-$w.ttf',
  ]);
  await load('MaterialIcons', <String>['$materialFonts/materialicons-regular.otf']);
  for (final String family in <String>['Inter', 'Outfit', 'Lora', 'JetBrainsMono']) {
    await load(family, <String>['assets/fonts/$family.ttf']);
  }
}

/// Recolhe os erros de layout ("RenderFlex overflowed") em vez de os deixar
/// rebentar o teste ao primeiro — interessa saber todos.
class LayoutErrors {
  final List<String> overflows = <String>[];
  void Function(FlutterErrorDetails)? _previous;

  void start() {
    _previous = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      final String text = details.exceptionAsString();
      if (text.contains('overflowed')) {
        overflows.add(text.split('\n').first);
      } else {
        _previous?.call(details);
      }
    };
  }

  void stop() => FlutterError.onError = _previous;
}

final GlobalKey _captureKey = GlobalKey();

/// O que um teste pode inspecionar depois de montar o Lume.
class LumeSession {
  LumeSession(this.platform);

  /// O "Kotlin" falso: guarda as aplicações que o Lume pediu para abrir.
  final FakePlatformLauncherService platform;

  /// Pedidos ao sistema pelo canal da plataforma (vibração, rotação…).
  final List<MethodCall> systemCalls = <MethodCall>[];

  /// A última orientação pedida com SystemChrome.setPreferredOrientations.
  /// Vazia: segue o sistema.
  List<String>? get preferredOrientations {
    for (final MethodCall call in systemCalls.reversed) {
      if (call.method == 'SystemChrome.setPreferredOrientations') {
        return (call.arguments as List<Object?>).cast<String>();
      }
    }
    return null;
  }
}

/// Monta o Lume inteiro num ecrã com esta forma.
///
/// `prefs` são preferências como o Lume as guarda; `defaultLauncher: false`
/// faz aparecer o banner "Definir o Lume como ecrã inicial", que é o caso de
/// quem acabou de instalar.
Future<LumeSession> pumpLume(
  WidgetTester tester,
  DeviceShape shape, {
  Map<String, Object> prefs = const <String, Object>{},
  bool defaultLauncher = true,
}) async {
  final LumeSession session = LumeSession(
    FakePlatformLauncherService(apps: sampleApps(), defaultLauncher: defaultLauncher),
  );
  addTearDown(session.platform.dispose);

  tester.view
    ..devicePixelRatio = DeviceShape.pixelRatio
    ..physicalSize = shape.size * DeviceShape.pixelRatio
    ..padding = FakeViewPadding(
      left: shape.padding.left * DeviceShape.pixelRatio,
      top: shape.padding.top * DeviceShape.pixelRatio,
      right: shape.padding.right * DeviceShape.pixelRatio,
      bottom: shape.padding.bottom * DeviceShape.pixelRatio,
    )
    ..viewPadding = FakeViewPadding(
      left: shape.padding.left * DeviceShape.pixelRatio,
      top: shape.padding.top * DeviceShape.pixelRatio,
      right: shape.padding.right * DeviceShape.pixelRatio,
      bottom: shape.padding.bottom * DeviceShape.pixelRatio,
    );
  tester.platformDispatcher
    ..platformBrightnessTestValue = Brightness.dark
    ..localesTestValue = const <Locale>[Locale('pt', 'PT')];
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearAllTestValues);

  // A vibração ao manter premido vai pelo canal da plataforma. Sem uma
  // resposta, o `await HapticFeedback...` nunca termina e o menu não abre.
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
    SystemChannels.platform,
    (MethodCall call) async {
      session.systemCalls.add(call);
      return null;
    },
  );
  addTearDown(() => tester.binding.defaultBinaryMessenger
      .setMockMethodCallHandler(SystemChannels.platform, null));

  await initializeDateFormatting();
  SharedPreferences.setMockInitialValues(prefs);
  final PreferencesService preferences = await PreferencesService.load();

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        preferencesServiceProvider.overrideWithValue(preferences),
        platformLauncherServiceProvider.overrideWithValue(session.platform),
      ],
      child: RepaintBoundary(
        key: _captureKey,
        child: const Stack(
          textDirection: TextDirection.ltr,
          children: <Widget>[
            // Faz de wallpaper: o Lume é transparente e sem isto o render
            // ficava preto.
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: <Color>[Color(0xFF7B6FA8), Color(0xFF3E3566)],
                  ),
                ),
              ),
            ),
            Positioned.fill(child: LumeApp()),
          ],
        ),
      ),
    ),
  );
  // A lista de apps chega de forma assíncrona; dois frames chegam para ela
  // e para o banner do launcher padrão.
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
  return session;
}

/// Desmonta o Lume, para os timers do relógio e da data serem cancelados.
Future<void> unmountLume(WidgetTester tester) => tester.pumpWidget(const SizedBox());

/// Guarda um PNG do ecrã atual, só quando LUME_RENDER=1. Serve para rever o
/// layout sem telemóvel; não é usado nas asserções.
Future<void> renderIfAsked(WidgetTester tester, String fileName) async {
  if (Platform.environment['LUME_RENDER'] != '1') return;
  await tester.runAsync(() async {
    final RenderRepaintBoundary boundary =
        _captureKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final ui.Image image = await boundary.toImage(pixelRatio: 1.5);
    final ByteData? png = await image.toByteData(format: ui.ImageByteFormat.png);
    final File out = File('build/screens/$fileName.png')..createSync(recursive: true);
    out.writeAsBytesSync(png!.buffer.asUint8List());
  });
}
