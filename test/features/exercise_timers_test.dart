import 'package:drift/native.dart';
import 'package:fitness_tracker/data/database/app_database.dart';
import 'package:fitness_tracker/data/models/program_model.dart';
import 'package:fitness_tracker/data/repositories/workout_repository.dart';
import 'package:fitness_tracker/features/workout/providers/active_workout_provider.dart';
import 'package:fitness_tracker/features/workout/widgets/exercise_countdown_timer.dart';
import 'package:fitness_tracker/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ExerciseCountdownTimer', () {
    Future<List<int>> pumpTimer(
      WidgetTester tester, {
      bool paused = false,
    }) async {
      final logged = <int>[];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ExerciseCountdownTimer(
              targetSeconds: 5,
              paused: paused,
              onLog: logged.add,
            ),
          ),
        ),
      );
      return logged;
    }

    String readout(WidgetTester tester) =>
        tester.widget<Text>(find.byKey(const Key('countdownReadout'))).data!;

    testWidgets('counts down and logs the full target at zero', (tester) async {
      final logged = await pumpTimer(tester);
      expect(readout(tester), '00:05');

      await tester.tap(find.text('Start'));
      await tester.pump(const Duration(seconds: 2));
      expect(readout(tester), '00:03');

      await tester.pump(const Duration(seconds: 3));
      expect(logged, [5]);
      expect(readout(tester), '00:05');
    });

    testWidgets('pause holds the clock, resume continues', (tester) async {
      await pumpTimer(tester);
      await tester.tap(find.text('Start'));
      await tester.pump(const Duration(seconds: 2));
      await tester.tap(find.text('Pause'));
      await tester.pump(const Duration(seconds: 10));
      expect(readout(tester), '00:03');

      await tester.tap(find.text('Resume'));
      await tester.pump(const Duration(seconds: 1));
      expect(readout(tester), '00:02');
    });

    testWidgets('log early reports the time held; reset clears it', (
      tester,
    ) async {
      final logged = await pumpTimer(tester);
      await tester.tap(find.text('Start'));
      await tester.pump(const Duration(seconds: 2));
      await tester.tap(find.text('Log early'));
      await tester.pump();
      expect(logged, [2]);

      await tester.tap(find.text('Start'));
      await tester.pump(const Duration(seconds: 1));
      await tester.tap(find.text('Reset'));
      await tester.pump();
      expect(readout(tester), '00:05');
      expect(logged, [2]);
    });

    testWidgets('a paused workout freezes the countdown', (tester) async {
      await pumpTimer(tester, paused: true);
      expect(
        tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed,
        isNull,
      );
    });
  });

  group('ActiveWorkoutNotifier timing', () {
    late AppDatabase db;
    late WorkoutRepository repo;
    late ProviderContainer container;
    late ActiveWorkoutNotifier notifier;
    late DateTime clock;

    final day = DayModel(
      id: 'd1',
      name: 'Mix',
      order: 1,
      blocks: [
        BlockModel(
          id: 'b1',
          name: 'Press',
          type: 'straight',
          targetSets: 2,
          exercises: [
            ExerciseModel(
              id: 'press',
              order: 1,
              name: 'Press',
              targetSets: 2,
              logMode: 'weightReps',
            ),
          ],
        ),
        BlockModel(
          id: 'b2',
          name: 'Hold',
          type: 'straight',
          targetSets: 1,
          exercises: [
            ExerciseModel(
              id: 'hold',
              order: 1,
              name: 'Hold',
              targetSets: 1,
              repScheme: [60],
              repUnit: 'sec',
              logMode: 'time',
            ),
          ],
        ),
      ],
    );

    setUp(() async {
      db = AppDatabase(NativeDatabase.memory());
      repo = WorkoutRepository(db);
      container = ProviderContainer(
        overrides: [workoutRepositoryProvider.overrideWithValue(repo)],
      );
      clock = DateTime(2026, 1, 1, 9);
      notifier = ActiveWorkoutNotifier(
        repo,
        container.read(_refProvider),
        'd1',
        now: () => clock,
      );
      notifier.initDay(day);
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });

    tearDown(() async {
      container.dispose();
      await db.close();
    });

    test('rep-based sets record time spent, excluding rest', () async {
      clock = clock.add(const Duration(seconds: 40));
      await notifier.logSet(
        exercise: day.blocks[0].exercises[0],
        block: day.blocks[0],
        weight: 20,
        reps: 10,
      );
      expect(notifier.state.loggedSets['press']!.first['durationSeconds'], 40);

      clock = clock.add(const Duration(seconds: 60)); // resting
      notifier.dismissRestTimer();
      clock = clock.add(const Duration(seconds: 25));
      await notifier.logSet(
        exercise: day.blocks[0].exercises[0],
        block: day.blocks[0],
        weight: 20,
        reps: 10,
      );
      expect(notifier.state.loggedSets['press']!.last['durationSeconds'], 25);
    });

    test(
      'timed sets keep the supplied duration and no stray weight/reps',
      () async {
        await notifier.logSet(
          exercise: day.blocks[1].exercises[0],
          block: day.blocks[1],
          durationSeconds: 45,
        );
        final set = notifier.state.loggedSets['hold']!.single;
        expect(set['durationSeconds'], 45);
        expect(set['weight'], isNull);
        expect(set['reps'], isNull);
      },
    );

    test(
      'pause freezes elapsed and blocks logging; resume excludes the gap',
      () async {
        final started = notifier.state.startTime!;
        clock = clock.add(const Duration(seconds: 30));
        notifier.pause();
        expect(notifier.state.isPaused, isTrue);

        clock = clock.add(const Duration(minutes: 5));
        await notifier.logSet(
          exercise: day.blocks[0].exercises[0],
          block: day.blocks[0],
          reps: 5,
        );
        expect(notifier.state.loggedSets, isEmpty);

        notifier.resume();
        expect(notifier.state.isPaused, isFalse);
        expect(
          notifier.state.startTime,
          started.add(const Duration(minutes: 5)),
        );

        clock = clock.add(const Duration(seconds: 10));
        await notifier.logSet(
          exercise: day.blocks[0].exercises[0],
          block: day.blocks[0],
          reps: 5,
        );
        // 30 s before the pause + 10 s after; the 5 minute pause is excluded.
        expect(
          notifier.state.loggedSets['press']!.single['durationSeconds'],
          40,
        );
      },
    );
  });
}

final _refProvider = Provider<Ref>((ref) => ref);
