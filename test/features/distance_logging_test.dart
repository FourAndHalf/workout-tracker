import 'package:drift/drift.dart' show Value;

import 'dart:io';

import 'package:drift/native.dart';
import 'package:fitness_tracker/app.dart';
import 'package:fitness_tracker/core/theme/app_theme.dart';
import 'package:fitness_tracker/core/widgets/app_card.dart';
import 'package:fitness_tracker/data/database/app_database.dart';
import 'package:fitness_tracker/data/models/program_model.dart';
import 'package:fitness_tracker/data/repositories/workout_repository.dart';
import 'package:fitness_tracker/features/program/program_providers.dart';
import 'package:fitness_tracker/features/progress/progress_screen.dart';
import 'package:fitness_tracker/features/workout/providers/active_workout_provider.dart';
import 'package:fitness_tracker/main.dart';
import 'package:fitness_tracker/router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

final _program = ProgramModel(
  schemaVersion: 1,
  programId: 'endurance-run-8wk',
  programName: '8 Wk Endurance',
  weeks: [
    WeekModel(
      number: 1,
      id: 'w1',
      title: 'Base Camp',
      focus: 'Find your easy effort.',
      days: [
        DayModel(
          id: 'w1-easy',
          name: 'Easy Run',
          order: 1,
          type: 'endurance',
          instructions: 'Fully conversational.',
          blocks: [
            BlockModel(
              id: 'b1',
              name: 'Run',
              type: 'endurance',
              targetSets: 1,
              restSeconds: 0,
              exercises: [
                ExerciseModel(
                  id: 'run',
                  order: 1,
                  name: 'Easy Run',
                  prescription: 'RPE 3–4, conversational',
                  instructions: 'Keep it honest.',
                  targetSets: 1,
                  distanceMeters: 5000,
                  logMode: 'distance',
                ),
              ],
            ),
            BlockModel(
              id: 'b2',
              name: 'Repeats',
              type: 'intervals',
              targetSets: 2,
              restSeconds: 90,
              exercises: [
                ExerciseModel(
                  id: 'rep',
                  order: 1,
                  name: '400 m Repeat',
                  targetSets: 2,
                  distanceMeters: 400,
                  logMode: 'distance',
                ),
              ],
            ),
          ],
        ),
        DayModel(
          id: 'w1-rest',
          name: 'Rest',
          order: 2,
          type: 'rest',
          instructions: 'Full rest or an easy walk.',
          blocks: [],
        ),
      ],
    ),
  ],
);

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

Future<void> _openPrograms(WidgetTester tester, AppDatabase db) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        currentProgramProvider.overrideWith((ref) async => _program),
      ],
      child: const FitnessTrackerApp(),
    ),
  );
  await _settle(tester);
  await tester.tap(
    find.descendant(
      of: find.byType(NavigationBar),
      matching: find.text('Programs'),
    ),
  );
  await _settle(tester);
}

