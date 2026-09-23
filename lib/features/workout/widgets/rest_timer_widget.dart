import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class RestTimerWidget extends StatefulWidget {
  final int initialSeconds;
  final VoidCallback onComplete;
  final VoidCallback onDismiss;

  const RestTimerWidget({
    super.key,
    required this.initialSeconds,
    required this.onComplete,
    required this.onDismiss,
  });

  @override
  State<RestTimerWidget> createState() => _RestTimerWidgetState();
}

class _RestTimerWidgetState extends State<RestTimerWidget> {
  late int _secondsRemaining;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _secondsRemaining = widget.initialSeconds;
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 1) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        _timer?.cancel();
        setState(() {
          _secondsRemaining = 0;
        });
        widget.onComplete();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _addSeconds(int seconds) {
    setState(() {
      _secondsRemaining += seconds;
    });
  }

  @override
  Widget build(BuildContext context) {
    final progress = widget.initialSeconds > 0 ? _secondsRemaining / widget.initialSeconds : 0.0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.colors.primary, width: 1.5),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 36,
            height: 36,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 3.5,
                  backgroundColor: context.colors.border,
                  valueColor: AlwaysStoppedAnimation<Color>(context.colors.primary),
                ),
                Text(
                  '$_secondsRemaining',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: context.colors.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'REST TIMER',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: context.colors.primary,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  _secondsRemaining > 0 ? 'Resting... $_secondsRemaining s' : 'Rest Complete! Ready for next set.',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: context.colors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => _addSeconds(30),
            child: Text('+30s', style: TextStyle(color: context.colors.secondary, fontSize: 12)),
          ),
          IconButton(
            icon: Icon(Icons.close_rounded, size: 20, color: context.colors.textMuted),
            onPressed: widget.onDismiss,
          ),
        ],
      ),
    );
  }
}
