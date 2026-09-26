import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../main.dart';
import '../../data/models/program_model.dart';
import '../../data/database/app_database.dart';

final currentProgramProvider = FutureProvider<ProgramModel>((ref) async {
  final repo = ref.watch(programRepositoryProvider);
  return repo.loadDefaultProgram();
});

final selectedDayIdProvider = StateProvider<String?>((ref) => null);

final completedWorkoutSessionsProvider = FutureProvider<List<WorkoutSession>>((
  ref,
) async {
  return ref.watch(workoutRepositoryProvider).getCompletedSessions();
});

class NextWorkoutInfo {
  final String programId;
  final String dayId;
  final String dayName;
  final int weekNumber;
  final int exerciseCount;

  const NextWorkoutInfo({
    required this.programId,
    required this.dayId,
    required this.dayName,
    this.weekNumber = 1,
    this.exerciseCount = 0,
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
  if (week.days.isEmpty) return null;

  final completedDayIds = sessions
      .where((session) => session.weekId == week.id)
      .map((session) => session.dayId)
      .toSet();

  final nextDay = week.days.firstWhere(
    (day) => !completedDayIds.contains(day.id),
    orElse: () => week.days.first,
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
  );
}

int activeWeekIndex(ProgramModel program, List<WorkoutSession> sessions) {
  for (var weekIndex = 0; weekIndex < program.weeks.length - 1; weekIndex++) {
    final week = program.weeks[weekIndex];
    final completedDays = sessions
        .where((session) => session.weekId == week.id)
        .map((session) => session.dayId)
        .toSet();
    if (week.days.isEmpty ||
        !week.days.every((day) => completedDays.contains(day.id))) {
      return weekIndex;
    }
  }
  return program.weeks.length - 1;
}
