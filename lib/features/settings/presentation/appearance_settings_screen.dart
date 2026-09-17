import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/launcher_constants.dart';
import '../../../core/theme/launcher_palette.dart';
import '../../../data/models/launcher_settings.dart';
import '../../gestures/services/system_gesture_service.dart';
import '../controller/settings_controller.dart';
import 'settings_screen.dart';

/// FASE 9 — aparência (plano, secção 15).
class AppearanceSettingsScreen extends ConsumerWidget {
  const AppearanceSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final LauncherSettings settings = ref.watch(settingsProvider);
    final SettingsNotifier controller = ref.read(settingsProvider.notifier);

    return Scaffold(
      backgroundColor: context.palette.panel,
      appBar: AppBar(title: const Text('Aparência')),
      body: SafeArea(
        top: false,
        child: ListView(
          children: <Widget>[
            const SettingsSectionTitle('Tema'),
            RadioGroup<ThemePreference>(
              groupValue: settings.theme,
              onChanged: (ThemePreference? value) {
                if (value != null) controller.setTheme(value);
              },
              child: Column(
                children: <Widget>[
                  for (final ThemePreference option in ThemePreference.values)
                    RadioListTile<ThemePreference>(
                      value: option,
                      title: Text(_themeLabel(option)),
                    ),
                ],
              ),
            ),

            const SettingsSectionTitle('Cor de destaque'),
            _AccentPicker(
              selected: settings.accent,
              onChanged: controller.setAccent,
            ),

            const SettingsSectionTitle('Alinhamento na Home'),
            RadioGroup<ContentAlignment>(
              groupValue: settings.contentAlignment,
              onChanged: (ContentAlignment? value) {
                if (value != null) controller.setContentAlignment(value);
              },
              child: const Column(
                children: <Widget>[
                  RadioListTile<ContentAlignment>(
                    value: ContentAlignment.start,
                    title: Text('À esquerda'),
                  ),
                  RadioListTile<ContentAlignment>(
                    value: ContentAlignment.center,
                    title: Text('Ao centro'),
                  ),
                ],
              ),
            ),

            const SettingsSectionTitle('Texto e espaçamento'),
            _SliderTile(
              title: 'Tamanho da letra',
              value: settings.fontScale,
              min: LauncherMetrics.minFontScale,
              max: LauncherMetrics.maxFontScale,
              format: (double v) => '${(v * 100).round()}%',
              onChanged: controller.setFontScale,
            ),
            _SliderTile(
              title: 'Espaço entre aplicações',
              value: settings.itemSpacing,
              min: LauncherMetrics.minItemSpacing,
              max: LauncherMetrics.maxItemSpacing,
              format: (double v) => '${v.round()} px',
              onChanged: controller.setItemSpacing,
            ),

            const SettingsSectionTitle('Ecrã inicial'),
            SwitchListTile(
              value: settings.showClock,
              title: const Text('Mostrar relógio'),
              onChanged: (bool value) => controller.setShowClock(value: value),
            ),
            SwitchListTile(
              value: settings.use24HourClock,
              title: const Text('Formato 24 horas'),
              onChanged: settings.showClock
                  ? (bool value) => controller.setUse24HourClock(value: value)
                  : null,
            ),
            SwitchListTile(
              value: settings.showDate,
              title: const Text('Mostrar data'),
              onChanged: (bool value) => controller.setShowDate(value: value),
            ),
            SwitchListTile(
              value: settings.showAlphabetIndex,
              title: const Text('Mostrar índice alfabético'),
              subtitle: const Text('A coluna A-Z à direita da Home'),
              onChanged: (bool value) => controller.setShowAlphabetIndex(value: value),
            ),

            const SettingsSectionTitle('Ícones'),
            RadioGroup<IconStyle>(
              groupValue: settings.iconStyle,
              onChanged: (IconStyle? value) {
                if (value != null) controller.setIconStyle(value);
              },
              child: const Column(
                children: <Widget>[
                  RadioListTile<IconStyle>(
                    value: IconStyle.symbols,
                    title: Text('Símbolos'),
                    subtitle: Text(
                      'Ícones neutros e iguais entre si. O Lume adivinha o de '
                      'cada aplicação; mantenha uma premida para escolher outro.',
                    ),
                  ),
                  RadioListTile<IconStyle>(
                    value: IconStyle.appIcons,
                    title: Text('Ícones originais'),
                    subtitle: Text('Os das próprias aplicações'),
                  ),
                  RadioListTile<IconStyle>(
                    value: IconStyle.none,
                    title: Text('Sem ícones'),
                    subtitle: Text('Só texto'),
                  ),
                ],
              ),
            ),

            const SettingsSectionTitle('Animações'),
            RadioGroup<MotionStyle>(
              groupValue: settings.animations,
              onChanged: (MotionStyle? value) {
                if (value != null) controller.setAnimations(value);
              },
              child: Column(
                children: <Widget>[
                  for (final MotionStyle style in MotionStyle.values)
                    RadioListTile<MotionStyle>(
                      value: style,
                      title: Text(style.label),
                      subtitle: Text(_motionHint(style)),
                    ),
                ],
              ),
            ),

            const SettingsSectionTitle('Painéis'),
            _SliderTile(
              title: 'Opacidade dos painéis',
              subtitle: 'Pesquisa, lista de aplicações e definições. '
                  'Abaixo de 100% deixa ver o wallpaper por trás.',
              value: settings.panelOpacity,
              min: LauncherMetrics.minPanelOpacity,
              max: LauncherMetrics.maxPanelOpacity,
              divisions: 6,
              format: (double v) => '${(v * 100).round()}%',
              onChanged: controller.setPanelOpacity,
            ),

            const SettingsSectionTitle('Favoritos'),
            _SliderTile(
              title: 'Favoritos visíveis na Home',
              value: settings.favoritesLimit.toDouble(),
              min: LauncherMetrics.minFavorites.toDouble(),
              max: LauncherMetrics.maxFavorites.toDouble(),
              divisions: LauncherMetrics.maxFavorites - LauncherMetrics.minFavorites,
              format: (double v) => '${v.round()}',
              onChanged: (double value) => controller.setFavoritesLimit(value.round()),
            ),
            const SettingsSectionTitle('Wallpaper'),
            Consumer(
              builder: (BuildContext context, WidgetRef ref, _) => ListTile(
                leading: const Icon(Icons.wallpaper_rounded),
                title: const Text('Mudar wallpaper'),
                subtitle: const Text('Abre o seletor do Android'),
                onTap: () =>
                    ref.read(systemGestureServiceProvider).openWallpaperPicker(),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  static String _motionHint(MotionStyle style) => switch (style) {
        MotionStyle.none => 'Tudo instantâneo',
        MotionStyle.crisp => 'Rápida e direta',
        MotionStyle.subtle => 'O equilíbrio de origem',
        MotionStyle.smooth => 'Mais demorada e macia',
        MotionStyle.bouncy => 'Passa do destino e volta',
      };

  static String _themeLabel(ThemePreference preference) => switch (preference) {
        ThemePreference.light => 'Claro',
        ThemePreference.dark => 'Escuro',
        ThemePreference.system => 'Seguir o sistema',
      };
}

/// Uma fila de círculos com as cores disponíveis.
class _AccentPicker extends StatelessWidget {
  const _AccentPicker({required this.selected, required this.onChanged});

  final AccentColor selected;
  final ValueChanged<AccentColor> onChanged;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Wrap(
        spacing: 16,
        runSpacing: 12,
        children: <Widget>[
          for (final AccentColor accent in AccentColor.values)
            Semantics(
              label: accent.label,
              selected: accent == selected,
              button: true,
              child: Tooltip(
                message: accent.label,
                child: InkWell(
                  onTap: () => onChanged(accent),
                  customBorder: const CircleBorder(),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(isDark ? accent.darkValue : accent.lightValue),
                        border: Border.all(
                          color: accent == selected
                              ? context.palette.primaryText
                              : Colors.transparent,
                          width: 2.5,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SliderTile extends StatelessWidget {
  const _SliderTile({
    required this.title,
    required this.value,
    required this.min,
    required this.max,
    required this.format,
    required this.onChanged,
    this.divisions,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final double value;
  final double min;
  final double max;
  final int? divisions;
  final String Function(double value) format;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Expanded(
                child: Text(title, style: Theme.of(context).textTheme.bodyLarge),
              ),
              Text(format(value), style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
          if (subtitle case final String text)
            Text(text, style: Theme.of(context).textTheme.bodySmall),
          Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
