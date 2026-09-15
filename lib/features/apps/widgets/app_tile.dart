import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/launcher_constants.dart';
import '../../../core/theme/launcher_palette.dart';
import '../../../data/models/installed_app.dart';
import '../../settings/controller/settings_controller.dart';
import '../controller/apps_controller.dart';
import 'app_context_menu.dart';
import 'app_icon.dart';

/// Um app numa lista (Home, drawer ou resultados de pesquisa).
///
/// Concentra aqui os três comportamentos que o plano pede (secções 12 e 13):
/// tocar abre, manter premido abre o menu contextual, e a posição do toque
/// é enviada ao Android para a animação de abertura arrancar do item certo.
class AppTile extends ConsumerWidget {
  const AppTile({
    required this.app,
    this.textStyle,
    this.dense = false,
    this.trailing,
    this.onLaunched,
    super.key,
  });

  final InstalledApp app;
  final TextStyle? textStyle;

  /// Espaçamento reduzido, para listas longas.
  final bool dense;
  final Widget? trailing;

  /// Chamado depois de o app abrir — usado para fechar a pesquisa.
  final VoidCallback? onLaunched;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showIcons = ref.watch(settingsProvider.select((s) => s.showIcons));
    final double spacing = dense
        ? 4
        : ref.watch(settingsProvider.select((s) => s.itemSpacing));

    return Semantics(
      button: true,
      label: app.name,
      child: InkWell(
        onTap: () => _launch(context, ref),
        onLongPress: () => _showMenu(context, ref),
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: LauncherMetrics.horizontalPadding,
            vertical: 8 + spacing,
          ),
          child: Row(
            children: <Widget>[
              if (showIcons) ...<Widget>[
                AppIcon(packageName: app.packageName),
                const SizedBox(width: 14),
              ],
              Expanded(
                child: Text(
                  app.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textStyle ?? Theme.of(context).textTheme.bodyLarge,
                ),
              ),
              ?trailing,
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _launch(BuildContext context, WidgetRef ref) async {
    final Rect? bounds = _globalBounds(context);
    final double ratio = MediaQuery.devicePixelRatioOf(context);
    final NavigatorState navigator = Navigator.of(context);

    final bool ok = await ref.read(appLauncherProvider).launch(
          app,
          sourceBounds: bounds,
          devicePixelRatio: ratio,
        );

    if (!ok) {
      if (!navigator.mounted) return;
      _showError(navigator.context, 'Não foi possível abrir ${app.name}.');
      return;
    }
    onLaunched?.call();
  }

  Future<void> _showMenu(BuildContext context, WidgetRef ref) async {
    await HapticFeedback.mediumImpact();
    if (!context.mounted) return;
    await showAppContextMenu(context, app);
  }

  static Rect? _globalBounds(BuildContext context) {
    final RenderObject? renderObject = context.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.hasSize) return null;
    final Offset origin = renderObject.localToGlobal(Offset.zero);
    return origin & renderObject.size;
  }

  static void _showError(BuildContext context, String message) {
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(
        content: Text(message, style: TextStyle(color: context.palette.primaryText)),
        duration: LauncherDurations.slow * 10,
      ),
    );
  }
}
