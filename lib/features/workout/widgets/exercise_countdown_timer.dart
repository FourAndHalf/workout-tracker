import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';

/// Countdown for a duration-based exercise (e.g. a 60 s hold). Reaching 00:00
/// logs the full target; "Log early" logs the time actually held. While
/// [paused] (the whole workout is paused) the countdown freezes.
class ExerciseCountdownTimer extends StatefulWidget {
  final int targetSeconds;
  final bool paused;
  final void Function(int elapsedSeconds) onLog;

  const ExerciseCountdownTimer({
    super.key,
    required this.targetSeconds,
    required this.onLog,
    this.paused = false,
  });

  @override
  State<ExerciseCountdownTimer> createState() => _ExerciseCountdownTimerState();
}

class _ExerciseCountdownTimerState extends State<ExerciseCountdownTimer> {
  int _elapsed = 0;
  bool _running = false;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _start() {
    _timer?.cancel();
    setState(() => _running = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (widget.paused) return;
      setState(() => _elapsed++);
      if (_elapsed >= widget.targetSeconds) _log(widget.targetSeconds);
    });
  }

  void _pause() {
    _timer?.cancel();
    setState(() => _running = false);
  }

  void _reset() {
    _timer?.cancel();
    setState(() {
      _running = false;
      _elapsed = 0;
    });
  }

  void _log(int seconds) {
    final isComplete = seconds >= widget.targetSeconds;
    _reset();
    if (isComplete) HapticFeedback.heavyImpact();
    widget.onLog(seconds);
  }

  String _clock(int seconds) {
    final mins = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return '$mins:$secs';
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final remaining = (widget.targetSeconds - _elapsed).clamp(
      0,
      widget.targetSeconds,
    );
    final progress = widget.targetSeconds > 0
        ? _elapsed / widget.targetSeconds
        : 0.0;
    final started = _elapsed > 0;

    return Column(
      children: [
        Row(
          children: [
            SizedBox(
              width: 72,
              height: 72,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox.expand(
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 5,
                      backgroundColor: colors.border,
                      valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
                    ),
                  ),
                  Text(
                    _clock(remaining),
                    key: const Key('countdownReadout'),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: colors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  ElevatedButton.icon(
                    icon: Icon(
                      _running
                          ? Icons.pause_outlined
                          : Icons.play_arrow_outlined,
                    ),
                    label: Text(
                      _running ? 'Pause' : (started ? 'Resume' : 'Start'),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    onPressed: widget.paused
                        ? null
                        : (_running ? _pause : _start),
                  ),
                  TextButton(
                    onPressed: started ? _reset : null,
                    child: const Text('Reset'),
                  ),
                  TextButton(
                    onPressed: started && !widget.paused
                        ? () => _log(_elapsed)
                        : null,
                    child: const Text('Log early'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
