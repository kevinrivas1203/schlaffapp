import 'package:flutter/material.dart';

class TimerDial extends StatelessWidget {
  final Duration elapsed;
  final bool running;

  const TimerDial({
    super.key,
    required this.elapsed,
    this.running = false,
  });

  String _formatDuration(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    final hours = two(d.inHours);
    final minutes = two(d.inMinutes.remainder(60));
    final seconds = two(d.inSeconds.remainder(60));
    return '$hours:$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 220,
        height: 220,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFF373A45),
          border: Border.all(
            color: const Color(0xFF89E7AF),
            width: 8,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 10,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _formatDuration(elapsed),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 42,
                fontWeight: FontWeight.w400,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            Icon(
              running ? Icons.pause : Icons.play_arrow_rounded,
              color: Colors.white70,
              size: 30,
            ),
          ],
        ),
      ),
    );
  }
}
