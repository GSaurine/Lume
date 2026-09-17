import '../../core/constants/launcher_constants.dart';
import '../models/launcher_settings.dart';
import '../services/preferences_service.dart';

/// Lê e escreve [LauncherSettings] nas preferências locais.
class SettingsRepository {
  const SettingsRepository(this._prefs);

  final PreferencesService _prefs;

  LauncherSettings load() {
    const LauncherSettings defaults = LauncherSettings();

    return LauncherSettings(
      theme: ThemePreference.parse(_prefs.getString(PreferenceKeys.theme)),
      fontScale: _prefs.getDouble(PreferenceKeys.fontScale, fallback: defaults.fontScale),
      itemSpacing:
          _prefs.getDouble(PreferenceKeys.itemSpacing, fallback: defaults.itemSpacing),
      iconStyle: IconStyle.parse(
        _prefs.getString(PreferenceKeys.iconStyle),
        fallback: defaults.iconStyle,
      ),
      panelOpacity:
          _prefs.getDouble(PreferenceKeys.panelOpacity, fallback: defaults.panelOpacity),
      accent: AccentColor.parse(
        _prefs.getInt(PreferenceKeys.accentColor, fallback: defaults.accent.index),
      ),
      contentAlignment:
          ContentAlignment.parse(_prefs.getString(PreferenceKeys.contentAlignment)),
      showClock: _prefs.getBool(PreferenceKeys.showClock, fallback: defaults.showClock),
      showDate: _prefs.getBool(PreferenceKeys.showDate, fallback: defaults.showDate),
      showAlphabetIndex: _prefs.getBool(
        PreferenceKeys.showAlphabetIndex,
        fallback: defaults.showAlphabetIndex,
      ),
      animations: MotionStyle.parse(_prefs.getString(PreferenceKeys.animationStyle)),
      use24HourClock:
          _prefs.getBool(PreferenceKeys.use24HourClock, fallback: defaults.use24HourClock),
      showSystemApps:
          _prefs.getBool(PreferenceKeys.showSystemApps, fallback: defaults.showSystemApps),
      searchPackageNames: _prefs.getBool(
        PreferenceKeys.searchPackageNames,
        fallback: defaults.searchPackageNames,
      ),
      searchAutoFocus:
          _prefs.getBool(PreferenceKeys.searchAutoFocus, fallback: defaults.searchAutoFocus),
      searchOpensSingleResult: _prefs.getBool(
        PreferenceKeys.searchOpensSingleResult,
        fallback: defaults.searchOpensSingleResult,
      ),
      favoritesLimit:
          _prefs.getInt(PreferenceKeys.favoritesLimit, fallback: defaults.favoritesLimit),
      gestures: _loadGestures(),
    );
  }

  Future<void> save(LauncherSettings settings) async {
    await Future.wait(<Future<void>>[
      _prefs.setString(PreferenceKeys.theme, settings.theme.key),
      _prefs.setDouble(PreferenceKeys.fontScale, settings.fontScale),
      _prefs.setDouble(PreferenceKeys.itemSpacing, settings.itemSpacing),
      _prefs.setString(PreferenceKeys.iconStyle, settings.iconStyle.key),
      _prefs.setDouble(PreferenceKeys.panelOpacity, settings.panelOpacity),
      _prefs.setInt(PreferenceKeys.accentColor, settings.accent.index),
      _prefs.setString(
        PreferenceKeys.contentAlignment,
        settings.contentAlignment.key,
      ),
      _prefs.setBool(PreferenceKeys.showClock, value: settings.showClock),
      _prefs.setBool(PreferenceKeys.showDate, value: settings.showDate),
      _prefs.setBool(PreferenceKeys.showAlphabetIndex, value: settings.showAlphabetIndex),
      _prefs.setString(PreferenceKeys.animationStyle, settings.animations.key),
      _prefs.setBool(PreferenceKeys.use24HourClock, value: settings.use24HourClock),
      _prefs.setBool(PreferenceKeys.showSystemApps, value: settings.showSystemApps),
      _prefs.setBool(PreferenceKeys.searchPackageNames, value: settings.searchPackageNames),
      _prefs.setBool(PreferenceKeys.searchAutoFocus, value: settings.searchAutoFocus),
      _prefs.setBool(
        PreferenceKeys.searchOpensSingleResult,
        value: settings.searchOpensSingleResult,
      ),
      _prefs.setInt(PreferenceKeys.favoritesLimit, settings.favoritesLimit),
      for (final MapEntry<LauncherGesture, GestureAction> entry in settings.gestures.entries)
        _prefs.setString('${PreferenceKeys.gesturePrefix}${entry.key.key}', entry.value.key),
    ]);
  }

  /// Apaga tudo e devolve os valores de origem.
  Future<LauncherSettings> reset() async {
    await _prefs.clear();
    return const LauncherSettings();
  }

  Map<LauncherGesture, GestureAction> _loadGestures() {
    return <LauncherGesture, GestureAction>{
      for (final LauncherGesture gesture in LauncherGesture.values)
        gesture: GestureAction.parse(
          _prefs.getString('${PreferenceKeys.gesturePrefix}${gesture.key}'),
          fallback: LauncherSettings.defaultGestures[gesture] ?? GestureAction.none,
        ),
    };
  }
}
