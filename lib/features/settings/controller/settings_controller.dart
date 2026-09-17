import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/core_providers.dart';
import '../../../data/models/launcher_settings.dart';

/// Estado das definições. Cada alteração é escrita nas preferências, mas o
/// estado em memória muda primeiro para a UI responder de imediato.
class SettingsNotifier extends Notifier<LauncherSettings> {
  @override
  LauncherSettings build() => ref.watch(settingsRepositoryProvider).load();

  void _update(LauncherSettings next) {
    if (next == state) return;
    state = next;
    // Escrita em disco sem bloquear a UI. Um erro aqui só significa que a
    // preferência não sobrevive ao reinício — não vale partir o ecrã.
    unawaited(ref.read(settingsRepositoryProvider).save(next));
  }

  void setTheme(ThemePreference value) => _update(state.copyWith(theme: value));

  void setFontScale(double value) => _update(state.copyWith(fontScale: value));

  void setItemSpacing(double value) => _update(state.copyWith(itemSpacing: value));

  void setIconStyle(IconStyle value) => _update(state.copyWith(iconStyle: value));

  void setPanelOpacity(double value) => _update(state.copyWith(panelOpacity: value));

  void setAccent(AccentColor value) => _update(state.copyWith(accent: value));

  void setContentAlignment(ContentAlignment value) =>
      _update(state.copyWith(contentAlignment: value));

  void setShowClock({required bool value}) => _update(state.copyWith(showClock: value));

  void setShowDate({required bool value}) => _update(state.copyWith(showDate: value));

  void setShowAlphabetIndex({required bool value}) =>
      _update(state.copyWith(showAlphabetIndex: value));

  void setAnimations(MotionStyle value) => _update(state.copyWith(animations: value));

  void setUse24HourClock({required bool value}) =>
      _update(state.copyWith(use24HourClock: value));

  void setShowSystemApps({required bool value}) =>
      _update(state.copyWith(showSystemApps: value));

  void setSearchPackageNames({required bool value}) =>
      _update(state.copyWith(searchPackageNames: value));

  void setSearchAutoFocus({required bool value}) =>
      _update(state.copyWith(searchAutoFocus: value));

  void setSearchOpensSingleResult({required bool value}) =>
      _update(state.copyWith(searchOpensSingleResult: value));

  void setFavoritesLimit(int value) => _update(state.copyWith(favoritesLimit: value));

  void setGesture(LauncherGesture gesture, GestureAction action) {
    final Map<LauncherGesture, GestureAction> next =
        Map<LauncherGesture, GestureAction>.of(state.gestures)..[gesture] = action;
    _update(state.copyWith(gestures: next));
  }

  Future<void> resetAll() async {
    state = await ref.read(settingsRepositoryProvider).reset();
  }
}

final NotifierProvider<SettingsNotifier, LauncherSettings> settingsProvider =
    NotifierProvider<SettingsNotifier, LauncherSettings>(SettingsNotifier.new);
