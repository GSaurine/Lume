import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume_launcher/core/providers/core_providers.dart';
import 'package:lume_launcher/data/models/installed_app.dart';
import 'package:lume_launcher/data/repositories/app_labels_repository.dart';
import 'package:lume_launcher/data/services/preferences_service.dart';
import 'package:lume_launcher/features/apps/controller/apps_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<AppLabelsRepository> makeRepository([Map<String, Object>? initial]) async {
  SharedPreferences.setMockInitialValues(initial ?? <String, Object>{});
  return AppLabelsRepository(await PreferencesService.load());
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppLabelsRepository', () {
    test('começa vazio', () async {
      final AppLabelsRepository repository = await makeRepository();
      expect(repository.labels(), isEmpty);
    });

    test('guarda e volta a ler', () async {
      final AppLabelsRepository repository = await makeRepository();
      await repository.save(<String, String>{'com.whatsapp': 'Zap'});
      expect(repository.labels(), <String, String>{'com.whatsapp': 'Zap'});
    });

    test('aceita nomes com caracteres que partiriam um formato de pares', () async {
      // É por isto que é JSON e não "package=nome": tudo o que se escolhesse
      // como separador pode aparecer dentro de um nome.
      final AppLabelsRepository repository = await makeRepository();
      const String awkward = 'a=b,c;d"e\\f{g}';
      await repository.save(<String, String>{'com.exemplo': awkward});
      expect(repository.labels()['com.exemplo'], awkward);
    });

    test('nomes em branco não são guardados', () async {
      final AppLabelsRepository repository = await makeRepository();
      final Map<String, String> saved =
          await repository.save(<String, String>{'com.exemplo': '   '});
      expect(saved, isEmpty);
      expect(repository.labels(), isEmpty);
    });

    test('espaços à volta são removidos', () async {
      final AppLabelsRepository repository = await makeRepository();
      await repository.save(<String, String>{'com.exemplo': '  Banco  '});
      expect(repository.labels()['com.exemplo'], 'Banco');
    });

    test('preferências corrompidas não rebentam o arranque', () async {
      final AppLabelsRepository repository = await makeRepository(<String, Object>{
        'flutter.app_labels': 'isto não é JSON',
      });
      expect(repository.labels(), isEmpty);
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
