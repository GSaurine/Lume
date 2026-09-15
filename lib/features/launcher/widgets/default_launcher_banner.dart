import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/launcher_constants.dart';
import '../../../core/theme/launcher_palette.dart';
import '../controller/home_controller.dart';

/// FASE 2 — fluxo de seleção como launcher padrão.
///
/// Só aparece enquanto o Lume não for o Home atual. Sem este aviso, quem
/// instala a app abre-a uma vez pelo drawer e nunca percebe que tem de a
/// definir como ecrã inicial.
class DefaultLauncherBanner extends ConsumerWidget {
  const DefaultLauncherBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<bool> status = ref.watch(isDefaultLauncherProvider);

    // Enquanto não sabemos, não mostramos nada: um banner que pisca no
    // arranque é pior do que um banner que chega 100 ms atrasado.
    if (status.value ?? true) return const SizedBox.shrink();

    final LauncherPalette palette = context.palette;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        LauncherMetrics.horizontalPadding,
        12,
        LauncherMetrics.horizontalPadding,
        0,
      ),
      child: Material(
        color: palette.panel,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => ref.read(isDefaultLauncherProvider.notifier).requestDefault(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: <Widget>[
                Icon(Icons.home_outlined, color: palette.accent, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Definir o Lume como ecrã inicial',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Toque para escolher na lista do Android.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: palette.tertiaryText),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
