import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/native.dart';
import 'package:fitness_tracker/app.dart';
import 'package:fitness_tracker/main.dart';
import 'package:fitness_tracker/data/database/app_database.dart';
import 'package:fitness_tracker/data/models/program_model.dart';
import 'package:fitness_tracker/features/program/program_providers.dart';
import 'package:fitness_tracker/router.dart';

void main() {
  // `appRouter` is a module-level singleton reused across every test in
  // this file, so reset it to a known location before each test.
  setUp(() => appRouter.go('/'));

  final mockProgram = ProgramModel(
    schemaVersion: 1,
    programId: 'ffts-4week',
    programName: '4 Week Program',
    weeks: [
      WeekModel(
        number: 1,
        id: 'w1',
        title: 'Fucked From The Start',
        days: [
          DayModel(
            id: 'w1-arms',
            name: 'Arms',
            order: 1,
            blocks: [
              BlockModel(
                id: 'w1-arms-b1',
                name: 'Incline Skull Crush',
                type: 'straight',
                targetSets: 3,
                exercises: [
                  ExerciseModel(
                    id: 'w1-arms-tri-01',
                    order: 1,
                    name: 'Incline Skull Crush',
                    targetSets: 3,
                    logMode: 'weightReps',
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );

  Future<void> pumpAppAtArmsDay(WidgetTester tester, AppDatabase db) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          currentProgramProvider.overrideWith((ref) async => mockProgram),
        ],
        child: const FitnessTrackerApp(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.text('Programs'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.widgetWithText(ListTile, 'Arms'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  testWidgets(
    'starting a workout logs sets and finishes on the same day-detail page',
    (WidgetTester tester) async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(() => db.close());

      await pumpAppAtArmsDay(tester, db);

      // Preview mode: browsing the plan, no logging controls yet.
      expect(find.text('Start Arms Workout'), findsOneWidget);
      expect(find.text('Log Set 1'), findsNothing);

      await tester.tap(find.text('Start Arms Workout'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Same page: still showing the Arms day, now with logging controls
      // and an elapsed timer instead of a navigation to a new screen.
      expect(find.text('Arms'), findsOneWidget);
      expect(find.textContaining('Elapsed:'), findsOneWidget);
      expect(find.text('Log Set 1'), findsOneWidget);
      expect(find.text('FINISH'), findsOneWidget);
      expect(find.text('Start Arms Workout'), findsNothing);

      await tester.tap(find.text('Log Set 1'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.textContaining('Set 1:'), findsOneWidget);
      expect(find.text('Log Set 2'), findsOneWidget);

      await tester.tap(find.text('FINISH'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Back to preview mode on the same page.
      expect(find.text('Start Arms Workout'), findsOneWidget);
      expect(find.textContaining('Elapsed:'), findsNothing);
    },
  );
}
