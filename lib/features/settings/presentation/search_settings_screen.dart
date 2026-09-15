import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/launcher_palette.dart';
import '../../../data/models/launcher_settings.dart';
import '../controller/settings_controller.dart';
import 'settings_screen.dart';

/// Definições de pesquisa (plano, secção 16).
class SearchSettingsScreen extends ConsumerWidget {
  const SearchSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final LauncherSettings settings = ref.watch(settingsProvider);
    final SettingsNotifier controller = ref.read(settingsProvider.notifier);

    return Scaffold(
      backgroundColor: context.palette.panel,
      appBar: AppBar(title: const Text('Pesquisa')),
      body: SafeArea(
        top: false,
        child: ListView(
          children: <Widget>[
            const SettingsSectionTitle('Comportamento'),
            SwitchListTile(
              value: settings.searchAutoFocus,
              title: const Text('Abrir o teclado automaticamente'),
              onChanged: (bool value) => controller.setSearchAutoFocus(value: value),
            ),
            SwitchListTile(
              value: settings.searchOpensSingleResult,
              title: const Text('Abrir quando sobra um resultado'),
              subtitle: const Text(
                'Escrever "wha" abre logo o WhatsApp, sem tocar em nada',
              ),
              onChanged: (bool value) =>
                  controller.setSearchOpensSingleResult(value: value),
            ),
            SwitchListTile(
              value: settings.searchPackageNames,
              title: const Text('Pesquisar também no package name'),
              subtitle: const Text('Útil para encontrar apps do sistema'),
              onChanged: (bool value) => controller.setSearchPackageNames(value: value),
            ),
            const SettingsSectionTitle('Como funciona'),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
              child: Text(
                'A pesquisa é local e ordena por relevância: nome exato, '
                'início do nome, início de qualquer palavra e iniciais '
                '("gm" encontra "Google Maps"). Acentos são ignorados. '
                'Nada sai do dispositivo.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
