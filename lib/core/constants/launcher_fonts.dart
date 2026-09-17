import 'package:flutter/material.dart';

/// Tipos de letra à escolha.
///
/// Vêm embutidos no APK, não da rede: o Lume não declara permissão de
/// Internet e essa promessa está escrita no ecrã "Sobre" e em todas as notas
/// de versão. Custam 1,4 MB no total.
///
/// São todas fontes variáveis. Isso importa para quem mexer aqui: com uma
/// fonte variável o `fontWeight` sozinho não muda a espessura — é preciso
/// passar também `fontVariations` com o eixo `wght`, e é o que [styleFor]
/// faz. E cada família suporta um intervalo de espessuras diferente, daí
/// [minWeight] e [maxWeight]: pedir 200 à Lora, que começa nos 400, daria um
/// resultado errado em silêncio.
enum LauncherFont {
  system('system', 'Do sistema', null, 100, 900),
  inter('inter', 'Inter', 'Inter', 100, 900),
  outfit('outfit', 'Outfit', 'Outfit', 100, 900),
  lora('lora', 'Lora', 'Lora', 400, 700),
  mono('mono', 'JetBrains Mono', 'JetBrainsMono', 100, 800);

  const LauncherFont(
    this.key,
    this.label,
    this.family,
    this.minWeight,
    this.maxWeight,
  );

  final String key;
  final String label;

  /// `null` usa a fonte do sistema — Roboto, ou a que o fabricante escolheu.
  final String? family;

  final int minWeight;
  final int maxWeight;

  /// Uma frase curta para o utilizador ver o desenho antes de escolher.
  String get sample => switch (this) {
        LauncherFont.system => 'A fonte do seu Android',
        LauncherFont.inter => 'Neutra e legível em tamanhos pequenos',
        LauncherFont.outfit => 'Geométrica, com formas arredondadas',
        LauncherFont.lora => 'Serifada, com mais carácter',
        LauncherFont.mono => 'Monoespaçada, largura fixa',
      };

  /// Aplica a família e a espessura a um estilo, respeitando o intervalo que
  /// a fonte realmente suporta.
  TextStyle apply(TextStyle style) {
    if (family == null) return style;

    final int requested = (style.fontWeight ?? FontWeight.w400).value;
    final int weight = requested.clamp(minWeight, maxWeight);

    return style.copyWith(
      fontFamily: family,
      fontVariations: <FontVariation>[FontVariation('wght', weight.toDouble())],
    );
  }

  static LauncherFont parse(String? key) {
    for (final LauncherFont font in LauncherFont.values) {
      if (font.key == key) return font;
    }
    return LauncherFont.system;
  }
}
