import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/launcher_palette.dart';
import '../../../data/models/launcher_settings.dart';
import '../../gestures/services/system_gesture_service.dart';
import '../controller/settings_controller.dart';
import 'settings_screen.dart';

/// Gestos (plano, secção 13 e 16).
class GesturesSettingsScreen extends ConsumerStatefulWidget {
  const GesturesSettingsScreen({super.key});

  @override
  ConsumerState<GesturesSettingsScreen> createState() => _GesturesSettingsScreenState();
}

class _GesturesSettingsScreenState extends ConsumerState<GesturesSettingsScreen> {
  bool? _accessibilityEnabled;

  @override
  void initState() {
    super.initState();
    _refreshAccessibility();
  }

  Future<void> _refreshAccessibility() async {
    final bool enabled =
        await ref.read(systemGestureServiceProvider).isAccessibilityEnabled();
    if (mounted) setState(() => _accessibilityEnabled = enabled);
  }

  @override
  Widget build(BuildContext context) {
    final LauncherSettings settings = ref.watch(settingsProvider);
    final bool needsAccessibility = settings.gestures.values.any(
      (GestureAction action) => action.needsAccessibility,
    );

    return Scaffold(
      backgroundColor: context.palette.panel,
      appBar: AppBar(title: const Text('Gestos')),
      body: SafeArea(
        top: false,
        child: ListView(
          children: <Widget>[
            const SettingsSectionTitle('Na Home'),
            for (final LauncherGesture gesture in LauncherGesture.values)
              ListTile(
                leading: Icon(_gestureIcon(gesture)),
                title: Text(_gestureLabel(gesture)),
                subtitle: Text(_actionLabel(settings.actionFor(gesture))),
                onTap: () => _pickAction(gesture, settings.actionFor(gesture)),
              ),
            const ListTile(
              leading: Icon(Icons.touch_app_outlined),
              title: Text('Manter premido'),
              subtitle: Text('Menu rápido (fixo)'),
              enabled: false,
            ),
            if (needsAccessibility || _accessibilityEnabled == false)
              _AccessibilityNotice(
                enabled: _accessibilityEnabled ?? false,
                onOpenSettings: () async {
                  await ref.read(systemGestureServiceProvider).openAccessibilitySettings();
                  await _refreshAccessibility();
                },
              ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAction(LauncherGesture gesture, GestureAction current) async {
    final GestureAction? chosen = await showModalBottomSheet<GestureAction>(
      context: context,
      builder: (BuildContext sheetContext) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 4, 24, 12),
              child: Text(
                _gestureLabel(gesture),
                style: Theme.of(sheetContext).textTheme.titleLarge,
              ),
            ),
            for (final GestureAction action in GestureAction.values)
              ListTile(
                title: Text(_actionLabel(action)),
                trailing: action == current
                    ? Icon(Icons.check_rounded, color: context.palette.accent)
                    : null,
                onTap: () => Navigator.of(sheetContext).pop(action),
              ),
          ],
        ),
      ),
    );

    if (chosen == null || !mounted) return;
    ref.read(settingsProvider.notifier).setGesture(gesture, chosen);
    if (chosen.needsAccessibility) await _refreshAccessibility();
  }

  static IconData _gestureIcon(LauncherGesture gesture) => switch (gesture) {
        LauncherGesture.swipeUp => Icons.keyboard_arrow_up_rounded,
        LauncherGesture.swipeDown => Icons.keyboard_arrow_down_rounded,
        LauncherGesture.swipeLeft => Icons.keyboard_arrow_left_rounded,
        LauncherGesture.swipeRight => Icons.keyboard_arrow_right_rounded,
        LauncherGesture.doubleTap => Icons.ads_click_rounded,
      };

  static String _gestureLabel(LauncherGesture gesture) => switch (gesture) {
        LauncherGesture.swipeUp => 'Deslizar para cima',
        LauncherGesture.swipeDown => 'Deslizar para baixo',
        LauncherGesture.swipeLeft => 'Deslizar para a esquerda',
        LauncherGesture.swipeRight => 'Deslizar para a direita',
        LauncherGesture.doubleTap => 'Toque duplo',
      };

  static String _actionLabel(GestureAction action) => switch (action) {
        GestureAction.none => 'Nada',
        GestureAction.openSearch => 'Abrir pesquisa',
        GestureAction.openAppList => 'Abrir lista de aplicações',
        GestureAction.openFavorites => 'Abrir favoritos',
        GestureAction.openSettings => 'Abrir definições',
        GestureAction.expandNotifications => 'Abrir notificações',
        GestureAction.openRecents => 'Aplicações recentes',
        GestureAction.lockScreen => 'Bloquear ecrã',
      };
}

class _AccessibilityNotice extends StatelessWidget {
  const _AccessibilityNotice({required this.enabled, required this.onOpenSettings});

  final bool enabled;
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final LauncherPalette palette = context.palette;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: palette.panelBorder),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(
                  enabled ? Icons.check_circle_outline_rounded : Icons.info_outline_rounded,
                  size: 20,
                  color: enabled ? palette.accent : palette.tertiaryText,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    enabled
                        ? 'Serviço de acessibilidade ativo'
                        : 'Serviço de acessibilidade desativado',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'O Android não deixa uma aplicação normal abrir as notificações, '
              'as recentes ou bloquear o ecrã. O Lume usa um serviço de '
              'acessibilidade só para executar essas três ações — não lê nem '
              'guarda o conteúdo do ecrã.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: onOpenSettings,
                child: Text(enabled ? 'Abrir definições do Android' : 'Ativar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
