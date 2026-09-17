import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/elapsed_time.dart';
import '../providers/active_workout_session_notifier.dart';

class ActiveWorkoutBanner extends ConsumerStatefulWidget {
  const ActiveWorkoutBanner({super.key});

  @override
  ConsumerState<ActiveWorkoutBanner> createState() => _ActiveWorkoutBannerState();
}

class _ActiveWorkoutBannerState extends ConsumerState<ActiveWorkoutBanner>
    with WidgetsBindingObserver {
  Timer? _tickTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  // Ticks only trigger a rebuild; the displayed value is always recomputed
  // from wall-clock time in build(), matching ActiveWorkoutScreen's timer.
  // Only runs while a session is active, so there's no background timer
  // (or leaked one between tests) when the banner has nothing to show.
  void _syncTicker(bool active) {
    if (active && _tickTimer == null) {
      _tickTimer = Timer.periodic(const Duration(seconds: 1), (t) {
        if (mounted) setState(() {});
      });
    } else if (!active && _tickTimer != null) {
      _tickTimer!.cancel();
      _tickTimer = null;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) setState(() {});
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tickTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final info = ref.watch(activeWorkoutSessionProvider);
    _syncTicker(info != null);
    if (info == null) return const SizedBox.shrink();

    final elapsed = elapsedSecondsSince(info.startTime);
    final mm = (elapsed ~/ 60).toString().padLeft(2, '0');
    final ss = (elapsed % 60).toString().padLeft(2, '0');

    return Material(
      color: AppColors.primary,
      child: InkWell(
        onTap: () => context.push('/workout/${info.dayId}'),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                const Icon(
                  Icons.fitness_center_rounded,
                  size: 18,
                  color: AppColors.background,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${info.dayName} in progress · $mm:$ss',
                    style: const TextStyle(
                      color: AppColors.background,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Text(
                  'TAP TO RETURN',
                  style: TextStyle(
                    color: AppColors.background,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(width: 2),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: AppColors.background,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
