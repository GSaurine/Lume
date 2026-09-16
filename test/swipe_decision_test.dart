import 'package:flutter_test/flutter_test.dart';
import 'package:lume_launcher/core/constants/launcher_constants.dart';
import 'package:lume_launcher/core/utils/swipe_decision.dart';

void main() {
  const double distancia = LauncherMetrics.swipeThreshold;
  const double rapido = LauncherMetrics.swipeVelocityThreshold;

  group('accepts', () {
    test('aceita um deslize rápido, mesmo curto', () {
      expect(
        SwipeDecision.accepts(delta: 10, velocity: rapido + 1),
        isTrue,
      );
    });

    test('aceita um arrasto longo que acaba parado', () {
      // Regressão: a primeira versão só olhava à velocidade final, por isso
      // arrastar devagar e parar antes de levantar o dedo não fazia nada.
      expect(
        SwipeDecision.accepts(delta: -(distancia + 1), velocity: 0),
        isTrue,
      );
    });

    test('rejeita um toque acidental: curto e lento', () {
      expect(
        SwipeDecision.accepts(delta: 5, velocity: 20),
        isFalse,
      );
    });

    test('rejeita exatamente abaixo dos dois limites', () {
      expect(
        SwipeDecision.accepts(delta: distancia - 1, velocity: rapido - 1),
        isFalse,
      );
    });

    test('aceita exatamente no limite da distância', () {
      expect(SwipeDecision.accepts(delta: distancia, velocity: 0), isTrue);
    });

    test('é simétrico nos dois sentidos', () {
      expect(SwipeDecision.accepts(delta: distancia, velocity: 0), isTrue);
      expect(SwipeDecision.accepts(delta: -distancia, velocity: 0), isTrue);
    });
  });

  group('isNegative', () {
    test('com velocidade real, manda a velocidade', () {
      expect(
        SwipeDecision.isNegative(delta: 100, velocity: -(rapido + 1)),
        isTrue,
      );
      expect(
        SwipeDecision.isNegative(delta: -100, velocity: rapido + 1),
        isFalse,
      );
    });

    test('com o dedo parado no fim, manda a distância percorrida', () {
      expect(SwipeDecision.isNegative(delta: -100, velocity: 0), isTrue);
      expect(SwipeDecision.isNegative(delta: 100, velocity: 0), isFalse);
    });

    test('um tremor final no sentido contrário não inverte o gesto', () {
      // Arrastou 200 px para cima e no fim o dedo escorregou 5 px para baixo.
      expect(SwipeDecision.isNegative(delta: -200, velocity: 30), isTrue);
    });
  });
}
