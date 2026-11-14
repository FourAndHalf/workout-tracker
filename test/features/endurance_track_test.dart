import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:fitness_tracker/data/database/app_database.dart';
import 'package:fitness_tracker/data/models/program_model.dart';
import 'package:fitness_tracker/data/repositories/program_repository.dart';
import 'package:fitness_tracker/data/repositories/workout_repository.dart';
import 'package:fitness_tracker/features/program/program_providers.dart';
import 'package:fitness_tracker/services/flux_widget_service.dart';
import 'package:flutter_test/flutter_test.dart';

ProgramModel _load(String asset) => ProgramModel.fromJson(
  jsonDecode(File(asset).readAsStringSync()) as Map<String, dynamic>,
);

WorkoutSession _session(String programId, String weekId, String dayId) =>
    WorkoutSession(
      id: dayId.hashCode,
      programId: programId,
      weekId: weekId,
      dayId: dayId,
      dayName: dayId,
      startedAt: DateTime(2026),
      finishedAt: DateTime(2026),
    );

void main() {
  group('8 Wk Endurance track', () {
    final program = _load('assets/programs/endurance_run_8wk.json');
    final exercises = program.weeks
        .expand((week) => week.days)
        .expand((day) => day.blocks)
        .expand((block) => block.exercises)
        .toList();

    test('is bundled and selectable', () {
      expect(
        ProgramRepository.bundledProgramAssets['endurance-run-8wk'],
        'assets/programs/endurance_run_8wk.json',
      );
      expect(program.programId, 'endurance-run-8wk');
      expect(program.programName, '8 Wk Endurance');
    });

    test('has eight weeks of five sessions and two rest days', () {
      expect(program.weeks, hasLength(8));
      for (final week in program.weeks) {
        expect(week.days, hasLength(7), reason: week.id);
        expect(week.trainingDays, hasLength(5), reason: week.id);
        expect(week.focus, isNotNull, reason: week.id);
        for (final day in week.days) {
          expect(day.blocks.isEmpty, day.isRestDay, reason: day.id);
        }
      }
    });

    test('uses only supported log modes and gives every exercise a target', () {
      expect(exercises.map((e) => e.logMode).toSet(), {
        'distance',
        'time',
        'repsOnly',
      });
      for (final exercise in exercises) {
        if (exercise.logMode == 'distance') {
          expect(exercise.distanceMeters, greaterThan(0), reason: exercise.id);
        } else {
          expect(exercise.repScheme, isNotNull, reason: exercise.id);
        }
      }
      expect(exercises.map((e) => e.id).toSet(), hasLength(exercises.length));
    });

    test('builds volume to a week-7 peak with deloads in weeks 4 and 8', () {
      double km(WeekModel week) =>
          week.days
              .expand((day) => day.blocks)
              .expand((block) => block.exercises)
              .fold<double>(
                0,
                (total, e) => total + (e.distanceMeters ?? 0) * e.targetSets,
              ) /
          1000;
      final volumes = program.weeks.map(km).toList();

      expect(volumes[0], inInclusiveRange(20, 26));
      expect(volumes[6], volumes.reduce((a, b) => a > b ? a : b));
      expect(volumes[6], greaterThan(40));
      expect(volumes[3], lessThan(volumes[2]));
      expect(volumes[7], lessThan(volumes[6]));
      // No build week jumps more than ~25% over the one before.
      for (final i in [1, 2, 5, 6]) {
        expect(volumes[i] / volumes[i - 1], lessThan(1.25), reason: 'week $i');
      }
    });

    test('ends with a 10K time trial', () {
      final test = program.weeks.last.trainingDays.last;
      expect(test.name, '10K Time Trial');
      expect(
        test.blocks.expand((b) => b.exercises).map((e) => e.distanceMeters),
        contains(10000),
      );
    });

    test('interval blocks carry their recovery as the rest timer', () {
      final intervals = program.weeks.first.days
          .firstWhere((day) => day.type == 'intervals')
          .blocks
          .firstWhere((block) => block.type == 'intervals');
      expect(intervals.restSeconds, 90);
      expect(intervals.exercises.single.targetSets, 6);
      expect(intervals.exercises.single.distanceMeters, 400);
    });

    test('rest days never hold a week open', () {
      final week1 = program.weeks.first;
      final done = [
        for (final day in week1.trainingDays)
          _session(program.programId, week1.id, day.id),
      ];

      expect(nextWorkoutFor(program, const [])!.dayId, 'end-w1-easy');
      // Skips Wednesday's rest day straight to the tempo run.
      expect(
        nextWorkoutFor(program, done.sublist(0, 2))!.dayId,
        'end-w1-tempo',
      );
      expect(activeWeekIndex(program, done), 1);
      expect(nextWorkoutFor(program, done)!.dayId, 'end-w2-easy');
    });

    test('session estimates come from the authored duration', () {
      final longRun = program.weeks[6].days.firstWhere(
        (day) => day.id == 'end-w7-long',
      );
      expect(longRun.estimatedDurationSeconds, isNotNull);
      expect(
        estimateWorkoutMinutes(longRun),
        longRun.estimatedDurationSeconds! ~/ 60,
      );
      expect(estimateWorkoutMinutes(longRun), greaterThan(90));
    });
  });

  group('existing tracks', () {
    test('badminton weeks advance without logging the rest day', () {
      final program = _load('assets/programs/badminton_mobility_strength.json');
      final week1 = program.weeks.first;

      expect(week1.days.where((day) => day.isRestDay), hasLength(1));
      expect(week1.trainingDays, hasLength(6));
      expect(
        program.weeks.expand((w) => w.days).where((d) => d.blocks.isEmpty),
        everyElement(
          isA<DayModel>().having((d) => d.isRestDay, 'isRestDay', isTrue),
        ),
      );

      final done = [
        for (final day in week1.trainingDays)
          _session(program.programId, week1.id, day.id),
      ];
      expect(activeWeekIndex(program, done), 1);
      expect(nextWorkoutFor(program, done)!.weekNumber, 2);
    });

    test('mobility blocks keep their zero rest and exercise cues', () {
      final program = _load('assets/programs/mobility_10min.json');
      final day = program.weeks.single.days.single;

      expect(day.estimatedDurationSeconds, 600);
      expect(estimateWorkoutMinutes(day), 10);
      expect(day.instructions, isNotNull);
      expect(program.weeks.single.focus, isNotNull);
      for (final block in day.blocks) {
        expect(block.restSeconds, 0);
        expect(block.exercises.single.instructions, isNotNull);
      }
      expect(day.blocks[1].exercises.single.side, 'each');
    });

    test('new model fields survive a JSON round trip', () {
      final program = _load('assets/programs/endurance_run_8wk.json');
      final copy = ProgramModel.fromJson(
        jsonDecode(jsonEncode(program.toJson())) as Map<String, dynamic>,
      );
      final day = copy.weeks.first.days[1];
      final repeat = day.blocks[1].exercises.single;

      expect(copy.weeks.first.focus, program.weeks.first.focus);
      expect(day.type, 'intervals');
      expect(day.instructions, isNotNull);
      expect(day.estimatedDurationSeconds, isNotNull);
      expect(day.blocks[1].restSeconds, 90);
      expect(repeat.logMode, 'distance');
      expect(repeat.distanceMeters, 400);
      expect(repeat.instructions, isNotNull);
      expect(copy.weeks.first.days[2].isRestDay, isTrue);
    });
  });

  group('estimateWorkoutMinutes', () {
    DayModel day(List<ExerciseModel> exercises, {int? rest}) => DayModel(
      id: 'd',
      name: 'Day',
      order: 1,
      blocks: [
        BlockModel(
          id: 'b',
          name: 'B',
          type: 'straight',
          targetSets: 1,
          restSeconds: rest,
          exercises: exercises,
        ),
      ],
    );

    test('sizes distance work at an easy pace plus recoveries', () {
      final intervals = day([
        ExerciseModel(
          id: 'rep',
          order: 1,
          name: '1 km Repeat',
          targetSets: 4,
          distanceMeters: 1000,
          logMode: 'distance',
        ),
      ], rest: 120);
      // 4 × (6:30 + 2:00) = 34 min.
      expect(estimateWorkoutMinutes(intervals), 34);
    });

    test('bodyweight reps are shorter than loaded sets', () {
      ExerciseModel four(String mode) => ExerciseModel(
        id: mode,
        order: 1,
        name: mode,
        targetSets: 4,
        logMode: mode,
      );
      expect(estimateWorkoutMinutes(day([four('repsOnly')])), 5);
      expect(estimateWorkoutMinutes(day([four('weightReps')])), 10);
    });
  });

  group('distance logging', () {
    late AppDatabase db;
    late WorkoutRepository repo;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      repo = WorkoutRepository(db);
    });
    tearDown(() => db.close());

    Future<void> logRun(
      int sessionId,
      double meters,
      int? seconds,
      DateTime at,
    ) async {
      final id = await repo.logExerciseSet(
        sessionId: sessionId,
        blockId: 'b',
        exerciseId: 'run',
        exerciseName: 'Easy Run',
        blockType: 'endurance',
        logMode: 'distance',
        setNumber: 1,
        distanceMeters: meters,
        durationSeconds: seconds,
      );
      await (db.update(db.exerciseLogs)..where((l) => l.id.equals(id))).write(
        ExerciseLogsCompanion(loggedAt: Value(at)),
      );
    }

    test('stores distance alongside the set', () async {
      final sessionId = await repo.startSession(
        programId: 'endurance-run-8wk',
        weekId: 'end-w1',
        dayId: 'end-w1-easy',
        dayName: 'Easy Run',
      );
      await logRun(sessionId, 5000, 1800, DateTime(2026, 11, 10));

      final log = (await repo.getLogsForSession(sessionId)).single;
      expect(log.distanceMeters, 5000);
      expect(log.durationSeconds, 1800);
      expect(log.weight, isNull);
    });

    test('weekly endurance totals distance and averages pace', () async {
      final sessionId = await repo.startSession(
        programId: 'endurance-run-8wk',
        weekId: 'end-w1',
        dayId: 'end-w1-easy',
        dayName: 'Easy Run',
      );
      // Saturday 14 Nov 2026; its week starts Monday 9 Nov.
      final now = DateTime(2026, 11, 14, 12);
      await logRun(sessionId, 5000, 1800, DateTime(2026, 11, 10));
      await logRun(sessionId, 3000, 900, DateTime(2026, 11, 12));
      await logRun(sessionId, 2000, null, DateTime(2026, 11, 13));
      await logRun(sessionId, 8000, 3000, DateTime(2026, 11, 4));
      // A lifting set must not count.
      await repo.logExerciseSet(
        sessionId: sessionId,
        blockId: 'b',
        exerciseId: 'curl',
        exerciseName: 'Curl',
        blockType: 'straight',
        logMode: 'weightReps',
        setNumber: 1,
        weight: 20,
        reps: 10,
        durationSeconds: 40,
      );

      final weeks = await repo.getWeeklyEndurance(weeks: 3, now: now);

      expect(weeks, hasLength(3));
      expect(weeks.map((w) => w.start).last, DateTime(2026, 11, 9));
      expect(weeks[0].distanceKm, 0);
      expect(weeks[0].paceSecondsPerKm, isNull);
      expect(weeks[1].distanceKm, 8);
      expect(weeks[2].distanceKm, 10);
      // Pace ignores the untimed 2 km: 2700 s over 8 km.
      expect(weeks[2].paceSecondsPerKm, closeTo(337.5, 0.001));
    });

    test('formats pace and distance', () {
      expect(formatPace(337.5), '5:38 /km');
      expect(formatPace(300), '5:00 /km');
      expect(formatDistance(400), '400 m');
      expect(formatDistance(5000), '5 km');
      expect(formatDistance(1500), '1.5 km');
      expect(paceSecondsPerKmFor(5000, 1500), 300);
      expect(paceSecondsPerKmFor(5000, null), isNull);
      expect(paceSecondsPerKmFor(0, 100), isNull);
    });
  });
}
