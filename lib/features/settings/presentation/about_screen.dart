import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/launcher_palette.dart';
import '../../apps/controller/apps_controller.dart';
import '../../favorites/controller/favorites_controller.dart';
import '../../launcher/controller/home_controller.dart';
import '../controller/settings_controller.dart';
import 'settings_screen.dart';

/// Sobre (plano, secções 16 e 17).
class AboutScreen extends ConsumerWidget {
  const AboutScreen({super.key});

  /// Manter em sincronia com `version:` no pubspec.yaml — há um teste que
  /// falha se as duas se separarem.
  static const String version = '0.1.2';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<bool> isDefault = ref.watch(isDefaultLauncherProvider);

    return Scaffold(
      backgroundColor: context.palette.panel,
      appBar: AppBar(title: const Text('Sobre')),
      body: SafeArea(
        top: false,
        child: ListView(
          children: <Widget>[
            const SettingsSectionTitle('Lume'),
            ListTile(
              title: const Text('Versão'),
              trailing: Text(version, style: Theme.of(context).textTheme.bodyLarge),
            ),
            ListTile(
              title: const Text('Ecrã inicial padrão'),
              subtitle: Text(
                switch (isDefault) {
                  AsyncData<bool>(value: true) => 'O Lume é o seu ecrã inicial',
                  AsyncData<bool>(value: false) => 'Outro launcher está definido',
                  _ => 'A verificar…',
                },
              ),
              trailing: (isDefault.value ?? true)
                  ? null
                  : TextButton(
                      onPressed: () =>
                          ref.read(isDefaultLauncherProvider.notifier).requestDefault(),
                      child: const Text('Definir'),
                    ),
            ),

            const SettingsSectionTitle('Privacidade'),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                'O Lume funciona inteiramente no dispositivo. Não tem servidor, '
                'não tem contas e não faz pedidos de rede — a app nem sequer '
                'declara a permissão de Internet.\n\n'
                'Os favoritos, as apps ocultas e as definições ficam no '
                'armazenamento local da app e desaparecem quando a desinstala.\n\n'
                'A lista de aplicações vem do PackageManager do Android e é lida '
                'de cada vez que é precisa; nada é enviado para fora.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),

            const SettingsSectionTitle('Manutenção'),
            ListTile(
              leading: const Icon(Icons.refresh_rounded),
              title: const Text('Recarregar aplicações'),
              subtitle: const Text('Se um app instalado não aparecer na lista'),
              onTap: () => ref.read(installedAppsProvider.notifier).reload(),
            ),
            ListTile(
              leading: Icon(Icons.restart_alt_rounded, color: context.palette.danger),
              title: Text(
                'Repor tudo',
                style: TextStyle(color: context.palette.danger),
              ),
              subtitle: const Text('Apaga favoritos, apps ocultas e definições'),
              onTap: () => _confirmReset(context, ref),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmReset(BuildContext context, WidgetRef ref) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('Repor tudo?'),
        content: const Text(
          'Favoritos, apps ocultas e todas as definições voltam ao estado '
          'inicial. As aplicações instaladas não são afetadas.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text('Repor', style: TextStyle(color: context.palette.danger)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await ref.read(settingsProvider.notifier).resetAll();
    ref
      ..invalidate(favoritePackagesProvider)
      ..invalidate(hiddenAppsProvider);

    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Definições repostas.')));
  }
}
