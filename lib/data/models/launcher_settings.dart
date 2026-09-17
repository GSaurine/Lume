import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show ThemeMode;

import '../../core/constants/launcher_constants.dart';

/// Gestos reconhecidos na Home (plano, secção 13).
enum LauncherGesture {
  swipeUp('swipe_up'),
  swipeDown('swipe_down'),
  swipeLeft('swipe_left'),
  swipeRight('swipe_right'),
  doubleTap('double_tap');

  const LauncherGesture(this.key);

  final String key;

  static LauncherGesture? tryParse(String key) {
    for (final LauncherGesture gesture in LauncherGesture.values) {
      if (gesture.key == key) return gesture;
    }
    return null;
  }
}

/// O que um gesto pode fazer.
enum GestureAction {
  none('none'),
  openSearch('open_search'),
  openAppList('open_app_list'),
  openFavorites('open_favorites'),
  openSettings('open_settings'),
  expandNotifications('expand_notifications'),
  openRecents('open_recents'),
  lockScreen('lock_screen');

  const GestureAction(this.key);

  final String key;

  /// Precisa do serviço de acessibilidade do Lume para funcionar de forma
  /// fiável no Android 12+.
  bool get needsAccessibility =>
      this == GestureAction.openRecents || this == GestureAction.lockScreen;

  static GestureAction parse(String? key, {GestureAction fallback = GestureAction.none}) {
    for (final GestureAction action in GestureAction.values) {
      if (action.key == key) return action;
    }
    return fallback;
  }
}

/// Preferência de tema escolhida pelo utilizador.
enum ThemePreference {
  light('light'),
  dark('dark'),
  system('system');

  const ThemePreference(this.key);

  final String key;

  ThemeMode get themeMode => switch (this) {
        ThemePreference.light => ThemeMode.light,
        ThemePreference.dark => ThemeMode.dark,
        ThemePreference.system => ThemeMode.system,
      };

  static ThemePreference parse(String? key) {
    for (final ThemePreference value in ThemePreference.values) {
      if (value.key == key) return value;
    }
    return ThemePreference.system;
  }
}

/// Todas as preferências do launcher num único objeto imutável.
@immutable
class LauncherSettings {
  const LauncherSettings({
    this.theme = ThemePreference.system,
    this.fontScale = 1,
    this.itemSpacing = 6,
    this.showIcons = false,
    this.panelOpacity = 1,
    this.showClock = true,
    this.showDate = true,
    this.showAlphabetIndex = true,
    this.animations = true,
    this.use24HourClock = true,
    this.showSystemApps = true,
    this.searchPackageNames = false,
    this.searchAutoFocus = true,
    this.searchOpensSingleResult = false,
    this.favoritesLimit = 6,
    this.gestures = defaultGestures,
  });

  /// Escolhas iniciais: só o Swipe Up está ligado, como manda o plano
  /// ("Primeiro: Swipe Up -> Search", secção 13).
  static const Map<LauncherGesture, GestureAction> defaultGestures =
      <LauncherGesture, GestureAction>{
    LauncherGesture.swipeUp: GestureAction.openSearch,
    LauncherGesture.swipeDown: GestureAction.expandNotifications,
    LauncherGesture.swipeLeft: GestureAction.openAppList,
    LauncherGesture.swipeRight: GestureAction.none,
    LauncherGesture.doubleTap: GestureAction.none,
  };

  final ThemePreference theme;
  final double fontScale;
  final double itemSpacing;

  /// Ícones desligados por omissão: a lista só com texto é a identidade
  /// visual do launcher (plano, secção 2).
  final bool showIcons;

  /// Opacidade dos painéis de ecrã inteiro. Opacos por omissão: o primeiro
  /// utilizador a experimentar o Lume queixou-se de o wallpaper atrapalhar a
  /// leitura na pesquisa. Quem gostar do efeito baixa este valor.
  final double panelOpacity;
  final bool showClock;
  final bool showDate;
  final bool showAlphabetIndex;
  final bool animations;
  final bool use24HourClock;
  final bool showSystemApps;
  final bool searchPackageNames;
  final bool searchAutoFocus;

