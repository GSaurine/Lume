import 'package:flutter_test/flutter_test.dart';
import 'package:lume_launcher/data/models/launcher_settings.dart';
import 'package:lume_launcher/data/repositories/settings_repository.dart';
import 'package:lume_launcher/data/services/preferences_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<SettingsRepository> makeRepository() async {
  SharedPreferences.setMockInitialValues(<String, Object>{});
  return SettingsRepository(await PreferencesService.load());
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('sem nada guardado devolve os valores de origem', () async {
    final SettingsRepository repository = await makeRepository();
    expect(repository.load(), const LauncherSettings());
  });

  test('o Swipe Up abre a pesquisa de origem (plano, secção 13)', () async {
    final SettingsRepository repository = await makeRepository();
    expect(
      repository.load().actionFor(LauncherGesture.swipeUp),
      GestureAction.openSearch,
    );
  });

  test('guarda e volta a ler tudo', () async {
    final SettingsRepository repository = await makeRepository();

    const LauncherSettings saved = LauncherSettings(
      theme: ThemePreference.dark,
      fontScale: 1.2,
      itemSpacing: 12,
      showIcons: true,
      showClock: false,
      showDate: false,
      showAlphabetIndex: false,
      animations: false,
      use24HourClock: false,
      showSystemApps: false,
      searchPackageNames: true,
      searchAutoFocus: false,
      searchOpensSingleResult: true,
      favoritesLimit: 9,
      gestures: <LauncherGesture, GestureAction>{
        LauncherGesture.swipeUp: GestureAction.openAppList,
        LauncherGesture.swipeDown: GestureAction.none,
        LauncherGesture.swipeLeft: GestureAction.openFavorites,
        LauncherGesture.swipeRight: GestureAction.openSettings,
        LauncherGesture.doubleTap: GestureAction.lockScreen,
      },
    );

    await repository.save(saved);
    expect(repository.load(), saved);
  });

  test('valores fora dos limites são cortados no copyWith', () {
    const LauncherSettings settings = LauncherSettings();

    expect(settings.copyWith(fontScale: 99).fontScale, lessThanOrEqualTo(1.35));
    expect(settings.copyWith(fontScale: 0).fontScale, greaterThanOrEqualTo(0.85));
    expect(settings.copyWith(favoritesLimit: 100).favoritesLimit, 10);
    expect(settings.copyWith(favoritesLimit: 0).favoritesLimit, 3);
  });

  test('duration devolve zero quando as animações estão desligadas', () {
    const LauncherSettings on = LauncherSettings();
    const LauncherSettings off = LauncherSettings(animations: false);
    const Duration input = Duration(milliseconds: 200);

    expect(on.duration(input), input);
    expect(off.duration(input), Duration.zero);
  });

  test('reset apaga tudo', () async {
    final SettingsRepository repository = await makeRepository();
    await repository.save(const LauncherSettings(theme: ThemePreference.dark));

    expect(await repository.reset(), const LauncherSettings());
    expect(repository.load(), const LauncherSettings());
  });
}
