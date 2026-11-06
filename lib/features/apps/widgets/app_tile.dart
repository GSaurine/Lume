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
    this.overWallpaper = false,
    this.textAlign,
    this.spacing,
    this.iconSize = LauncherMetrics.iconSize,
    super.key,
  });

  final InstalledApp app;
  final TextStyle? textStyle;

  /// Espaçamento reduzido, para listas longas.
  final bool dense;
  final Widget? trailing;

  /// Chamado depois de o app abrir — usado para fechar a pesquisa.
  final VoidCallback? onLaunched;

  /// Na Home, o item fica sobre o wallpaper e por baixo dele está a camada de
  /// gestos. O `InkWell` usa `HitTestBehavior.opaque` e engoliria os deslizes
  /// que começassem em cima de um favorito, por isso aí usamos um detetor
  /// translúcido — assim o toque continua a funcionar e o arrasto passa.
  /// A ondulação do Material também não assenta bem sobre uma fotografia.
  final bool overWallpaper;

  /// Alinhamento do nome. Só usado na Home, onde o utilizador escolhe se o
  /// conteúdo fica encostado à esquerda ou ao centro.
  final TextAlign? textAlign;

  /// Espaçamento vertical imposto, que ganha à definição do utilizador. Os
  /// favoritos usam-no quando não cabem todos com o espaço que ele escolheu.
  final double? spacing;

  /// Lado do ícone. Os favoritos encolhem-no quando são muitos.
  final double iconSize;

  /// O espaçamento de [dense].
  static const double denseSpacing = 4;

  /// Altura de um item: o texto (ou o ícone, se for maior) e 8 + [spacing]
  /// em cima e em baixo. Para quem precisa de saber se os itens cabem, ou de
  /// os pôr numa grelha.
  static double heightFor({
    required double lineHeight,
    required double spacing,
    required bool showIcons,
    double iconSize = LauncherMetrics.iconSize,
  }) {
    final double content = showIcons && iconSize > lineHeight ? iconSize : lineHeight;
    return content + 2 * (8 + spacing);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showIcons = ref.watch(settingsProvider.select((s) => s.showIcons));
    final double spacing = this.spacing ??
        (dense ? denseSpacing : ref.watch(settingsProvider.select((s) => s.itemSpacing)));

    final bool centred = textAlign == TextAlign.center;

    final Widget content = Padding(
      padding: EdgeInsets.symmetric(
        horizontal: LauncherMetrics.horizontalPadding,
        vertical: 8 + spacing,
      ),
      // Ao centro, o ícone e o nome têm de andar juntos: com um Expanded o
      // texto centrava-se na linha toda e o ícone ficava encostado à margem,
      // longe dele.
      child: Row(
        mainAxisAlignment:
            centred ? MainAxisAlignment.center : MainAxisAlignment.start,
        children: <Widget>[
          if (showIcons) ...<Widget>[
            AppIcon(app: app, size: iconSize),
            // O intervalo acompanha o ícone, para a proporção não mudar.
            SizedBox(width: 14 * iconSize / LauncherMetrics.iconSize),
          ],
          Flexible(
            fit: centred ? FlexFit.loose : FlexFit.tight,
            child: Text(
              app.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: textAlign,
              style: textStyle ?? Theme.of(context).textTheme.bodyLarge,
            ),
          ),
          ?trailing,
        ],
      ),
    );

    return Semantics(
      button: true,
      label: app.name,
      child: overWallpaper
          ? GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () => _launch(context, ref),
              onLongPress: () => _showMenu(context, ref),
              // O IgnorePointer é tão necessário como o `translucent`.
              // Translucent faz o detetor receber os eventos mesmo sem nada
              // por baixo, mas se um filho responder ao hit test a procura
              // do Stack pára aqui na mesma — e o Text responde sempre, na
              // largura toda por causa do Expanded. Silenciando o conteúdo,
              // o gesto continua a descer até à camada de gestos da Home.
              child: IgnorePointer(child: content),
            )
          : InkWell(
              onTap: () => _launch(context, ref),
              onLongPress: () => _showMenu(context, ref),
              borderRadius: BorderRadius.circular(10),
              child: content,
            ),
    );
  }

  Future<void> _launch(BuildContext context, WidgetRef ref) async {
    // O toque pode chegar com atraso (com o toque duplo ligado na Home, o
    // Flutter espera para ver se vem um segundo), e entretanto o item pode
    // ter saído do ecrã.
    if (!context.mounted) return;
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
