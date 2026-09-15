import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/text_normalizer.dart';
import '../../../data/models/installed_app.dart';
import '../../apps/controller/apps_controller.dart';
import '../../favorites/controller/favorites_controller.dart';
import '../../settings/controller/settings_controller.dart';

/// FASE 6 — pesquisa.
///
/// O plano começa com um `contains` simples (secção 11). Isto é um passo
/// à frente e continua trivial: pontuamos cada app para que "wh" mostre
/// WhatsApp antes de "Ver no WhatsApp", e escrever o início de qualquer
/// palavra do nome funcione ("drive" encontra "Google Drive").
class SearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void update(String value) => state = value;

  void clear() => state = '';
}

final NotifierProvider<SearchQueryNotifier, String> searchQueryProvider =
    NotifierProvider<SearchQueryNotifier, String>(SearchQueryNotifier.new);

final Provider<List<InstalledApp>> searchResultsProvider = Provider<List<InstalledApp>>(
  (Ref ref) {
    final String query = TextNormalizer.fold(ref.watch(searchQueryProvider));
    final List<InstalledApp> apps = ref.watch(visibleAppsProvider);
    if (query.isEmpty) return apps;

    final bool matchPackageNames = ref.watch(
      settingsProvider.select((settings) => settings.searchPackageNames),
    );
    final List<String> favorites = ref.watch(favoritePackagesProvider);

    final List<_ScoredApp> scored = <_ScoredApp>[];
    for (final InstalledApp app in apps) {
      final int score = AppMatcher.score(
        app: app,
        query: query,
        matchPackageName: matchPackageNames,
        favoriteRank: favorites.indexOf(app.packageName),
      );
      if (score > 0) scored.add(_ScoredApp(app, score));
    }

    scored.sort((_ScoredApp a, _ScoredApp b) {
      final int byScore = b.score.compareTo(a.score);
      return byScore != 0 ? byScore : a.app.foldedName.compareTo(b.app.foldedName);
    });

    return scored.map((_ScoredApp entry) => entry.app).toList(growable: false);
  },
);

class _ScoredApp {
  const _ScoredApp(this.app, this.score);

  final InstalledApp app;
  final int score;
}

/// Pontuação de relevância. 0 significa "não corresponde".
abstract final class AppMatcher {
  static const int _exactName = 1000;
  static const int _namePrefix = 800;
  static const int _wordPrefix = 600;
  static const int _initials = 500;
  static const int _nameContains = 300;
  static const int _packageContains = 100;

  static int score({
    required InstalledApp app,
    required String query,
    required bool matchPackageName,
    int favoriteRank = -1,
  }) {
    if (query.isEmpty) return 1;

    final String name = app.foldedName;
    int base = 0;

    if (name == query) {
      base = _exactName;
    } else if (name.startsWith(query)) {
      base = _namePrefix;
    } else {
      final List<String> words = TextNormalizer.words(name);
      if (words.skip(1).any((String word) => word.startsWith(query))) {
        base = _wordPrefix;
      } else if (_matchesInitials(words, query)) {
        base = _initials;
      } else if (name.contains(query)) {
        base = _nameContains;
      } else if (matchPackageName && TextNormalizer.fold(app.packageName).contains(query)) {
        base = _packageContains;
      }
    }

    if (base == 0) return 0;

    // Nomes curtos ganham a nomes longos com a mesma correspondência:
    // "Fotos" antes de "Fotos e vídeos do Google".
    base -= (name.length ~/ 4).clamp(0, 40);

    // Um favorito empatado fica à frente.
    if (favoriteRank >= 0) base += 60 - favoriteRank.clamp(0, 50);

    return base < 1 ? 1 : base;
  }

  /// "gm" encontra "Google Maps".
  static bool _matchesInitials(List<String> words, String query) {
    if (query.length < 2 || words.length < 2) return false;
    final String initials = words.map((String word) => word[0]).join();
    return initials.startsWith(query);
  }
}
