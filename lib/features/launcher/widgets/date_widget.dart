import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Data por extenso, por baixo do relógio ("Segunda, 15 Setembro").
///
/// Só se atualiza à meia-noite.
class DateWidget extends StatefulWidget {
  const DateWidget({super.key});

  @override
  State<DateWidget> createState() => _DateWidgetState();
}

class _DateWidgetState extends State<DateWidget> with WidgetsBindingObserver {
  Timer? _timer;
  DateTime _today = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scheduleMidnight();
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
  }

  void _scheduleMidnight() {
    final DateTime now = DateTime.now();
    final DateTime midnight = DateTime(now.year, now.month, now.day + 1);
    _timer?.cancel();
    _timer = Timer(midnight.difference(now), _refresh);
  }

  void _refresh() {
    if (!mounted) return;
    setState(() => _today = DateTime.now());
    _scheduleMidnight();
  }

  @override
  Widget build(BuildContext context) {
    final String locale = Localizations.localeOf(context).toLanguageTag();
    final String weekday = DateFormat.EEEE(locale).format(_today);
    final String day = DateFormat.MMMMd(locale).format(_today);

    return Text(
      '${_capitalize(weekday)}, $day',
      style: Theme.of(context).textTheme.titleMedium,
    );
  }

  static String _capitalize(String value) =>
      value.isEmpty ? value : value[0].toUpperCase() + value.substring(1);
}
