import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/launcher_constants.dart';
import '../../../core/theme/launcher_palette.dart';
import '../../../data/models/installed_app.dart';
import '../../apps/widgets/app_icon.dart';
import '../../apps/widgets/app_tile.dart';
import '../../launcher/controller/home_controller.dart';
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
    final bool reordering = ref.watch(reorderModeProvider);

    if (favorites.isEmpty) return const _EmptyFavoritesHint();

    final List<InstalledApp> visible = favorites.take(limit).toList(growable: false);

    if (reordering) return _ReorderableFavorites(apps: visible);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (final InstalledApp app in visible)
          AppTile(
            app: app,
            key: ValueKey<String>('favorite-${app.id}'),
            overWallpaper: true,
            textAlign: ref
                .watch(settingsProvider.select((s) => s.contentAlignment))
                .textAlign,
            textStyle:
                Theme.of(context).textTheme.headlineSmall.onWallpaper(context),
          ),
      ],
    );
  }
}

/// A mesma lista, mas com setas para trocar a ordem.
///
/// Setas e não arrastar, por duas razões. A Home tem gestos próprios de
/// deslize e um arrasto vertical competia com eles na arena de gestos. E o
/// ReorderableListView, encaixado aqui dentro de uma Column, deixava a cópia
/// flutuante do item presa no Overlay depois de largar — ficava um ícone
/// solto no fundo do ecrã até a app reiniciar.
///
/// Para três a seis favoritos as setas são até mais rápidas, e funcionam com
/// uma mão só. O arrasto continua a existir em Gerir favoritos, que é um
/// ecrã normal onde nada disto se aplica.
class _ReorderableFavorites extends ConsumerWidget {
  const _ReorderableFavorites({required this.apps});

  final List<InstalledApp> apps;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final TextStyle style =
        Theme.of(context).textTheme.headlineSmall.onWallpaper(context);
    final bool showIcons = ref.watch(settingsProvider.select((s) => s.showIcons));

    void move(int from, int to) =>
        ref.read(favoritePackagesProvider.notifier).reorder(from, to);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (final (int index, InstalledApp app) in apps.indexed)
          Padding(
            key: ValueKey<String>('reorder-${app.id}'),
            padding: const EdgeInsets.symmetric(
              horizontal: LauncherMetrics.horizontalPadding,
              vertical: 2,
            ),
            child: Row(
              children: <Widget>[
                _MoveButton(
                  icon: Icons.keyboard_arrow_up_rounded,
                  tooltip: 'Subir',
                  onPressed: index == 0 ? null : () => move(index, index - 1),
                ),
                _MoveButton(
                  icon: Icons.keyboard_arrow_down_rounded,
                  tooltip: 'Descer',
                  onPressed:
                      index == apps.length - 1 ? null : () => move(index, index + 1),
                ),
                const SizedBox(width: 8),
                if (showIcons) ...<Widget>[
                  AppIcon(app: app),
                  const SizedBox(width: 14),
                ],
                Expanded(
                  child: Text(
                    app.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: style,
                  ),
                ),
              ],
            ),
          ),
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: FilledButton.tonal(
            onPressed: () => ref.read(reorderModeProvider.notifier).exit(),
            child: const Text('Concluído'),
          ),
        ),
      ],
    );
  }
}

class _MoveButton extends StatelessWidget {
  const _MoveButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;

  /// `null` desativa o botão — nos extremos da lista.
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final LauncherPalette palette = context.palette;

    return IconButton(
      onPressed: onPressed,
      icon: Icon(icon),
      tooltip: tooltip,
      visualDensity: VisualDensity.compact,
      color: palette.primaryText,
      disabledColor: palette.tertiaryText.withValues(alpha: 0.4),
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
      // IgnorePointer: um Text responde sempre ao hit test
      // (RenderParagraph.hitTestSelf é true) e engolia os deslizes feitos por
      // cima desta dica, que é texto puro e não tem nada para tocar.
      child: IgnorePointer(
        child: Text(
          'Arraste uma letra à direita ou deslize para cima para pesquisar.\n'
          'Mantenha um app premido para o guardar aqui.',
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: context.palette.secondaryText, height: 1.5)
              .onWallpaper(context),
        ),
      ),
    );
  }
}
