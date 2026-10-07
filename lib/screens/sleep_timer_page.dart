import 'dart:async';

import 'package:flutter/material.dart';

import '../data/sleep_data.dart';
import '../widgets/timer_dial.dart';

class SleepTimerPage extends StatefulWidget {
  const SleepTimerPage({super.key, required this.question});

  final String question;

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
      helpText: isStart ? 'Hora de inicio' : 'Hora de finalización',
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
    return '${time.hour.toString().padLeft(2, '0')}:'
        '${time.minute.toString().padLeft(2, '0')}';
  }

  String _formatTimeOfDay(TimeOfDay time) =>
      '${time.hour.toString().padLeft(2, '0')}:'
      '${time.minute.toString().padLeft(2, '0')}';

  void _saveEntry() {
    final minutes = _manualMode ? _manualMinutes : _elapsed.inMinutes;
    if (_manualMode && _manualStart == _manualEnd) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La hora de inicio y fin no pueden ser iguales.'),
        ),
      );
      return;
    }
    if (minutes <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registra al menos un minuto.')),
      );
      return;
    }
    Navigator.of(context).pop(
      SleepEntry(
        question: widget.question,
        minutes: minutes,
        startTime: _manualMode
            ? _formatTimeOfDay(_manualStart)
            : _formatClockTime(_startTime),
        endTime: _manualMode
            ? _formatTimeOfDay(_manualEnd)
            : _formatClockTime(_endTime),
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
    return Scaffold(
      appBar: AppBar(title: const Text('Registrar tiempo')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            widget.question,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 20),
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(
                value: false,
                icon: Icon(Icons.timer_outlined),
                label: Text('Temporizador'),
              ),
              ButtonSegment(
                value: true,
                icon: Icon(Icons.edit_calendar_outlined),
                label: Text('Manual'),
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
              label: Text('Inicio: ${_formatTimeOfDay(_manualStart)}'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => _chooseManualTime(isStart: false),
              icon: const Icon(Icons.stop),
              label: Text('Fin: ${_formatTimeOfDay(_manualEnd)}'),
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
                  label: const Text('Iniciar'),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: _running ? _stopTimer : null,
                  icon: const Icon(Icons.stop),
                  label: const Text('Terminar'),
                ),
              ],
            ),
            if (_timerStopped) ...[
              const SizedBox(height: 12),
              Text(
                'Inicio ${_formatClockTime(_startTime)} · '
                'fin ${_formatClockTime(_endTime)}',
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 12),
          ],
          Center(
            child: Text(
              _manualMode
                  ? 'Duración: ${duration.inHours} h '
                        '${duration.inMinutes.remainder(60).toString().padLeft(2, '0')} min'
                  : 'Duración: ${_formatDuration(duration)}',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 28),
          FilledButton.icon(
            onPressed: _manualMode || _timerStopped ? _saveEntry : null,
            icon: const Icon(Icons.save_outlined),
            label: const Text('Guardar tiempo'),
          ),
        ],
      ),
    );
  }
}
