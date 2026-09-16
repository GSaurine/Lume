import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume_launcher/core/providers/core_providers.dart';
import 'package:lume_launcher/data/models/installed_app.dart';
import 'package:lume_launcher/data/services/platform_launcher_service.dart';
import 'package:lume_launcher/data/services/preferences_service.dart';
import 'package:lume_launcher/features/apps/widgets/app_tile.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Substitui o canal com o Kotlin. Nenhum teste deve tocar no MethodChannel.
class FakePlatformLauncherService extends PlatformLauncherService {
  FakePlatformLauncherService();

  final List<String> launched = <String>[];

  @override
  Future<List<InstalledApp>> getInstalledApps() async => const <InstalledApp>[];

  @override
  Future<Uint8List?> getAppIcon(String packageName, {int size = 0}) async => null;

  @override
  Stream<LauncherPlatformEvent> events() => const Stream<LauncherPlatformEvent>.empty();

  @override
  Future<bool> launchApp(InstalledApp app, {Rect? sourceBounds}) async {
    launched.add(app.packageName);
    return true;
  }
}

const InstalledApp brave = InstalledApp(
  name: 'Brave',
  packageName: 'com.brave.browser',
  activityName: 'com.brave.browser.Main',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakePlatformLauncherService platform;
  late bool dragReachedGestureLayer;

  Future<Widget> buildHomeLike({required bool overWallpaper}) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final PreferencesService preferences = await PreferencesService.load();
    platform = FakePlatformLauncherService();
    dragReachedGestureLayer = false;

    return ProviderScope(
      overrides: [
        preferencesServiceProvider.overrideWithValue(preferences),
        platformLauncherServiceProvider.overrideWithValue(platform),
      ],
      child: MaterialApp(
        home: Scaffold(
          // A mesma montagem da Home: a camada de gestos por baixo, o
          // conteúdo por cima.
          body: Stack(
            children: <Widget>[
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onHorizontalDragEnd: (_) => dragReachedGestureLayer = true,
                ),
              ),
              Align(
                child: AppTile(app: brave, overWallpaper: overWallpaper),
              ),
            ],
          ),
        ),
      ),
    );
  }

  group('AppTile sobre o wallpaper', () {
    testWidgets('deixa passar o arrasto para a camada de gestos', (tester) async {
      // Regressão dupla. Primeiro o InkWell (HitTestBehavior.opaque) engolia
      // o deslize; depois, já com um detetor translúcido, era o Text lá
      // dentro que o engolia — RenderParagraph.hitTestSelf devolve sempre
      // true, e o Expanded faz a sua caixa ocupar a linha inteira.
      await tester.pumpWidget(await buildHomeLike(overWallpaper: true));

      // warnIfMissed: o Text não responde mesmo ao hit test — é esse o
      // objetivo. Quem recebe o ponteiro nessa posição é o detetor à volta.
      await tester.drag(
        find.text('Brave'),
        const Offset(-200, 0),
        warnIfMissed: false,
      );
      await tester.pumpAndSettle();

      expect(dragReachedGestureLayer, isTrue);
    });

    testWidgets('continua a abrir a aplicação ao toque', (tester) async {
      await tester.pumpWidget(await buildHomeLike(overWallpaper: true));

      await tester.tap(find.text('Brave'), warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(platform.launched, <String>['com.brave.browser']);
      expect(dragReachedGestureLayer, isFalse);
    });
  });

  group('AppTile num painel opaco', () {
    testWidgets('absorve o arrasto, como se espera de um item de lista',
        (tester) async {
      // Documenta o porquê de existir `overWallpaper`: dentro da lista de
      // aplicações o item deve mesmo absorver o gesto.
      await tester.pumpWidget(await buildHomeLike(overWallpaper: false));

      await tester.drag(find.text('Brave'), const Offset(-200, 0));
      await tester.pumpAndSettle();

      expect(dragReachedGestureLayer, isFalse);
    });
  });
}
