import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/launcher_constants.dart';
import '../../../core/theme/launcher_palette.dart';
import '../../../data/models/installed_app.dart';
import '../../settings/controller/settings_controller.dart';
import '../controller/apps_controller.dart';
import '../widgets/alphabet_index_bar.dart';
import '../widgets/app_tile.dart';

/// Lista completa de aplicativos, agrupada por letra.
///
/// O índice à direita salta para a secção correspondente. Usamos
/// `ScrollablePositionedList`? Não: uma dependência extra para isto não se
/// justifica — calculamos o deslocamento a partir das alturas conhecidas.
class AppListScreen extends ConsumerStatefulWidget {
  const AppListScreen({super.key});

  @override
  ConsumerState<AppListScreen> createState() => _AppListScreenState();
}

class _AppListScreenState extends ConsumerState<AppListScreen> {
  final ScrollController _controller = ScrollController();
  String? _activeLetter;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, List<InstalledApp>> grouped = ref.watch(appsByLetterProvider);
    final List<String> letters = ref.watch(availableLettersProvider);
    final bool isLoading = ref.watch(installedAppsProvider).isLoading;
    final LauncherPalette palette = context.palette;

    final List<_ListEntry> entries = _flatten(grouped, letters);

    return Scaffold(
      backgroundColor: palette.panel,
      appBar: AppBar(
        title: Text('Aplicações  ·  ${entries.whereType<_AppEntry>().length}'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).maybePop(),
          tooltip: 'Voltar',
        ),
      ),
      body: SafeArea(
        top: false,
        child: switch ((isLoading, entries.isEmpty)) {
          (true, true) => const Center(child: CircularProgressIndicator.adaptive()),
          (false, true) => const _EmptyState(),
          _ => Row(
              children: <Widget>[
                Expanded(
                  child: ListView.builder(
                    controller: _controller,
                    padding: const EdgeInsets.only(bottom: 32),
                    itemCount: entries.length,
                    itemExtentBuilder: (int index, SliverLayoutDimensions _) =>
                        entries[index].height,
                    itemBuilder: (BuildContext context, int index) =>
                        entries[index].build(context),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: AlphabetIndexBar(
                    letters: letters,
                    selected: _activeLetter,
                    onWallpaper: false,
                    onLetterChanged: (String? letter) => _jumpTo(letter, entries),
                  ),
                ),
              ],
            ),
        },
      ),
    );
  }

  /// Achata os grupos numa lista única de cabeçalhos + apps, para que a
  /// `ListView` saiba a altura de cada item sem os construir todos.
  List<_ListEntry> _flatten(
    Map<String, List<InstalledApp>> grouped,
    List<String> letters,
  ) {
    final double spacing = ref.watch(settingsProvider.select((s) => s.itemSpacing));
    final bool showIcons = ref.watch(settingsProvider.select((s) => s.showIcons));
    final double fontScale = ref.watch(settingsProvider.select((s) => s.fontScale));

    final double rowHeight = <double>[
      (showIcons ? LauncherMetrics.iconSize : 22 * fontScale) + 16 + spacing * 2,
      44,
    ].reduce((double a, double b) => a > b ? a : b);

    return <_ListEntry>[
      for (final String letter in letters) ...<_ListEntry>[
        _HeaderEntry(letter),
        for (final InstalledApp app in grouped[letter] ?? const <InstalledApp>[])
          _AppEntry(app, rowHeight),
      ],
    ];
  }

  void _jumpTo(String? letter, List<_ListEntry> entries) {
    if (letter == null) return;
    setState(() => _activeLetter = letter);

    double offset = 0;
    for (final _ListEntry entry in entries) {
      if (entry is _HeaderEntry && entry.letter == letter) break;
      offset += entry.height;
    }

    if (!_controller.hasClients) return;
    _controller.jumpTo(offset.clamp(0, _controller.position.maxScrollExtent));
  }
}

sealed class _ListEntry {
  double get height;

  Widget build(BuildContext context);
}

class _HeaderEntry implements _ListEntry {
  const _HeaderEntry(this.letter);

  final String letter;

  @override
  double get height => 38;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(
          LauncherMetrics.horizontalPadding,
          12,
          LauncherMetrics.horizontalPadding,
          4,
        ),
        child: Text(
          letter,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: context.palette.accent,
                fontWeight: FontWeight.w700,
              ),
        ),
      );
}

class _AppEntry implements _ListEntry {
  const _AppEntry(this.app, this.height);

  final InstalledApp app;

  @override
  final double height;

  @override
  Widget build(BuildContext context) => AppTile(app: app, key: ValueKey<String>(app.id));
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(
          'Nenhuma aplicação para mostrar.\n'
          'Verifique se ocultou apps nas definições.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    );
  }
}
