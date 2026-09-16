import 'package:flutter/material.dart';

import '../../../core/theme/launcher_palette.dart';

/// A dica "↑ Pesquisar" no fundo da Home (plano, secção 2).
///
/// Também é tocável: o gesto sozinho não é descobrível e um alvo no fundo
/// do ecrã é o mais fácil de alcançar com uma mão (plano, secção 14).
class SearchHint extends StatelessWidget {
  const SearchHint({required this.onTap, this.visible = true, super.key});

  final VoidCallback onTap;
  final bool visible;

  @override
  Widget build(BuildContext context) {
    if (!visible) return const SizedBox.shrink();

    final LauncherPalette palette = context.palette;

    return Center(
      child: TextButton.icon(
        onPressed: onTap,
        icon: Icon(Icons.keyboard_arrow_up_rounded, size: 20, color: palette.secondaryText),
        label: Text(
          'Pesquisar',
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: palette.secondaryText)
              .onWallpaper(context),
        ),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          foregroundColor: palette.secondaryText,
        ),
      ),
    );
  }
}
