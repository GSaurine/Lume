import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app.dart';
import 'core/providers/core_providers.dart';
import 'data/services/preferences_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // O launcher desenha por cima do wallpaper e por baixo das barras do
  // sistema; as barras ficam transparentes.
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
    ),
  );

  // Carregado antes do primeiro frame para que os favoritos e o tema certos
  // apareçam de imediato, sem um flash de valores por omissão.
  final PreferencesService preferences = await PreferencesService.load();

  // Nomes de meses e dias da semana traduzidos (widget da data).
  await initializeDateFormatting();

  runApp(
    ProviderScope(
      overrides: [
        preferencesServiceProvider.overrideWithValue(preferences),
      ],
      child: const LumeApp(),
    ),
  );
}
