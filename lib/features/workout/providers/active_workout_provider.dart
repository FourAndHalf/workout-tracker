import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../main.dart';
import '../../home/home_providers.dart';
import '../../program/program_providers.dart';
import '../../../data/models/program_model.dart';
import '../../../data/repositories/workout_repository.dart';
import 'active_workout_session_notifier.dart';

class ActiveWorkoutState {
  final int? sessionId;
  final String dayId;
  final DayModel? dayModel;
  final int currentBlockIndex;
  final int currentExerciseIndex;
  final Map<String, List<Map<String, dynamic>>>
  loggedSets; // exerciseId -> list of logged set maps
  final Map<String, List<int>>
  restPauseChunks; // exerciseId -> list of chunk reps
  final bool isResting;
  final int restSeconds;
  final DateTime? startTime;

  ActiveWorkoutState({
    this.sessionId,
    required this.dayId,
    this.dayModel,
    this.currentBlockIndex = 0,
    this.currentExerciseIndex = 0,
    this.loggedSets = const {},
    this.restPauseChunks = const {},
    this.isResting = false,
    this.restSeconds = 60,
    this.startTime,
  });

  ActiveWorkoutState copyWith({
    int? sessionId,
    String? dayId,
    DayModel? dayModel,
    int? currentBlockIndex,
    int? currentExerciseIndex,
    Map<String, List<Map<String, dynamic>>>? loggedSets,
    Map<String, List<int>>? restPauseChunks,
    bool? isResting,
    int? restSeconds,
    DateTime? startTime,
  }) {
    return ActiveWorkoutState(
      sessionId: sessionId ?? this.sessionId,
      dayId: dayId ?? this.dayId,
      dayModel: dayModel ?? this.dayModel,
      currentBlockIndex: currentBlockIndex ?? this.currentBlockIndex,
      currentExerciseIndex: currentExerciseIndex ?? this.currentExerciseIndex,
      loggedSets: loggedSets ?? this.loggedSets,
      restPauseChunks: restPauseChunks ?? this.restPauseChunks,
      isResting: isResting ?? this.isResting,
      restSeconds: restSeconds ?? this.restSeconds,
      startTime: startTime ?? this.startTime,
    );
  }
}

class ActiveWorkoutNotifier extends StateNotifier<ActiveWorkoutState> {
  final WorkoutRepository _workoutRepo;
  final Ref _ref;

  ActiveWorkoutNotifier(this._workoutRepo, this._ref, String dayId)
    : super(ActiveWorkoutState(dayId: dayId, startTime: DateTime.now()));

  void initDay(DayModel day, {String weekId = 'w1'}) async {
    final sessionId = await _workoutRepo.startSession(
      programId: 'ffts-4week',
      weekId: weekId,
      dayId: day.id,
      dayName: day.name,
    );
    state = state.copyWith(sessionId: sessionId, dayModel: day);
    _ref
        .read(activeWorkoutSessionProvider.notifier)
        .start(
          dayId: state.dayId,
          dayName: day.name,
          startTime: state.startTime!,
        );
  }

