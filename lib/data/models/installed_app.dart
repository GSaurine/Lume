import 'package:flutter/foundation.dart';

import '../../core/utils/text_normalizer.dart';

/// Um aplicativo instalado, tal como o Android o reporta (plano, secção 9).
///
/// Diferença face ao modelo do plano: o ícone **não** vive aqui. Codificar
/// ~150 ícones em PNG durante o arranque custa vários segundos; em vez disso
/// pedimos cada ícone sob demanda (ver `appIconProvider`) e o Kotlin mantém
/// uma LruCache. Isto cumpre a FASE 10 sem mudar o resto do modelo.
///
/// `isFavorite` e `isHidden` também não estão aqui: são preferências locais,
/// não factos do Android, e vivem nos respetivos repositórios.
@immutable
class InstalledApp {
  const InstalledApp({
    required this.name,
    required this.packageName,
    required this.activityName,
    this.isSystemApp = false,
  });

  factory InstalledApp.fromMap(Map<Object?, Object?> map) {
    final String packageName = map['packageName']! as String;
    return InstalledApp(
      name: (map['name'] as String?)?.trim().isNotEmpty ?? false
          ? (map['name']! as String).trim()
          : packageName,
      packageName: packageName,
      activityName: (map['activityName'] as String?) ?? '',
      isSystemApp: (map['isSystemApp'] as bool?) ?? false,
    );
  }

  /// Nome visível ao utilizador.
  final String name;

  /// Identificador estável do app, ex.: `com.whatsapp`.
  final String packageName;

  /// Activity de entrada. Alguns apps expõem mais do que uma.
  final String activityName;

  /// Veio pré-instalado com o sistema.
  final bool isSystemApp;

  /// Identidade do item na lista — um package pode ter várias entradas.
  String get id => '$packageName/$activityName';

  /// Usado para aplicar o nome que o utilizador escolheu. Tudo o resto —
  /// ordenação, letra do índice, pesquisa — deriva de [name], por isso basta
  /// trocá-lo aqui para o resto seguir.
  InstalledApp withName(String newName) => InstalledApp(
        name: newName,
        packageName: packageName,
        activityName: activityName,
        isSystemApp: isSystemApp,
      );

  /// Nome preparado para pesquisa: minúsculas e sem acentos.
  String get foldedName => TextNormalizer.fold(name);

  /// Secção alfabética a que pertence: 'A'..'Z' ou '#'.
  String get indexLetter => TextNormalizer.indexLetter(name);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InstalledApp &&
          other.packageName == packageName &&
          other.activityName == activityName &&
          other.name == name;

  @override
  int get hashCode => Object.hash(packageName, activityName, name);

  @override
  String toString() => 'InstalledApp($name, $packageName)';
}

/// Evento vindo do Android pelo EventChannel.
@immutable
class LauncherPlatformEvent {
  const LauncherPlatformEvent({required this.type, this.packageName});

  factory LauncherPlatformEvent.fromMap(Map<Object?, Object?> map) => LauncherPlatformEvent(
        type: LauncherEventType.parse(map['type'] as String?),
        packageName: map['packageName'] as String?,
      );

  final LauncherEventType type;
  final String? packageName;

  /// A lista de apps deixou de estar atualizada?
  bool get affectsAppList =>
      type == LauncherEventType.packageAdded ||
      type == LauncherEventType.packageRemoved ||
      type == LauncherEventType.packageChanged;
}

enum LauncherEventType {
  packageAdded,
  packageRemoved,
  packageChanged,
  homePressed,
  unknown;

  static LauncherEventType parse(String? raw) => switch (raw) {
        'package_added' => LauncherEventType.packageAdded,
        'package_removed' => LauncherEventType.packageRemoved,
        'package_changed' => LauncherEventType.packageChanged,
        'home_pressed' => LauncherEventType.homePressed,
        _ => LauncherEventType.unknown,
      };
}
