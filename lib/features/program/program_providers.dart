import 'package:flutter_riverpod/flutter_riverpod.dart';

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
