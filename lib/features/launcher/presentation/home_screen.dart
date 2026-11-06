import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/launcher_constants.dart';
import '../../../core/theme/launcher_palette.dart';
import '../../../core/utils/launcher_route.dart';
import '../../../core/utils/swipe_decision.dart';
import '../../../data/models/installed_app.dart';
import '../../../data/models/launcher_settings.dart';
import '../../apps/controller/apps_controller.dart';
import '../../apps/presentation/app_list_screen.dart';
import '../../apps/widgets/alphabet_index_bar.dart';
import '../../apps/widgets/letter_apps_panel.dart';
import '../../favorites/presentation/favorites_screen.dart';
import '../../favorites/presentation/favorites_section.dart';
import '../../gestures/controller/gesture_controller.dart';
import '../../search/presentation/search_screen.dart';
import '../../settings/controller/settings_controller.dart';
import '../../settings/presentation/settings_screen.dart';
import '../controller/home_controller.dart';
import '../widgets/clock_widget.dart';
import '../widgets/date_widget.dart';
import '../widgets/default_launcher_banner.dart';
import '../widgets/search_hint.dart';

/// FASE 5 — a Home (plano, secção 14).
///
/// Relógio, data, favoritos, índice alfabético e área de gestos, desenhados
/// por cima do wallpaper do utilizador.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final LauncherSettings settings = ref.watch(settingsProvider);
    final LauncherPalette palette = context.palette;
    final String? selectedLetter = ref.watch(selectedLetterProvider);

    // Carregar em Home já dentro do Lume repõe o estado inicial.
    ref.listen<AsyncValue<LauncherPlatformEvent>>(platformEventsProvider, (_, next) {
      if (next.value?.type == LauncherEventType.homePressed) _resetToHome();
    });

    return PopScope(
      // Num launcher, Back nunca fecha a Home: só fecha o que estiver aberto.
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (!didPop) _closeLetterPanel();
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: <Widget>[
            // Véu que garante contraste do texto sobre qualquer wallpaper.
            const _WallpaperScrim(),

            // Camada de gestos, por baixo de tudo o que é tocável.
            _GestureLayer(
              onGesture: _handleGesture,
              onReorder: () => ref.read(reorderModeProvider.notifier).toggle(),
              doubleTapEnabled:
                  settings.actionFor(LauncherGesture.doubleTap) != GestureAction.none,
            ),

            SafeArea(
              child: LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
                  // O índice alfabético fica à direita; nada lhe deve passar
                  // por baixo.
                  final double barGap =
                      settings.showAlphabetIndex ? LauncherMetrics.alphabetBarWidth : 0;
                  final Widget searchHint = SearchHint(
                    onTap: () => _open(LauncherDestination.search),
                    visible: settings.actionFor(LauncherGesture.swipeUp) ==
                        GestureAction.openSearch,
                  );

                  return constraints.maxWidth > constraints.maxHeight
                      ? _LandscapeLayout(
                          settings: settings,
                          barGap: barGap,
                          searchHint: searchHint,
                        )
                      : _PortraitLayout(
                          settings: settings,
                          barGap: barGap,
                          searchHint: searchHint,
                        );
                },
              ),
            ),

            if (settings.showAlphabetIndex)
              Positioned(
                top: 0,
                bottom: 0,
                right: 0,
                child: SafeArea(
                  child: Padding(
                    // De pé há altura de sobra; deitado, 72dp em cima e em
                    // baixo deixavam 9dp por letra.
                    padding: EdgeInsets.symmetric(
                      vertical: _isLandscape(context) ? 12 : 72,
                    ),
                    child: Consumer(
                      builder: (BuildContext context, WidgetRef ref, _) {
                        return AlphabetIndexBar(
                          letters: ref.watch(availableLettersProvider),
                          selected: selectedLetter,
                          onLetterChanged: (String? letter) =>
                              ref.read(selectedLetterProvider.notifier).select(letter),
                        );
                      },
                    ),
                  ),
                ),
              ),

            // Painel da letra escolhida, com barreira para fechar ao tocar fora.
            if (selectedLetter != null)
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _closeLetterPanel,
                  child: ColoredBox(
                    color: palette.scrim,
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.only(
                          right: LauncherMetrics.alphabetBarWidth,
                        ),
                        child: AnimatedSwitcher(
                          duration: settings.duration(LauncherDurations.fast),
                          child: LetterAppsPanel(
                            key: ValueKey<String>(selectedLetter),
                            letter: selectedLetter,
                            onClose: _closeLetterPanel,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  static bool _isLandscape(BuildContext context) {
    final Size size = MediaQuery.sizeOf(context);
    return size.width > size.height;
  }

  void _closeLetterPanel() => ref.read(selectedLetterProvider.notifier).close();

  void _resetToHome() {
    _closeLetterPanel();
    Navigator.of(context).popUntil((Route<dynamic> route) => route.isFirst);
  }

  Future<void> _handleGesture(LauncherGesture gesture) async {
    final GestureAction action = ref.read(settingsProvider).actionFor(gesture);
    if (action == GestureAction.none) return;

    final GestureOutcome outcome = await ref.read(gestureControllerProvider).run(action);
    if (!mounted) return;

    if (outcome.destination case final LauncherDestination destination) {
      await _open(destination);
      return;
    }
    if (outcome.failureMessage case final String message) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _open(LauncherDestination destination) async {
    _closeLetterPanel();
    final MotionStyle style = ref.read(settingsProvider).animations;

    final Route<void> route = switch (destination) {
      LauncherDestination.search =>
        LauncherRoute.fromBottom<void>(const SearchScreen(), style: style),
      LauncherDestination.appList =>
        LauncherRoute.fromRight<void>(const AppListScreen(), style: style),
      LauncherDestination.favorites =>
        LauncherRoute.fromRight<void>(const FavoritesScreen(), style: style),
      LauncherDestination.settings =>
        LauncherRoute.fromBottom<void>(const SettingsScreen(), style: style),
    };

    await Navigator.of(context).push(route);
  }
}

/// O telemóvel de pé: banner, relógio e data em cima, favoritos no meio,
/// "Pesquisar" em baixo.
class _PortraitLayout extends StatelessWidget {
  const _PortraitLayout({
    required this.settings,
    required this.barGap,
    required this.searchHint,
  });

  final LauncherSettings settings;
  final double barGap;
  final Widget searchHint;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const DefaultLauncherBanner(),
        const SizedBox(height: 24),
        if (settings.showClock || settings.showDate)
          Padding(
            // A mesma largura útil dos favoritos: eles descontam a barra
            // alfabética, e sem isto o relógio centrado ficava desalinhado deles.
            padding: EdgeInsets.only(
              left: LauncherMetrics.horizontalPadding,
              right: LauncherMetrics.horizontalPadding + barGap,
            ),
            child: _ClockAndDate(settings: settings),
          ),
        // Um intervalo antes dos favoritos: quando eles deslizam numa caixa,
        // a caixa começa logo aqui, e o nome esbatido ficava colado à data.
        const SizedBox(height: 16),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: barGap),
            // Um terço do espaço livre por cima e dois por baixo, como os dois
            // Spacer de antes — mas assim a secção sabe a altura que tem e
            // pode adaptar-se em vez de transbordar.
            child: const Align(
              alignment: Alignment(0, -1 / 3),
              child: FavoritesSection(),
            ),
          ),
        ),
        searchHint,
        const SizedBox(height: 12),
      ],
    );
  }
}

