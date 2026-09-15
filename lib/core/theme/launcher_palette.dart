import 'package:flutter/material.dart';

/// Cores próprias do launcher.
///
/// Vivem numa [ThemeExtension] e não no [ColorScheme] porque a Home é
/// desenhada **por cima do wallpaper**: precisamos de tons de texto e de
/// véus (scrims) que o Material não modela.
@immutable
class LauncherPalette extends ThemeExtension<LauncherPalette> {
  const LauncherPalette({
    required this.primaryText,
    required this.secondaryText,
    required this.tertiaryText,
    required this.panel,
    required this.panelBorder,
    required this.scrim,
    required this.accent,
    required this.danger,
  });

  /// Texto sobre wallpaper claro.
  static const LauncherPalette light = LauncherPalette(
    primaryText: Color(0xFF101014),
    secondaryText: Color(0xFF4A4A52),
    tertiaryText: Color(0xFF8A8A93),
    panel: Color(0xF2FAFAFC),
    panelBorder: Color(0x14000000),
    scrim: Color(0x40FFFFFF),
    accent: Color(0xFF2B6CB0),
    danger: Color(0xFFB3261E),
  );

  /// Texto sobre wallpaper escuro.
  static const LauncherPalette dark = LauncherPalette(
    primaryText: Color(0xFFF4F4F6),
    secondaryText: Color(0xFFB4B4BC),
    tertiaryText: Color(0xFF75757E),
    panel: Color(0xF213131A),
    panelBorder: Color(0x1FFFFFFF),
    scrim: Color(0x59000000),
    accent: Color(0xFF8AB4F8),
    danger: Color(0xFFF2B8B5),
  );

  final Color primaryText;
  final Color secondaryText;
  final Color tertiaryText;

  /// Fundo de painéis, folhas e ecrãs de definições.
  final Color panel;
  final Color panelBorder;

  /// Véu por cima do wallpaper, para o texto continuar legível sobre
  /// fotografias claras/escuras.
  final Color scrim;
  final Color accent;
  final Color danger;

  @override
  LauncherPalette copyWith({
    Color? primaryText,
    Color? secondaryText,
    Color? tertiaryText,
    Color? panel,
    Color? panelBorder,
    Color? scrim,
    Color? accent,
    Color? danger,
  }) {
    return LauncherPalette(
      primaryText: primaryText ?? this.primaryText,
      secondaryText: secondaryText ?? this.secondaryText,
      tertiaryText: tertiaryText ?? this.tertiaryText,
      panel: panel ?? this.panel,
      panelBorder: panelBorder ?? this.panelBorder,
      scrim: scrim ?? this.scrim,
      accent: accent ?? this.accent,
      danger: danger ?? this.danger,
    );
  }

  @override
  LauncherPalette lerp(ThemeExtension<LauncherPalette>? other, double t) {
    if (other is! LauncherPalette) return this;
    return LauncherPalette(
      primaryText: Color.lerp(primaryText, other.primaryText, t)!,
      secondaryText: Color.lerp(secondaryText, other.secondaryText, t)!,
      tertiaryText: Color.lerp(tertiaryText, other.tertiaryText, t)!,
      panel: Color.lerp(panel, other.panel, t)!,
      panelBorder: Color.lerp(panelBorder, other.panelBorder, t)!,
      scrim: Color.lerp(scrim, other.scrim, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
    );
  }
}

extension LauncherPaletteContext on BuildContext {
  /// Atalho: `context.palette.primaryText`.
  LauncherPalette get palette =>
      Theme.of(this).extension<LauncherPalette>() ?? LauncherPalette.dark;
}
