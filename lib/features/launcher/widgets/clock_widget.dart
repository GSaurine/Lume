import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/launcher_palette.dart';
import '../../settings/controller/settings_controller.dart';

/// Relógio da Home.
///
/// Acorda uma vez por minuto — e exatamente no início do minuto seguinte,
/// não de 60 em 60 segundos a partir do arranque. Um timer por segundo num
/// ecrã sempre visível é desperdício puro de bateria (FASE 10).
class ClockWidget extends ConsumerStatefulWidget {
  const ClockWidget({super.key});

  @override
  ConsumerState<ClockWidget> createState() => _ClockWidgetState();
}

class _ClockWidgetState extends ConsumerState<ClockWidget> with WidgetsBindingObserver {
  Timer? _timer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scheduleNextTick();
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Voltar ao Home depois de horas noutro app tem de mostrar a hora certa.
    if (state == AppLifecycleState.resumed) _tick();
  }

  void _scheduleNextTick() {
    final DateTime now = DateTime.now();
    final DateTime nextMinute = DateTime(now.year, now.month, now.day, now.hour, now.minute)
        .add(const Duration(minutes: 1));
    _timer?.cancel();
    _timer = Timer(nextMinute.difference(now), _tick);
  }

  void _tick() {
    if (!mounted) return;
    setState(() => _now = DateTime.now());
    _scheduleNextTick();
  }

  @override
  Widget build(BuildContext context) {
    final bool use24h = ref.watch(settingsProvider.select((s) => s.use24HourClock));
    final String locale = Localizations.localeOf(context).toLanguageTag();
    final DateFormat format = use24h ? DateFormat.Hm(locale) : DateFormat.jm(locale);

    return Text(
      format.format(_now),
      style: Theme.of(context).textTheme.displayLarge.onWallpaper(context),
      semanticsLabel: 'São ${format.format(_now)}',
    );
  }
}
