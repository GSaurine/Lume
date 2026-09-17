import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/launcher_constants.dart';
import '../../../core/constants/launcher_symbols.dart';
import '../../../core/theme/launcher_palette.dart';
import '../../../data/models/installed_app.dart';
import '../../../data/models/launcher_settings.dart';
import '../../settings/controller/settings_controller.dart';
import '../controller/apps_controller.dart';

/// O que aparece à esquerda do nome de uma aplicação.
///
/// Segue a definição escolhida: um símbolo do Lume, o ícone real da aplicação,
/// ou nada. A escolha do símbolo tem três níveis, do mais forte ao mais fraco:
/// o que o utilizador escolheu, o que o [SymbolGuesser] adivinhou, e um
/// círculo neutro se nada bater certo.
class AppIcon extends ConsumerWidget {
  const AppIcon({
    required this.app,
    this.size = LauncherMetrics.iconSize,
    this.style,
    super.key,
  });

  final InstalledApp app;
  final double size;

  /// Força um estilo em vez de usar o das definições. Usado nos ecrãs de
  /// gestão, onde faz sentido mostrar sempre alguma coisa.
  final IconStyle? style;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final IconStyle effective =
        style ?? ref.watch(settingsProvider.select((s) => s.iconStyle));

    return switch (effective) {
      IconStyle.none => const SizedBox.shrink(),
      IconStyle.symbols => _SymbolIcon(app: app, size: size),
      IconStyle.appIcons => _PlatformIcon(packageName: app.packageName, size: size),
    };
  }
}

class _SymbolIcon extends ConsumerWidget {
  const _SymbolIcon({required this.app, required this.size});

  final InstalledApp app;
  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final LauncherSymbol symbol = ref.watch(appSymbolProvider(app));
    return SizedBox(
      width: size,
      height: size,
      child: Icon(
        symbol.icon,
        size: size * 0.82,
        color: context.palette.secondaryText,
        shadows: context.palette.textShadows,
      ),
    );
  }
}

/// Ícone real da aplicação, carregado sob demanda.
///
/// Enquanto o Android não responde mostramos um espaço reservado do tamanho
/// final — assim a lista nunca "salta" quando os ícones chegam (FASE 10).
class _PlatformIcon extends ConsumerWidget {
  const _PlatformIcon({required this.packageName, required this.size});

  final String packageName;
  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<Uint8List?> icon = ref.watch(appIconProvider(packageName));

    return SizedBox(
      width: size,
      height: size,
      child: switch (icon) {
        AsyncData<Uint8List?>(:final Uint8List? value) when value != null => Image.memory(
            value,
            width: size,
            height: size,
            gaplessPlayback: true,
            errorBuilder: (BuildContext context, Object error, StackTrace? stack) =>
                _Placeholder(size: size),
          ),
        _ => _Placeholder(size: size),
      },
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.palette.panelBorder,
        borderRadius: BorderRadius.circular(size * 0.25),
      ),
      child: SizedBox.square(dimension: size),
    );
  }
}
