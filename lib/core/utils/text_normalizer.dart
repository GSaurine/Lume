/// Normalização de texto para pesquisa e ordenação alfabética.
///
/// Sem isto, "Áudio" não aparece ao escrever "audio" e fica arrumado fora
/// da secção "A" da lista.
abstract final class TextNormalizer {
  static const Map<int, String> _foldings = <int, String>{
    0x00E0: 'a', 0x00E1: 'a', 0x00E2: 'a', 0x00E3: 'a', 0x00E4: 'a', 0x00E5: 'a',
    0x00E7: 'c',
    0x00E8: 'e', 0x00E9: 'e', 0x00EA: 'e', 0x00EB: 'e',
    0x00EC: 'i', 0x00ED: 'i', 0x00EE: 'i', 0x00EF: 'i',
    0x00F1: 'n',
    0x00F2: 'o', 0x00F3: 'o', 0x00F4: 'o', 0x00F5: 'o', 0x00F6: 'o', 0x00F8: 'o',
    0x00F9: 'u', 0x00FA: 'u', 0x00FB: 'u', 0x00FC: 'u',
    0x00FD: 'y', 0x00FF: 'y',
    0x0153: 'oe', 0x00E6: 'ae', 0x00DF: 'ss',
  };

  /// Minúsculas, sem acentos e sem espaços à volta.
  static String fold(String input) {
    final String lower = input.toLowerCase().trim();
    final StringBuffer buffer = StringBuffer();
    for (final int rune in lower.runes) {
      buffer.write(_foldings[rune] ?? String.fromCharCode(rune));
    }
    return buffer.toString();
  }

  /// Letra de secção de um nome: 'A'..'Z' ou '#' para tudo o resto
  /// (números, emoji, alfabetos não latinos).
  static String indexLetter(String name) {
    final String folded = fold(name);
    if (folded.isEmpty) return '#';
    final int code = folded.codeUnitAt(0);
    final bool isLatinLetter = code >= 0x61 && code <= 0x7A;
    return isLatinLetter ? folded[0].toUpperCase() : '#';
  }

  /// Divide um nome em palavras, para dar prioridade a correspondências
  /// no início de cada palavra ("dm" encontra "Google Drive"? não;
  /// "dri" encontra "Google Drive"? sim).
  static List<String> words(String folded) =>
      folded.split(RegExp(r'[\s._\-/+&:]+')).where((String w) => w.isNotEmpty).toList();
}
