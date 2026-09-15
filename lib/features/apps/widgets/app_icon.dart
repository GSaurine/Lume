import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/launcher_constants.dart';
import '../../../core/theme/launcher_palette.dart';
import '../controller/apps_controller.dart';

/// Ícone de um app, carregado sob demanda.
///
/// Enquanto o Android não responde mostramos um espaço reservado do tamanho
/// final — assim a lista nunca "salta" quando os ícones chegam (FASE 10).
class AppIcon extends ConsumerWidget {
  const AppIcon({
    required this.packageName,
    this.size = LauncherMetrics.iconSize,
    super.key,
  });

  final String packageName;
  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<Uint8List?> icon = ref.watch(appIconProvider(packageName));

    return SizedBox(
      width: size,
      height: size,
      child: switch (icon) {
        AsyncData<Uint8List?>(:final Uint8List? value) when value != null => Image.memory(
            value,
            width: size,
            height: size,
            gaplessPlayback: true,
            errorBuilder: (BuildContext context, Object error, StackTrace? stack) =>
                _Placeholder(size: size),
          ),
        _ => _Placeholder(size: size),
      },
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.palette.panelBorder,
        borderRadius: BorderRadius.circular(size * 0.25),
      ),
      child: SizedBox.square(dimension: size),
    );
  }
}
