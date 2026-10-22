import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons_600.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/ledger.dart';

class RestTimerWidget extends StatefulWidget {
  final int initialSeconds;
  final VoidCallback onComplete;
  final VoidCallback onDismiss;

  /// The workout is paused: the countdown holds still.
  final bool paused;

  const RestTimerWidget({
    super.key,
    required this.initialSeconds,
    required this.onComplete,
    required this.onDismiss,
    this.paused = false,
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
      if (widget.paused) return;
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
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final progress = widget.initialSeconds > 0
        ? _secondsRemaining / widget.initialSeconds
        : 0.0;
    final clock =
        '${_secondsRemaining ~/ 60}:${(_secondsRemaining % 60).toString().padLeft(2, '0')}';

    return AppCard(
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
      child: Row(
        children: [
          GaugeArc(
            value: progress,
            size: 48,
            stroke: 4,
            child: Text(
              '$_secondsRemaining',
              style: AppText.metricDelta.copyWith(color: colors.textPrimary),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Rest',
                  style: textTheme.bodySmall?.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
                Text(
                  _secondsRemaining > 0
                      ? 'Next set in $clock'
                      : 'Ready for the next set',
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(56, 36),
              padding: const EdgeInsets.symmetric(horizontal: 12),
            ),
            onPressed: () => _addSeconds(30),
            child: const Text('+30s'),
          ),
          IconButton(
            tooltip: 'Skip rest',
            icon: Icon(
              LucideIcons600.x,
              size: 20,
              color: colors.textSecondary,
            ),
            onPressed: widget.onDismiss,
          ),
        ],
      ),
    );
  }
}
