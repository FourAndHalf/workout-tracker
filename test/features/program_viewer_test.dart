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
                name: 'Triceps',
                type: 'restPause',
                targetSets: 2,
                exercises: [
                  ExerciseModel(
                    id: 'w1-arms-tri-01',
                    order: 1,
                    name: 'Rope Extensions',
                    targetSets: 2,
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
          DayModel(id: 'w1-shoulders', name: 'Shoulders', order: 2, blocks: []),
          DayModel(id: 'w1-back', name: 'Back', order: 3, blocks: []),
          DayModel(id: 'w1-chest-abs', name: 'Chest + Abs', order: 4, blocks: []),
          DayModel(id: 'w1-legs', name: 'Legs', order: 5, blocks: []),
        ],
      ),
    ],
  );

  testWidgets('ProgramListScreen renders program details and training days', (WidgetTester tester) async {
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

    // Tap on Programs tab in bottom navigation bar
    await tester.tap(find.text('Programs'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Verify Program Screen Header
    expect(find.text('4 Week Program'), findsOneWidget);
    expect(find.text('Training Days'), findsOneWidget);

    // Verify 5 Days present
    expect(find.text('Arms'), findsOneWidget);
    expect(find.text('Shoulders'), findsOneWidget);
    expect(find.text('Back'), findsOneWidget);
    expect(find.text('Chest + Abs'), findsOneWidget);
    expect(find.text('Legs'), findsOneWidget);
  });

  testWidgets('Tapping Arms opens DayDetailScreen with blocks and exercises', (WidgetTester tester) async {
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

    // Tap Programs tab
    await tester.tap(find.text('Programs'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Tap Arms day in training days list
    final armsFinder = find.widgetWithText(ListTile, 'Arms');
    expect(armsFinder, findsOneWidget);
    await tester.tap(armsFinder);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Verify Day Detail Screen Header and exercises
    expect(find.text('Start Arms Workout'), findsOneWidget);
    expect(find.text('Rope Extensions'), findsOneWidget);
    expect(find.text('Incline Skull Crush'), findsAtLeast(1));

  });
}