void main() {
  setUp(() => appRouter.go('/'));

  testWidgets('a run logs distance and time and shows the pace', (
    tester,
  ) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    await _openPrograms(tester, db);

    // The rest day is listed but not counted as a session to do.
    expect(find.text('0/1 done'), findsOneWidget);
    expect(find.text('Rest day · nothing to log'), findsOneWidget);
    expect(find.text('Find your easy effort.'), findsOneWidget);

    await tester.tap(find.widgetWithText(AppCard, 'Easy Run'));
    await _settle(tester);
    expect(find.text('Fully conversational.'), findsOneWidget);
    expect(find.text('5 km'), findsOneWidget);
    expect(find.text('2 × 400 m'), findsOneWidget);
    expect(find.text('Keep it honest.'), findsOneWidget);
    expect(find.text('INTERVALS'), findsOneWidget);

    await tester.tap(find.text('Start Easy Run Workout'));
    await _settle(tester);

    final distance = find.descendant(
      of: find.byKey(const Key('distanceField')).first,
      matching: find.byType(TextField),
    );
    expect(tester.widget<TextField>(distance).controller!.text, '5');
    expect(
      find.text('Leave the time at 0:00 to use the set clock.'),
      findsNWidgets(2),
    );

    await tester.enterText(
      find.descendant(
        of: find.byKey(const Key('minutesField')).first,
        matching: find.byType(TextField),
      ),
      '27',
    );
    await tester.enterText(
      find.descendant(
        of: find.byKey(const Key('secondsField')).first,
        matching: find.byType(TextField),
      ),
      '30',
    );
    await tester.pump();
    expect(find.text('Pace 5:30 /km'), findsOneWidget);

    await tester.ensureVisible(find.text('Log Set 1').first);
    await tester.tap(find.text('Log Set 1').first);
    await _settle(tester);

    expect(find.text('Set 1: 5 km · 27:30 · 5:30 /km'), findsOneWidget);
    // restSeconds: 0 moves straight on without a rest timer.
    expect(find.textContaining('Rest'), findsNothing);

    final log = await tester.runAsync(
      () => db.select(db.exerciseLogs).getSingle(),
    );
    expect(log!.distanceMeters, 5000);
    expect(log.durationSeconds, 1650);
    expect(log.logMode, 'distance');
    expect(log.weight, isNull);
    expect(log.reps, isNull);
  });

  testWidgets('a rest day cannot be started', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    await _openPrograms(tester, db);

    await tester.tap(find.widgetWithText(AppCard, 'Rest'));
    await _settle(tester);

    expect(find.text('Rest day'), findsOneWidget);
    expect(find.text('Full rest or an easy walk.'), findsOneWidget);
    expect(find.textContaining('Start'), findsNothing);
  });

  group('rest timer', () {
    late AppDatabase db;
    late ProviderContainer container;
    late ActiveWorkoutNotifier notifier;
    final day = _program.weeks.single.days.first;

    setUp(() async {
      db = AppDatabase(NativeDatabase.memory());
      container = ProviderContainer(
        overrides: [
          workoutRepositoryProvider.overrideWithValue(WorkoutRepository(db)),
        ],
      );
      notifier = container.read(activeWorkoutProvider(day.id).notifier);
      notifier.initDay(day, weekId: 'w1', programId: _program.programId);
      await Future<void>.delayed(Duration.zero);
    });

    tearDown(() async {
      container.dispose();
      await db.close();
    });

    test('a block with zero rest skips the timer', () async {
      final block = day.blocks[0];
      await notifier.logSet(
        exercise: block.exercises.single,
        block: block,
        distanceMeters: 5000,
        durationSeconds: 1650,
      );

      expect(notifier.state.isResting, isFalse);
      expect(notifier.state.currentBlockIndex, 1);
      expect(notifier.state.loggedSets['run']!.single['distanceMeters'], 5000);
    });

    test('an interval block rests for its own recovery', () async {
      final block = day.blocks[1];
      await notifier.logSet(
        exercise: block.exercises.single,
        block: block,
        distanceMeters: 400,
        durationSeconds: 95,
      );

      expect(notifier.state.isResting, isTrue);
      expect(notifier.state.restSeconds, 90);
    });

    test('lock-screen completion logs the target distance', () async {
      await notifier.completeCurrentSetFromLockScreen();

      final log = await db.select(db.exerciseLogs).getSingle();
      expect(log.distanceMeters, 5000);
      expect(log.exerciseId, 'run');
    });
  });

  testWidgets('weekly distance card shows the total and latest pace', (
    tester,
  ) async {
    Widget card(List<WeeklyEndurance> weeks) => MaterialApp(
      theme: AppTheme.darkTheme,
      home: Scaffold(body: EnduranceCard(weeks: weeks)),
    );

    await tester.pumpWidget(card(const []));
    expect(find.text('No distance logged yet.'), findsOneWidget);

    await tester.pumpWidget(
      card([
        WeeklyEndurance(start: DateTime(2026, 11, 2), distanceMeters: 8000),
        WeeklyEndurance(
          start: DateTime(2026, 11, 9),
          distanceMeters: 10000,
          pacedMeters: 8000,
          pacedSeconds: 2700,
        ),
      ]),
    );
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('Weekly distance'), findsOneWidget);
    expect(
      find.text('18.0 km over 2 weeks · 5:38 /km this week'),
      findsOneWidget,
    );
    expect(find.text('10.0 km'), findsOneWidget);
  });

  test('distance column is added when upgrading from schema 3', () async {
    final db = AppDatabase(
      NativeDatabase.memory(
        setup: (raw) {
          raw.execute('''
            CREATE TABLE exercise_logs (
              id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
              session_id INTEGER NOT NULL,
              block_id TEXT NOT NULL,
              exercise_id TEXT NOT NULL,
              exercise_name TEXT NOT NULL,
              block_type TEXT NOT NULL,
              log_mode TEXT NOT NULL,
              set_number INTEGER NOT NULL,
              weight REAL,
              reps INTEGER,
              target_reps INTEGER,
              hit_failure INTEGER NOT NULL DEFAULT 0,
              duration_seconds INTEGER,
              notes TEXT,
              logged_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now'))
            );
          ''');
          raw.execute(
            "INSERT INTO exercise_logs (session_id, block_id, exercise_id, "
            "exercise_name, block_type, log_mode, set_number, weight, reps) "
            "VALUES (1, 'b', 'curl', 'Curl', 'straight', 'weightReps', 1, "
            "20, 10)",
          );
          raw.execute('PRAGMA user_version = 3');
        },
      ),
    );
    addTearDown(db.close);

    final old = await db.select(db.exerciseLogs).getSingle();
    expect(old.weight, 20);
    expect(old.distanceMeters, isNull);

    await db
        .into(db.exerciseLogs)
        .insert(
          ExerciseLogsCompanion.insert(
            sessionId: 1,
            blockId: 'b',
            exerciseId: 'run',
            exerciseName: 'Easy Run',
            blockType: 'endurance',
            logMode: 'distance',
            setNumber: 1,
            distanceMeters: const Value(5000),
          ),
        );
    expect((await db.select(db.exerciseLogs).get()).last.distanceMeters, 5000);
  });

  test('an on-disk version 3 database upgrades without losing data', () async {
    final dir = await Directory.systemTemp.createTemp('fitness_db_');
    addTearDown(() => dir.delete(recursive: true));
    final file = File('${dir.path}/fitness_tracker.sqlite');

    // A real database file with every table and some history.
    final v4 = AppDatabase(NativeDatabase(file));
    final sessionId = await v4
        .into(v4.workoutSessions)
        .insert(
          WorkoutSessionsCompanion.insert(
            programId: 'ffts-4week',
            weekId: 'w1',
            dayId: 'w1-arms',
            dayName: 'Arms',
            finishedAt: Value(DateTime(2026, 11, 1, 8)),
          ),
        );
    await v4
        .into(v4.exerciseLogs)
        .insert(
          ExerciseLogsCompanion.insert(
            sessionId: sessionId,
            blockId: 'b',
            exerciseId: 'curl',
            exerciseName: 'Curl',
            blockType: 'straight',
            logMode: 'weightReps',
            setNumber: 1,
            weight: const Value(20),
            reps: const Value(10),
          ),
        );
    await v4.close();

    // Roll the file back to exactly what version 3 stored: no distance
    // column, user_version 3. Then open it with the current app.
    var rolledBack = false;
    final upgraded = AppDatabase(
      NativeDatabase(
        file,
        setup: (raw) {
          if (rolledBack) return;
          rolledBack = true;
          raw.execute('ALTER TABLE exercise_logs DROP COLUMN distance_meters');
          raw.execute('PRAGMA user_version = 3');
        },
      ),
    );
    addTearDown(upgraded.close);

    final old = await upgraded.select(upgraded.exerciseLogs).getSingle();
    expect(old.weight, 20);
    expect(old.reps, 10);
    expect(old.distanceMeters, isNull);
    expect(
      (await upgraded.select(upgraded.workoutSessions).getSingle()).dayName,
      'Arms',
    );

    final version = await upgraded
        .customSelect('PRAGMA user_version')
        .getSingle();
    expect(version.data.values.single, 4);

    await upgraded
        .into(upgraded.exerciseLogs)
        .insert(
          ExerciseLogsCompanion.insert(
            sessionId: sessionId,
            blockId: 'b',
            exerciseId: 'run',
            exerciseName: 'Easy Run',
            blockType: 'endurance',
            logMode: 'distance',
            setNumber: 1,
            distanceMeters: const Value(5000),
            durationSeconds: const Value(1650),
          ),
        );
    final run = await (upgraded.select(
      upgraded.exerciseLogs,
    )..where((l) => l.exerciseId.equals('run'))).getSingle();
    expect(run.distanceMeters, 5000);
  });
}