/// O telemóvel deitado: relógio e "Pesquisar" à esquerda, favoritos à
/// direita.
///
/// Empilhar tudo numa coluna, como de pé, não cabe: sobram uns 390dp de
/// altura e só seis favoritos pedem 340.
class _LandscapeLayout extends StatelessWidget {
  const _LandscapeLayout({
    required this.settings,
    required this.barGap,
    required this.searchHint,
  });

  final LauncherSettings settings;
  final double barGap;
  final Widget searchHint;

  @override
  Widget build(BuildContext context) {
    final bool centred = settings.contentAlignment == ContentAlignment.center;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const DefaultLauncherBanner(),
              const SizedBox(height: 16),
              // Ocupa o que sobra entre o banner e o "Pesquisar". Se o relógio
              // não couber — empilhado, com letra grande e o banner visível —
              // encolhe em vez de empurrar o resto para fora do ecrã.
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: LauncherMetrics.horizontalPadding,
                  ),
                  child: (settings.showClock || settings.showDate)
                      ? FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: centred ? Alignment.topCenter : Alignment.topLeft,
                          child: _ClockAndDate(settings: settings),
                        )
                      : const SizedBox.shrink(),
                ),
              ),
              searchHint,
              const SizedBox(height: 8),
            ],
          ),
        ),
        Expanded(
          flex: 3,
          child: Padding(
            padding: EdgeInsets.only(right: barGap),
            child: const Align(child: FavoritesSection()),
          ),
        ),
      ],
    );
  }
}

/// Relógio e data, que são texto puro: sem IgnorePointer absorviam os
/// deslizes começados por cima deles.
class _ClockAndDate extends StatelessWidget {
  const _ClockAndDate({required this.settings});

  final LauncherSettings settings;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: settings.contentAlignment.crossAxis,
        children: <Widget>[
          if (settings.showClock) const ClockWidget(),
          if (settings.showDate) ...<Widget>[
            const SizedBox(height: 6),
            const DateWidget(),
          ],
        ],
      ),
    );
  }
}

