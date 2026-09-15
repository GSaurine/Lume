import 'package:flutter_test/flutter_test.dart';
import 'package:lume_launcher/core/utils/text_normalizer.dart';

void main() {
  group('fold', () {
    test('remove acentos e passa a minúsculas', () {
      expect(TextNormalizer.fold('Áudio'), 'audio');
      expect(TextNormalizer.fold('CÂMARA'), 'camara');
      expect(TextNormalizer.fold('Coração'), 'coracao');
      expect(TextNormalizer.fold('  Spotify  '), 'spotify');
    });

    test('deixa intacto o que já é ASCII', () {
      expect(TextNormalizer.fold('WhatsApp'), 'whatsapp');
    });
  });

  group('indexLetter', () {
    test('devolve a inicial sem acento', () {
      expect(TextNormalizer.indexLetter('Áudio'), 'A');
      expect(TextNormalizer.indexLetter('spotify'), 'S');
    });

    test('agrupa números, símbolos e outros alfabetos em #', () {
      expect(TextNormalizer.indexLetter('1Password'), '#');
      expect(TextNormalizer.indexLetter('微信'), '#');
      expect(TextNormalizer.indexLetter(''), '#');
    });
  });

  group('words', () {
    test('divide em separadores comuns de nomes de apps', () {
      expect(TextNormalizer.words('google play store'),
          <String>['google', 'play', 'store']);
      expect(TextNormalizer.words('adobe-acrobat'), <String>['adobe', 'acrobat']);
      expect(TextNormalizer.words('files_by_google'),
          <String>['files', 'by', 'google']);
    });
  });
}
