import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:fitness_tracker/data/database/app_database.dart';
import 'package:fitness_tracker/data/repositories/workout_repository.dart';
import 'package:fitness_tracker/data/models/program_model.dart';
import 'package:fitness_tracker/features/workout/providers/active_workout_provider.dart';

void main() {
  late AppDatabase db;
  late WorkoutRepository workoutRepo;
  late ActiveWorkoutNotifier notifier;

  final mockDay = DayModel(
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
  );

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    workoutRepo = WorkoutRepository(db);
    notifier = ActiveWorkoutNotifier(workoutRepo, 'w1-arms');
    notifier.initDay(mockDay);
  });

  tearDown(() async {
    await db.close();
  });

  group('ActiveWorkoutNotifier Unit Tests', () {
    test('Initializes workout session correctly', () async {
      await Future.delayed(Duration.zero);
      expect(notifier.state.dayId, equals('w1-arms'));
      expect(notifier.state.sessionId, isNotNull);
    });

    test('Logs weightReps set and triggers rest timer', () async {
      await Future.delayed(Duration.zero);

      final block = mockDay.blocks[1];
      final exercise = block.exercises.first;

      await notifier.logSet(
        exercise: exercise,
        block: block,
        weight: 35.0,
        reps: 20,
      );

      expect(notifier.state.loggedSets[exercise.id], isNotNull);
      expect(notifier.state.loggedSets[exercise.id]!.length, equals(1));
      expect(
        notifier.state.loggedSets[exercise.id]!.first['weight'],
        equals(35.0),
      );
      expect(notifier.state.isResting, isTrue);

      notifier.dismissRestTimer();
      expect(notifier.state.isResting, isFalse);
    });

    test('Logs cumulative rest-pause chunks correctly', () async {
      await Future.delayed(Duration.zero);

      final block = mockDay.blocks.first;
      final exercise = block.exercises.first;

      await notifier.addRestPauseChunk(
        exercise: exercise,
        block: block,
        chunkReps: 30,
      );

      await notifier.addRestPauseChunk(
        exercise: exercise,
        block: block,
        chunkReps: 25,
      );

      expect(notifier.state.restPauseChunks[exercise.id], equals([30, 25]));
    });

    test(
      'Lock-screen completion logs the current set and advances exercise',
      () async {
        final day = DayModel(
          id: 'w1-sequence',
          name: 'Sequence',
          order: 1,
          blocks: [
            BlockModel(
              id: 'sequence-block',
              name: 'Sequence',
              type: 'straight',
              targetSets: 1,
              exercises: [
                ExerciseModel(
                  id: 'first',
                  order: 1,
                  name: 'First exercise',
                  targetSets: 1,
                  repTarget: 10,
                  logMode: 'repsOnly',
                ),
                ExerciseModel(
                  id: 'second',
                  order: 2,
                  name: 'Second exercise',
                  targetSets: 1,
                  repTarget: 8,
                  logMode: 'repsOnly',
                ),
              ],
            ),
          ],
        );
        final sequenceNotifier = ActiveWorkoutNotifier(workoutRepo, day.id);
        addTearDown(sequenceNotifier.dispose);
        sequenceNotifier.initDay(day);
        await Future<void>.delayed(Duration.zero);

        await sequenceNotifier.completeCurrentSetFromLockScreen();

        expect(sequenceNotifier.state.currentExerciseIndex, 1);
        expect(sequenceNotifier.state.loggedSets['first']!.single['reps'], 10);
      },
    );

    test('Finishes workout session in database', () async {
      await Future.delayed(Duration.zero);
      await notifier.finishWorkout(notes: 'Awesome session');

      final completed = await workoutRepo.getCompletedSessions();
      expect(completed.length, equals(1));
      expect(completed.first.notes, equals('Awesome session'));
    });
  });
}
