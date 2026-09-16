import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fitness_tracker/data/database/app_database.dart';
import 'package:fitness_tracker/data/repositories/workout_repository.dart';
import 'package:fitness_tracker/features/history/history_screen.dart';
import 'package:fitness_tracker/features/progress/progress_screen.dart';
import 'package:fitness_tracker/main.dart';

void main() {
  late AppDatabase db;
  late WorkoutRepository repository;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repository = WorkoutRepository(db);
  });

  tearDown(() => db.close());

  testWidgets('history shows the calendar and logged day details', (
    tester,
  ) async {
    final sessionId = await repository.startSession(
      programId: 'program',
      weekId: 'week',
      dayId: 'day',
      dayName: 'Push day',
    );
    await repository.logExerciseSet(
      sessionId: sessionId,
      blockId: 'block',
      exerciseId: 'press',
      exerciseName: 'Bench press',
      blockType: 'straight',
      logMode: 'weightReps',
      setNumber: 1,
      weight: 60,
      reps: 8,
    );
    await repository.finishSession(sessionId);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [workoutRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(home: HistoryScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Workout History'), findsOneWidget);
  });

  testWidgets('progress shows an empty state before workout logs exist', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [workoutRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(home: ProgressScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Log a workout to see your progress.'), findsOneWidget);
  });
}
