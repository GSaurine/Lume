import 'package:flutter_test/flutter_test.dart';
import 'package:lume_launcher/core/constants/launcher_symbols.dart';
import 'package:lume_launcher/core/utils/symbol_guesser.dart';

LauncherSymbol? guess(String name, String package) =>
    SymbolGuesser.guess(name: name, packageName: package);

void main() {
  group('aplicações conhecidas', () {
    test('acerta nas que quase toda a gente tem', () {
      expect(guess('Spotify', 'com.spotify.music'), LauncherSymbol.music);
      expect(guess('YouTube', 'com.google.android.youtube'), LauncherSymbol.video);
      expect(guess('Instagram', 'com.instagram.android'), LauncherSymbol.camera);
      expect(guess('LinkedIn', 'com.linkedin.android'), LauncherSymbol.work);
      expect(guess('WhatsApp', 'com.whatsapp'), LauncherSymbol.chat);
    });

    test('o package ganha ao nome', () {
      // O nome muda com o idioma do telemóvel; o package não. Mesmo que o
      // nome sugira outra coisa, a tabela de packages decide.
      expect(guess('Música', 'com.google.android.youtube'), LauncherSymbol.video);
    });
  });

  group('palpite por palavra-chave', () {
    test('apanha bancos que nunca poderíamos listar', () {
      // O caso que motivou isto: há milhares de bancos e quase todos dizem
      // "banco" ou "bank" algures.
      expect(guess('ActivoBank', 'wit.android.bcpBankingApp.activoBank'),
          LauncherSymbol.bank);
      expect(guess('Banco Alimentar', 'pt.exemplo.qualquer'), LauncherSymbol.bank);
      expect(guess('MyBank', 'com.exemplo.mybank'), LauncherSymbol.bank);
    });

    test('ignora acentos e maiúsculas', () {
      expect(guess('MÚSICA', 'com.exemplo.qualquer'), LauncherSymbol.music);
      expect(guess('Câmara Rápida', 'com.exemplo.qualquer'), LauncherSymbol.camera);
    });

    test('apanha plurais portugueses em -ões', () {
      // "cartões" não contém "cartao", por isso precisa de entrada própria.
      expect(guess('Cartões', 'com.exemplo.xyz'), LauncherSymbol.card);
      expect(guess('Cartão', 'com.exemplo.xyz'), LauncherSymbol.card);
    });

    test('a ordem da lista decide os empates', () {
      // "foto" está listado antes de "video": uma galeria chamada
      // "Fotos e Vídeos" fica com o ícone de fotografia.
      expect(guess('Fotos e Vídeos', 'com.exemplo.xyz'), LauncherSymbol.photo);
    });

    test('procura no nome e no package', () {
      expect(guess('Qualquer coisa', 'com.exemplo.weather'), LauncherSymbol.weather);
      expect(guess('Meteorologia', 'com.exemplo.xyz'), LauncherSymbol.weather);
    });
  });

  test('devolve null quando não faz ideia', () {
    expect(guess('Zxqv', 'com.zxqv.zxqv'), isNull);
  });

  group('catálogo', () {
    test('não há chaves repetidas', () {
      final Set<String> keys =
          LauncherSymbol.values.map((LauncherSymbol s) => s.key).toSet();
      expect(keys.length, LauncherSymbol.values.length);
    });

    test('todos os símbolos estão num grupo com etiqueta', () {
      for (final SymbolGroup group in SymbolGroup.values) {
        expect(group.symbols, isNotEmpty, reason: '${group.label} está vazio');
      }
      final int agrupados = SymbolGroup.values
          .fold(0, (int total, SymbolGroup g) => total + g.symbols.length);
      expect(agrupados, LauncherSymbol.values.length);
    });

    test('tryParse devolve o símbolo guardado, e null para lixo', () {
      expect(LauncherSymbol.tryParse('bank'), LauncherSymbol.bank);
      expect(LauncherSymbol.tryParse('nao_existe'), isNull);
      expect(LauncherSymbol.tryParse(null), isNull);
    });
  });
}
