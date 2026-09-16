import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/launcher_constants.dart';
import '../../../core/theme/launcher_palette.dart';
import '../../../data/models/installed_app.dart';
import '../../apps/widgets/app_tile.dart';
import '../../settings/controller/settings_controller.dart';
import '../controller/favorites_controller.dart';

/// Favoritos na Home (plano, secção 12).
///
/// Quando ainda não há favoritos mostramos uma dica em vez de espaço vazio:
/// o gesto de os criar (manter premido) não é descobrível sozinho.
class FavoritesSection extends ConsumerWidget {
  const FavoritesSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<InstalledApp> favorites = ref.watch(favoriteAppsProvider);
    final int limit = ref.watch(settingsProvider.select((s) => s.favoritesLimit));

    if (favorites.isEmpty) return const _EmptyFavoritesHint();

    final List<InstalledApp> visible = favorites.take(limit).toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (final InstalledApp app in visible)
          AppTile(
            app: app,
            key: ValueKey<String>('favorite-${app.id}'),
            textStyle:
                Theme.of(context).textTheme.headlineSmall.onWallpaper(context),
          ),
      ],
    );
  }
}

class _EmptyFavoritesHint extends StatelessWidget {
  const _EmptyFavoritesHint();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: LauncherMetrics.horizontalPadding,
        vertical: 8,
      ),
      child: Text(
        'Arraste uma letra à direita ou deslize para cima para pesquisar.\n'
        'Mantenha um app premido para o guardar aqui.',
        style: Theme.of(context)
            .textTheme
            .bodyMedium
            ?.copyWith(color: context.palette.secondaryText, height: 1.5)
            .onWallpaper(context),
      ),
    );
  }
}
