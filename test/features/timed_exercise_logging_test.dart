import 'package:drift/native.dart';
import 'package:fitness_tracker/app.dart';
import 'package:fitness_tracker/core/widgets/app_card.dart';
import 'package:fitness_tracker/data/database/app_database.dart';
import 'package:fitness_tracker/data/models/program_model.dart';
import 'package:fitness_tracker/features/program/program_providers.dart';
import 'package:fitness_tracker/main.dart';
import 'package:fitness_tracker/router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() => appRouter.go('/'));

  final program = ProgramModel(
    schemaVersion: 1,
    programId: 'ffts-4week',
    programName: '4 Week Program',
    weeks: [
      WeekModel(
        number: 1,
        id: 'w1',
        title: 'Week',
        days: [
          DayModel(
            id: 'w1-mob',
            name: 'Mobility',
            order: 1,
            blocks: [
              BlockModel(
                id: 'b1',
                name: 'Deep Squat Hold',
                type: 'straight',
                targetSets: 1,
                exercises: [
                  ExerciseModel(
                    id: 'squat',
                    order: 1,
                    name: 'Deep Squat Hold',
                    targetSets: 1,
                    repScheme: [60],
                    repUnit: 'sec',
                    logMode: 'time',
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );

  testWidgets('a timed exercise logs its held time, not weight or reps', (
    tester,
  ) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          currentProgramProvider.overrideWith((ref) async => program),
        ],
        child: const FitnessTrackerApp(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Programs'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.widgetWithText(AppCard, 'Mobility'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Start Mobility Workout'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byKey(const Key('countdownReadout')), findsOneWidget);
    expect(find.text('Duration (seconds)'), findsNothing);
    expect(find.text('Log Set 1'), findsNothing);

    await tester.tap(find.text('Start'));
    await tester.pump(const Duration(seconds: 3));
    await tester.tap(find.text('Log early'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Set 1: 0:03'), findsOneWidget);
    expect(find.textContaining('kg'), findsNothing);
    expect(find.textContaining('reps'), findsNothing);
  });
}
