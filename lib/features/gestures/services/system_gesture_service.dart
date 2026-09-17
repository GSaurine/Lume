import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/core_providers.dart';
import '../../../data/services/platform_launcher_service.dart';

/// Ações do sistema pedidas por gestos (plano, secção 13).
///
/// Todas devolvem `false` quando o Android as recusa — por exemplo abrir as
/// notificações num Android 12+ sem o serviço de acessibilidade ativo. A UI
/// usa esse `false` para explicar o que falta em vez de não fazer nada.
class SystemGestureService {
  const SystemGestureService(this._platform);

  final PlatformLauncherService _platform;

  Future<bool> expandNotifications() => _platform.expandNotifications();

  Future<bool> openRecents() => _platform.openRecents();

  Future<bool> lockScreen() => _platform.lockScreen();

  Future<bool> isAccessibilityEnabled() => _platform.isAccessibilityEnabled();

  Future<bool> openAccessibilitySettings() => _platform.openAccessibilitySettings();

  Future<bool> openSystemSettings() => _platform.openSystemSettings();

  Future<bool> openWallpaperPicker() => _platform.openWallpaperPicker();
}

final Provider<SystemGestureService> systemGestureServiceProvider =
    Provider<SystemGestureService>(
  (Ref ref) => SystemGestureService(ref.watch(platformLauncherServiceProvider)),
);
