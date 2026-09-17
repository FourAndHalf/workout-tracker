import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/elapsed_time.dart';
import '../../data/models/program_model.dart';
import '../../services/daily_workout_alarm_service.dart';
import '../program/program_providers.dart';
import '../../main.dart';
import 'providers/active_workout_provider.dart';
import 'widgets/set_logger_card.dart';
import 'widgets/cumulative_counter.dart';
import 'widgets/rest_timer_widget.dart';

class ActiveWorkoutScreen extends ConsumerStatefulWidget {
  final String dayId;

  const ActiveWorkoutScreen({super.key, required this.dayId});

  @override
  ConsumerState<ActiveWorkoutScreen> createState() =>
      _ActiveWorkoutScreenState();
}

class _ActiveWorkoutScreenState extends ConsumerState<ActiveWorkoutScreen>
    with WidgetsBindingObserver {
  static const _targetSeconds = 45 * 60;
  Timer? _elapsedTimer;
  bool _lockScreenTimerStarted = false;
  String? _lastLockScreenState;
  late final DailyWorkoutAlarmService _alarmService;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _alarmService = ref.read(dailyWorkoutAlarmServiceProvider);
    if (!kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS)) {
      WakelockPlus.enable();
    }
    _startElapsedTimer();
  }

  void _startElapsedTimer() {
    // Ticks only trigger a rebuild — the displayed value is always
    // recomputed from wall-clock time in build(), so missed/delayed ticks
    // while the screen is off don't cause the timer to fall behind.
    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (mounted) setState(() {});
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _elapsedTimer?.cancel();
    if (!kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS)) {
      WakelockPlus.disable();
    }
    _alarmService.setActiveWorkoutActionHandler(null);
    super.dispose();
  }

  String _formatElapsed(int seconds) {
    final mins = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return '$mins:$secs';
  }

  String _lockScreenSetLabel(ActiveWorkoutState state, DayModel day) {
    if (day.blocks.isEmpty) return 'Workout complete';
    final block =
        day.blocks[state.currentBlockIndex.clamp(0, day.blocks.length - 1)];
    if (block.exercises.isEmpty) return 'Workout complete';
    final exercise =
        block.exercises[state.currentExerciseIndex.clamp(
          0,
          block.exercises.length - 1,
        )];
    final logged = state.loggedSets[exercise.id]?.length ?? 0;
    final set = (logged + 1).clamp(1, exercise.targetSets);
    return '${exercise.name}  •  Set $set/${exercise.targetSets}';
  }

  String _nextExerciseName(ActiveWorkoutState state, DayModel day) {
    for (
      var blockIndex = state.currentBlockIndex;
      blockIndex < day.blocks.length;
      blockIndex++
    ) {
      final block = day.blocks[blockIndex];
      final start = blockIndex == state.currentBlockIndex
          ? state.currentExerciseIndex + 1
          : 0;
      if (start < block.exercises.length) return block.exercises[start].name;
    }
    return 'Workout complete';
  }

  void _syncLockScreenNotification(ActiveWorkoutState state, DayModel day) {
    if (state.sessionId == null || state.startTime == null) return;
    final currentSet = _lockScreenSetLabel(state, day);
    final nextExercise = _nextExerciseName(state, day);
    final key =
        '${state.currentBlockIndex}:${state.currentExerciseIndex}:$currentSet:$nextExercise';
    if (_lastLockScreenState == key) return;
    _lastLockScreenState = key;
    _alarmService.setActiveWorkoutActionHandler(() async {
      await ref
          .read(activeWorkoutProvider(widget.dayId).notifier)
          .completeCurrentSetFromLockScreen();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _alarmService.updateWorkoutTimer(
        state.startTime!,
        workoutName: day.name,
        targetEndAt: state.startTime!.add(const Duration(minutes: 45)),
        currentSet: currentSet,
        nextExercise: nextExercise,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final programAsync = ref.watch(currentProgramProvider);
    final workoutState = ref.watch(activeWorkoutProvider(widget.dayId));
    final workoutNotifier = ref.read(
      activeWorkoutProvider(widget.dayId).notifier,
    );

    return programAsync.when(
      data: (program) {
        final week = program.weeks.firstWhere(
          (candidate) => candidate.days.any(
            (candidateDay) => candidateDay.id == widget.dayId,
          ),
          orElse: () => program.weeks.first,
        );
        final day = week.days.firstWhere(
          (d) => d.id == widget.dayId,
          orElse: () => week.days.first,
        );

        if (workoutState.dayModel == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            workoutNotifier.initDay(day, weekId: week.id);
          });
        }
        if (workoutState.sessionId != null &&
            workoutState.startTime != null &&
            !_lockScreenTimerStarted) {
          _lockScreenTimerStarted = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _alarmService.startWorkoutTimer(
              workoutState.startTime!,
              workoutName: day.name,
              targetEndAt: workoutState.startTime!.add(
                const Duration(minutes: 45),
              ),
              currentSet: _lockScreenSetLabel(workoutState, day),
              nextExercise: _nextExerciseName(workoutState, day),
            );
          });
        }
        _syncLockScreenNotification(workoutState, day);

        final elapsedSeconds = workoutState.startTime == null
            ? 0
            : elapsedSecondsSince(workoutState.startTime!);

        return Scaffold(
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  day.name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Elapsed: ${_formatElapsed(elapsedSeconds)}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.primary,
                  ),
                ),
                Text(
                  'Target: 45:00',
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton.icon(
                icon: const Icon(
                  Icons.check_circle_outline,
                  color: AppColors.primary,
                ),
                label: const Text(
                  'FINISH',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onPressed: () async {
                  await ref
                      .read(dailyWorkoutAlarmServiceProvider)
                      .stopWorkoutTimer();
                  await workoutNotifier.finishWorkout();
                  ref.invalidate(completedWorkoutSessionsProvider);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Workout Session Completed! 🎉'),
                      ),
                    );
                    context.go('/');
                  }
                },
              ),
            ],
          ),
          body: Column(
            children: [
              LinearProgressIndicator(
                value: (elapsedSeconds / _targetSeconds).clamp(0.0, 1.0),
                minHeight: 3,
                backgroundColor: AppColors.border,
                color: AppColors.primary,
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: day.blocks.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 16),
                  itemBuilder: (context, blockIndex) {
                    final block = day.blocks[blockIndex];

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ...block.exercises.map((exercise) {
                          if (exercise.logMode == 'cumulative') {
                            final chunks =
                                workoutState.restPauseChunks[exercise.id] ?? [];
                            return CumulativeCounter(
                              targetReps: exercise.repTarget ?? 100,
                              loggedChunks: chunks,
                              onAddChunk: (chunkReps) {
                                workoutNotifier.addRestPauseChunk(
                                  exercise: exercise,
                                  block: block,
                                  chunkReps: chunkReps,
                                );
                              },
                            );
                          } else {
                            final loggedSets =
                                workoutState.loggedSets[exercise.id] ?? [];
                            final currentSetNum = loggedSets.length + 1;

                            return SetLoggerCard(
                              exercise: exercise,
                              currentSetNumber: currentSetNum,
                              loggedSets: loggedSets,
                              onLogSet:
                                  ({
                                    weight,
                                    reps,
                                    hitFailure = false,
                                    durationSeconds,
                                  }) {
                                    workoutNotifier.logSet(
                                      exercise: exercise,
                                      block: block,
                                      weight: weight,
                                      reps: reps,
                                      hitFailure: hitFailure,
                                      durationSeconds: durationSeconds,
                                    );
                                  },
                            );
                          }
                        }),
                      ],
                    );
                  },
                ),
              ),

              if (workoutState.isResting)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: RestTimerWidget(
                    initialSeconds: workoutState.restSeconds,
                    onComplete: () {
                      workoutNotifier.dismissRestTimer();
                    },
                    onDismiss: () {
                      workoutNotifier.dismissRestTimer();
                    },
                  ),
                ),
            ],
          ),
        );
      },
      loading: () => const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      ),
      error: (err, stack) => Scaffold(body: Center(child: Text('Error: $err'))),
    );
  }
}