  /// Log a set for the current exercise
  Future<void> logSet({
    required ExerciseModel exercise,
    required BlockModel block,
    double? weight,
    int? reps,
    bool hitFailure = false,
    int? durationSeconds,
  }) async {
    if (state.sessionId == null) return;

    final currentSets = state.loggedSets[exercise.id] ?? [];
    final setNumber = currentSets.length + 1;

    final logId = await _workoutRepo.logExerciseSet(
      sessionId: state.sessionId!,
      blockId: block.id,
      exerciseId: exercise.id,
      exerciseName: exercise.name,
      blockType: block.type,
      logMode: exercise.logMode,
      setNumber: setNumber,
      weight: weight,
      reps: reps,
      targetReps: exercise.repTarget,
      hitFailure: hitFailure,
      durationSeconds: durationSeconds,
    );
    _ref.invalidate(dashboardAnalyticsProvider);

    final updatedSets = Map<String, List<Map<String, dynamic>>>.from(
      state.loggedSets,
    );
    final setList = List<Map<String, dynamic>>.from(currentSets);
    setList.add({
      'logId': logId,
      'weight': weight,
      'reps': reps,
      'hitFailure': hitFailure,
      'durationSeconds': durationSeconds,
    });
    updatedSets[exercise.id] = setList;

    // Determine sequence progression (superset vs straight block)
    bool shouldTriggerRest = false;
    int nextExerciseIdx = state.currentExerciseIndex;
    int nextBlockIdx = state.currentBlockIndex;

    if (block.type == 'superset' ||
        block.type == 'triSet' ||
        block.type == 'giantSet') {
      // Compound block: move to next exercise in the set sequence
      if (state.currentExerciseIndex < block.exercises.length - 1) {
        nextExerciseIdx = state.currentExerciseIndex + 1;
      } else {
        // Finished last exercise in compound round → start rest timer
        nextExerciseIdx = 0;
        shouldTriggerRest = true;
      }
    } else {
      // Straight set: trigger rest after each set
      shouldTriggerRest = true;
      if (setList.length >= exercise.targetSets) {
        if (state.currentExerciseIndex < block.exercises.length - 1) {
          nextExerciseIdx = state.currentExerciseIndex + 1;
        } else if (state.currentBlockIndex <
            state.dayModel!.blocks.length - 1) {
          nextBlockIdx = state.currentBlockIndex + 1;
          nextExerciseIdx = 0;
        }
      }
    }

    state = state.copyWith(
      loggedSets: updatedSets,
      currentExerciseIndex: nextExerciseIdx,
      currentBlockIndex: nextBlockIdx,
      isResting: shouldTriggerRest,
      restSeconds: 60,
    );
  }

  Future<void> completeCurrentSetFromLockScreen() async {
    final day = state.dayModel;
    if (day == null || state.sessionId == null || day.blocks.isEmpty) return;

    final block = day.blocks[state.currentBlockIndex];
    if (block.exercises.isEmpty) return;
    final exercise = block.exercises[state.currentExerciseIndex];

    if (exercise.logMode == 'cumulative') {
      await addRestPauseChunk(
        exercise: exercise,
        block: block,
        chunkReps: exercise.repTarget ?? 1,
      );
      return;
    }

    await logSet(
      exercise: exercise,
      block: block,
      reps: exercise.repTarget ?? 1,
    );
  }

  /// Add chunk for rest-pause cumulative mode
  Future<void> addRestPauseChunk({
    required ExerciseModel exercise,
    required BlockModel block,
    required int chunkReps,
  }) async {
    if (state.sessionId == null) return;

    final chunks = List<int>.from(state.restPauseChunks[exercise.id] ?? []);
    chunks.add(chunkReps);

    await _workoutRepo.logExerciseSet(
      sessionId: state.sessionId!,
      blockId: block.id,
      exerciseId: exercise.id,
      exerciseName: exercise.name,
      blockType: block.type,
      logMode: exercise.logMode,
      setNumber: chunks.length,
      reps: chunkReps,
      targetReps: exercise.repTarget,
    );

    final updatedChunks = Map<String, List<int>>.from(state.restPauseChunks);
    updatedChunks[exercise.id] = chunks;

    state = state.copyWith(restPauseChunks: updatedChunks);
  }

  void dismissRestTimer() {
    state = state.copyWith(isResting: false);
  }

  Future<void> finishWorkout({String? notes}) async {
    if (state.sessionId != null) {
      await _workoutRepo.finishSession(state.sessionId!, notes: notes);
      _ref.invalidate(dashboardAnalyticsProvider);
      _ref.invalidate(nextWorkoutDayProvider);
    }
    if (_ref.read(activeWorkoutSessionProvider)?.dayId == state.dayId) {
      _ref.read(activeWorkoutSessionProvider.notifier).clear();
    }
    // Reset to a fresh, inactive state so the day-detail page reverts to
    // its plain preview mode instead of staying "active" forever.
    state = ActiveWorkoutState(dayId: state.dayId, startTime: DateTime.now());
  }
}

final activeWorkoutProvider =
    StateNotifierProvider.family<
      ActiveWorkoutNotifier,
      ActiveWorkoutState,
      String
    >((ref, dayId) {
      final repo = ref.watch(workoutRepositoryProvider);
      return ActiveWorkoutNotifier(repo, ref, dayId);
    });
