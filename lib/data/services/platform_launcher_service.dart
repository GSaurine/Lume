import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../core/constants/launcher_constants.dart';
import '../models/installed_app.dart';

/// Único ponto de contacto com o Kotlin (plano, secção 5).
///
/// Nenhuma outra parte da app deve falar com MethodChannel diretamente.
/// Todos os métodos falham em silêncio (devolvem `false`/`null` e registam
/// um aviso): num launcher, uma exceção não tratada deixa o utilizador sem
/// ecrã inicial.
class PlatformLauncherService {
  const PlatformLauncherService();

  static const MethodChannel _methods = MethodChannel(LauncherChannels.methods);
  static const EventChannel _events = EventChannel(LauncherChannels.events);

  // --- FASE 3: descoberta de aplicativos -------------------------------

  Future<List<InstalledApp>> getInstalledApps() async {
    final List<Object?>? raw = await _invoke<List<Object?>>('getInstalledApps');
    if (raw == null) return const <InstalledApp>[];
    return raw
        .whereType<Map<Object?, Object?>>()
        .map(InstalledApp.fromMap)
        .toList(growable: false);
  }

  Future<InstalledApp?> getApp(String packageName) async {
    final Map<Object?, Object?>? raw = await _invoke<Map<Object?, Object?>>(
      'getApp',
      <String, Object?>{'packageName': packageName},
    );
    return raw == null ? null : InstalledApp.fromMap(raw);
  }

  Future<Uint8List?> getAppIcon(
    String packageName, {
    int size = LauncherMetrics.iconPixelSize,
  }) {
    return _invoke<Uint8List>(
      'getAppIcon',
      <String, Object?>{'packageName': packageName, 'size': size},
    );
  }

  Future<bool> isAppInstalled(String packageName) =>
      _invokeBool('isAppInstalled', <String, Object?>{'packageName': packageName});

  // --- FASE 4: abrir aplicativos ---------------------------------------

  /// [sourceBounds] é o retângulo do item tocado em *pixels físicos*; o
  /// Android usa-o para animar a abertura a partir desse ponto.
  Future<bool> launchApp(InstalledApp app, {Rect? sourceBounds}) {
    return _invokeBool('launchApp', <String, Object?>{
      'packageName': app.packageName,
      'activityName': app.activityName.isEmpty ? null : app.activityName,
      if (sourceBounds != null)
        'sourceBounds': <double>[
          sourceBounds.left,
          sourceBounds.top,
          sourceBounds.right,
          sourceBounds.bottom,
        ],
    });
  }

  Future<bool> openAppInfo(String packageName) =>
      _invokeBool('openAppInfo', <String, Object?>{'packageName': packageName});

  Future<bool> requestUninstall(String packageName) =>
      _invokeBool('requestUninstall', <String, Object?>{'packageName': packageName});

  // --- FASE 2: papel de Home Launcher ----------------------------------

  Future<bool> isDefaultLauncher() => _invokeBool('isDefaultLauncher');

  Future<bool> requestDefaultLauncher() => _invokeBool('requestDefaultLauncher');

  // --- Gestos / sistema -------------------------------------------------

  Future<bool> expandNotifications() => _invokeBool('expandNotifications');

  Future<bool> isAccessibilityEnabled() => _invokeBool('isAccessibilityEnabled');

  Future<bool> openAccessibilitySettings() => _invokeBool('openAccessibilitySettings');

  Future<bool> openSystemSettings() => _invokeBool('openSystemSettings');

  /// Abre o seletor de wallpaper do Android.
  Future<bool> openWallpaperPicker() => _invokeBool('openWallpaperPicker');

  Future<bool> lockScreen() => _invokeBool('lockScreen');

  Future<bool> openRecents() => _invokeBool('openRecents');

  Future<bool> clearIconCache() => _invokeBool('clearIconCache');

  /// Apps instaladas/removidas e botão Home premido.
  Stream<LauncherPlatformEvent> events() {
    return _events
        .receiveBroadcastStream()
        .where((Object? event) => event is Map)
        .map((Object? event) =>
            LauncherPlatformEvent.fromMap(event! as Map<Object?, Object?>))
        .handleError((Object error, StackTrace stack) {
      debugPrint('[Lume] falha no EventChannel: $error');
    });
  }

  // --- Internals --------------------------------------------------------

  Future<T?> _invoke<T>(String method, [Map<String, Object?>? arguments]) async {
    try {
      return await _methods.invokeMethod<T>(method, arguments);
    } on PlatformException catch (error) {
      debugPrint('[Lume] $method falhou: ${error.code} ${error.message}');
      return null;
    } on MissingPluginException {
      debugPrint('[Lume] $method não está implementado nesta plataforma.');
      return null;
    }
  }

  Future<bool> _invokeBool(String method, [Map<String, Object?>? arguments]) async =>
      await _invoke<bool>(method, arguments) ?? false;
}
