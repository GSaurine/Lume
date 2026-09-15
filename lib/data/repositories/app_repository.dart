import 'dart:typed_data';
import 'dart:ui' show Rect;

import '../models/installed_app.dart';
import '../services/platform_launcher_service.dart';

/// A fonte de verdade dos apps é o Android (plano, secção 8).
///
/// Este repositório só traduz o serviço de plataforma para termos de domínio
/// e ordena a lista. Nada é persistido aqui.
class AppRepository {
  const AppRepository(this._platform);

  final PlatformLauncherService _platform;

  /// Lista completa, já ordenada alfabeticamente ignorando acentos.
  Future<List<InstalledApp>> loadApps() async {
    final List<InstalledApp> apps = await _platform.getInstalledApps();
    apps.sort((InstalledApp a, InstalledApp b) => a.foldedName.compareTo(b.foldedName));
    return apps;
  }

  Future<Uint8List?> loadIcon(String packageName) =>
      _platform.getAppIcon(packageName);

  Future<bool> launch(InstalledApp app, {Rect? sourceBounds}) =>
      _platform.launchApp(app, sourceBounds: sourceBounds);

  Future<bool> openAppInfo(String packageName) => _platform.openAppInfo(packageName);

  Future<bool> requestUninstall(String packageName) =>
      _platform.requestUninstall(packageName);

  Future<bool> isInstalled(String packageName) => _platform.isAppInstalled(packageName);

  /// Apps instaladas/removidas e botão Home premido.
  Stream<LauncherPlatformEvent> watchPlatformEvents() => _platform.events();
}
