import 'package:flutter/material.dart';

import '../../data/models/launcher_settings.dart';

/// Decide que cor de destaque usar, a partir das definições e do tema em uso.
///
/// As cores da paleta já trazem um tom para o tema claro e outro para o
/// escuro. Uma cor escolhida à mão não traz nada disso: se a pessoa escolher
/// um azul-escuro, ele desaparece sobre o painel escuro, e um amarelo-claro
/// desaparece sobre o painel claro. Por isso o matiz e a saturação são os
/// dela e o brilho é ajustado — é o que mantém a cor legível sem lhe tirar a
/// escolha.
abstract final class AccentResolver {
  /// Faixas de luminosidade em que uma cor de destaque continua legível.
  static const (double, double) _darkRange = (0.62, 0.82);
  static const (double, double) _lightRange = (0.26, 0.46);

  /// Abaixo disto a cor lê-se como cinzento e o destaque perde-se.
  static const double _minSaturation = 0.32;

  static Color resolve(LauncherSettings settings, Brightness brightness) {
    final int? custom = settings.customAccentArgb;
    if (custom == null) {
      return Color(
        brightness == Brightness.dark
            ? settings.accent.darkValue
            : settings.accent.lightValue,
      );
    }
    return fit(Color(custom), brightness);
  }

  /// Ajusta uma cor qualquer para ficar legível no tema dado.
  static Color fit(Color color, Brightness brightness) {
    final HSLColor hsl = HSLColor.fromColor(color);
    final (double min, double max) =
        brightness == Brightness.dark ? _darkRange : _lightRange;

    return hsl
        .withSaturation(hsl.saturation.clamp(_minSaturation, 1))
        .withLightness(hsl.lightness.clamp(min, max))
        .toColor();
  }

  /// A cor tal como a pessoa a escolheu, para o seletor e para as amostras.
  static Color raw(double hue, double saturation) =>
      HSLColor.fromAHSL(1, hue, saturation, 0.55).toColor();
}
