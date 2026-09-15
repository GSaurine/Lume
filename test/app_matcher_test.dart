import 'package:flutter_test/flutter_test.dart';
import 'package:lume_launcher/data/models/installed_app.dart';
import 'package:lume_launcher/features/search/controller/search_controller.dart';

InstalledApp app(String name, {String package = 'com.example.app'}) => InstalledApp(
      name: name,
      packageName: package,
      activityName: '$package.MainActivity',
    );

int scoreOf(String name, String query, {String package = 'com.example.app'}) =>
    AppMatcher.score(
      app: app(name, package: package),
      query: query,
      matchPackageName: false,
    );

void main() {
  group('AppMatcher', () {
    test('não corresponde quando não há relação', () {
      expect(scoreOf('Spotify', 'xyz'), 0);
    });

    test('prefixo do nome ganha a correspondência no meio', () {
      expect(scoreOf('WhatsApp', 'wha'), greaterThan(scoreOf('Ver no WhatsApp', 'wha')));
    });

    test('encontra pelo início de qualquer palavra', () {
      expect(scoreOf('Google Drive', 'drive'), greaterThan(0));
    });

    test('encontra pelas iniciais', () {
      expect(scoreOf('Google Maps', 'gm'), greaterThan(0));
      // Uma inicial só é ambígua de mais para contar como tal.
      expect(scoreOf('Google Maps', 'g'), greaterThan(0));
    });

    test('ignora acentos nos dois lados', () {
      expect(
        AppMatcher.score(app: app('Câmara'), query: 'camara', matchPackageName: false),
        greaterThan(0),
      );
    });

    test('nome mais curto ganha em caso de empate', () {
      expect(scoreOf('Fotos', 'fotos'), greaterThan(scoreOf('Fotos e vídeos', 'fotos')));
    });

    test('só pesquisa no package quando a definição está ligada', () {
      final InstalledApp target = app('Definições', package: 'com.android.settings');

      expect(
        AppMatcher.score(app: target, query: 'settings', matchPackageName: false),
        0,
      );
      expect(
        AppMatcher.score(app: target, query: 'settings', matchPackageName: true),
        greaterThan(0),
      );
    });

    test('um favorito fica à frente de um não favorito com a mesma relevância', () {
      final int favorite = AppMatcher.score(
        app: app('Telegram'),
        query: 'tel',
        matchPackageName: false,
        favoriteRank: 0,
      );
      final int plain = AppMatcher.score(
        app: app('Telegram'),
        query: 'tel',
        matchPackageName: false,
      );
      expect(favorite, greaterThan(plain));
    });

    test('query vazia aceita tudo', () {
      expect(scoreOf('Spotify', ''), greaterThan(0));
    });
  });
}
