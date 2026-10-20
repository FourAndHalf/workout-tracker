import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:fitness_tracker/core/theme/app_theme.dart';
import 'package:fitness_tracker/data/database/app_database.dart';
import 'package:fitness_tracker/data/repositories/workout_repository.dart';
import 'package:fitness_tracker/features/history/session_detail_screen.dart';
import 'package:fitness_tracker/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Future<int> _session(
  AppDatabase db,
  DateTime at,
  List<(String, double)> sets,
) async {
  final id = await db
      .into(db.workoutSessions)
      .insert(
        WorkoutSessionsCompanion.insert(
          programId: 'p',
          weekId: 'w',
          dayId: 'd',
          dayName: 'Push',
          startedAt: Value(at),
          finishedAt: Value(at.add(const Duration(minutes: 45))),
        ),
      );
  var n = 0;
  for (final (name, weight) in sets) {
    n++;
    await db
        .into(db.exerciseLogs)
        .insert(
          ExerciseLogsCompanion.insert(
            sessionId: id,
            blockId: 'b',
            exerciseId: name,
            exerciseName: name,
            blockType: 'straight',
            logMode: 'weightReps',
            setNumber: n,
            weight: Value(weight),
            reps: const Value(8),
            loggedAt: Value(at),
          ),
        );
  }
  return id;
}

void main() {
  testWidgets('session detail groups sets per exercise with deltas', (
    tester,
  ) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    late int id;
    await tester.runAsync(() async {
      await _session(db, DateTime(2026, 10, 13, 7), [('Bench', 60)]);
      id = await _session(db, DateTime(2026, 10, 20, 7), [
        ('Bench', 62.5),
        ('Bench', 65),
        ('Dips', 10),
      ]);
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          workoutRepositoryProvider.overrideWithValue(WorkoutRepository(db)),
        ],
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: SessionDetailScreen(sessionId: id),
        ),
      ),
    );
    for (var i = 0; i < 5; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump();
    }

    expect(find.text('Push'), findsOneWidget);
    expect(find.text('45 min'), findsOneWidget);
    expect(find.text('Bench'), findsOneWidget);
    expect(find.text('2 sets'), findsOneWidget);
    // Best 65 kg against last week's 60 kg.
    expect(find.text('▲ 5 kg'), findsOneWidget);
    // Dips wasn't in the previous session.
    expect(find.text('New'), findsOneWidget);
    expect(find.text('Previous best 60 kg'), findsOneWidget);
  });
}
