import 'package:flutter/material.dart';

import '../../data/models/launcher_settings.dart';
import '../constants/launcher_constants.dart';

/// Transições do launcher.
///
/// O Material traz transições desenhadas para ecrãs com AppBar; aqui os ecrãs
/// são painéis que sobem sobre o wallpaper. O estilo — duração e curva — vem
/// das definições, para o launcher acompanhar o tema que a pessoa montou no
/// telemóvel (plano, secção 15).
abstract final class LauncherRoute {
  /// Ecrã que entra de baixo, como a pesquisa.
  static Route<T> fromBottom<T>(Widget page, {required MotionStyle style}) =>
      _build<T>(page, style: style, begin: const Offset(0, 0.06));

  /// Ecrã que entra da direita, como a lista de aplicações.
  static Route<T> fromRight<T>(Widget page, {required MotionStyle style}) =>
      _build<T>(page, style: style, begin: const Offset(0.06, 0));

  static Route<T> _build<T>(
    Widget page, {
    required MotionStyle style,
    required Offset begin,
  }) {
    final Duration duration = style.isInstant
        ? Duration.zero
        : Duration(
            microseconds:
                (LauncherDurations.normal.inMicroseconds * style.scale).round(),
          );

    // Estilos mais expressivos deslocam mais, senão a curva não se nota.
    final Offset offset = begin * style.scale.clamp(1, 2.5);

    return PageRouteBuilder<T>(
      // Opaca de propósito: sem isto a Home continua a ser desenhada por
      // baixo e o seu texto lê-se através do painel — o relógio e o banner
      // apareciam como fantasmas atrás da lista de aplicações. O wallpaper
      // continua visível porque é a janela do launcher que é transparente.
      barrierColor: Colors.transparent,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      pageBuilder: (BuildContext context, Animation<double> animation,
              Animation<double> secondaryAnimation) =>
          page,
      transitionsBuilder: (
        BuildContext context,
        Animation<double> animation,
        Animation<double> secondaryAnimation,
        Widget child,
      ) {
        if (duration == Duration.zero) return child;

        final CurvedAnimation curved = CurvedAnimation(
          parent: animation,
          curve: style.curve,
          // A curva de saída nunca passa dos limites: um easeOutBack ao
          // contrário faria o painel sair do ecrã e voltar a espreitar.
          reverseCurve: Curves.easeInCubic,
        );
        return FadeTransition(
          // O fade segue uma curva própria: com easeOutBack, a opacidade
          // ultrapassaria 1 e o Flutter lança um erro.
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
          child: SlideTransition(
            position: Tween<Offset>(begin: offset, end: Offset.zero).animate(curved),
            child: child,
          ),
        );
      },
    );
  }
}
