import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'data/models/launcher_settings.dart';
import 'features/launcher/presentation/home_screen.dart';
import 'features/settings/controller/settings_controller.dart';

/// Raiz da aplicação.
class LumeApp extends ConsumerStatefulWidget {
  const LumeApp({super.key});

  /// Aplica "Manter sempre de pé". Só afeta a atividade do Lume: as outras
  /// aplicações continuam a rodar. Uma lista vazia devolve a decisão ao
  /// Android, que segue a rotação automática do sistema.
  ///
  /// Em ecrãs grandes (tablets, dobráveis abertos) o Android 16 ignora o
  /// pedido; num telemóvel é respeitado.
  static Future<void> applyOrientation({required bool lockPortrait}) =>
      SystemChrome.setPreferredOrientations(
        lockPortrait ? const <DeviceOrientation>[DeviceOrientation.portraitUp] : const <DeviceOrientation>[],
      );

  @override
  ConsumerState<LumeApp> createState() => _LumeAppState();
}

class _LumeAppState extends ConsumerState<LumeApp> {
  @override
  void initState() {
    super.initState();
    unawaited(
      LumeApp.applyOrientation(lockPortrait: ref.read(settingsProvider).lockPortrait),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<bool>(
      settingsProvider.select((LauncherSettings s) => s.lockPortrait),
      (bool? previous, bool next) => unawaited(LumeApp.applyOrientation(lockPortrait: next)),
    );

    final LauncherSettings settings = ref.watch(settingsProvider);

    return MaterialApp(
      title: 'Lume',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(settings),
      darkTheme: AppTheme.dark(settings),
      themeMode: settings.theme.themeMode,
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
