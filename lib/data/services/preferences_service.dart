import 'package:shared_preferences/shared_preferences.dart';

/// Armazenamento local (plano, secção 10).
///
/// Tudo fica no dispositivo: não há backend, contas nem sincronização
/// (plano, secção 17). A instância é carregada uma vez no arranque para que
/// as leituras sejam síncronas — o launcher não pode mostrar um spinner
/// antes de desenhar os favoritos.
class PreferencesService {
  const PreferencesService(this._prefs);

  static Future<PreferencesService> load() async =>
      PreferencesService(await SharedPreferences.getInstance());

  final SharedPreferences _prefs;

  List<String> getStringList(String key) => _prefs.getStringList(key) ?? const <String>[];

  Future<void> setStringList(String key, List<String> value) =>
      _prefs.setStringList(key, value);

  String? getString(String key) => _prefs.getString(key);

  Future<void> setString(String key, String value) => _prefs.setString(key, value);

  bool getBool(String key, {required bool fallback}) => _prefs.getBool(key) ?? fallback;

  Future<void> setBool(String key, {required bool value}) => _prefs.setBool(key, value);

  double getDouble(String key, {required double fallback}) =>
      _prefs.getDouble(key) ?? fallback;

  Future<void> setDouble(String key, double value) => _prefs.setDouble(key, value);

  int getInt(String key, {required int fallback}) => _prefs.getInt(key) ?? fallback;

  Future<void> setInt(String key, int value) => _prefs.setInt(key, value);

  Future<void> remove(String key) => _prefs.remove(key);

  /// Usado pelo ecrã "Sobre" para repor o launcher de origem.
  Future<void> clear() => _prefs.clear();
}
