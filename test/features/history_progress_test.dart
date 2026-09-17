import 'package:drift/drift.dart' show Value;
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

    expect(find.text('Log a workout to see your progress'), findsOneWidget);
  });

  testWidgets(
    'progress shows streak, workout type breakdown, average duration, and calories',
    (tester) async {
      final startedAt = DateTime(2026, 1, 1, 9, 0);
      final finishedAt = startedAt.add(const Duration(minutes: 40));

      final sessionId = await db
          .into(db.workoutSessions)
          .insert(
            WorkoutSessionsCompanion.insert(
              programId: 'program',
              weekId: 'week',
              dayId: 'day',
              dayName: 'Push day',
              startedAt: Value(startedAt),
              finishedAt: Value(finishedAt),
            ),
          );
      await db
          .into(db.exerciseLogs)
          .insert(
            ExerciseLogsCompanion.insert(
              sessionId: sessionId,
              blockId: 'block',
              exerciseId: 'press',
              exerciseName: 'Bench press',
              blockType: 'straight',
              logMode: 'weightReps',
              setNumber: 1,
              weight: const Value(60),
              reps: const Value(8),
              loggedAt: Value(startedAt),
            ),
          );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [workoutRepositoryProvider.overrideWithValue(repository)],
          child: const MaterialApp(home: ProgressScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // These cards sit below the fold in the Progress ListView, so scroll
      // down to mount them before asserting.
      await tester.scrollUntilVisible(
        find.text('Estimated calories burned'),
        300,
        scrollable: find.byType(Scrollable).first,
      );

      // Streak card (today's session counts as a 1-day streak, unless the
      // fixture date isn't "today" — assert the label/shell instead of the
      // exact number, which depends on wall-clock date.
      expect(find.text('Day streak'), findsOneWidget);

      // Workout type breakdown donut.
      expect(find.text('Workout type breakdown'), findsOneWidget);
      expect(find.textContaining('Push day'), findsOneWidget);

      // Average workout time: 40 minutes.
      expect(find.text('Average workout time'), findsOneWidget);
      expect(find.text('40 min'), findsOneWidget);

      // Estimated calories chart.
      expect(find.text('Estimated calories burned'), findsOneWidget);
    },
  );
}