/// Camada transparente que interpreta os gestos na área livre da Home.
class _GestureLayer extends StatefulWidget {
  const _GestureLayer({
    required this.onGesture,
    required this.onReorder,
    required this.doubleTapEnabled,
  });

  final Future<void> Function(LauncherGesture gesture) onGesture;
  final VoidCallback onReorder;

  /// Só se escuta o toque duplo quando ele faz alguma coisa. Enquanto o
  /// escuta, o Flutter segura cada toque uns 300ms à espera de um segundo —
  /// e abrir um favorito ficava esse tempo mais lento sem razão.
  final bool doubleTapEnabled;

  @override
  State<_GestureLayer> createState() => _GestureLayerState();
}

class _GestureLayerState extends State<_GestureLayer> {
  double _verticalDelta = 0;
  double _horizontalDelta = 0;

  @override
  Widget build(BuildContext context) {
    final VoidCallback onReorder = widget.onReorder;

    return Positioned.fill(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onDoubleTap: widget.doubleTapEnabled
            ? () => widget.onGesture(LauncherGesture.doubleTap)
            : null,
        onLongPress: () async {
          await HapticFeedback.mediumImpact();
          if (context.mounted) {
            await _showHomeMenu(context, onReorder: onReorder);
          }
        },
        onVerticalDragStart: (_) => _verticalDelta = 0,
        onVerticalDragUpdate: (DragUpdateDetails details) =>
            _verticalDelta += details.delta.dy,
        onVerticalDragEnd: (DragEndDetails details) {
          final double delta = _verticalDelta;
          final double velocity = details.velocity.pixelsPerSecond.dy;
          _verticalDelta = 0;
          if (!SwipeDecision.accepts(delta: delta, velocity: velocity)) return;
          widget.onGesture(
            SwipeDecision.isNegative(delta: delta, velocity: velocity)
                ? LauncherGesture.swipeUp
                : LauncherGesture.swipeDown,
          );
        },
        onHorizontalDragStart: (_) => _horizontalDelta = 0,
        onHorizontalDragUpdate: (DragUpdateDetails details) =>
            _horizontalDelta += details.delta.dx,
        onHorizontalDragEnd: (DragEndDetails details) {
          final double delta = _horizontalDelta;
          final double velocity = details.velocity.pixelsPerSecond.dx;
          _horizontalDelta = 0;
          if (!SwipeDecision.accepts(delta: delta, velocity: velocity)) return;
          widget.onGesture(
            SwipeDecision.isNegative(delta: delta, velocity: velocity)
                ? LauncherGesture.swipeLeft
                : LauncherGesture.swipeRight,
          );
        },
      ),
    );
  }

  /// Long press na área livre: atalho para personalizar (plano, secção 13).
  static Future<void> _showHomeMenu(
    BuildContext context, {
    required VoidCallback onReorder,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      // Sem isto a folha fica presa a 9/16 da altura: deitado, uns 230dp para
      // a pega e quatro entradas.
      isScrollControlled: true,
      builder: (BuildContext sheetContext) => SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.tune_rounded),
                title: const Text('Definições do Lume'),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  Navigator.of(context).push(
                    LauncherRoute.fromBottom<void>(const SettingsScreen(), style: MotionStyle.subtle),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.swap_vert_rounded),
                title: const Text('Reordenar favoritos'),
                subtitle: const Text('Com setas, sem sair do ecrã inicial'),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  onReorder();
                },
              ),
              ListTile(
                leading: const Icon(Icons.star_outline_rounded),
                title: const Text('Gerir favoritos'),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  Navigator.of(context).push(
                    LauncherRoute.fromRight<void>(const FavoritesScreen(), style: MotionStyle.subtle),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.apps_rounded),
                title: const Text('Todas as aplicações'),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  Navigator.of(context).push(
                    LauncherRoute.fromRight<void>(const AppListScreen(), style: MotionStyle.subtle),
                  );
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

/// Gradiente subtil no topo e no fundo. Sem ele, um wallpaper claro torna
/// o relógio ilegível.
class _WallpaperScrim extends StatelessWidget {
  const _WallpaperScrim();

  @override
  Widget build(BuildContext context) {
    final Color scrim = context.palette.scrim;
    return Positioned.fill(
      child: IgnorePointer(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: <Color>[
                scrim,
                scrim.withValues(alpha: scrim.a * 0.35),
                scrim.withValues(alpha: scrim.a * 0.35),
                scrim,
              ],
              stops: const <double>[0, 0.3, 0.7, 1],
            ),
          ),
        ),
      ),
    );
  }
}
