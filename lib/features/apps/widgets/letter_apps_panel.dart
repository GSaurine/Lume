import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/launcher_palette.dart';
import '../../../data/models/installed_app.dart';
import '../controller/apps_controller.dart';
import 'app_tile.dart';

/// Painel que aparece ao escolher uma letra no índice alfabético.
///
/// Mostra só os apps dessa letra — normalmente três ou quatro — o que evita
/// abrir a lista completa para a maioria dos acessos.
class LetterAppsPanel extends ConsumerWidget {
  const LetterAppsPanel({required this.letter, required this.onClose, super.key});

  final String letter;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<InstalledApp> apps =
        ref.watch(appsByLetterProvider)[letter] ?? const <InstalledApp>[];
    final LauncherPalette palette = context.palette;

    if (apps.isEmpty) return const SizedBox.shrink();

    return Align(
      alignment: Alignment.centerRight,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.72,
          maxHeight: MediaQuery.sizeOf(context).height * 0.6,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: palette.panel,
            borderRadius: const BorderRadius.horizontal(left: Radius.circular(20)),
            border: Border.all(color: palette.panelBorder),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 4),
                child: Text(
                  letter,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: palette.tertiaryText,
                      ),
                ),
              ),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  padding: const EdgeInsets.only(bottom: 12),
                  itemCount: apps.length,
                  itemBuilder: (BuildContext context, int index) => AppTile(
                    app: apps[index],
                    dense: true,
                    onLaunched: onClose,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
