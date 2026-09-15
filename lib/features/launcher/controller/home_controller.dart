import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/core_providers.dart';

/// FASE 2 — o Lume é o Home atual?
///
/// Usado para mostrar (ou esconder) o aviso de configuração na Home.
class DefaultLauncherNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() =>
      ref.watch(platformLauncherServiceProvider).isDefaultLauncher();

  /// Abre o ecrã do sistema e volta a verificar o estado a seguir.
  Future<void> requestDefault() async {
    await ref.read(platformLauncherServiceProvider).requestDefaultLauncher();
    await refresh();
  }

  Future<void> refresh() async {
    state = await AsyncValue.guard(
      () => ref.read(platformLauncherServiceProvider).isDefaultLauncher(),
    );
  }
}

final AsyncNotifierProvider<DefaultLauncherNotifier, bool> isDefaultLauncherProvider =
    AsyncNotifierProvider<DefaultLauncherNotifier, bool>(DefaultLauncherNotifier.new);

/// Letra selecionada no índice alfabético da Home, ou `null` quando o
/// painel está fechado.
class LetterOverlayNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void select(String? letter) {
    if (state == letter) return;
    state = letter;
  }

  void close() => select(null);
}

final NotifierProvider<LetterOverlayNotifier, String?> selectedLetterProvider =
    NotifierProvider<LetterOverlayNotifier, String?>(LetterOverlayNotifier.new);
