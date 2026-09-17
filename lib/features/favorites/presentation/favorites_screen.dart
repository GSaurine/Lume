import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/launcher_constants.dart';
import '../../../core/theme/launcher_palette.dart';
import '../../../core/utils/launcher_route.dart';
import '../../../data/models/installed_app.dart';
import '../../apps/controller/apps_controller.dart';
import '../../apps/widgets/app_icon.dart';
import '../../settings/controller/settings_controller.dart';
import '../controller/favorites_controller.dart';

/// FASE 7 — gerir e reordenar favoritos.
class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<InstalledApp> favorites = ref.watch(favoriteAppsProvider);
    final int limit = ref.watch(settingsProvider.select((s) => s.favoritesLimit));
    final LauncherPalette palette = context.palette;

    return Scaffold(
      backgroundColor: palette.panel,
      appBar: AppBar(
        title: const Text('Favoritos'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).maybePop(),
          tooltip: 'Voltar',
        ),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: 'Adicionar',
            onPressed: () => Navigator.of(context).push(
              LauncherRoute.fromBottom<void>(
                const _AddFavoriteScreen(),
                style: ref.read(settingsProvider).animations,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: favorites.isEmpty
            ? const _EmptyFavorites()
            : Column(
                children: <Widget>[
                  if (favorites.length > limit)
                    _LimitNotice(shown: limit, total: favorites.length),
                  Expanded(
                    child: ReorderableListView.builder(
                      padding: const EdgeInsets.only(bottom: 32),
                      itemCount: favorites.length,
                      // onReorderItem já entrega o índice de destino ajustado.
                      onReorderItem: (int oldIndex, int newIndex) => ref
                          .read(favoritePackagesProvider.notifier)
                          .reorder(oldIndex, newIndex),
                      itemBuilder: (BuildContext context, int index) {
                        final InstalledApp app = favorites[index];
                        return Dismissible(
                          key: ValueKey<String>('fav-${app.id}'),
                          direction: DismissDirection.endToStart,
                          background: ColoredBox(
                            color: palette.danger.withValues(alpha: 0.18),
                            child: const Align(
                              alignment: Alignment.centerRight,
                              child: Padding(
                                padding: EdgeInsets.only(right: 24),
                                child: Icon(Icons.star_border_rounded),
                              ),
                            ),
                          ),
                          onDismissed: (_) => ref
                              .read(favoritePackagesProvider.notifier)
                              .remove(app.packageName),
                          child: ListTile(
                            leading: AppIcon(app: app),
                            title: Text(app.name),
                            subtitle: index >= limit
                                ? Text(
                                    'Fora dos $limit visíveis na Home',
                                    style: TextStyle(color: palette.tertiaryText),
                                  )
                                : null,
                            trailing: ReorderableDragStartListener(
                              index: index,
                              child: Icon(
                                Icons.drag_handle_rounded,
                                color: palette.tertiaryText,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _LimitNotice extends StatelessWidget {
  const _LimitNotice({required this.shown, required this.total});

  final int shown;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        LauncherMetrics.horizontalPadding,
        8,
        LauncherMetrics.horizontalPadding,
        8,
      ),
      child: Text(
        'A Home mostra os primeiros $shown de $total. '
        'Altere o limite em Definições > Aparência.',
        style: Theme.of(context).textTheme.bodySmall,
      ),
    );
  }
}

class _EmptyFavorites extends StatelessWidget {
  const _EmptyFavorites();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(
          'Sem favoritos.\n\n'
          'Mantenha um app premido em qualquer lista e escolha '
          '"Adicionar aos favoritos".',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    );
  }
}

/// Escolher apps para favoritos a partir da lista completa.
class _AddFavoriteScreen extends ConsumerStatefulWidget {
  const _AddFavoriteScreen();

  @override
  ConsumerState<_AddFavoriteScreen> createState() => _AddFavoriteScreenState();
}

class _AddFavoriteScreenState extends ConsumerState<_AddFavoriteScreen> {
  String _filter = '';

  @override
  Widget build(BuildContext context) {
    final List<String> favorites = ref.watch(favoritePackagesProvider);
    final List<InstalledApp> apps = ref
        .watch(visibleAppsProvider)
        .where((InstalledApp app) =>
            _filter.isEmpty || app.foldedName.contains(_filter.toLowerCase()))
        .toList(growable: false);

    return Scaffold(
      backgroundColor: context.palette.panel,
      appBar: AppBar(
        title: const Text('Adicionar aos favoritos'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.of(context).maybePop(),
          tooltip: 'Fechar',
        ),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: LauncherMetrics.horizontalPadding,
                vertical: 8,
              ),
              child: TextField(
                autocorrect: false,
                decoration: const InputDecoration(hintText: 'Filtrar'),
                style: Theme.of(context).textTheme.bodyLarge,
                onChanged: (String value) => setState(() => _filter = value),
              ),
            ),
            const Divider(),
            Expanded(
              child: ListView.builder(
                itemCount: apps.length,
                itemBuilder: (BuildContext context, int index) {
                  final InstalledApp app = apps[index];
                  final bool isFavorite = favorites.contains(app.packageName);
                  return CheckboxListTile(
                    value: isFavorite,
                    title: Text(app.name),
                    secondary: AppIcon(app: app),
                    onChanged: (_) => ref
                        .read(favoritePackagesProvider.notifier)
                        .toggle(app.packageName),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
