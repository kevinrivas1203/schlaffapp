import 'dart:async';

import 'package:flutter/material.dart';

import '../data/sleep_data.dart';
import '../localization.dart';
import '../widgets/timer_dial.dart';

class SleepTimerPage extends StatefulWidget {
  const SleepTimerPage({
    super.key,
    required this.question,
    this.historyEntries = const [],
    this.historyDate,
  });

  final String question;
  final List<SleepEntry> historyEntries;
  final DateTime? historyDate;

  @override
  State<SleepTimerPage> createState() => _SleepTimerPageState();
}

class _SleepTimerPageState extends State<SleepTimerPage> {
  bool _manualMode = false;
  DateTime? _startTime;
  DateTime? _endTime;
  Duration _elapsed = Duration.zero;
  Timer? _timer;
  bool _running = false;
  bool _timerStopped = false;
  TimeOfDay _manualStart = TimeOfDay.now();
  TimeOfDay _manualEnd = TimeOfDay.now();

  int get _manualMinutes {
    final startMinutes = _manualStart.hour * 60 + _manualStart.minute;
    final endMinutes = _manualEnd.hour * 60 + _manualEnd.minute;
    return durationMinutesForInterval(startMinutes, endMinutes);
  }

  void _startTimer() {
    if (_running) return;
    _startTime = DateTime.now();
    _endTime = null;
    _elapsed = Duration.zero;
    _timerStopped = false;
    _running = true;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _elapsed = DateTime.now().difference(_startTime!));
    });
    setState(() {});
  }

  void _stopTimer() {
    if (!_running || _startTime == null) return;
    _endTime = DateTime.now();
    _running = false;
    _timerStopped = true;
    _timer?.cancel();
    _elapsed = _endTime!.difference(_startTime!);
    setState(() {});
  }

  Future<void> _chooseManualTime({required bool isStart}) async {
    final initial = isStart ? _manualStart : _manualEnd;
    final selected = await showTimePicker(
      context: context,
      initialTime: initial,
      helpText: appText(
        context,
        isStart ? 'Hora de inicio' : 'Hora de finalización',
      ),
      builder: (context, child) {
        final mediaQuery = MediaQuery.of(context);
        return MediaQuery(
          data: mediaQuery.copyWith(alwaysUse24HourFormat: false),
          child: child!,
        );
      },
    );
    if (selected == null) return;
    setState(() {
      if (isStart) {
        _manualStart = selected;
      } else {
        _manualEnd = selected;
      }
    });
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(
      2,
      '0',
    );
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(
      2,
      '0',
    );
    return '$hours:$minutes:$seconds';
  }

  String _formatClockTime(DateTime? time) {
    if (time == null) return '--:--';
    return TimeOfDay.fromDateTime(time).format(context);
  }

  String _formatManualTime(TimeOfDay time) =>
      MaterialLocalizations.of(context).formatTimeOfDay(
        time,
        alwaysUse24HourFormat: false,
      );

  String _storedClockTime(DateTime? time) {
    if (time == null) return '--:--';
    return '${time.hour.toString().padLeft(2, '0')}:'
        '${time.minute.toString().padLeft(2, '0')}';
  }

  String _storedTimeOfDay(TimeOfDay time) =>
      '${time.hour.toString().padLeft(2, '0')}:'
      '${time.minute.toString().padLeft(2, '0')}';

  String _formatHistoryTime(String value) {
    final minutes = parseTimeOfDayMinutes(value);
    if (minutes == null) return value;

    final hour = minutes ~/ 60;
    final minute = minutes % 60;
    final period = switch (AppLanguageScope.of(context)) {
      AppLanguage.spanish => hour < 12 ? 'a. m.' : 'p. m.',
      AppLanguage.portuguese => hour < 12 ? 'AM' : 'PM',
      AppLanguage.german => hour < 12 ? 'AM' : 'PM',
    };
    final hour12 = hour % 12 == 0 ? 12 : hour % 12;
    return '${hour12.toString().padLeft(2, '0')}:'
        '${minute.toString().padLeft(2, '0')} $period';
  }

  String _formatEntryInterval(SleepEntry entry) {
    final start = parseTimeOfDayMinutes(entry.startTime);
    final end = parseTimeOfDayMinutes(entry.endTime);
    final interval =
        '${_formatHistoryTime(entry.startTime)} – '
        '${_formatHistoryTime(entry.endTime)}';
    if (start != null && end != null && end <= start) {
      return '$interval · ${appText(context, 'termina al día siguiente')}';
    }
    return interval;
  }

  String _formatHistoryDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}.'
      '${date.month.toString().padLeft(2, '0')}.'
      '${date.year}';

  void _saveEntry() {
    final minutes = _manualMode ? _manualMinutes : _elapsed.inMinutes;
    if (_manualMode && _manualStart == _manualEnd) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            appText(context, 'La hora de inicio y fin no pueden ser iguales.'),
          ),
        ),
      );
      return;
    }
    if (minutes <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(appText(context, 'Registra al menos un minuto.'))),
      );
      return;
    }
    Navigator.of(context).pop(
      SleepEntry(
        question: widget.question,
        minutes: minutes,
        startTime: _manualMode
            ? _storedTimeOfDay(_manualStart)
            : _storedClockTime(_startTime),
        endTime: _manualMode
            ? _storedTimeOfDay(_manualEnd)
            : _storedClockTime(_endTime),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final duration = _manualMode
        ? Duration(minutes: _manualMinutes)
        : _elapsed;
    final historyEntries = widget.historyEntries.toList()
      ..sort((a, b) {
        final aStart = parseTimeOfDayMinutes(a.startTime) ?? 0;
        final bStart = parseTimeOfDayMinutes(b.startTime) ?? 0;
        return aStart.compareTo(bStart);
      });
    return Scaffold(
      appBar: AppBar(title: Text(appText(context, 'Registrar tiempo'))),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            appText(context, widget.question),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 20),
          SegmentedButton<bool>(
            segments: [
              ButtonSegment(
                value: false,
                icon: Icon(Icons.timer_outlined),
                label: Text(appText(context, 'Temporizador')),
              ),
              ButtonSegment(
                value: true,
                icon: Icon(Icons.edit_calendar_outlined),
                label: Text(appText(context, 'Manual')),
              ),
            ],
            selected: {_manualMode},
            onSelectionChanged: (selection) =>
                setState(() => _manualMode = selection.first),
          ),
          const SizedBox(height: 28),
          if (_manualMode) ...[
            OutlinedButton.icon(
              onPressed: () => _chooseManualTime(isStart: true),
              icon: const Icon(Icons.play_arrow),
              label: Text(
                appText(context, 'Inicio: {time}', {
                  'time': _formatManualTime(_manualStart),
                }),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => _chooseManualTime(isStart: false),
              icon: const Icon(Icons.stop),
              label: Text(
                appText(context, 'Fin: {time}', {
                  'time': _formatManualTime(_manualEnd),
                }),
              ),
            ),
            const SizedBox(height: 24),
          ] else ...[
            Center(child: TimerDial(elapsed: _elapsed, running: _running)),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FilledButton.icon(
                  onPressed: _running ? null : _startTimer,
                  icon: const Icon(Icons.play_arrow),
                  label: Text(appText(context, 'Iniciar')),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: _running ? _stopTimer : null,
                  icon: const Icon(Icons.stop),
                  label: Text(appText(context, 'Terminar')),
                ),
              ],
            ),
            if (_timerStopped) ...[
              const SizedBox(height: 12),
              Text(
                appText(context, 'Inicio {start} · fin {end}', {
                  'start': _formatClockTime(_startTime),
                  'end': _formatClockTime(_endTime),
                }),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 12),
          ],
          Center(
            child: Text(
              _manualMode
                  ? appText(context, 'Duración: {duration}', {
                      'duration': appText(context, '{hours} h {minutes} min', {
                        'hours': '${duration.inHours}',
                        'minutes': duration.inMinutes
                            .remainder(60)
                            .toString()
                            .padLeft(2, '0'),
                      }),
                    })
                  : appText(context, 'Duración: {duration}', {
                      'duration': _formatDuration(duration),
                    }),
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 28),
          FilledButton.icon(
            onPressed: _manualMode || _timerStopped ? _saveEntry : null,
            icon: const Icon(Icons.save_outlined),
            label: Text(appText(context, 'Guardar tiempo')),
          ),
          const SizedBox(height: 24),
          Text(
            appText(context, 'Historial del día ({count})', {
              'count': '${historyEntries.length}',
            }),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          if (widget.historyDate != null) ...[
            const SizedBox(height: 4),
            Text(_formatHistoryDate(widget.historyDate!)),
          ],
          const SizedBox(height: 8),
          if (historyEntries.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                appText(
                  context,
                  'Todavía no hay registros guardados para este día.',
                ),
                textAlign: TextAlign.center,
              ),
            )
          else
            ...historyEntries.map(
              (entry) => Card(
                child: ListTile(
                  leading: const Icon(Icons.history),
                  title: Text(appText(context, entry.question)),
                  subtitle: Text(_formatEntryInterval(entry)),
                  trailing: Text(
                    appText(context, '{hours} h {minutes} min', {
                      'hours': '${entry.minutes ~/ 60}',
                      'minutes': (entry.minutes % 60).toString().padLeft(2, '0'),
                    }),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
