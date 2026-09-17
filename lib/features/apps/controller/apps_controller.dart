import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' show Rect;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/launcher_constants.dart';
import '../../../core/constants/launcher_symbols.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/utils/symbol_guesser.dart';
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

/// Nomes dados pelo utilizador, por package name.
class AppLabelsNotifier extends Notifier<Map<String, String>> {
  @override
  Map<String, String> build() => ref.watch(appLabelsRepositoryProvider).read();

  String? labelFor(String packageName) => state[packageName];

  Future<void> rename(String packageName, String newName) async {
    final Map<String, String> next = Map<String, String>.of(state);
    if (newName.trim().isEmpty) {
      next.remove(packageName);
    } else {
      next[packageName] = newName.trim();
    }
    state = await ref.read(appLabelsRepositoryProvider).save(next);
  }

  Future<void> reset(String packageName) => rename(packageName, '');

  Future<void> resetAll() async {
    state = await ref.read(appLabelsRepositoryProvider).save(const <String, String>{});
  }
}

final NotifierProvider<AppLabelsNotifier, Map<String, String>> appLabelsProvider =
    NotifierProvider<AppLabelsNotifier, Map<String, String>>(AppLabelsNotifier.new);

/// Símbolos que o utilizador escolheu, por package name.
class AppSymbolsNotifier extends Notifier<Map<String, String>> {
  @override
  Map<String, String> build() => ref.watch(appSymbolsRepositoryProvider).read();

  Future<void> assign(String packageName, LauncherSymbol? symbol) async {
    final Map<String, String> next = Map<String, String>.of(state);
    if (symbol == null) {
      next.remove(packageName);
    } else {
      next[packageName] = symbol.key;
    }
    state = await ref.read(appSymbolsRepositoryProvider).save(next);
  }

  Future<void> resetAll() async {
    state = await ref.read(appSymbolsRepositoryProvider).save(const <String, String>{});
  }
}

final NotifierProvider<AppSymbolsNotifier, Map<String, String>> appSymbolsProvider =
    NotifierProvider<AppSymbolsNotifier, Map<String, String>>(AppSymbolsNotifier.new);

/// O símbolo a mostrar para uma aplicação, já com as três camadas resolvidas:
/// escolha do utilizador, palpite automático, e um círculo neutro se nada
/// bater certo.
final appSymbolProvider = Provider.family<LauncherSymbol, InstalledApp>(
  (Ref ref, InstalledApp app) {
    final String? chosen = ref.watch(
      appSymbolsProvider.select((Map<String, String> m) => m[app.packageName]),
    );
    return LauncherSymbol.tryParse(chosen) ??
        SymbolGuesser.guess(name: app.name, packageName: app.packageName) ??
        LauncherSymbol.circle;
  },
);

/// A lista que a UI mostra: sem apps ocultas, opcionalmente sem apps do
/// sistema, e já com os nomes que o utilizador escolheu.
final Provider<List<InstalledApp>> visibleAppsProvider = Provider<List<InstalledApp>>(
  (Ref ref) {
    final List<InstalledApp> apps =
        ref.watch(installedAppsProvider).value ?? const <InstalledApp>[];
    final Set<String> hidden = ref.watch(hiddenAppsProvider);
    final bool showSystemApps = ref.watch(
      settingsProvider.select((settings) => settings.showSystemApps),
    );

    final Map<String, String> labels = ref.watch(appLabelsProvider);

    final List<InstalledApp> visible = apps
        .where((InstalledApp app) => !hidden.contains(app.packageName))
        .where((InstalledApp app) => showSystemApps || !app.isSystemApp)
        .map((InstalledApp app) {
          final String? custom = labels[app.packageName];
          return custom == null ? app : app.withName(custom);
        })
        .toList();

    // Renomear muda a ordem alfabética e a letra do índice, por isso a lista
    // volta a ser ordenada aqui e não no repositório.
    if (labels.isNotEmpty) {
      visible.sort((InstalledApp a, InstalledApp b) =>
          a.foldedName.compareTo(b.foldedName));
    }
    return List<InstalledApp>.unmodifiable(visible);
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
