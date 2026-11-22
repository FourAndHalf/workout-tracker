import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../main.dart';
import '../../data/models/program_model.dart';
import '../../data/database/app_database.dart';
import '../../data/repositories/program_repository.dart';
import '../../core/utils/workout_estimate.dart';

const selectedProgramPreferenceKey = 'selected_program_id';

/// Overridden in `main()` with the stored value so the first frame already
/// shows the last-used track.
final initialProgramIdProvider = Provider<String>(
  (ref) => ProgramRepository.defaultProgramId,
);

class SelectedProgramNotifier extends Notifier<String> {
  @override
  String build() => ref.watch(initialProgramIdProvider);

  Future<void> select(String programId) async {
    state = programId;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(selectedProgramPreferenceKey, programId);
  }
}

final selectedProgramIdProvider =
    NotifierProvider<SelectedProgramNotifier, String>(
      SelectedProgramNotifier.new,
    );

final availableProgramsProvider = FutureProvider<List<ProgramModel>>((ref) {
  return ref.watch(programRepositoryProvider).loadBundledPrograms();
});

final currentProgramProvider = FutureProvider<ProgramModel>((ref) async {
  final repo = ref.watch(programRepositoryProvider);
  final programId = ref.watch(selectedProgramIdProvider);
  return repo.loadBundledProgram(programId);
});

final selectedDayIdProvider = StateProvider<String?>((ref) => null);

final completedWorkoutSessionsProvider = FutureProvider<List<WorkoutSession>>((
  ref,
) async {
  final programId = ref.watch(selectedProgramIdProvider);
  final sessions = await ref
      .watch(workoutRepositoryProvider)
      .getCompletedSessions();
  return sessions.where((session) => session.programId == programId).toList();
});

class NextWorkoutInfo {
  final String programId;
  final String dayId;
  final String dayName;
  final int weekNumber;
  final int exerciseCount;
  final int estimatedMinutes;

  const NextWorkoutInfo({
    required this.programId,
    required this.dayId,
    required this.dayName,
    this.weekNumber = 1,
    this.exerciseCount = 0,
    this.estimatedMinutes = 0,
  });
}

/// The next workout day the user hasn't completed yet, so the Home
/// screen's "Start" shortcut always advances instead of always starting
/// week 1 day 1.
final nextWorkoutDayProvider = FutureProvider<NextWorkoutInfo?>((ref) async {
  final program = await ref.watch(currentProgramProvider.future);
  final sessions = await ref.watch(completedWorkoutSessionsProvider.future);
  return nextWorkoutFor(program, sessions);
});

NextWorkoutInfo? nextWorkoutFor(
  ProgramModel program,
  List<WorkoutSession> sessions,
) {
  if (program.weeks.isEmpty) return null;

  final weekIndex = activeWeekIndex(program, sessions);
  final week = program.weeks[weekIndex];
  final trainingDays = week.trainingDays;
  if (trainingDays.isEmpty) return null;

  final completedDayIds = sessions
      .where((session) => session.weekId == week.id)
      .map((session) => session.dayId)
      .toSet();

  final nextDay = trainingDays.firstWhere(
    (day) => !completedDayIds.contains(day.id),
    orElse: () => trainingDays.first,
  );

  return NextWorkoutInfo(
    programId: program.programId,
    dayId: nextDay.id,
    dayName: nextDay.name,
    weekNumber: week.number,
    exerciseCount: nextDay.blocks.fold<int>(
      0,
      (total, block) => total + block.exercises.length,
    ),
    estimatedMinutes: estimateWorkoutMinutes(nextDay),
  );
}

/// The first week with a training day still to do. Rest days have nothing to
/// log, so they never hold a week open.
int activeWeekIndex(ProgramModel program, List<WorkoutSession> sessions) {
  for (var weekIndex = 0; weekIndex < program.weeks.length - 1; weekIndex++) {
    final week = program.weeks[weekIndex];
    final completedDays = sessions
        .where((session) => session.weekId == week.id)
        .map((session) => session.dayId)
        .toSet();
    final trainingDays = week.trainingDays;
    if (trainingDays.isEmpty ||
        !trainingDays.every((day) => completedDays.contains(day.id))) {
      return weekIndex;
    }
  }
  return program.weeks.length - 1;
}

/// The week holding [dayId] and that day, falling back to the first week and
/// day when the id is unknown.
(WeekModel, DayModel) locateDay(ProgramModel program, String dayId) {
  final week = program.weeks.firstWhere(
    (candidate) => candidate.days.any((day) => day.id == dayId),
    orElse: () => program.weeks.first,
  );
  final day = week.days.firstWhere(
    (candidate) => candidate.id == dayId,
    orElse: () => week.days.first,
  );
  return (week, day);
}
