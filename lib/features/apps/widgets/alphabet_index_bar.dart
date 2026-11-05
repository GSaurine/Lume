import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/launcher_constants.dart';
import '../../../core/theme/launcher_palette.dart';

/// Índice alfabético vertical (plano, secção 2 e FASE 5).
///
/// É a forma rápida de chegar a um app sem abrir a lista completa: arrastar
/// o dedo pelas letras e largar na pretendida. Só mostra letras que têm
/// pelo menos um app, para não haver alvos vazios.
///
/// Quando não há altura para todas — com o telemóvel deitado ficam uns 9dp
/// por letra, e uma letra precisa de 12,6 — mostra só algumas, com pontos
/// entre elas, como o índice dos contactos do iPhone. O dedo continua a
/// percorrer a lista completa: arrastar por cima de um ponto dá a letra que
/// lá está escondida.
class AlphabetIndexBar extends StatefulWidget {
  const AlphabetIndexBar({
    required this.letters,
    required this.onLetterChanged,
    this.selected,
    this.onInteractionEnd,
    this.onWallpaper = true,
    super.key,
  });

  final List<String> letters;
  final String? selected;

  /// Recebe `null` quando o dedo sai da barra.
  final ValueChanged<String?> onLetterChanged;
  final VoidCallback? onInteractionEnd;

  /// Na Home as letras ficam sobre o wallpaper e precisam de sombra; na lista
  /// de aplicações estão sobre um painel opaco e não precisam.
  final bool onWallpaper;

  /// As etiquetas a desenhar quando só cabem [capacity]: letras espaçadas por
  /// igual, com `null` (um ponto) entre elas, a primeira e a última sempre
  /// presentes. Com espaço para todas devolve a lista tal como está.
  ///
  /// Se a letra [selected] ficou escondida, toma o lugar da etiqueta que está
  /// debaixo do dedo — quem arrasta tem de ver em que letra vai.
  @visibleForTesting
  static List<String?> labelsThatFit(
    List<String> letters,
    int capacity, {
    String? selected,
  }) {
    final int n = letters.length;
    if (capacity >= n || n <= 2) return letters;

    final List<String?> labels;
    if (capacity < 3) {
      labels = <String?>[letters.first, letters.last];
    } else {
      // Número ímpar de posições, para começar e acabar numa letra:
      // letra, ponto, letra, ..., ponto, letra.
      final int slots = capacity.isOdd ? capacity : capacity - 1;
      final int shown = (slots + 1) ~/ 2;

      labels = <String?>[];
      for (int i = 0; i < shown; i++) {
        if (i > 0) labels.add(null);
        labels.add(letters[(i * (n - 1) / (shown - 1)).round()]);
      }
    }

    final int selectedIndex = selected == null ? -1 : letters.indexOf(selected);
    if (selectedIndex >= 0 && !labels.contains(selected)) {
      // O dedo percorre a lista completa (ver _report): a letra i ocupa a
      // fatia [i/n, (i+1)/n] da barra. A etiqueta nessa altura é esta.
      final int slot = ((selectedIndex + 0.5) / n * labels.length).floor();
      labels[slot.clamp(0, labels.length - 1)] = selected;
    }
    return labels;
  }

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

    final double lineHeight = (style?.fontSize ?? 11) * (style?.height ?? 1.15);

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
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final int capacity = constraints.maxHeight.isFinite
                ? (constraints.maxHeight / lineHeight).floor()
                : widget.letters.length;
            final List<String?> labels = AlphabetIndexBar.labelsThatFit(
              widget.letters,
              capacity,
              selected: widget.selected,
            );

            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                for (final String? label in labels)
                  Expanded(
                    child: Center(
                      child: Text(
                        label ?? '•',
                        style: () {
                          final bool selected = label != null && label == widget.selected;
                          final TextStyle? base = style?.copyWith(
                            color: selected ? palette.primaryText : palette.secondaryText,
                            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                          );
                          return widget.onWallpaper ? base.onWallpaper(context) : base;
                        }(),
                      ),
                    ),
                  ),
              ],
            );
          },
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
