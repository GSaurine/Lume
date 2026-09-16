import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lume_launcher/features/settings/presentation/about_screen.dart';

/// A versão vive em dois sítios: no `pubspec.yaml`, que define o que o Android
/// vê, e numa constante que o ecrã "Sobre" mostra. Separarem-se é fácil e
/// silencioso — o utilizador fica a ver um número errado sem ninguém dar por
/// isso. Este teste impede-o.
void main() {
  test('a versão do ecrã Sobre é a mesma do pubspec.yaml', () {
    final String pubspec = File('pubspec.yaml').readAsStringSync();
    final RegExpMatch? match =
        RegExp(r'^version:\s*(\S+)', multiLine: true).firstMatch(pubspec);

    expect(match, isNotNull, reason: 'não encontrei "version:" no pubspec.yaml');

    // "0.1.1+2" -> "0.1.1"; o que vem depois do "+" é o versionCode do Android.
    final String pubspecVersion = match!.group(1)!.split('+').first;

    expect(
      AboutScreen.version,
      pubspecVersion,
      reason: 'Atualize AboutScreen.version para $pubspecVersion.',
    );
  });

  test('o CHANGELOG tem uma entrada para a versão atual', () {
    final String changelog = File('CHANGELOG.md').readAsStringSync();
    expect(
      changelog,
      contains('## v${AboutScreen.version}'),
      reason: 'Falta a secção "## v${AboutScreen.version}" no CHANGELOG.md.',
    );
  });
}
