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
///
/// A secção mede a altura que tem e escolhe como se dispor — ver
/// [FavoritesLayout]. Com o telemóvel deitado sobram uns 390dp, e seis
/// favoritos com o espaçamento de origem já pedem 340.
class FavoritesSection extends ConsumerWidget {
  const FavoritesSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<InstalledApp> favorites = ref.watch(favoriteAppsProvider);
    final int limit = ref.watch(settingsProvider.select((s) => s.favoritesLimit));
    final bool reordering = ref.watch(reorderModeProvider);

    if (favorites.isEmpty) return const _EmptyFavoritesHint();

    final List<InstalledApp> visible = favorites.take(limit).toList(growable: false);

    if (reordering) {
      // Em modo de reordenar o scroll não incomoda: não se está a deslizar
      // para abrir nada.
      return SingleChildScrollView(child: _ReorderableFavorites(apps: visible));
    }

    final double preferredSpacing =
        ref.watch(settingsProvider.select((s) => s.itemSpacing));
    final bool showIcons = ref.watch(settingsProvider.select((s) => s.showIcons));
    final TextAlign textAlign =
        ref.watch(settingsProvider.select((s) => s.contentAlignment)).textAlign;
    final TextStyle style =
        Theme.of(context).textTheme.headlineSmall.onWallpaper(context);
    // A escala de acessibilidade do Android soma-se à do Lume.
    final double lineHeight =
        MediaQuery.textScalerOf(context).scale(style.fontSize ?? 23) *
            (style.height ?? 1.25);

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final FavoritesLayout layout = FavoritesLayout.choose(
          count: visible.length,
          availableHeight: constraints.maxHeight,
          availableWidth: constraints.maxWidth,
          lineHeight: lineHeight,
          preferredSpacing: preferredSpacing,
          showIcons: showIcons,
        );

        Widget tile(InstalledApp app) => AppTile(
              app: app,
              key: ValueKey<String>('favorite-${app.id}'),
              overWallpaper: true,
              textAlign: textAlign,
              textStyle: style,
              spacing: layout.spacing,
            );

        final Widget list = layout.columns == 1
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[for (final InstalledApp app in visible) tile(app)],
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  for (int start = 0; start < visible.length; start += layout.columns)
                    Row(
                      children: <Widget>[
                        for (int i = start; i < start + layout.columns; i++)
                          Expanded(
                            child: i < visible.length
                                ? tile(visible[i])
                                : const SizedBox.shrink(),
                          ),
                      ],
                    ),
                ],
              );

        if (layout.fits) return list;

        // Último recurso, para configurações extremas: deixa deslizar em vez
        // de cortar. Translúcido para os gestos da Home continuarem a chegar
        // à camada de baixo.
        return SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          hitTestBehavior: HitTestBehavior.translucent,
          child: list,
        );
      },
    );
  }
}

/// Como dispor os favoritos na altura disponível.
///
/// Tenta, por esta ordem, e fica com a primeira que cabe: uma coluna com o
/// espaçamento que a pessoa escolheu; uma coluna compacta; duas colunas com
/// o espaçamento escolhido; duas colunas compactas. Duas colunas só se cada
/// uma tiver largura para um nome se ler.
@immutable
class FavoritesLayout {
  const FavoritesLayout({
    required this.columns,
    required this.spacing,
    required this.fits,
  });

  final int columns;
  final double spacing;

  /// `false` quando nem a opção mais compacta cabe.
  final bool fits;

  static const double compactSpacing = 0;
  static const double minColumnWidth = 160;

  static FavoritesLayout choose({
    required int count,
    required double availableHeight,
    required double availableWidth,
    required double lineHeight,
    required double preferredSpacing,
    required bool showIcons,
  }) {
    if (count == 0 || !availableHeight.isFinite) {
      return FavoritesLayout(columns: 1, spacing: preferredSpacing, fits: true);
    }

    final bool twoColumnsFit = availableWidth / 2 >= minColumnWidth;
    final List<(int, double)> candidates = <(int, double)>[
      (1, preferredSpacing),
      if (preferredSpacing > compactSpacing) (1, compactSpacing),
      if (twoColumnsFit) (2, preferredSpacing),
      if (twoColumnsFit && preferredSpacing > compactSpacing) (2, compactSpacing),
    ];

    for (final (int columns, double spacing) in candidates) {
      final int rows = (count / columns).ceil();
      final double needed =
          rows * AppTile.heightFor(lineHeight: lineHeight, spacing: spacing, showIcons: showIcons);
      if (needed <= availableHeight) {
        return FavoritesLayout(columns: columns, spacing: spacing, fits: true);
      }
    }
    return FavoritesLayout(
      columns: twoColumnsFit ? 2 : 1,
      spacing: compactSpacing,
      fits: false,
    );
  }
}

/// A mesma lista, mas com setas para trocar a ordem.
///
/// Setas e não arrastar porque a Home tem gestos próprios de deslize, e um
/// arrasto vertical competiria com eles na arena de gestos. Para três a seis
/// favoritos as setas também são rápidas e funcionam com uma mão só. O
/// arrasto continua em Gerir favoritos, que é um ecrã normal.
///
/// Nota histórica: houve um ícone "preso" no fundo do ecrã que se atribuiu
/// por engano ao ReorderableListView. Era o flutter/flutter#188035 — sombras
/// de texto desenhadas fora do sítio pelo Impeller — e foi resolvido subindo
/// o Flutter para 3.44.5 ou superior (ver o piso em pubspec.yaml).
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
