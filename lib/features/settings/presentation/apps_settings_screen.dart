import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/launcher_symbols.dart';
import '../../../core/theme/launcher_palette.dart';
import '../../../data/models/installed_app.dart';
import '../../../data/models/launcher_settings.dart';
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
    final Map<String, String> labels = ref.watch(appLabelsProvider);
    final Map<String, String> symbols = ref.watch(appSymbolsProvider);
    final Map<String, InstalledApp> byPackage = <String, InstalledApp>{
      for (final InstalledApp app in ref.watch(visibleAppsProvider))
        app.packageName: app,
    };
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
            SettingsSectionTitle('Nomes personalizados (${labels.length})'),
            if (labels.isEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Text(
                  'Mantenha um app premido e escolha "Dar outro nome" para o '
                  'chamar como quiser. O nome fica ligado ao package, por isso '
                  'sobrevive a atualizações e a mudanças de idioma.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              )
            else ...<Widget>[
              for (final MapEntry<String, String> entry in labels.entries)
                ListTile(
                  leading: switch (byPackage[entry.key]) {
                    final InstalledApp app =>
                      AppIcon(app: app, style: IconStyle.symbols),
                    null => null,
                  },
                  title: Text(entry.value),
                  subtitle: Text(entry.key),
                  trailing: TextButton(
                    onPressed: () =>
                        ref.read(appLabelsProvider.notifier).reset(entry.key),
                    child: const Text('Repor'),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: OutlinedButton(
                  onPressed: () => ref.read(appLabelsProvider.notifier).resetAll(),
                  child: const Text('Repor todos os nomes'),
                ),
              ),
            ],

            SettingsSectionTitle('Ícones escolhidos (${symbols.length})'),
            if (symbols.isEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Text(
                  'O Lume sugere um símbolo a cada aplicação a partir do nome '
                  'e do package. Mantenha uma premida e escolha "Escolher '
                  'ícone" para trocar — a sua escolha ganha sempre ao palpite.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              )
            else ...<Widget>[
              for (final MapEntry<String, String> entry in symbols.entries)
                if (byPackage[entry.key] case final InstalledApp app)
                  ListTile(
                    leading: AppIcon(app: app, style: IconStyle.symbols),
                    title: Text(app.name),
                    subtitle: Text(
                      LauncherSymbol.tryParse(entry.value)?.label ?? entry.value,
                    ),
                    trailing: TextButton(
                      onPressed: () => ref
                          .read(appSymbolsProvider.notifier)
                          .assign(entry.key, null),
                      child: const Text('Automático'),
                    ),
                  ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: OutlinedButton(
                  onPressed: () => ref.read(appSymbolsProvider.notifier).resetAll(),
                  child: const Text('Repor todos os ícones'),
                ),
              ),
            ],

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
                  leading: AppIcon(app: app, style: IconStyle.symbols),
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
