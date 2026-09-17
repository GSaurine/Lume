import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/launcher_constants.dart';
import '../../../core/constants/launcher_fonts.dart';
import '../../../core/theme/accent_resolver.dart';
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
              custom: settings.customAccentArgb,
              onChanged: controller.setAccent,
            ),
            _CustomAccentPicker(
              current: settings.customAccentArgb,
              onChanged: controller.setCustomAccent,
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

            const SettingsSectionTitle('Tipo de letra'),
            RadioGroup<LauncherFont>(
              groupValue: settings.font,
              onChanged: (LauncherFont? value) {
                if (value != null) controller.setFont(value);
              },
              child: Column(
                children: <Widget>[
                  for (final LauncherFont font in LauncherFont.values)
                    RadioListTile<LauncherFont>(
                      value: font,
                      title: Text(
                        font.label,
                        style: font.apply(
                          Theme.of(context).textTheme.bodyLarge ?? const TextStyle(),
                        ),
                      ),
                      subtitle: Text(
                        font.sample,
                        style: font.apply(
                          Theme.of(context).textTheme.bodySmall ?? const TextStyle(),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            const SettingsSectionTitle('Relógio'),
            RadioGroup<ClockStyle>(
              groupValue: settings.clockStyle,
              onChanged: (ClockStyle? value) {
                if (value != null) controller.setClockStyle(value);
              },
              child: Column(
                children: <Widget>[
                  for (final ClockStyle style in ClockStyle.values)
                    RadioListTile<ClockStyle>(
                      value: style,
                      title: Text(style.label),
                      secondary: Text(
                        style.isStacked ? '09\n41' : '09:41',
                        textAlign: TextAlign.center,
                        style: settings.font.apply(
                          TextStyle(
                            fontSize: style.size * 0.34,
                            fontWeight: style.weight,
                            height: style.isStacked ? 0.95 : 1.2,
                            color: context.palette.primaryText,
                          ),
                        ),
                      ),
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
  const _AccentPicker({
    required this.selected,
    required this.custom,
    required this.onChanged,
  });

  final AccentColor selected;

  /// Quando há cor personalizada, nenhum dos círculos está ativo.
  final int? custom;
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
                          color: accent == selected && custom == null
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

/// Seletor de cor livre: matiz e saturação.
///
/// O brilho não é escolhido de propósito. Uma cor de destaque tem de se ler
/// sobre painéis claros *e* escuros, e deixar essa dimensão livre garantia
/// que mais cedo ou mais tarde alguém escolheria uma que desaparecia num dos
/// temas. O matiz e a saturação — que é onde está a identidade da cor —
/// ficam inteiramente à escolha; ver [AccentResolver].
class _CustomAccentPicker extends StatefulWidget {
  const _CustomAccentPicker({required this.current, required this.onChanged});

  final int? current;
  final ValueChanged<int> onChanged;

  @override
  State<_CustomAccentPicker> createState() => _CustomAccentPickerState();
}

class _CustomAccentPickerState extends State<_CustomAccentPicker> {
  late double _hue;
  late double _saturation;

  @override
  void initState() {
    super.initState();
    final HSLColor start = widget.current == null
        ? const HSLColor.fromAHSL(1, 250, 0.7, 0.55)
        : HSLColor.fromColor(Color(widget.current!));
    _hue = start.hue;
    _saturation = start.saturation.clamp(0.0, 1.0);
  }

  void _emit() => widget.onChanged(AccentResolver.raw(_hue, _saturation).toARGB32());

  @override
  Widget build(BuildContext context) {
    final LauncherPalette palette = context.palette;
    final Color preview = AccentResolver.raw(_hue, _saturation);
    final bool active = widget.current != null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: preview,
                  border: Border.all(
                    color: active ? palette.primaryText : palette.panelBorder,
                    width: active ? 2.5 : 1,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  'Cor à escolha',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
              Text(
                '#${preview.toARGB32().toRadixString(16).substring(2).toUpperCase()}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          _HueSlider(
            hue: _hue,
            saturation: _saturation,
            onChanged: (double value) {
              setState(() => _hue = value);
              _emit();
            },
          ),
          Slider(
            value: _saturation,
            onChanged: (double value) {
              setState(() => _saturation = value);
              _emit();
            },
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'O brilho é ajustado ao tema para a cor não desaparecer sobre os '
              'painéis claros ou escuros.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

/// Slider com o arco-íris por trás, para se ver o que se está a escolher.
class _HueSlider extends StatelessWidget {
  const _HueSlider({
    required this.hue,
    required this.saturation,
    required this.onChanged,
  });

  final double hue;
  final double saturation;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            height: 6,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(3),
              gradient: LinearGradient(
                colors: <Color>[
                  for (int degree = 0; degree <= 360; degree += 30)
                    HSLColor.fromAHSL(1, degree.toDouble() % 360, saturation, 0.55)
                        .toColor(),
                ],
              ),
            ),
          ),
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: Colors.transparent,
            inactiveTrackColor: Colors.transparent,
            thumbColor: HSLColor.fromAHSL(1, hue, saturation, 0.55).toColor(),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
          ),
          child: Slider(value: hue, max: 359, onChanged: onChanged),
        ),
      ],
    );
  }
}
