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
            _GestureLayer(onGesture: _handleGesture),

            SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  const DefaultLauncherBanner(),
                  const SizedBox(height: 24),
                  if (settings.showClock || settings.showDate)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: LauncherMetrics.horizontalPadding,
                      ),
                      // Relógio e data são texto puro: sem IgnorePointer
                      // absorviam os deslizes começados por cima deles.
                      child: IgnorePointer(
                        child: Column(
                          crossAxisAlignment: settings.contentAlignment.crossAxis,
                          children: <Widget>[
                            if (settings.showClock) const ClockWidget(),
                            if (settings.showDate) ...<Widget>[
                              const SizedBox(height: 6),
                              const DateWidget(),
                            ],
                          ],
                        ),
                      ),
                    ),
                  const Spacer(),

                  // O índice alfabético fica à direita; os favoritos não lhe
                  // devem passar por baixo.
                  Padding(
                    padding: EdgeInsets.only(
                      right: settings.showAlphabetIndex
                          ? LauncherMetrics.alphabetBarWidth
                          : 0,
                    ),
                    child: const FavoritesSection(),
                  ),
                  const Spacer(flex: 2),
                  SearchHint(
                    onTap: () => _open(LauncherDestination.search),
                    visible: settings.actionFor(LauncherGesture.swipeUp) ==
                        GestureAction.openSearch,
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),

            if (settings.showAlphabetIndex)
              Positioned(
                top: 0,
                bottom: 0,
                right: 0,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 72),
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
    final bool animate = ref.read(settingsProvider).animations;

    final Route<void> route = switch (destination) {
      LauncherDestination.search =>
        LauncherRoute.fromBottom<void>(const SearchScreen(), animate: animate),
      LauncherDestination.appList =>
        LauncherRoute.fromRight<void>(const AppListScreen(), animate: animate),
      LauncherDestination.favorites =>
        LauncherRoute.fromRight<void>(const FavoritesScreen(), animate: animate),
      LauncherDestination.settings =>
        LauncherRoute.fromBottom<void>(const SettingsScreen(), animate: animate),
    };

    await Navigator.of(context).push(route);
  }
}

/// Camada transparente que interpreta os gestos na área livre da Home.
class _GestureLayer extends StatefulWidget {
  const _GestureLayer({required this.onGesture});

  final Future<void> Function(LauncherGesture gesture) onGesture;

  @override
  State<_GestureLayer> createState() => _GestureLayerState();
}

class _GestureLayerState extends State<_GestureLayer> {
  double _verticalDelta = 0;
  double _horizontalDelta = 0;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onDoubleTap: () => widget.onGesture(LauncherGesture.doubleTap),
        onLongPress: () async {
          await HapticFeedback.mediumImpact();
          if (context.mounted) await _showHomeMenu(context);
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
  static Future<void> _showHomeMenu(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ListTile(
              leading: const Icon(Icons.tune_rounded),
              title: const Text('Definições do Lume'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                Navigator.of(context).push(
                  LauncherRoute.fromBottom<void>(const SettingsScreen(), animate: true),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.star_outline_rounded),
              title: const Text('Gerir favoritos'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                Navigator.of(context).push(
                  LauncherRoute.fromRight<void>(const FavoritesScreen(), animate: true),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.apps_rounded),
              title: const Text('Todas as aplicações'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                Navigator.of(context).push(
                  LauncherRoute.fromRight<void>(const AppListScreen(), animate: true),
                );
              },
            ),
            const SizedBox(height: 12),
          ],
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
