/// Constantes partilhadas por toda a app.
///
/// Os nomes dos canais têm de ser idênticos aos de `AppManager.kt`.
library;

/// Canais de comunicação Flutter <-> Kotlin (plano, secção 5).
abstract final class LauncherChannels {
  static const String methods = 'com.lume.launcher/apps';
  static const String events = 'com.lume.launcher/events';
}

/// Chaves usadas no armazenamento local (plano, secção 10).
abstract final class PreferenceKeys {
  static const String favorites = 'favorites';
  static const String hiddenApps = 'hidden_apps';

  /// Nomes dados pelo utilizador, em JSON: {packageName: nome}.
  static const String appLabels = 'app_labels';

  static const String theme = 'settings.theme';
  static const String fontScale = 'settings.font_scale';
  static const String itemSpacing = 'settings.item_spacing';
  static const String showIcons = 'settings.show_icons';
  static const String panelOpacity = 'settings.panel_opacity';
  static const String accentColor = 'settings.accent_color';
  static const String contentAlignment = 'settings.content_alignment';
  static const String showClock = 'settings.show_clock';
  static const String showDate = 'settings.show_date';
  static const String showAlphabetIndex = 'settings.show_alphabet_index';
  static const String animations = 'settings.animations';
  static const String use24HourClock = 'settings.use_24h_clock';
  static const String showSystemApps = 'settings.show_system_apps';
  static const String searchPackageNames = 'settings.search_package_names';
  static const String searchAutoFocus = 'settings.search_auto_focus';
  static const String searchOpensSingleResult = 'settings.search_opens_single_result';
  static const String favoritesLimit = 'settings.favorites_limit';

  /// Prefixo; a chave final é `settings.gesture.<gesto>`.
  static const String gesturePrefix = 'settings.gesture.';
}

/// Números mágicos da UI num só sítio.
abstract final class LauncherMetrics {
  /// Lado do ícone pedido ao Android, em pixels. Um só tamanho mantém a
  /// cache do Kotlin e a ImageCache do Flutter pequenas (FASE 10).
  static const int iconPixelSize = 144;

  /// Tamanho a que o ícone é desenhado, em logical pixels.
  static const double iconSize = 34;

  static const double horizontalPadding = 24;
  static const double alphabetBarWidth = 30;

  static const double minFontScale = 0.85;
  static const double maxFontScale = 1.35;
  static const double minItemSpacing = 0;
  static const double maxItemSpacing = 16;

  /// Opacidade dos painéis (pesquisa, lista, definições). Não desce abaixo
  /// de 0.7: mais do que isso e o wallpaper come o texto por baixo.
  static const double minPanelOpacity = 0.7;
  static const double maxPanelOpacity = 1;

  static const int minFavorites = 3;
  static const int maxFavorites = 10;

  /// Distância mínima, em logical pixels, para um swipe contar.
  static const double swipeThreshold = 60;

  /// Velocidade mínima, em logical pixels/s, para um swipe contar.
  static const double swipeVelocityThreshold = 180;
}

/// Durações de animação. Todas curtas: o launcher é aberto dezenas de vezes
/// por dia e qualquer atraso é sentido (plano, secção 23).
abstract final class LauncherDurations {
  static const Duration fast = Duration(milliseconds: 120);
  static const Duration normal = Duration(milliseconds: 200);
  static const Duration slow = Duration(milliseconds: 280);

  /// Espera antes de recarregar a lista após um evento de pacote, para
  /// agrupar instalações em lote (ex.: restauro de backup).
  static const Duration packageEventDebounce = Duration(milliseconds: 600);

  static const Duration searchDebounce = Duration(milliseconds: 90);
}
