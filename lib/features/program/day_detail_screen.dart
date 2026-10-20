import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/elapsed_time.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/ledger.dart';
import '../../data/models/program_model.dart';
import '../../services/daily_workout_alarm_service.dart';
import '../../services/flux_widget_service.dart';
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
  static const _fallbackTargetSeconds = 45 * 60;
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
        '${state.currentBlockIndex}:${state.currentExerciseIndex}:$currentSet:$nextExercise:${state.startTime!.millisecondsSinceEpoch}';
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
          isPaused: workoutState.isPaused,
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

    final dayWeek = programAsync.whenOrNull(
      data: (program) => _findDay(program),
    );

    return Scaffold(
      appBar: AppBar(
        title: dayWeek == null
            ? null
            : Text(
                'Week ${dayWeek.$1.number} · Day ${dayWeek.$2.order}',
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(color: context.colors.textSecondary),
              ),
      ),
      body: programAsync.when(
        data: (program) {
          final (week, day) = _findDay(program);

          if (isActive) {
            _syncLockScreenNotification(workoutState, day);
          }

          final elapsedSeconds = workoutState.startTime == null || !isActive
              ? 0
              : elapsedSecondsSince(
                  workoutState.startTime!,
                  now: workoutState.pausedAt,
                );

          final activeExerciseStates = isActive
              ? _buildActiveExerciseStates(workoutState, workoutNotifier, day)
              : null;

          final estimatedSeconds = estimateWorkoutMinutes(day) * 60;
          final targetSeconds = estimatedSeconds > 0
              ? estimatedSeconds
              : _fallbackTargetSeconds;
          final (setsDone, setsTotal) = _setProgress(workoutState, day);

          return Column(
            children: [
              if (isActive)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                  child: _SessionPanel(
                    elapsed: _formatElapsed(elapsedSeconds),
                    target: _formatElapsed(targetSeconds),
                    isPaused: workoutState.isPaused,
                    setsDone: setsDone,
                    setsTotal: setsTotal,
                    nowLabel: _lockScreenSetLabel(workoutState, day),
                    onTogglePause: workoutState.isPaused
                        ? workoutNotifier.resume
                        : workoutNotifier.pause,
                  ),
                ),
              Expanded(
                // Not a lazy ListView: exercise tiles hold their typed
                // weight/reps, which must survive scrolling out of view.
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        day.name,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        week.title,
                        style: Theme.of(context).textTheme.bodyMedium
                            ?.copyWith(color: context.colors.textSecondary),
                      ),
                      const SizedBox(height: 16),

                      if (!isActive) ...[
                        _OverviewStrip(day: day),
                        const SizedBox(height: 12),
                      ],

                      if (day.reviewNote != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: context.colors.warningContainer,
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.warning_amber_rounded,
                                color: context.colors.warning,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  day.reviewNote!,
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(color: context.colors.warning),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],

                      IgnorePointer(
                        ignoring: workoutState.isPaused,
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 220),
                          opacity: workoutState.isPaused ? 0.45 : 1,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              for (final entry in day.blocks.asMap().entries)
                                BlockCard(
                                  block: entry.value,
                                  blockIndex: entry.key,
                                  activeExerciseStates: activeExerciseStates,
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              if (isActive && workoutState.isResting)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: RestTimerWidget(
                    initialSeconds: workoutState.restSeconds,
                    paused: workoutState.isPaused,
                    onComplete: () => workoutNotifier.dismissRestTimer(),
                    onDismiss: () => workoutNotifier.dismissRestTimer(),
                  ),
                ),

              Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                decoration: BoxDecoration(
                  color: context.colors.card,
                  border: Border(top: BorderSide(color: context.colors.border)),
                ),
                child: SafeArea(
                  top: false,
                  child: SizedBox(
                    width: double.infinity,
                    child: isActive
                        ? ElevatedButton.icon(
                            icon: const Icon(Icons.flag_outlined, size: 18),
                            label: const Text('Finish workout'),
                            onPressed: () async {
                              await _alarmService.stopWorkoutTimer();
                              await workoutNotifier.finishWorkout();
                              ref.invalidate(completedWorkoutSessionsProvider);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Workout saved. Nice work.'),
                                  ),
                                );
                              }
                            },
                          )
                        : ElevatedButton.icon(
                            icon: const Icon(Icons.play_arrow_rounded),
                            label: Text('Start ${day.name} Workout'),
                            onPressed: () {
                              workoutNotifier.initDay(
                                day,
                                weekId: week.id,
                                programId: widget.programId,
                              );
                            },
                          ),
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) =>
            Center(child: Text('Error loading day detail: $err')),
      ),
    );
  }

  (WeekModel, DayModel) _findDay(ProgramModel program) {
    final week = program.weeks.firstWhere(
      (candidate) =>
          candidate.days.any((candidateDay) => candidateDay.id == widget.dayId),
      orElse: () => program.weeks.first,
    );
    final day = week.days.firstWhere(
      (d) => d.id == widget.dayId,
      orElse: () => week.days.first,
    );
    return (week, day);
  }

  /// Sets logged against sets planned; a rest-pause target counts as one.
  (int, int) _setProgress(ActiveWorkoutState state, DayModel day) {
    var done = 0;
    var total = 0;
    for (final block in day.blocks) {
      for (final exercise in block.exercises) {
        if (exercise.logMode == 'cumulative') {
          total++;
          final reps = (state.restPauseChunks[exercise.id] ?? const <int>[])
              .fold(0, (sum, v) => sum + v);
          if (reps >= (exercise.repTarget ?? 100)) done++;
        } else {
          total += exercise.targetSets;
          done += (state.loggedSets[exercise.id]?.length ?? 0).clamp(
            0,
            exercise.targetSets,
          );
        }
      }
    }
    return (done, total);
  }
}

