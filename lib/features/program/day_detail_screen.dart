import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/elapsed_time.dart';
import '../../data/models/program_model.dart';
import '../../services/daily_workout_alarm_service.dart';
import '../../main.dart';
import '../workout/providers/active_workout_provider.dart';
import '../workout/widgets/rest_timer_widget.dart';
import 'program_providers.dart';
import 'widgets/block_card.dart';
import 'widgets/exercise_tile.dart';

class DayDetailScreen extends ConsumerStatefulWidget {
  final String programId;
  final String dayId;

  const DayDetailScreen({
    super.key,
    required this.programId,
    required this.dayId,
  });

  @override
  ConsumerState<DayDetailScreen> createState() => _DayDetailScreenState();
}

class _DayDetailScreenState extends ConsumerState<DayDetailScreen>
    with WidgetsBindingObserver {
  static const _targetSeconds = 45 * 60;
  Timer? _elapsedTimer;
  bool _wasActive = false;
  String? _lastLockScreenState;
  late final DailyWorkoutAlarmService _alarmService;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _alarmService = ref.read(dailyWorkoutAlarmServiceProvider);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) setState(() {});
  }

  void _syncActiveTracking(bool isActive) {
    if (isActive == _wasActive) return;
    _wasActive = isActive;

    if (isActive) {
      _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (t) {
        if (mounted) setState(() {});
      });
      if (!kIsWeb &&
          (defaultTargetPlatform == TargetPlatform.android ||
              defaultTargetPlatform == TargetPlatform.iOS)) {
        WakelockPlus.enable();
      }
    } else {
      _elapsedTimer?.cancel();
      _elapsedTimer = null;
      _lastLockScreenState = null;
      if (!kIsWeb &&
          (defaultTargetPlatform == TargetPlatform.android ||
              defaultTargetPlatform == TargetPlatform.iOS)) {
        WakelockPlus.disable();
      }
      _alarmService.setActiveWorkoutActionHandler(null);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _elapsedTimer?.cancel();
    if (_wasActive) {
      if (!kIsWeb &&
          (defaultTargetPlatform == TargetPlatform.android ||
              defaultTargetPlatform == TargetPlatform.iOS)) {
        WakelockPlus.disable();
      }
      _alarmService.setActiveWorkoutActionHandler(null);
    }
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

  Map<String, ActiveExerciseLogState> _buildActiveExerciseStates(
    ActiveWorkoutState workoutState,
    ActiveWorkoutNotifier notifier,
    DayModel day,
  ) {
    final states = <String, ActiveExerciseLogState>{};
    for (final block in day.blocks) {
      for (final exercise in block.exercises) {
        final loggedSets = workoutState.loggedSets[exercise.id] ?? [];
        final chunks = workoutState.restPauseChunks[exercise.id] ?? [];
        states[exercise.id] = ActiveExerciseLogState(
          currentSetNumber: loggedSets.length + 1,
          loggedSets: loggedSets,
          restPauseChunks: chunks,
          onLogSet: ({weight, reps, hitFailure = false, durationSeconds}) {
            notifier.logSet(
              exercise: exercise,
              block: block,
              weight: weight,
              reps: reps,
              hitFailure: hitFailure,
              durationSeconds: durationSeconds,
            );
          },
          onAddChunk: (chunkReps) {
            notifier.addRestPauseChunk(
              exercise: exercise,
              block: block,
              chunkReps: chunkReps,
            );
          },
        );
      }
    }
    return states;
  }

  @override
  Widget build(BuildContext context) {
    final programAsync = ref.watch(currentProgramProvider);
    final workoutState = ref.watch(activeWorkoutProvider(widget.dayId));
    final workoutNotifier = ref.read(
      activeWorkoutProvider(widget.dayId).notifier,
    );
    final isActive = workoutState.sessionId != null;
    _syncActiveTracking(isActive);

    return Scaffold(
      appBar: AppBar(title: Text(widget.dayId.toUpperCase())),
      body: programAsync.when(
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

          if (isActive) {
            _syncLockScreenNotification(workoutState, day);
          }

          final elapsedSeconds = workoutState.startTime == null || !isActive
              ? 0
              : elapsedSecondsSince(workoutState.startTime!);

          final activeExerciseStates = isActive
              ? _buildActiveExerciseStates(workoutState, workoutNotifier, day)
              : null;

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              day.name,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: context.colors.primary,
                              ),
                            ),
                          ),
                          isActive
                              ? Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      'Elapsed: ${_formatElapsed(elapsedSeconds)}',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: context.colors.primary,
                                      ),
                                    ),
                                    Text(
                                      'Target: 45:00',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: context.colors.textMuted,
                                      ),
                                    ),
                                  ],
                                )
                              : Text(
                                  '${day.blocks.length} Blocks',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: context.colors.textSecondary,
                                  ),
                                ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      if (isActive) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: LinearProgressIndicator(
                            value: (elapsedSeconds / _targetSeconds).clamp(
                              0.0,
                              1.0,
                            ),
                            minHeight: 3,
                            backgroundColor: context.colors.border,
                            color: context.colors.primary,
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      if (day.reviewNote != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: context.colors.warning.withValues(
                              alpha: 0.1,
                            ),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: context.colors.warning,
                              width: 0.5,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.warning_amber_rounded,
                                color: context.colors.warning,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  day.reviewNote!,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: context.colors.warning,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      ...day.blocks.asMap().entries.map((entry) {
                        return BlockCard(
                          block: entry.value,
                          blockIndex: entry.key,
                          activeExerciseStates: activeExerciseStates,
                        );
                      }),
                    ],
                  ),
                ),
              ),

              if (isActive && workoutState.isResting)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: RestTimerWidget(
                    initialSeconds: workoutState.restSeconds,
                    onComplete: () => workoutNotifier.dismissRestTimer(),
                    onDismiss: () => workoutNotifier.dismissRestTimer(),
                  ),
                ),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: context.colors.surface,
                  border: Border(top: BorderSide(color: context.colors.border)),
                ),
                child: SafeArea(
                  child: SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: isActive
                        ? ElevatedButton.icon(
                            icon: const Icon(Icons.check_circle_outline),
                            label: const Text(
                              'FINISH',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            onPressed: () async {
                              await _alarmService.stopWorkoutTimer();
                              await workoutNotifier.finishWorkout();
                              ref.invalidate(completedWorkoutSessionsProvider);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Workout Session Completed! 🎉',
                                    ),
                                  ),
                                );
                              }
                            },
                          )
                        : ElevatedButton.icon(
                            icon: const Icon(Icons.play_arrow_rounded),
                            label: Text(
                              'Start ${day.name} Workout',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            onPressed: () {
                              workoutNotifier.initDay(day, weekId: week.id);
                            },
                          ),
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => Center(
          child: CircularProgressIndicator(color: context.colors.primary),
        ),
        error: (err, stack) =>
            Center(child: Text('Error loading day detail: $err')),
      ),
    );
  }
}
