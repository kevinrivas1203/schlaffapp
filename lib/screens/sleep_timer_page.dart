import 'dart:async';

import 'package:flutter/material.dart';

import '../widgets/timer_dial.dart';

class SleepTimerPage extends StatefulWidget {
  final String question;

  const SleepTimerPage({super.key, required this.question});

  @override
  State<SleepTimerPage> createState() => _SleepTimerPageState();
}

class _SleepTimerPageState extends State<SleepTimerPage> {
  DateTime? _startTime;
  DateTime? _endTime;
  Duration _elapsed = Duration.zero;
  Timer? _timer;
  bool _running = false;

  void _startTimer() {
    if (_running) return;
    _startTime = DateTime.now();
    _endTime = null;
    _elapsed = Duration.zero;
    _running = true;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        _elapsed = DateTime.now().difference(_startTime!);
      });
    });
    setState(() {});
  }

  void _stopTimer() {
    if (!_running || _startTime == null) return;
    _endTime = DateTime.now();
    _running = false;
    _timer?.cancel();
    _elapsed = _endTime!.difference(_startTime!);
    setState(() {});
  }

  String _formatDuration(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    final hours = two(d.inHours);
    final minutes = two(d.inMinutes.remainder(60));
    final seconds = two(d.inSeconds.remainder(60));
    return '$hours:$minutes:$seconds';
  }

  String _formatClockTime(DateTime? time) {
    if (time == null) return '-';
    final hour = time.toLocal().hour.toString().padLeft(2, '0');
    final minute = time.toLocal().minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.question)),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
        child: Column(
          children: [
            const SizedBox(height: 8),
            TimerDial(elapsed: _elapsed, running: _running),
            const SizedBox(height: 28),
            Text(
              widget.question,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: _startTimer,
                  child: const Text('Starten'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _stopTimer,
                  child: const Text('Beenden'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text('Start: ${_formatClockTime(_startTime)}'),
            const SizedBox(height: 8),
            Text('Beendet: ${_formatClockTime(_endTime)}'),
            const SizedBox(height: 12),
            Text(
              'Dauer: ${_formatDuration(_elapsed)}',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ],
        ),
      ),
    );
  }
}
