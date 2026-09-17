import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/app_labels_repository.dart';
import '../../data/repositories/app_repository.dart';
import '../../data/repositories/favorites_repository.dart';
import '../../data/repositories/settings_repository.dart';
import '../../data/services/platform_launcher_service.dart';
import '../../data/services/preferences_service.dart';

/// Preferências já carregadas.
///
/// É substituído em `main()` por uma instância real — daí o `throw`: se algum
/// teste ou entry point se esquecer do override, falha de imediato em vez de
/// devolver dados vazios em silêncio.
final Provider<PreferencesService> preferencesServiceProvider =
    Provider<PreferencesService>((Ref ref) {
  throw StateError(
    'preferencesServiceProvider tem de ser substituído no ProviderScope. '
    'Ver bootstrap() em lib/main.dart.',
  );
});

final Provider<PlatformLauncherService> platformLauncherServiceProvider =
    Provider<PlatformLauncherService>((Ref ref) => const PlatformLauncherService());

final Provider<AppRepository> appRepositoryProvider = Provider<AppRepository>(
  (Ref ref) => AppRepository(ref.watch(platformLauncherServiceProvider)),
);

final Provider<AppLabelsRepository> appLabelsRepositoryProvider =
    Provider<AppLabelsRepository>(
  (Ref ref) => AppLabelsRepository(ref.watch(preferencesServiceProvider)),
);

final Provider<FavoritesRepository> favoritesRepositoryProvider =
    Provider<FavoritesRepository>(
  (Ref ref) => FavoritesRepository(ref.watch(preferencesServiceProvider)),
);

final Provider<SettingsRepository> settingsRepositoryProvider = Provider<SettingsRepository>(
  (Ref ref) => SettingsRepository(ref.watch(preferencesServiceProvider)),
);
