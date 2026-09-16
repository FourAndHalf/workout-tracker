import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/native.dart';
import 'package:fitness_tracker/app.dart';
import 'package:fitness_tracker/main.dart';
import 'package:fitness_tracker/data/database/app_database.dart';
import 'package:fitness_tracker/features/home/home_providers.dart';

void main() {
  test('daily motivation quote is stable for the same date', () {
    final first = dailyMotivationQuote(DateTime(2026, 9, 16));
    final second = dailyMotivationQuote(DateTime(2026, 9, 16, 23, 59));

    expect(first.quote, second.quote);
    expect(first.source, isNotEmpty);
  });

  testWidgets('HomeScreen renders action tiles and analytics', (
    WidgetTester tester,
  ) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(() => db.close());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: const FitnessTrackerApp(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text('Start'), findsOneWidget);
    expect(find.text('Plan'), findsOneWidget);
    expect(find.text('Food'), findsOneWidget);
    expect(find.text('Your week at a glance'), findsOneWidget);
    expect(find.byIcon(Icons.format_quote_rounded), findsOneWidget);
    expect(find.text('Training volume'), findsOneWidget);
  });

  test('DashboardAnalytics calculates weekly metrics from persisted data', () {
    final analytics = DashboardAnalytics.fromData(
      sessions: [
        WorkoutSession(
          id: 1,
          programId: 'p',
          weekId: 'w',
          dayId: 'd',
          dayName: 'Arms',
          startedAt: DateTime(2026, 9, 16),
          finishedAt: DateTime(2026, 9, 16, 1),
          notes: null,
        ),
      ],
      logs: [
        ExerciseLog(
          id: 1,
          sessionId: 1,
          blockId: 'b',
          exerciseId: 'e',
          exerciseName: 'Bench Press',
          blockType: 'straight',
          logMode: 'weightReps',
          setNumber: 1,
          weight: 50,
          reps: 10,
          targetReps: 10,
          hitFailure: false,
          durationSeconds: null,
          notes: null,
          loggedAt: DateTime(2026, 9, 16),
        ),
      ],
      now: DateTime(2026, 9, 16),
    );

    expect(analytics.workoutsThisWeek, 1);
    expect(analytics.setsThisWeek, 1);
    expect(analytics.volumeThisWeek, 500);
    expect(analytics.currentStreak, 1);
    expect(analytics.topExerciseName, 'Bench Press');
    expect(analytics.topExerciseWeight, 50);
  });
}
