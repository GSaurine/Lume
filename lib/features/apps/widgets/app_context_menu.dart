import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/launcher_constants.dart';
import '../../../core/theme/launcher_palette.dart';
import '../../../data/models/installed_app.dart';
import '../../favorites/controller/favorites_controller.dart';
import '../controller/apps_controller.dart';

/// FASE 7 — menu de Long Press (plano, secção 12).
Future<void> showAppContextMenu(BuildContext context, InstalledApp app) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (BuildContext sheetContext) => _AppContextMenu(app: app),
  );
}

class _AppContextMenu extends ConsumerWidget {
  const _AppContextMenu({required this.app});

  final InstalledApp app;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final LauncherPalette palette = context.palette;
    final bool isFavorite = ref.watch(
      favoritePackagesProvider.select((List<String> f) => f.contains(app.packageName)),
    );
    final bool isHidden = ref.watch(
      hiddenAppsProvider.select((Set<String> h) => h.contains(app.packageName)),
    );

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 4, 24, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(app.name, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 2),
                Text(
                  app.packageName,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: palette.tertiaryText,
                      ),
                ),
              ],
            ),
          ),
          const Divider(),
          ListTile(
            leading: Icon(isFavorite ? Icons.star_rounded : Icons.star_border_rounded),
            title: Text(isFavorite ? 'Remover dos favoritos' : 'Adicionar aos favoritos'),
            onTap: () async {
              final NavigatorState navigator = Navigator.of(context);
              await ref.read(favoritePackagesProvider.notifier).toggle(app.packageName);
              if (navigator.mounted) navigator.pop();
            },
          ),
          ListTile(
            leading: Icon(
              isHidden ? Icons.visibility_rounded : Icons.visibility_off_outlined,
            ),
            title: Text(isHidden ? 'Mostrar na lista' : 'Ocultar da lista'),
            subtitle: isHidden
                ? null
                : const Text('Continua a aparecer na pesquisa por nome exato.'),
            onTap: () async {
              final NavigatorState navigator = Navigator.of(context);
              await ref.read(hiddenAppsProvider.notifier).toggle(app.packageName);
              if (navigator.mounted) navigator.pop();
            },
          ),
          ListTile(
            leading: const Icon(Icons.info_outline_rounded),
            title: const Text('Informações da aplicação'),
            onTap: () async {
              final NavigatorState navigator = Navigator.of(context);
              await ref.read(appLauncherProvider).openAppInfo(app.packageName);
              if (navigator.mounted) navigator.pop();
            },
          ),
          if (!app.isSystemApp)
            ListTile(
              leading: Icon(Icons.delete_outline_rounded, color: palette.danger),
              title: Text('Desinstalar', style: TextStyle(color: palette.danger)),
              onTap: () async {
                final NavigatorState navigator = Navigator.of(context);
                // Quem confirma é o Android; nós só abrimos o pedido.
                await ref.read(appLauncherProvider).requestUninstall(app.packageName);
                if (navigator.mounted) navigator.pop();
              },
            ),
          const SizedBox(height: LauncherMetrics.horizontalPadding / 2),
        ],
      ),
    );
  }
}