/// Pinned above the plan while a workout runs: the clock, pause, and how far
/// through the day's sets the user is.
class _SessionPanel extends StatelessWidget {
  final String elapsed;
  final String target;
  final bool isPaused;
  final int setsDone;
  final int setsTotal;
  final String nowLabel;
  final VoidCallback onTogglePause;

  const _SessionPanel({
    required this.elapsed,
    required this.target,
    required this.isPaused,
    required this.setsDone,
    required this.setsTotal,
    required this.nowLabel,
    required this.onTogglePause,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final muted = textTheme.bodySmall?.copyWith(color: colors.textSecondary);
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(isPaused ? 'Paused' : 'Elapsed', style: muted),
                        const SizedBox(width: 8),
                        if (isPaused)
                          StatusBadge(
                            'On hold',
                            foreground: colors.warning,
                            background: colors.warningContainer,
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      elapsed,
                      style: AppText.metricHero.copyWith(
                        color: isPaused ? colors.textSecondary : null,
                      ),
                    ),
                    Text('Target $target', style: muted),
                  ],
                ),
              ),
              RoundIconButton(
                tooltip: isPaused ? 'Resume workout' : 'Pause workout',
                icon: isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                filled: isPaused,
                onPressed: onTogglePause,
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: TweenAnimationBuilder<double>(
              tween: Tween(end: setsTotal == 0 ? 0 : setsDone / setsTotal),
              duration: const Duration(milliseconds: 250),
              builder: (context, value, _) =>
                  LinearProgressIndicator(value: value, minHeight: 6),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                '$setsDone of $setsTotal sets',
                style: AppText.metricTable.copyWith(fontSize: 12),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  nowLabel,
                  textAlign: TextAlign.end,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: muted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// The pre-start summary: what the session asks of the user.
class _OverviewStrip extends StatelessWidget {
  final DayModel day;

  const _OverviewStrip({required this.day});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final exercises = day.blocks.fold<int>(
      0,
      (total, block) => total + block.exercises.length,
    );
    final sets = day.blocks.fold<int>(
      0,
      (total, block) =>
          total + block.exercises.fold<int>(0, (sum, e) => sum + e.targetSets),
    );
    final minutes = estimateWorkoutMinutes(day);
    final items = [
      ('Exercises', '$exercises'),
      ('Sets', '$sets'),
      ('Est. time', '${minutes}m'),
      ('Blocks', '${day.blocks.length}'),
    ];
    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
      child: IntrinsicHeight(
        child: Row(
          children: [
            for (var i = 0; i < items.length; i++) ...[
              if (i > 0) VerticalDivider(width: 1, color: colors.border),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      items[i].$1,
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(color: colors.textSecondary),
                    ),
                    const SizedBox(height: 4),
                    Text(items[i].$2, style: AppText.metricCard),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
