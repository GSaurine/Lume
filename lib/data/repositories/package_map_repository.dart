import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../services/preferences_service.dart';

/// Preferências do utilizador associadas a uma aplicação: o nome que lhe deu,
/// o símbolo que lhe escolheu.
///
/// A chave é sempre o *package name*. O nome que o Android reporta muda com o
/// idioma do telemóvel e com as atualizações da aplicação; o package não.
///
/// Guardado como JSON e não como lista de pares, porque um nome pode conter
/// qualquer caractere — incluindo o separador que se escolhesse.
class PackageMapRepository {
  const PackageMapRepository(this._prefs, this.storageKey);

  final PreferencesService _prefs;

  /// Chave nas preferências. É o que distingue um repositório de nomes de um
  /// de símbolos.
  final String storageKey;

  Map<String, String> read() {
    final String? raw = _prefs.getString(storageKey);
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
      debugPrint('[Lume] preferências ilegíveis em $storageKey: $error');
      return const <String, String>{};
    }
  }

  Future<Map<String, String>> save(Map<String, String> values) async {
    final Map<String, String> cleaned = <String, String>{
      for (final MapEntry<String, String> entry in values.entries)
        if (entry.value.trim().isNotEmpty) entry.key: entry.value.trim(),
    };

    if (cleaned.isEmpty) {
      await _prefs.remove(storageKey);
    } else {
      await _prefs.setString(storageKey, jsonEncode(cleaned));
    }
    return cleaned;
  }
}
