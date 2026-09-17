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

  test('os painéis são opacos de origem', () async {
    // Veio do primeiro utilizador a experimentar o Lume: o wallpaper por trás
    // da pesquisa atrapalhava a leitura.
    final SettingsRepository repository = await makeRepository();
    expect(repository.load().panelOpacity, 1);
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
      iconStyle: IconStyle.appIcons,
      panelOpacity: 0.8,
      showClock: false,
      showDate: false,
      showAlphabetIndex: false,
      animations: MotionStyle.none,
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
    expect(settings.copyWith(panelOpacity: 5).panelOpacity, 1);
    expect(settings.copyWith(panelOpacity: 0).panelOpacity, greaterThanOrEqualTo(0.7));
  });

  test('duration segue o estilo de animação escolhido', () {
    const Duration base = Duration(milliseconds: 200);

    expect(
      const LauncherSettings(animations: MotionStyle.none).duration(base),
      Duration.zero,
    );
    expect(
      const LauncherSettings().duration(base),
      base,
    );
    // Um estilo mais expressivo alonga o movimento.
    expect(
      const LauncherSettings(animations: MotionStyle.smooth).duration(base),
      greaterThan(base),
    );
    expect(
      const LauncherSettings(animations: MotionStyle.crisp).duration(base),
      lessThan(base),
    );
  });

  test('reset apaga tudo', () async {
    final SettingsRepository repository = await makeRepository();
    await repository.save(const LauncherSettings(theme: ThemePreference.dark));

    expect(await repository.reset(), const LauncherSettings());
    expect(repository.load(), const LauncherSettings());
  });
}
