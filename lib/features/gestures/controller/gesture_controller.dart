import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/launcher_settings.dart';
import '../services/system_gesture_service.dart';

/// Ecrãs internos que um gesto pode abrir.
enum LauncherDestination { search, appList, favorites, settings }

/// Resultado de executar um gesto. Separa "o que aconteceu" de "quem navega":
/// a navegação precisa de `BuildContext`, que não pertence a um controller.
class GestureOutcome {
  const GestureOutcome._({this.destination, this.failureMessage});

  const GestureOutcome.nothing() : this._();

  const GestureOutcome.navigate(LauncherDestination destination)
      : this._(destination: destination);

  const GestureOutcome.failed(String message) : this._(failureMessage: message);

  final LauncherDestination? destination;
  final String? failureMessage;

  bool get handled => destination != null || failureMessage != null;
}

class GestureController {
  const GestureController(this._system);

  final SystemGestureService _system;

  Future<GestureOutcome> run(GestureAction action) async {
    switch (action) {
      case GestureAction.none:
        return const GestureOutcome.nothing();

      case GestureAction.openSearch:
        return const GestureOutcome.navigate(LauncherDestination.search);

      case GestureAction.openAppList:
        return const GestureOutcome.navigate(LauncherDestination.appList);

      case GestureAction.openFavorites:
        return const GestureOutcome.navigate(LauncherDestination.favorites);

      case GestureAction.openSettings:
        return const GestureOutcome.navigate(LauncherDestination.settings);

      case GestureAction.expandNotifications:
        final bool ok = await _system.expandNotifications();
        return ok
            ? const GestureOutcome.nothing()
            : const GestureOutcome.failed(
                'O Android não deixou abrir as notificações. Ative o serviço '
                'de acessibilidade do Lume em Definições > Gestos.',
              );

      case GestureAction.openRecents:
        final bool ok = await _system.openRecents();
        return ok
            ? const GestureOutcome.nothing()
            : const GestureOutcome.failed(
                'Precisa do serviço de acessibilidade do Lume para abrir as '
                'aplicações recentes.',
              );

      case GestureAction.lockScreen:
        final bool ok = await _system.lockScreen();
        return ok
            ? const GestureOutcome.nothing()
            : const GestureOutcome.failed(
                'Precisa do serviço de acessibilidade do Lume (Android 9 ou '
                'superior) para bloquear o ecrã.',
              );
    }
  }
}

final Provider<GestureController> gestureControllerProvider = Provider<GestureController>(
  (Ref ref) => GestureController(ref.watch(systemGestureServiceProvider)),
);
