import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/native.dart';
import 'package:fitness_tracker/app.dart';
import 'package:fitness_tracker/main.dart';
import 'package:fitness_tracker/data/database/app_database.dart';
import 'package:fitness_tracker/data/models/program_model.dart';
import 'package:fitness_tracker/features/program/program_providers.dart';

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
                name: 'Triceps Rest Pause',
                type: 'restPause',
                targetSets: 1,
                exercises: [
                  ExerciseModel(
                    id: 'w1-arms-tri-01',
                    order: 1,
                    name: 'Rope Extensions',
                    targetSets: 1,
                    repTarget: 100,
                    logMode: 'cumulative',
                  ),
                ],
              ),
              BlockModel(
                id: 'w1-arms-b2',
                name: 'Incline Skull Crush',
                type: 'straight',
                targetSets: 3,
                exercises: [
                  ExerciseModel(
                    id: 'w1-arms-tri-02',
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

  testWidgets('ActiveWorkoutScreen renders elapsed timer, loggers, and FINISH button', (WidgetTester tester) async {
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

    // Tap Programs -> tap Arms -> tap Start Arms Workout
    await tester.tap(find.text('Programs'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    final armsFinder = find.widgetWithText(ListTile, 'Arms');
    await tester.tap(armsFinder);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.text('Start Arms Workout'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Verify Active Workout Screen Header
    expect(find.text('FINISH'), findsOneWidget);
    expect(find.textContaining('Elapsed:'), findsOneWidget);

    // Verify Set Loggers
    expect(find.text('REST-PAUSE PROGRESS'), findsOneWidget);
    expect(find.text('Log Set 1'), findsOneWidget);
  });
}
