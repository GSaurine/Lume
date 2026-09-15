import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume_launcher/core/providers/core_providers.dart';
import 'package:lume_launcher/data/services/preferences_service.dart';
import 'package:lume_launcher/features/favorites/controller/favorites_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<ProviderContainer> makeContainer(Map<String, Object> initial) async {
  SharedPreferences.setMockInitialValues(initial);
  final PreferencesService preferences = await PreferencesService.load();

  final ProviderContainer container = ProviderContainer(
    overrides: [preferencesServiceProvider.overrideWithValue(preferences)],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('começa vazio', () async {
    final ProviderContainer container = await makeContainer(<String, Object>{});
    expect(container.read(favoritePackagesProvider), isEmpty);
  });

  test('lê os favoritos guardados, pela ordem em que ficaram', () async {
    final ProviderContainer container = await makeContainer(<String, Object>{
      'flutter.favorites': <String>['com.whatsapp', 'com.spotify.music'],
    });

    expect(
      container.read(favoritePackagesProvider),
      <String>['com.whatsapp', 'com.spotify.music'],
    );
  });

  test('toggle adiciona e remove', () async {
    final ProviderContainer container = await makeContainer(<String, Object>{});
    final FavoritesNotifier notifier = container.read(favoritePackagesProvider.notifier);

    await notifier.toggle('com.whatsapp');
    expect(container.read(favoritePackagesProvider), <String>['com.whatsapp']);

    await notifier.toggle('com.whatsapp');
    expect(container.read(favoritePackagesProvider), isEmpty);
  });

  test('não duplica o mesmo package', () async {
    final ProviderContainer container = await makeContainer(<String, Object>{});
    final FavoritesNotifier notifier = container.read(favoritePackagesProvider.notifier);

    await notifier.add('com.whatsapp');
    await notifier.add('com.whatsapp');

    expect(container.read(favoritePackagesProvider), <String>['com.whatsapp']);
  });

  test('reorder move o favorito para a posição certa', () async {
    final ProviderContainer container = await makeContainer(<String, Object>{
      'flutter.favorites': <String>['a', 'b', 'c'],
    });
    final FavoritesNotifier notifier = container.read(favoritePackagesProvider.notifier);

    await notifier.reorder(0, 2);
    expect(container.read(favoritePackagesProvider), <String>['b', 'c', 'a']);

    await notifier.reorder(2, 0);
    expect(container.read(favoritePackagesProvider), <String>['a', 'b', 'c']);
  });

  test('a ordem sobrevive a uma nova leitura das preferências', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final PreferencesService preferences = await PreferencesService.load();

    final ProviderContainer first = ProviderContainer(
      overrides: [preferencesServiceProvider.overrideWithValue(preferences)],
    );
    await first.read(favoritePackagesProvider.notifier).add('com.whatsapp');
    await first.read(favoritePackagesProvider.notifier).add('com.spotify.music');
    first.dispose();

    final PreferencesService reloaded = await PreferencesService.load();
    final ProviderContainer second = ProviderContainer(
      overrides: [preferencesServiceProvider.overrideWithValue(reloaded)],
    );
    addTearDown(second.dispose);

    expect(
      second.read(favoritePackagesProvider),
      <String>['com.whatsapp', 'com.spotify.music'],
    );
  });
}
