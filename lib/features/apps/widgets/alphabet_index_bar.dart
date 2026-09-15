import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/launcher_constants.dart';
import '../../../core/theme/launcher_palette.dart';

/// Índice alfabético vertical (plano, secção 2 e FASE 5).
///
/// É a forma rápida de chegar a um app sem abrir a lista completa: arrastar
/// o dedo pelas letras e largar na pretendida. Só mostra letras que têm
/// pelo menos um app, para não haver alvos vazios.
class AlphabetIndexBar extends StatefulWidget {
  const AlphabetIndexBar({
    required this.letters,
    required this.onLetterChanged,
    this.selected,
    this.onInteractionEnd,
    super.key,
  });

  final List<String> letters;
  final String? selected;

  /// Recebe `null` quando o dedo sai da barra.
  final ValueChanged<String?> onLetterChanged;
  final VoidCallback? onInteractionEnd;

  @override
  State<AlphabetIndexBar> createState() => _AlphabetIndexBarState();
}

class _AlphabetIndexBarState extends State<AlphabetIndexBar> {
  final GlobalKey _barKey = GlobalKey();
  String? _lastReported;

  @override
  Widget build(BuildContext context) {
    if (widget.letters.isEmpty) return const SizedBox.shrink();

    final TextStyle? style = Theme.of(context).textTheme.labelSmall;
    final LauncherPalette palette = context.palette;

    return GestureDetector(
      key: _barKey,
      behavior: HitTestBehavior.opaque,
      onTapDown: (TapDownDetails details) => _report(details.localPosition),
      onTapUp: (_) => widget.onInteractionEnd?.call(),
      onVerticalDragStart: (DragStartDetails details) => _report(details.localPosition),
      onVerticalDragUpdate: (DragUpdateDetails details) => _report(details.localPosition),
      onVerticalDragEnd: (_) => widget.onInteractionEnd?.call(),
      onVerticalDragCancel: () => _lastReported = null,
      child: SizedBox(
        width: LauncherMetrics.alphabetBarWidth,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            for (final String letter in widget.letters)
              Expanded(
                child: Center(
                  child: Text(
                    letter,
                    style: style?.copyWith(
                      color: letter == widget.selected
                          ? palette.primaryText
                          : palette.tertiaryText,
                      fontWeight:
                          letter == widget.selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Converte a posição do dedo na letra correspondente.
  void _report(Offset localPosition) {
    final RenderObject? renderObject = _barKey.currentContext?.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.hasSize) return;

    final double height = renderObject.size.height;
    if (height <= 0) return;

    final int index =
        (localPosition.dy / (height / widget.letters.length)).floor();
    if (index < 0 || index >= widget.letters.length) {
      if (_lastReported != null) {
        _lastReported = null;
        widget.onLetterChanged(null);
      }
      return;
    }

    final String letter = widget.letters[index];
    if (letter == _lastReported) return;
    _lastReported = letter;
    HapticFeedback.selectionClick();
    widget.onLetterChanged(letter);
  }
}
