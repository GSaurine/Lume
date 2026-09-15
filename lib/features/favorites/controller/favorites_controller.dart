import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/core_providers.dart';
import '../../../data/models/installed_app.dart';
import '../../apps/controller/apps_controller.dart';

/// FASE 7 — favoritos.
///
/// O estado é a lista *ordenada* de package names. A ordem é a que o
/// utilizador definiu no editor de favoritos.
class FavoritesNotifier extends Notifier<List<String>> {
  @override
  List<String> build() {
    // Quando a lista de apps muda, limpamos packages desinstalados do disco.
    ref.listen<AsyncValue<List<InstalledApp>>>(
      installedAppsProvider,
      (AsyncValue<List<InstalledApp>>? previous, AsyncValue<List<InstalledApp>> next) {
        final List<InstalledApp>? apps = next.value;
        if (apps == null || apps.isEmpty) return;
        _prune(apps.map((InstalledApp app) => app.packageName).toSet());
      },
    );

    return ref.watch(favoritesRepositoryProvider).favorites();
  }

  bool isFavorite(String packageName) => state.contains(packageName);

  Future<void> toggle(String packageName) async {
    if (isFavorite(packageName)) {
      await remove(packageName);
    } else {
      await add(packageName);
    }
  }

  Future<void> add(String packageName) async {
    if (isFavorite(packageName)) return;
    await _save(<String>[...state, packageName]);
  }

  Future<void> remove(String packageName) async {
    if (!isFavorite(packageName)) return;
    await _save(state.where((String p) => p != packageName).toList());
  }

  /// Move o favorito de [oldIndex] para [newIndex] (drag & drop na lista).
  Future<void> reorder(int oldIndex, int newIndex) async {
    if (oldIndex < 0 || oldIndex >= state.length) return;
    final List<String> next = List<String>.of(state);
    final String moved = next.removeAt(oldIndex);
    next.insert(newIndex.clamp(0, next.length), moved);
    await _save(next);
  }

  Future<void> clear() => _save(const <String>[]);

  Future<void> _save(List<String> packageNames) async {
    state = await ref.read(favoritesRepositoryProvider).setFavorites(packageNames);
  }

  void _prune(Set<String> installedPackages) {
    final List<String> kept = state.where(installedPackages.contains).toList();
    if (kept.length == state.length) return;
    // Não usamos `await`: o estado em memória é a fonte imediata da UI e a
    // escrita em disco pode acontecer a seguir.
    state = kept;
    ref.read(favoritesRepositoryProvider).setFavorites(kept).ignore();
  }
}

final NotifierProvider<FavoritesNotifier, List<String>> favoritePackagesProvider =
    NotifierProvider<FavoritesNotifier, List<String>>(FavoritesNotifier.new);

/// Favoritos resolvidos para apps reais, pela ordem escolhida e limitados
/// ao número configurado nas definições.
final Provider<List<InstalledApp>> favoriteAppsProvider = Provider<List<InstalledApp>>(
  (Ref ref) {
    final List<String> packages = ref.watch(favoritePackagesProvider);
    if (packages.isEmpty) return const <InstalledApp>[];

    final Map<String, InstalledApp> byPackage = <String, InstalledApp>{
      for (final InstalledApp app in ref.watch(visibleAppsProvider)) app.packageName: app,
    };

    return <InstalledApp>[
      for (final String packageName in packages)
        if (byPackage[packageName] case final InstalledApp app) app,
    ];
  },
);
