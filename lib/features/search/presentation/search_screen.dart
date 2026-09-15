import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/launcher_constants.dart';
import '../../../core/theme/launcher_palette.dart';
import '../../../data/models/installed_app.dart';
import '../../apps/controller/apps_controller.dart';
import '../../apps/widgets/app_tile.dart';
import '../../settings/controller/settings_controller.dart';
import '../controller/search_controller.dart';

/// FASE 6 — pesquisa (plano, secção 11).
///
/// O campo fica em baixo, junto ao teclado: é onde o polegar chega e evita
/// que a lista de resultados salte quando o teclado abre.
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // A pesquisa começa sempre limpa; manter o texto anterior obriga a
    // apagá-lo antes de escrever.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(searchQueryProvider.notifier).clear();
      if (ref.read(settingsProvider).searchAutoFocus) _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<InstalledApp> results = ref.watch(searchResultsProvider);
    final String query = ref.watch(searchQueryProvider);
    final LauncherPalette palette = context.palette;

    return Scaffold(
      backgroundColor: palette.panel,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Expanded(
              child: results.isEmpty
                  ? _NoResults(query: query)
                  : ListView.builder(
                      // Resultados de baixo para cima: o melhor fica junto
                      // ao campo de texto.
                      reverse: true,
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: const EdgeInsets.only(bottom: 8),
                      itemCount: results.length,
                      itemBuilder: (BuildContext context, int index) => AppTile(
                        app: results[index],
                        key: ValueKey<String>(results[index].id),
                        onLaunched: _close,
                      ),
                    ),
            ),
            _SearchField(
              controller: _controller,
              focusNode: _focusNode,
              onChanged: _onQueryChanged,
              onSubmitted: () => _openFirst(results),
              onClear: () {
                _controller.clear();
                ref.read(searchQueryProvider.notifier).clear();
              },
              hasText: query.isNotEmpty,
            ),
          ],
        ),
      ),
    );
  }

  void _onQueryChanged(String value) {
    ref.read(searchQueryProvider.notifier).update(value);

    if (!ref.read(settingsProvider).searchOpensSingleResult || value.trim().isEmpty) {
      return;
    }
    final List<InstalledApp> results = ref.read(searchResultsProvider);
    if (results.length == 1) _launch(results.first);
  }

  void _openFirst(List<InstalledApp> results) {
    if (results.isEmpty) return;
    _launch(results.first);
  }

  Future<void> _launch(InstalledApp app) async {
    final bool ok = await ref.read(appLauncherProvider).launch(app);
    if (ok) _close();
  }

  void _close() {
    if (!mounted) return;
    ref.read(searchQueryProvider.notifier).clear();
    Navigator.of(context).maybePop();
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onSubmitted,
    required this.onClear,
    required this.hasText,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final VoidCallback onSubmitted;
  final VoidCallback onClear;
  final bool hasText;

  @override
  Widget build(BuildContext context) {
    final LauncherPalette palette = context.palette;

    return Container(
      padding: const EdgeInsets.fromLTRB(
        LauncherMetrics.horizontalPadding,
        12,
        12,
        16,
      ),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: palette.panelBorder)),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              autocorrect: false,
              enableSuggestions: false,
              textInputAction: TextInputAction.go,
              style: Theme.of(context).textTheme.headlineSmall,
              cursorColor: palette.accent,
              decoration: const InputDecoration(hintText: 'Pesquisar aplicações'),
              onChanged: onChanged,
              onSubmitted: (_) => onSubmitted(),
            ),
          ),
          IconButton(
            onPressed: hasText ? onClear : () => Navigator.of(context).maybePop(),
            icon: Icon(
              hasText ? Icons.close_rounded : Icons.keyboard_arrow_down_rounded,
              color: palette.tertiaryText,
            ),
            tooltip: hasText ? 'Limpar' : 'Fechar',
          ),
        ],
      ),
    );
  }
}

class _NoResults extends StatelessWidget {
  const _NoResults({required this.query});

  final String query;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(
          query.isEmpty
              ? 'Escreva para encontrar uma aplicação.'
              : 'Sem resultados para "$query".',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    );
  }
}
