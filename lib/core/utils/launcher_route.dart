import 'package:flutter/material.dart';

import '../constants/launcher_constants.dart';

/// Transições do launcher.
///
/// Material dá transições desenhadas para apps com AppBar; aqui os ecrãs são
/// painéis que sobem sobre o wallpaper. Curtas e discretas de propósito
/// (plano, secção 14).
abstract final class LauncherRoute {
  /// Ecrã que entra de baixo, como a pesquisa.
  static Route<T> fromBottom<T>(Widget page, {required bool animate}) =>
      _build<T>(page, animate: animate, begin: const Offset(0, 0.06));

  /// Ecrã que entra da direita, como a lista de apps.
  static Route<T> fromRight<T>(Widget page, {required bool animate}) =>
      _build<T>(page, animate: animate, begin: const Offset(0.06, 0));

  static Route<T> _build<T>(
    Widget page, {
    required bool animate,
    required Offset begin,
  }) {
    final Duration duration = animate ? LauncherDurations.normal : Duration.zero;

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
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(begin: begin, end: Offset.zero).animate(curved),
            child: child,
          ),
        );
      },
    );
  }
}
