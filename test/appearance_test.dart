import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume_launcher/core/constants/launcher_fonts.dart';
import 'package:lume_launcher/core/theme/accent_resolver.dart';
import 'package:lume_launcher/data/models/launcher_settings.dart';

void main() {
  group('LauncherFont', () {
    test('a fonte do sistema não toca no estilo', () {
      const TextStyle style = TextStyle(fontSize: 20, fontWeight: FontWeight.w700);
      expect(LauncherFont.system.apply(style), style);
    });

    test('define o eixo wght e não só o fontWeight', () {
      // São fontes variáveis: sem fontVariations a espessura fica na de
      // origem, sem aviso nenhum.
      final TextStyle style = LauncherFont.inter.apply(
        const TextStyle(fontWeight: FontWeight.w700),
      );

      expect(style.fontFamily, 'Inter');
      expect(style.fontVariations, isNotNull);
      expect(style.fontVariations!.single.axis, 'wght');
      expect(style.fontVariations!.single.value, 700);
    });

    test('corta a espessura ao que a família suporta', () {
      // A Lora só vai de 400 a 700. Pedir-lhe 200 — o peso do relógio fino —
      // daria um resultado errado em silêncio.
      final TextStyle thin = LauncherFont.lora.apply(
        const TextStyle(fontWeight: FontWeight.w200),
      );
      expect(thin.fontVariations!.single.value, 400);

      final TextStyle heavy = LauncherFont.lora.apply(
        const TextStyle(fontWeight: FontWeight.w900),
      );
      expect(heavy.fontVariations!.single.value, 700);
    });

    test('sem fontWeight assume o peso normal', () {
      final TextStyle style = LauncherFont.outfit.apply(const TextStyle());
      expect(style.fontVariations!.single.value, 400);
    });

    test('todas as chaves são distintas e o parse aguenta lixo', () {
      final Set<String> keys =
          LauncherFont.values.map((LauncherFont f) => f.key).toSet();
      expect(keys.length, LauncherFont.values.length);
      expect(LauncherFont.parse('nao_existe'), LauncherFont.system);
      expect(LauncherFont.parse(null), LauncherFont.system);
    });
  });

  group('AccentResolver', () {
    test('sem cor personalizada usa o tom certo da paleta', () {
      const LauncherSettings settings = LauncherSettings(accent: AccentColor.violet);

      expect(
        AccentResolver.resolve(settings, Brightness.dark).toARGB32(),
        AccentColor.violet.darkValue,
      );
      expect(
        AccentResolver.resolve(settings, Brightness.light).toARGB32(),
        AccentColor.violet.lightValue,
      );
    });

    test('a cor personalizada ganha à paleta', () {
      const LauncherSettings settings =
          LauncherSettings(customAccentArgb: 0xFF00FF00);
      final Color resolved = AccentResolver.resolve(settings, Brightness.dark);
      expect(resolved.toARGB32(), isNot(AccentColor.blue.darkValue));
    });

    test('mantém o matiz que a pessoa escolheu', () {
      const double hue = 120; // verde
      final Color chosen = AccentResolver.raw(hue, 0.8);

      for (final Brightness brightness in Brightness.values) {
        final HSLColor fitted =
            HSLColor.fromColor(AccentResolver.fit(chosen, brightness));
        expect((fitted.hue - hue).abs(), lessThan(1.5), reason: '$brightness');
      }
    });

    test('um preto escolhido à mão continua visível nos dois temas', () {
      // O caso que o ajuste existe para evitar: escolher preto ou branco
      // fazia a cor desaparecer num dos temas.
      for (final Color extreme in <Color>[
        const Color(0xFF000000),
        const Color(0xFFFFFFFF),
      ]) {
        final HSLColor dark =
            HSLColor.fromColor(AccentResolver.fit(extreme, Brightness.dark));
        final HSLColor light =
            HSLColor.fromColor(AccentResolver.fit(extreme, Brightness.light));

        expect(dark.lightness, greaterThanOrEqualTo(0.6));
        expect(light.lightness, lessThanOrEqualTo(0.5));
      }
    });

    test('um cinzento ganha saturação suficiente para se ler como cor', () {
      final HSLColor fitted = HSLColor.fromColor(
        AccentResolver.fit(const Color(0xFF808080), Brightness.dark),
      );
      expect(fitted.saturation, greaterThanOrEqualTo(0.3));
    });
  });

  group('ClockStyle', () {
    test('só o empilhado parte o relógio em duas linhas', () {
      final List<ClockStyle> stacked =
          ClockStyle.values.where((ClockStyle s) => s.isStacked).toList();
      expect(stacked, <ClockStyle>[ClockStyle.stacked]);
    });

    test('as chaves são distintas e o parse aguenta lixo', () {
      final Set<String> keys =
          ClockStyle.values.map((ClockStyle s) => s.key).toSet();
      expect(keys.length, ClockStyle.values.length);
      expect(ClockStyle.parse('nao_existe'), ClockStyle.thin);
    });
  });
}
