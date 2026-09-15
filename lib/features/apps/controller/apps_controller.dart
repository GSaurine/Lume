import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' show Rect;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/launcher_constants.dart';
import '../../../core/providers/core_providers.dart';
import '../../../data/models/installed_app.dart';
import '../../settings/controller/settings_controller.dart';

/// Eventos do Android (app instalada/removida, Home premido).
///
/// É um único stream partilhado; vários widgets podem escutá-lo sem abrir
/// mais do que um EventChannel.
final StreamProvider<LauncherPlatformEvent> platformEventsProvider =
    StreamProvider<LauncherPlatformEvent>(
  (Ref ref) => ref.watch(appRepositoryProvider).watchPlatformEvents(),
);

/// FASE 3 — lista crua de apps instaladas, tal como o Android a reporta.
class InstalledAppsNotifier extends AsyncNotifier<List<InstalledApp>> {
  Timer? _reloadTimer;

  @override
  Future<List<InstalledApp>> build() async {
    ref.onDispose(() => _reloadTimer?.cancel());

    // Instalar/desinstalar um app torna a lista obsoleta. Agrupamos os
    // eventos porque um restauro de backup dispara dezenas seguidos.
    ref.listen<AsyncValue<LauncherPlatformEvent>>(
      platformEventsProvider,
      (AsyncValue<LauncherPlatformEvent>? previous, AsyncValue<LauncherPlatformEvent> next) {
        final LauncherPlatformEvent? event = next.value;
        if (event == null || !event.affectsAppList) return;
        _reloadTimer?.cancel();
        _reloadTimer = Timer(LauncherDurations.packageEventDebounce, reload);
      },
    );

    return ref.read(appRepositoryProvider).loadApps();
  }

  /// Recarrega sem piscar: mantém a lista atual visível durante o pedido.
  Future<void> reload() async {
    final AsyncValue<List<InstalledApp>> previous = state;
    state = await AsyncValue.guard(() => ref.read(appRepositoryProvider).loadApps());
    if (state.hasError && previous.hasValue) {
      // Falhar a recarga não deve esvaziar o ecrã inicial.
      state = AsyncData<List<InstalledApp>>(previous.requireValue);
    }
  }
}

final AsyncNotifierProvider<InstalledAppsNotifier, List<InstalledApp>> installedAppsProvider =
    AsyncNotifierProvider<InstalledAppsNotifier, List<InstalledApp>>(
  InstalledAppsNotifier.new,
);

/// Apps ocultas pelo utilizador (menu contextual > Ocultar).
class HiddenAppsNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() => ref.watch(favoritesRepositoryProvider).hidden().toSet();

  Future<void> toggle(String packageName) async {
    final Set<String> next = Set<String>.of(state);
    if (!next.remove(packageName)) next.add(packageName);
    state = next;
    await ref.read(favoritesRepositoryProvider).setHidden(next.toList());
  }

  Future<void> showAll() async {
    state = const <String>{};
    await ref.read(favoritesRepositoryProvider).setHidden(const <String>[]);
  }

  bool isHidden(String packageName) => state.contains(packageName);
}

final NotifierProvider<HiddenAppsNotifier, Set<String>> hiddenAppsProvider =
    NotifierProvider<HiddenAppsNotifier, Set<String>>(HiddenAppsNotifier.new);

/// A lista que a UI mostra: sem apps ocultas e, opcionalmente, sem apps
/// do sistema.
final Provider<List<InstalledApp>> visibleAppsProvider = Provider<List<InstalledApp>>(
  (Ref ref) {
    final List<InstalledApp> apps =
        ref.watch(installedAppsProvider).value ?? const <InstalledApp>[];
    final Set<String> hidden = ref.watch(hiddenAppsProvider);
    final bool showSystemApps = ref.watch(
      settingsProvider.select((settings) => settings.showSystemApps),
    );

    return apps
        .where((InstalledApp app) => !hidden.contains(app.packageName))
        .where((InstalledApp app) => showSystemApps || !app.isSystemApp)
        .toList(growable: false);
  },
);

/// Apps agrupadas por letra, na ordem em que a lista as mostra.
final Provider<Map<String, List<InstalledApp>>> appsByLetterProvider =
    Provider<Map<String, List<InstalledApp>>>((Ref ref) {
  final Map<String, List<InstalledApp>> grouped = <String, List<InstalledApp>>{};
  for (final InstalledApp app in ref.watch(visibleAppsProvider)) {
    grouped.putIfAbsent(app.indexLetter, () => <InstalledApp>[]).add(app);
  }
  return grouped;
});

/// Letras que têm pelo menos um app, na ordem A-Z com '#' no fim.
final Provider<List<String>> availableLettersProvider = Provider<List<String>>((Ref ref) {
  final List<String> letters = ref.watch(appsByLetterProvider).keys.toList()
    ..sort((String a, String b) {
      if (a == '#') return 1;
      if (b == '#') return -1;
      return a.compareTo(b);
    });
  return letters;
});

/// Ícone de um app, pedido ao Android sob demanda.
///
/// Um provider por package: a família fica em memória durante a sessão, o
/// que é intencional — o número de apps é limitado e assim a `ImageCache`
/// do Flutter recebe sempre a *mesma* instância de `Uint8List` e não volta
/// a descodificar o PNG (FASE 10).
final appIconProvider = FutureProvider.family<Uint8List?, String>(
  (Ref ref, String packageName) => ref.watch(appRepositoryProvider).loadIcon(packageName),
);

/// Abrir um app (FASE 4).
///
/// [sourceBounds] vem em logical pixels e é convertido para pixels físicos,
/// que é o que o Android espera para animar a partir do item tocado.
final Provider<AppLauncher> appLauncherProvider = Provider<AppLauncher>(AppLauncher.new);

class AppLauncher {
  AppLauncher(this._ref);

  final Ref _ref;

  Future<bool> launch(InstalledApp app, {Rect? sourceBounds, double devicePixelRatio = 1}) {
    final Rect? bounds = sourceBounds == null
        ? null
        : Rect.fromLTRB(
            sourceBounds.left * devicePixelRatio,
            sourceBounds.top * devicePixelRatio,
            sourceBounds.right * devicePixelRatio,
            sourceBounds.bottom * devicePixelRatio,
          );
    return _ref.read(appRepositoryProvider).launch(app, sourceBounds: bounds);
  }

  Future<bool> openAppInfo(String packageName) =>
      _ref.read(appRepositoryProvider).openAppInfo(packageName);

  Future<bool> requestUninstall(String packageName) =>
      _ref.read(appRepositoryProvider).requestUninstall(packageName);
}
