import 'package:flutter_test/flutter_test.dart';
import 'package:fitness_tracker/data/database/app_database.dart';
import 'package:fitness_tracker/data/models/program_model.dart';
import 'package:fitness_tracker/features/program/program_providers.dart';

void main() {
  test('active week advances only after every day is completed', () {
    final program = ProgramModel(
      schemaVersion: 1,
      programId: 'program',
      programName: 'Program',
      weeks: [
        WeekModel(
          number: 1,
          id: 'w1',
          title: 'Week 1',
          days: [
            DayModel(id: 'w1-d1', name: 'Day 1', order: 1, blocks: []),
            DayModel(id: 'w1-d2', name: 'Day 2', order: 2, blocks: []),
          ],
        ),
        WeekModel(
          number: 2,
          id: 'w2',
          title: 'Week 2',
          days: [DayModel(id: 'w2-d1', name: 'Day 1', order: 1, blocks: [])],
        ),
      ],
    );

    WorkoutSession session(String weekId, String dayId) => WorkoutSession(
      id: dayId.hashCode,
      programId: 'program',
      weekId: weekId,
      dayId: dayId,
      dayName: dayId,
      startedAt: DateTime(2026),
      finishedAt: DateTime(2026),
    );

    expect(activeWeekIndex(program, [session('w1', 'w1-d1')]), 0);
    expect(
      activeWeekIndex(program, [
        session('w1', 'w1-d1'),
        session('w1', 'w1-d2'),
      ]),
      1,
    );
  });
}
