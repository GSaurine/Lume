import '../../core/constants/launcher_constants.dart';
import '../services/preferences_service.dart';

/// Favoritos e apps ocultas (plano, secções 10 e 12).
///
/// Guardamos apenas o *package name*: o nome muda quando o utilizador troca
/// de idioma e o ícone muda a cada atualização do app, mas o package é estável.
class FavoritesRepository {
  const FavoritesRepository(this._prefs);

  final PreferencesService _prefs;

  List<String> favorites() => _prefs.getStringList(PreferenceKeys.favorites);

  List<String> hidden() => _prefs.getStringList(PreferenceKeys.hiddenApps);

  Future<List<String>> setFavorites(List<String> packageNames) async {
    final List<String> unique = _dedupe(packageNames);
    await _prefs.setStringList(PreferenceKeys.favorites, unique);
    return unique;
  }

  Future<List<String>> setHidden(List<String> packageNames) async {
    final List<String> unique = _dedupe(packageNames);
    await _prefs.setStringList(PreferenceKeys.hiddenApps, unique);
    return unique;
  }

  /// Remove das preferências os packages que já não estão instalados.
  ///
  /// Sem isto, desinstalar e reinstalar um app reordena silenciosamente os
  /// favoritos e a lista cresce para sempre.
  Future<void> pruneUninstalled(Set<String> installedPackages) async {
    final List<String> currentFavorites = favorites();
    final List<String> keptFavorites =
        currentFavorites.where(installedPackages.contains).toList();
    if (keptFavorites.length != currentFavorites.length) {
      await _prefs.setStringList(PreferenceKeys.favorites, keptFavorites);
    }

    final List<String> currentHidden = hidden();
    final List<String> keptHidden = currentHidden.where(installedPackages.contains).toList();
    if (keptHidden.length != currentHidden.length) {
      await _prefs.setStringList(PreferenceKeys.hiddenApps, keptHidden);
    }
  }

  static List<String> _dedupe(List<String> values) {
    final Set<String> seen = <String>{};
    return values.where(seen.add).toList(growable: false);
  }
}
