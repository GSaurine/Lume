import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/launcher_constants.dart';
import '../../../core/theme/launcher_palette.dart';
import '../../../data/models/installed_app.dart';
import '../../../data/models/launcher_settings.dart';
import '../../apps/controller/apps_controller.dart';
import '../../apps/widgets/app_icon.dart';
import '../../apps/widgets/app_tile.dart';
import '../../launcher/controller/home_controller.dart';
import '../../settings/controller/settings_controller.dart';
import '../controller/favorites_controller.dart';

/// Favoritos na Home (plano, secções 12 e 25.1).
///
/// Quando ainda não há favoritos mostramos uma dica em vez de espaço vazio:
/// o gesto de os criar (manter premido) não é descobrível sozinho.
///
/// A secção mede a altura que tem e escolhe como se dispor — ver
/// [FavoritesLayout]. Com o telemóvel deitado sobram uns 390dp, e seis
/// favoritos com o espaçamento de origem já pedem 340.
class FavoritesSection extends ConsumerStatefulWidget {
  const FavoritesSection({super.key});

  @override
  ConsumerState<FavoritesSection> createState() => _FavoritesSectionState();
}

class _FavoritesSectionState extends ConsumerState<FavoritesSection> {
  /// Da caixa deslizante, quando há uma.
  final ScrollController _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Carregar em Home volta a caixa ao início, como fecha tudo o resto.
    ref.listen<AsyncValue<LauncherPlatformEvent>>(platformEventsProvider, (_, next) {
      if (next.value?.type == LauncherEventType.homePressed && _scroll.hasClients) {
        _scroll.jumpTo(0);
      }
    });

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
    final FavoritesOverflow overflow =
        ref.watch(settingsProvider.select((s) => s.favoritesOverflow));
    final TextAlign textAlign =
        ref.watch(settingsProvider.select((s) => s.contentAlignment)).textAlign;
    final TextStyle style =
        Theme.of(context).textTheme.headlineSmall.onWallpaper(context);
    final double baseFontSize = style.fontSize ?? 23;
    // A escala de acessibilidade do Android soma-se à do Lume (que já está no
    // tema), e não é forçosamente linear: medimos cada tamanho por ela.
    final TextScaler textScaler = MediaQuery.textScalerOf(context);
    // Só interessam em duas colunas, para encolher até os nomes caberem.
    final List<double> nameWidths = overflow == FavoritesOverflow.shrink
        ? <double>[for (final InstalledApp app in visible) _measure(app.name, style, textScaler)]
        : const <double>[];

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final FavoritesLayout layout = FavoritesLayout.choose(
          count: visible.length,
          availableHeight: constraints.maxHeight,
          availableWidth: constraints.maxWidth,
          fontSizeAt: (double scale) => textScaler.scale(baseFontSize * scale),
          lineHeightFactor: style.height ?? 1.25,
          preferredSpacing: preferredSpacing,
          showIcons: showIcons,
          overflow: overflow,
          nameWidths: nameWidths,
        );

        final TextStyle tileStyle = layout.scale == 1
            ? style
            : style.copyWith(fontSize: baseFontSize * layout.scale);

        Widget tile(InstalledApp app) => AppTile(
              app: app,
              key: ValueKey<String>('favorite-${app.id}'),
              overWallpaper: true,
              textAlign: textAlign,
              textStyle: tileStyle,
              spacing: layout.spacing,
              iconSize: LauncherMetrics.iconSize * layout.scale,
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

        if (!layout.scrolls) return list;
        return _FavoritesScrollBox(controller: _scroll, child: list);
      },
    );
  }

  /// Largura de um nome numa linha, no tamanho escolhido nas definições.
  static double _measure(String text, TextStyle style, TextScaler textScaler) {
    final TextPainter painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      textScaler: textScaler,
      maxLines: 1,
    )..layout();
    final double width = painter.width;
    painter.dispose();
    return width;
  }
}

