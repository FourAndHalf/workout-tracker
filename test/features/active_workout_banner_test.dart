import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/native.dart';
import 'package:fitness_tracker/app.dart';
import 'package:fitness_tracker/main.dart';
import 'package:fitness_tracker/data/database/app_database.dart';
import 'package:fitness_tracker/data/models/program_model.dart';
import 'package:fitness_tracker/features/program/program_providers.dart';
import 'package:fitness_tracker/features/workout/widgets/active_workout_banner.dart';

void main() {
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

  Future<void> startArmsWorkout(WidgetTester tester) async {
    await tester.tap(find.text('Programs'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.widgetWithText(ListTile, 'Arms'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.text('Start Arms Workout'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  testWidgets('banner is not shown when there is no active session', (
    WidgetTester tester,
  ) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(() => db.close());

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

    expect(find.byType(ActiveWorkoutBanner), findsOneWidget);
    expect(find.textContaining('in progress'), findsNothing);
  });

  testWidgets(
    'banner appears after leaving an active workout and returns to it on tap',
    (WidgetTester tester) async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(() => db.close());

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

      await startArmsWorkout(tester);
      expect(find.textContaining('Elapsed:'), findsOneWidget);

      // Back out to Home without finishing the workout. Two "Back" buttons
      // are mounted (the day detail screen underneath, and the workout
      // screen on top), so target the topmost one explicitly.
      await tester.tap(find.byTooltip('Back').last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.textContaining('Arms in progress'), findsOneWidget);

      await tester.tap(find.byType(ActiveWorkoutBanner));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.textContaining('Elapsed:'), findsOneWidget);

      // Finish the workout so no periodic timers are left running past the
      // end of this test, which would otherwise bleed into the next one.
      await tester.tap(find.text('FINISH'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
    },
  );

  testWidgets('banner disappears after finishing the workout', (
    WidgetTester tester,
  ) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(() => db.close());

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

    await startArmsWorkout(tester);

    await tester.tap(find.text('FINISH'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.textContaining('in progress'), findsNothing);
  });
}
