import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/launcher_palette.dart';
import '../../../data/models/installed_app.dart';
import '../../apps/controller/apps_controller.dart';
import '../../apps/widgets/app_icon.dart';
import '../controller/settings_controller.dart';
import 'settings_screen.dart';

/// Definições de aplicações: apps do sistema e apps ocultas.
class AppsSettingsScreen extends ConsumerWidget {
  const AppsSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool showSystemApps =
        ref.watch(settingsProvider.select((s) => s.showSystemApps));
    final Set<String> hidden = ref.watch(hiddenAppsProvider);
    final List<InstalledApp> allApps =
        ref.watch(installedAppsProvider).value ?? const <InstalledApp>[];
    final List<InstalledApp> hiddenApps = allApps
        .where((InstalledApp app) => hidden.contains(app.packageName))
        .toList(growable: false);

    return Scaffold(
      backgroundColor: context.palette.panel,
      appBar: AppBar(
        title: const Text('Aplicações'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Recarregar lista',
            onPressed: () => ref.read(installedAppsProvider.notifier).reload(),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          children: <Widget>[
            const SettingsSectionTitle('Visibilidade'),
            SwitchListTile(
              value: showSystemApps,
              title: const Text('Mostrar aplicações do sistema'),
              subtitle: const Text(
                'Inclui Definições, Câmara, Telefone e outras pré-instaladas',
              ),
              onChanged: (bool value) =>
                  ref.read(settingsProvider.notifier).setShowSystemApps(value: value),
            ),
            ListTile(
              title: const Text('Aplicações detetadas'),
              trailing: Text(
                '${allApps.length}',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
            SettingsSectionTitle('Ocultas (${hiddenApps.length})'),
            if (hiddenApps.isEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Text(
                  'Nenhuma aplicação oculta. Mantenha um app premido numa '
                  'lista para o ocultar.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              )
            else ...<Widget>[
              for (final InstalledApp app in hiddenApps)
                ListTile(
                  leading: AppIcon(packageName: app.packageName),
                  title: Text(app.name),
                  trailing: TextButton(
                    onPressed: () =>
                        ref.read(hiddenAppsProvider.notifier).toggle(app.packageName),
                    child: const Text('Mostrar'),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: OutlinedButton(
                  onPressed: () => ref.read(hiddenAppsProvider.notifier).showAll(),
                  child: const Text('Mostrar todas'),
                ),
              ),
            ],
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
