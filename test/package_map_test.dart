import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume_launcher/core/constants/launcher_constants.dart';
import 'package:lume_launcher/core/providers/core_providers.dart';
import 'package:lume_launcher/data/models/installed_app.dart';
import 'package:lume_launcher/data/repositories/package_map_repository.dart';
import 'package:lume_launcher/data/services/preferences_service.dart';
import 'package:lume_launcher/features/apps/controller/apps_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<PackageMapRepository> makeRepository([Map<String, Object>? initial]) async {
  SharedPreferences.setMockInitialValues(initial ?? <String, Object>{});
  return PackageMapRepository(
    await PreferencesService.load(),
    PreferenceKeys.appLabels,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PackageMapRepository', () {
    test('começa vazio', () async {
      final PackageMapRepository repository = await makeRepository();
      expect(repository.read(), isEmpty);
    });

    test('guarda e volta a ler', () async {
      final PackageMapRepository repository = await makeRepository();
      await repository.save(<String, String>{'com.whatsapp': 'Zap'});
      expect(repository.read(), <String, String>{'com.whatsapp': 'Zap'});
    });

    test('aceita nomes com caracteres que partiriam um formato de pares', () async {
      // É por isto que é JSON e não "package=nome": tudo o que se escolhesse
      // como separador pode aparecer dentro de um nome.
      final PackageMapRepository repository = await makeRepository();
      const String awkward = 'a=b,c;d"e\\f{g}';
      await repository.save(<String, String>{'com.exemplo': awkward});
      expect(repository.read()['com.exemplo'], awkward);
    });

    test('nomes em branco não são guardados', () async {
      final PackageMapRepository repository = await makeRepository();
      final Map<String, String> saved =
          await repository.save(<String, String>{'com.exemplo': '   '});
      expect(saved, isEmpty);
      expect(repository.read(), isEmpty);
    });

    test('espaços à volta são removidos', () async {
      final PackageMapRepository repository = await makeRepository();
      await repository.save(<String, String>{'com.exemplo': '  Banco  '});
      expect(repository.read()['com.exemplo'], 'Banco');
    });

    test('preferências corrompidas não rebentam o arranque', () async {
      final PackageMapRepository repository = await makeRepository(<String, Object>{
        'flutter.app_labels': 'isto não é JSON',
      });
      expect(repository.read(), isEmpty);
    });
  });

  group('AppLabelsNotifier', () {
    Future<ProviderContainer> makeContainer() async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final PreferencesService preferences = await PreferencesService.load();
      final ProviderContainer container = ProviderContainer(
        overrides: [preferencesServiceProvider.overrideWithValue(preferences)],
      );
      addTearDown(container.dispose);
      return container;
    }

    test('renomear e repor', () async {
      final ProviderContainer container = await makeContainer();
      final AppLabelsNotifier notifier = container.read(appLabelsProvider.notifier);

      await notifier.rename('com.whatsapp', 'Zap');
      expect(container.read(appLabelsProvider)['com.whatsapp'], 'Zap');

      await notifier.reset('com.whatsapp');
      expect(container.read(appLabelsProvider), isEmpty);
    });
  });

  group('InstalledApp.withName', () {
    const InstalledApp app = InstalledApp(
      name: 'Autenticação Gov',
      packageName: 'pt.gov.autenticacao',
      activityName: 'pt.gov.autenticacao.Main',
    );

    test('muda também a letra do índice e a chave de pesquisa', () {
      expect(app.indexLetter, 'A');
      expect(app.foldedName, 'autenticacao gov');

      final InstalledApp renamed = app.withName('Gov');
      expect(renamed.indexLetter, 'G');
      expect(renamed.foldedName, 'gov');
    });

    test('mantém a identidade da aplicação', () {
      final InstalledApp renamed = app.withName('Gov');
      expect(renamed.packageName, app.packageName);
      expect(renamed.activityName, app.activityName);
      expect(renamed.isSystemApp, app.isSystemApp);
    });
  });
}