/// A caixa onde os favoritos deslizam quando não cabem.
///
/// Um arrasto vertical que comece aqui dentro move a lista; fora dela,
/// continua a ser um gesto da Home. Funciona sozinho pela ordem da arena de
/// gestos: o Scrollable está por cima da camada de gestos, recebe o toque
/// primeiro e ganha o arrasto vertical. É translúcido para os toques e os
/// deslizes para os lados continuarem a chegar à camada de baixo. E quando a
/// lista cabe inteira o Scrollable nem regista o arrasto, por isso os gestos
/// da Home passam.
///
/// As pontas esbatem-se quando há mais lista desse lado.
class _FavoritesScrollBox extends StatefulWidget {
  const _FavoritesScrollBox({required this.controller, required this.child});

  final ScrollController controller;
  final Widget child;

  @override
  State<_FavoritesScrollBox> createState() => _FavoritesScrollBoxState();
}

class _FavoritesScrollBoxState extends State<_FavoritesScrollBox> {
  static const double _fadeExtent = 28;

  bool _moreAbove = false;
  bool _moreBelow = true;

  bool _onMetrics(ScrollMetrics metrics) {
    final bool above = metrics.extentBefore > 0.5;
    final bool below = metrics.extentAfter > 0.5;
    if (above != _moreAbove || below != _moreBelow) {
      setState(() {
        _moreAbove = above;
        _moreBelow = below;
      });
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollMetricsNotification>(
      onNotification: (ScrollMetricsNotification n) => _onMetrics(n.metrics),
      child: NotificationListener<ScrollNotification>(
        onNotification: (ScrollNotification n) => _onMetrics(n.metrics),
        child: ShaderMask(
          blendMode: BlendMode.dstIn,
          shaderCallback: (Rect bounds) {
            final double stop = math.min(_fadeExtent / bounds.height, 0.5);
            return LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: <Color>[
                _moreAbove ? Colors.transparent : Colors.white,
                Colors.white,
                Colors.white,
                _moreBelow ? Colors.transparent : Colors.white,
              ],
              stops: <double>[0, stop, 1 - stop, 1],
            ).createShader(bounds);
          },
          child: SingleChildScrollView(
            key: const ValueKey<String>('favorites-scroll'),
            controller: widget.controller,
            physics: const ClampingScrollPhysics(),
            hitTestBehavior: HitTestBehavior.translucent,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

/// Como dispor os favoritos na altura disponível.
@immutable
class FavoritesLayout {
  const FavoritesLayout({
    required this.columns,
    required this.spacing,
    required this.scale,
    required this.scrolls,
  });

  final int columns;
  final double spacing;

  /// Fator da letra e do ícone; 1 é o tamanho escolhido nas definições.
  final double scale;

  /// A lista não cabe e desliza dentro da sua caixa.
  final bool scrolls;

  static const double compactSpacing = 0;
  static const double minColumnWidth = 160;

  /// Abaixo disto um nome já não se lê num relance.
  static const double minFontSize = 16;
  static const double minIconSize = 24;

  /// Os degraus de Encolher, antes do mínimo legível.
  static const List<double> shrinkSteps = <double>[1, 0.9, 0.8];

  /// Em duas colunas, a parte dos nomes que tem de caber inteira. Não é
  /// toda: um nome muito comprido não deve arrastar todos para o mínimo.
  static const double namesThatMustFit = 0.9;

  /// Escolhe a disposição.
  ///
  /// [fontSizeAt] dá o tamanho de letra que fica no ecrã para uma escala, já
  /// com a escala de acessibilidade do Android; a altura de uma linha é esse
  /// tamanho vezes [lineHeightFactor]. [nameWidths] são as larguras dos
  /// nomes no tamanho escolhido (escala 1).
  ///
  /// Com [FavoritesOverflow.shrink] tenta, por esta ordem, e fica com a
  /// primeira que cabe: o espaçamento escolhido; o compacto; letra e ícone a
  /// 90% e 80%; o mínimo legível — primeiro numa coluna e depois em duas, se
  /// cada uma tiver largura para um nome se ler. Em duas colunas, cada
  /// tentativa também tem de deixar ler os nomes ([namesThatMustFit]); se
  /// nenhuma deixar, fica o mínimo legível, que é onde se corta menos. Se
  /// nem assim couber, desliza no mais compacto.
  ///
  /// Com [FavoritesOverflow.scroll] nada muda de tamanho: uma coluna, como a
  /// pessoa a configurou, e desliza se não couber.
  static FavoritesLayout choose({
    required int count,
    required double availableHeight,
    required double availableWidth,
    required double Function(double scale) fontSizeAt,
    required double lineHeightFactor,
    required double preferredSpacing,
    required bool showIcons,
    FavoritesOverflow overflow = FavoritesOverflow.shrink,
    List<double> nameWidths = const <double>[],
  }) {
    bool namesFit(int columns, double scale) {
      if (columns == 1 || nameWidths.isEmpty) return true;
      final double room = availableWidth / columns -
          2 * LauncherMetrics.horizontalPadding -
          (showIcons ? (LauncherMetrics.iconSize + 14) * scale : 0);
      final int fitting = nameWidths.where((double w) => w * scale <= room).length;
      return fitting >= (nameWidths.length * namesThatMustFit).ceil();
    }

    bool fits(int columns, double spacing, double scale) {
      final int rows = (count / columns).ceil();
      final double rowHeight = AppTile.heightFor(
        lineHeight: fontSizeAt(scale) * lineHeightFactor,
        spacing: spacing,
        showIcons: showIcons,
        iconSize: LauncherMetrics.iconSize * scale,
      );
      return rows * rowHeight <= availableHeight;
    }

    if (count == 0 || !availableHeight.isFinite) {
      return FavoritesLayout(columns: 1, spacing: preferredSpacing, scale: 1, scrolls: false);
    }

    if (overflow == FavoritesOverflow.scroll) {
      return FavoritesLayout(
        columns: 1,
        spacing: preferredSpacing,
        scale: 1,
        scrolls: !fits(1, preferredSpacing, 1),
      );
    }

    final double floor = minimumScale(fontSizeAt: fontSizeAt, showIcons: showIcons);
    final List<double> scales = <double>[
      for (final double step in shrinkSteps)
        if (step > floor) step,
      floor,
    ];
    final bool twoColumnsFit = availableWidth / 2 >= minColumnWidth;

    for (final int columns in <int>[1, if (twoColumnsFit) 2]) {
      final List<(double, double)> attempts = <(double, double)>[
        (preferredSpacing, 1),
        if (preferredSpacing > compactSpacing) (compactSpacing, 1),
        for (final double scale in scales.skip(1)) (compactSpacing, scale),
      ];
      for (final (double spacing, double scale) in attempts) {
        if (fits(columns, spacing, scale) && (scale == floor || namesFit(columns, scale))) {
          return FavoritesLayout(
            columns: columns,
            spacing: spacing,
            scale: scale,
            scrolls: false,
          );
        }
      }
    }

    return FavoritesLayout(
      columns: twoColumnsFit ? 2 : 1,
      spacing: compactSpacing,
      scale: floor,
      scrolls: true,
    );
  }

  /// A menor escala em que a letra e o ícone ainda se leem. Nunca acima de 1:
  /// com a letra já pequena nas definições, não há para onde encolher.
  static double minimumScale({
    required double Function(double scale) fontSizeAt,
    required bool showIcons,
  }) {
    final double text = minFontSize / fontSizeAt(1);
    final double icon = showIcons ? minIconSize / LauncherMetrics.iconSize : 0;
    return math.min(1, math.max(text, icon));
  }

  @override
  String toString() =>
      'FavoritesLayout($columns colunas, espaço $spacing, escala $scale'
      '${scrolls ? ', desliza' : ''})';
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
