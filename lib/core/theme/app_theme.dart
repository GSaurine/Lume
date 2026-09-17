import 'package:flutter/material.dart';

import '../../data/models/launcher_settings.dart';
import '../constants/launcher_fonts.dart';
import 'accent_resolver.dart';
import 'launcher_palette.dart';

/// FASE 9 — temas claro e escuro.
///
/// Material 3 como base, mas sem a sua "cor de superfície": a Home é
/// transparente e mostra o wallpaper (plano, secção 18).
abstract final class AppTheme {
  static ThemeData light(LauncherSettings settings) =>
      _build(Brightness.light, LauncherPalette.light, settings);

  static ThemeData dark(LauncherSettings settings) =>
      _build(Brightness.dark, LauncherPalette.dark, settings);

  static ThemeData _build(
    Brightness brightness,
    LauncherPalette basePalette,
    LauncherSettings settings,
  ) {
    final double fontScale = settings.fontScale;
    final Color accent = AccentResolver.resolve(settings, brightness);
    // A transparência dos painéis vive só aqui. Assim tudo o que use
    // `context.palette.panel` — pesquisa, lista, definições, folhas — segue a
    // definição sem ter de a ler por conta própria.
    final LauncherPalette palette = basePalette.copyWith(
      panel: basePalette.panel.withValues(alpha: settings.panelOpacity),
      accent: accent,
    );
    final ColorScheme scheme = ColorScheme.fromSeed(
      seedColor: palette.accent,
      brightness: brightness,
    ).copyWith(
      surface: palette.panel,
      onSurface: palette.primaryText,
      error: palette.danger,
    );

    final TextTheme text = _textTheme(palette, fontScale, settings.font);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      textTheme: text,
      extensions: <ThemeExtension<dynamic>>[palette],

      // A Home desenha sobre o wallpaper; quem precisa de fundo (definições,
      // folhas) pinta-o explicitamente com `palette.panel`.
      scaffoldBackgroundColor: Colors.transparent,
      canvasColor: Colors.transparent,
      splashFactory: InkSparkle.splashFactory,

      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: text.titleLarge,
        iconTheme: IconThemeData(color: palette.secondaryText),
      ),
      listTileTheme: ListTileThemeData(
        textColor: palette.primaryText,
        iconColor: palette.secondaryText,
        titleTextStyle: text.bodyLarge,
        subtitleTextStyle: text.bodySmall,
      ),
      dividerTheme: DividerThemeData(color: palette.panelBorder, space: 1, thickness: 1),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (Set<WidgetState> states) =>
              states.contains(WidgetState.selected) ? palette.accent : palette.tertiaryText,
        ),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: palette.accent,
        inactiveTrackColor: palette.panelBorder,
        thumbColor: palette.accent,
        trackHeight: 2,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: palette.panel,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: palette.tertiaryText,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: palette.panel,
        contentTextStyle: text.bodyMedium,
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: InputBorder.none,
        focusedBorder: InputBorder.none,
        enabledBorder: InputBorder.none,
        hintStyle: text.headlineSmall?.copyWith(color: palette.tertiaryText),
        contentPadding: EdgeInsets.zero,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: <TargetPlatform, PageTransitionsBuilder>{
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
        },
      ),
    );
  }

  /// Escala tipográfica própria. Um launcher tem poucos tamanhos: relógio,
  /// nome de app e legenda.
  static TextTheme _textTheme(
    LauncherPalette palette,
    double scale,
    LauncherFont font,
  ) {
    double size(double value) => value * scale;

    // A fonte é aplicada de uma vez em _applyFont, mais abaixo. Com fontes
    // variáveis não basta o fontWeight: é preciso o eixo `wght`, e há que
    // respeitar o intervalo de espessuras de cada família.
    return _applyFont(
      font,
      TextTheme(
      // Relógio.
      displayLarge: TextStyle(
        fontSize: size(64),
        height: 1,
        fontWeight: FontWeight.w200,
        letterSpacing: -2,
        color: palette.primaryText,
      ),
      // Data.
      titleMedium: TextStyle(
        fontSize: size(15),
        height: 1.3,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.2,
        color: palette.secondaryText,
      ),
      titleLarge: TextStyle(
        fontSize: size(20),
        fontWeight: FontWeight.w500,
        color: palette.primaryText,
      ),
      // Favoritos na Home.
      headlineSmall: TextStyle(
        fontSize: size(23),
        height: 1.25,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.3,
        color: palette.primaryText,
      ),
      // Itens da lista de apps.
      bodyLarge: TextStyle(
        fontSize: size(17),
        height: 1.3,
        fontWeight: FontWeight.w400,
        color: palette.primaryText,
      ),
      bodyMedium: TextStyle(
        fontSize: size(15),
        height: 1.35,
        color: palette.secondaryText,
      ),
      bodySmall: TextStyle(
        fontSize: size(13),
        height: 1.35,
        color: palette.secondaryText,
      ),
      // Índice alfabético.
      labelSmall: TextStyle(
        fontSize: size(11),
        height: 1.15,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.4,
        color: palette.tertiaryText,
      ),
      labelLarge: TextStyle(
        fontSize: size(14),
        fontWeight: FontWeight.w500,
        color: palette.accent,
      ),
      ),
    );
  }

  /// Passa cada estilo do tema pela fonte escolhida.
  static TextTheme _applyFont(LauncherFont font, TextTheme theme) {
    TextStyle? f(TextStyle? style) => style == null ? null : font.apply(style);

    return TextTheme(
      displayLarge: f(theme.displayLarge),
      titleMedium: f(theme.titleMedium),
      titleLarge: f(theme.titleLarge),
      headlineSmall: f(theme.headlineSmall),
      bodyLarge: f(theme.bodyLarge),
      bodyMedium: f(theme.bodyMedium),
      bodySmall: f(theme.bodySmall),
      labelSmall: f(theme.labelSmall),
      labelLarge: f(theme.labelLarge),
    );
  }
}
