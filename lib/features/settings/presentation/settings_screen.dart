import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/launcher_palette.dart';
import '../../../core/utils/launcher_route.dart';
import '../../../data/models/launcher_settings.dart';
import '../controller/settings_controller.dart';
import 'about_screen.dart';
import 'appearance_settings_screen.dart';
import 'apps_settings_screen.dart';
import 'gestures_settings_screen.dart';
import 'search_settings_screen.dart';


/// FASE 8 — Definições (plano, secção 16).
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final MotionStyle style =
        ref.watch(settingsProvider.select((s) => s.animations));

    void open(Widget screen) {
      Navigator.of(context).push(LauncherRoute.fromRight<void>(screen, style: style));
    }

    return Scaffold(
      backgroundColor: context.palette.panel,
      appBar: AppBar(
        title: const Text('Definições'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.of(context).maybePop(),
          tooltip: 'Fechar',
        ),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          children: <Widget>[
            _SettingsEntry(
              icon: Icons.palette_outlined,
              title: 'Aparência',
              subtitle: 'Tema, cor, alinhamento, opacidade, wallpaper',
              onTap: () => open(const AppearanceSettingsScreen()),
            ),
            _SettingsEntry(
              icon: Icons.swipe_outlined,
              title: 'Gestos',
              subtitle: 'O que cada deslize faz',
              onTap: () => open(const GesturesSettingsScreen()),
            ),
            _SettingsEntry(
              icon: Icons.search_rounded,
              title: 'Pesquisa',
              subtitle: 'Teclado automático, packages, atalhos',
              onTap: () => open(const SearchSettingsScreen()),
            ),
            _SettingsEntry(
              icon: Icons.apps_rounded,
              title: 'Aplicações',
              subtitle: 'Apps do sistema, ocultas e nomes personalizados',
              onTap: () => open(const AppsSettingsScreen()),
            ),
            _SettingsEntry(
              icon: Icons.info_outline_rounded,
              title: 'Sobre',
              subtitle: 'Versão, privacidade, repor definições',
              onTap: () => open(const AboutScreen()),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsEntry extends StatelessWidget {
  const _SettingsEntry({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: Icon(Icons.chevron_right_rounded, color: context.palette.tertiaryText),
      onTap: onTap,
    );
  }
}

/// Cabeçalho de grupo reutilizado pelos sub-ecrãs de definições.
class SettingsSectionTitle extends StatelessWidget {
  const SettingsSectionTitle(this.title, {super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: context.palette.accent,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
      ),
    );
  }
}
