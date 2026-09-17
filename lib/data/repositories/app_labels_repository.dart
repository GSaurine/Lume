import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../core/constants/launcher_constants.dart';
import '../services/preferences_service.dart';

/// Nomes que o utilizador deu às aplicações.
///
/// Guardado como JSON e não como lista de pares, porque um nome pode conter
/// qualquer caractere — incluindo o separador que se escolhesse.
///
/// A chave é o *package name*: o nome que o Android reporta muda com o idioma
/// do telemóvel e com as atualizações da aplicação.
class AppLabelsRepository {
  const AppLabelsRepository(this._prefs);

  final PreferencesService _prefs;

  Map<String, String> labels() {
    final String? raw = _prefs.getString(PreferenceKeys.appLabels);
    if (raw == null || raw.isEmpty) return const <String, String>{};

    try {
      final Object? decoded = jsonDecode(raw);
      if (decoded is! Map) return const <String, String>{};
      return <String, String>{
        for (final MapEntry<Object?, Object?> entry in decoded.entries)
          if (entry.key is String && entry.value is String)
            entry.key! as String: entry.value! as String,
      };
    } on FormatException catch (error) {
      // Preferências corrompidas não devem impedir o launcher de arrancar.
      debugPrint('[Lume] nomes personalizados ilegíveis: $error');
      return const <String, String>{};
    }
  }

  Future<Map<String, String>> save(Map<String, String> labels) async {
    final Map<String, String> cleaned = <String, String>{
      for (final MapEntry<String, String> entry in labels.entries)
        if (entry.value.trim().isNotEmpty) entry.key: entry.value.trim(),
    };

    if (cleaned.isEmpty) {
      await _prefs.remove(PreferenceKeys.appLabels);
    } else {
      await _prefs.setString(PreferenceKeys.appLabels, jsonEncode(cleaned));
    }
    return cleaned;
  }
}
