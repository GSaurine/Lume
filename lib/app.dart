import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'data/models/launcher_settings.dart';
import 'features/launcher/presentation/home_screen.dart';
import 'features/settings/controller/settings_controller.dart';

/// Raiz da aplicação.
class LumeApp extends ConsumerWidget {
  const LumeApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final double fontScale = ref.watch(settingsProvider.select((s) => s.fontScale));
    final double panelOpacity =
        ref.watch(settingsProvider.select((s) => s.panelOpacity));
    final ThemePreference theme = ref.watch(settingsProvider.select((s) => s.theme));

    return MaterialApp(
      title: 'Lume',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(fontScale: fontScale, panelOpacity: panelOpacity),
      darkTheme: AppTheme.dark(fontScale: fontScale, panelOpacity: panelOpacity),
      themeMode: theme.themeMode,
      localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const <Locale>[Locale('pt'), Locale('en')],
      // A escala de letra das definições do Lume está no tema; a escala de
      // acessibilidade do Android continua a ser aplicada por cima dela, de
      // propósito (plano, secção 14).
      home: const HomeScreen(),
    );
  }
}