  /// Abre logo o app quando a pesquisa tem um único resultado.
  final bool searchOpensSingleResult;
  final int favoritesLimit;
  final Map<LauncherGesture, GestureAction> gestures;

  GestureAction actionFor(LauncherGesture gesture) =>
      gestures[gesture] ?? defaultGestures[gesture] ?? GestureAction.none;

  /// Duração efetiva de uma animação: zero quando o utilizador as desliga.
  Duration duration(Duration value) => animations ? value : Duration.zero;

  LauncherSettings copyWith({
    ThemePreference? theme,
    double? fontScale,
    double? itemSpacing,
    bool? showIcons,
    double? panelOpacity,
    bool? showClock,
    bool? showDate,
    bool? showAlphabetIndex,
    bool? animations,
    bool? use24HourClock,
    bool? showSystemApps,
    bool? searchPackageNames,
    bool? searchAutoFocus,
    bool? searchOpensSingleResult,
    int? favoritesLimit,
    Map<LauncherGesture, GestureAction>? gestures,
  }) {
    return LauncherSettings(
      theme: theme ?? this.theme,
      fontScale: (fontScale ?? this.fontScale)
          .clamp(LauncherMetrics.minFontScale, LauncherMetrics.maxFontScale),
      itemSpacing: (itemSpacing ?? this.itemSpacing)
          .clamp(LauncherMetrics.minItemSpacing, LauncherMetrics.maxItemSpacing),
      showIcons: showIcons ?? this.showIcons,
      panelOpacity: (panelOpacity ?? this.panelOpacity)
          .clamp(LauncherMetrics.minPanelOpacity, LauncherMetrics.maxPanelOpacity),
      showClock: showClock ?? this.showClock,
      showDate: showDate ?? this.showDate,
      showAlphabetIndex: showAlphabetIndex ?? this.showAlphabetIndex,
      animations: animations ?? this.animations,
      use24HourClock: use24HourClock ?? this.use24HourClock,
      showSystemApps: showSystemApps ?? this.showSystemApps,
      searchPackageNames: searchPackageNames ?? this.searchPackageNames,
      searchAutoFocus: searchAutoFocus ?? this.searchAutoFocus,
      searchOpensSingleResult: searchOpensSingleResult ?? this.searchOpensSingleResult,
      favoritesLimit: (favoritesLimit ?? this.favoritesLimit)
          .clamp(LauncherMetrics.minFavorites, LauncherMetrics.maxFavorites),
      gestures: gestures ?? this.gestures,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LauncherSettings &&
          other.theme == theme &&
          other.fontScale == fontScale &&
          other.itemSpacing == itemSpacing &&
          other.showIcons == showIcons &&
          other.panelOpacity == panelOpacity &&
          other.showClock == showClock &&
          other.showDate == showDate &&
          other.showAlphabetIndex == showAlphabetIndex &&
          other.animations == animations &&
          other.use24HourClock == use24HourClock &&
          other.showSystemApps == showSystemApps &&
          other.searchPackageNames == searchPackageNames &&
          other.searchAutoFocus == searchAutoFocus &&
          other.searchOpensSingleResult == searchOpensSingleResult &&
          other.favoritesLimit == favoritesLimit &&
          mapEquals(other.gestures, gestures);

  @override
  int get hashCode => Object.hash(
        theme,
        fontScale,
        itemSpacing,
        showIcons,
        panelOpacity,
        showClock,
        showDate,
        showAlphabetIndex,
        animations,
        use24HourClock,
        showSystemApps,
        searchPackageNames,
        searchAutoFocus,
        searchOpensSingleResult,
        favoritesLimit,
        Object.hashAll(gestures.entries.map((e) => Object.hash(e.key, e.value))),
      );
}
