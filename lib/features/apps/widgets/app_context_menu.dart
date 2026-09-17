import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/launcher_constants.dart';
import '../../../core/constants/launcher_symbols.dart';
import '../../../core/theme/launcher_palette.dart';
import '../../../core/utils/text_normalizer.dart';
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
    final bool isRenamed = ref.watch(
      appLabelsProvider.select((Map<String, String> l) => l.containsKey(app.packageName)),
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
            leading: const Icon(Icons.drive_file_rename_outline_rounded),
            title: Text(isRenamed ? 'Mudar o nome' : 'Dar outro nome'),
            // Sem legenda com o nome original: neste ponto `app.name` já é o
            // nome personalizado, porque a substituição acontece na lista.
            subtitle: isRenamed ? const Text('Nome personalizado') : null,
            onTap: () async {
              final NavigatorState navigator = Navigator.of(context);
              await showRenameAppDialog(context, app);
              if (navigator.mounted) navigator.pop();
            },
          ),
          ListTile(
            leading: Icon(ref.watch(appSymbolProvider(app)).icon),
            title: const Text('Escolher ícone'),
            onTap: () async {
              final NavigatorState navigator = Navigator.of(context);
              navigator.pop();
              await showSymbolPicker(context, app);
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

/// Diálogo para dar outro nome a uma aplicação.
///
/// Guardamos o nome contra o package name, por isso sobrevive a mudanças de
/// idioma e a atualizações da aplicação. Deixar o campo vazio repõe o nome
/// que o Android reporta.
Future<void> showRenameAppDialog(BuildContext context, InstalledApp app) {
  return showDialog<void>(
    context: context,
    builder: (BuildContext dialogContext) => _RenameAppDialog(app: app),
  );
}

class _RenameAppDialog extends ConsumerStatefulWidget {
  const _RenameAppDialog({required this.app});

  final InstalledApp app;

  @override
  ConsumerState<_RenameAppDialog> createState() => _RenameAppDialogState();
}

class _RenameAppDialogState extends ConsumerState<_RenameAppDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.app.name,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isRenamed = ref
        .watch(appLabelsProvider)
        .containsKey(widget.app.packageName);

    return AlertDialog(
      title: const Text('Dar outro nome'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          TextField(
            controller: _controller,
            autofocus: true,
            textCapitalization: TextCapitalization.sentences,
            style: Theme.of(context).textTheme.bodyLarge,
            decoration: const InputDecoration(hintText: 'Nome'),
            onSubmitted: (_) => _save(),
          ),
          const SizedBox(height: 8),
          Text(
            'Muda também a posição na lista e na pesquisa.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
      actions: <Widget>[
        if (isRenamed)
          TextButton(
            onPressed: _reset,
            child: const Text('Repor original'),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        TextButton(onPressed: _save, child: const Text('Guardar')),
      ],
    );
  }

  Future<void> _save() async {
    final NavigatorState navigator = Navigator.of(context);
    await ref
        .read(appLabelsProvider.notifier)
        .rename(widget.app.packageName, _controller.text);
    if (navigator.mounted) navigator.pop();
  }

  Future<void> _reset() async {
    final NavigatorState navigator = Navigator.of(context);
    await ref.read(appLabelsProvider.notifier).reset(widget.app.packageName);
    if (navigator.mounted) navigator.pop();
  }
}

/// Seletor de símbolo para uma aplicação.
///
/// Existe porque a tabela automática nunca vai cobrir tudo: há milhares de
/// bancos, de lojas e de aplicações locais, e não faz sentido listá-los. O
/// palpite acerta na maioria; isto resolve o resto.
Future<void> showSymbolPicker(BuildContext context, InstalledApp app) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (BuildContext sheetContext) => _SymbolPicker(app: app),
  );
}

class _SymbolPicker extends ConsumerStatefulWidget {
  const _SymbolPicker({required this.app});

  final InstalledApp app;

  @override
  ConsumerState<_SymbolPicker> createState() => _SymbolPickerState();
}

class _SymbolPickerState extends ConsumerState<_SymbolPicker> {
  String _query = '';

  /// Só os grupos que ainda têm alguma coisa depois do filtro.
  Map<SymbolGroup, List<LauncherSymbol>> get _matches {
    final String needle = TextNormalizer.fold(_query);
    final Map<SymbolGroup, List<LauncherSymbol>> result =
        <SymbolGroup, List<LauncherSymbol>>{};

    for (final SymbolGroup group in SymbolGroup.values) {
      final List<LauncherSymbol> found = group.symbols
          .where((LauncherSymbol s) =>
              needle.isEmpty || TextNormalizer.fold(s.label).contains(needle))
          .toList();
      if (found.isNotEmpty) result[group] = found;
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final InstalledApp app = widget.app;
    final LauncherPalette palette = context.palette;
    final LauncherSymbol current = ref.watch(appSymbolProvider(app));
    final bool isCustom = ref.watch(
      appSymbolsProvider.select((Map<String, String> m) => m.containsKey(app.packageName)),
    );

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      builder: (BuildContext context, ScrollController controller) {
        return Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 4, 12, 8),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Ícone de ${app.name}',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        Text(
                          isCustom
                              ? 'Escolhido por si'
                              : 'Sugerido automaticamente',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: palette.tertiaryText,
                              ),
                        ),
                      ],
                    ),
                  ),
                  if (isCustom)
                    TextButton(
                      onPressed: () async {
                        final NavigatorState navigator = Navigator.of(context);
                        await ref
                            .read(appSymbolsProvider.notifier)
                            .assign(app.packageName, null);
                        if (navigator.mounted) navigator.pop();
                      },
                      child: const Text('Automático'),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
              child: TextField(
                autocorrect: false,
                style: Theme.of(context).textTheme.bodyLarge,
                decoration: InputDecoration(
                  hintText: 'Procurar símbolo',
                  hintStyle: Theme.of(context).textTheme.bodyMedium,
                  prefixIcon: Icon(Icons.search_rounded, color: palette.tertiaryText),
                ),
                onChanged: (String value) => setState(() => _query = value),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.only(bottom: 24),
                children: <Widget>[
                  for (final MapEntry<SymbolGroup, List<LauncherSymbol>> entry
                      in _matches.entries) ...<Widget>[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                      child: Text(
                        entry.key.label.toUpperCase(),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: palette.accent,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1,
                            ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Wrap(
                        children: <Widget>[
                          for (final LauncherSymbol symbol in entry.value)
                            _SymbolChoice(
                              symbol: symbol,
                              selected: symbol == current,
                              onTap: () async {
                                final NavigatorState navigator = Navigator.of(context);
                                await ref
                                    .read(appSymbolsProvider.notifier)
                                    .assign(app.packageName, symbol);
                                if (navigator.mounted) navigator.pop();
                              },
                            ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SymbolChoice extends StatelessWidget {
  const _SymbolChoice({
    required this.symbol,
    required this.selected,
    required this.onTap,
  });

  final LauncherSymbol symbol;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final LauncherPalette palette = context.palette;

    return Tooltip(
      message: symbol.label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: LauncherMetrics.symbolPickerTile,
          height: LauncherMetrics.symbolPickerTile,
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? palette.accent : palette.panelBorder,
              width: selected ? 2 : 1,
            ),
          ),
          child: Icon(
            symbol.icon,
            size: 26,
            color: selected ? palette.accent : palette.secondaryText,
          ),
        ),
      ),
    );
  }
}
