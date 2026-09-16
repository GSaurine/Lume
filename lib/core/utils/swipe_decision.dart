import '../constants/launcher_constants.dart';

/// Decide se um arrasto conta como deslize, e para que lado.
///
/// Está fora do widget de propósito: é a regra mais fácil de acertar mal num
/// launcher e a que mais se sente quando está errada. Assim dá para testar
/// sem montar a Home inteira.
abstract final class SwipeDecision {
  /// Um deslize conta se foi rápido **ou** se percorreu distância suficiente.
  ///
  /// Olhar só à velocidade final deixa de fora quem arrasta devagar e pára
  /// antes de levantar o dedo — um gesto intencional, e o mais comum em ecrãs
  /// grandes ou com o telemóvel seguro numa só mão.
  static bool accepts({required double delta, required double velocity}) =>
      delta.abs() >= LauncherMetrics.swipeThreshold ||
      velocity.abs() >= LauncherMetrics.swipeVelocityThreshold;

  /// `true` para cima ou para a esquerda (eixos negativos do Flutter).
  ///
  /// Quando a velocidade final é praticamente nula, é a distância percorrida
  /// que diz a direção — caso contrário um arrasto lento apanharia o sentido
  /// do último tremor do dedo.
  static bool isNegative({required double delta, required double velocity}) =>
      velocity.abs() >= LauncherMetrics.swipeVelocityThreshold
          ? velocity < 0
          : delta < 0;
}
