import 'package:fitness_tracker/core/utils/workout_estimate.dart';
import 'package:fitness_tracker/data/models/program_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('estimateWorkoutMinutes counts timed exercises by duration', () {
    ExerciseModel timed(int seconds) => ExerciseModel(
      id: 't$seconds',
      order: 1,
      name: 'Hold',
      targetSets: 1,
      repScheme: [seconds],
      logMode: 'time',
    );
    final day = DayModel(
      id: 'd',
      name: 'Day',
      order: 1,
      blocks: [
        BlockModel(
          id: 'b',
          name: 'B',
          type: 'straight',
          targetSets: 1,
          exercises: [
            timed(60),
            timed(60),
            ExerciseModel(
              id: 'lift',
              order: 3,
              name: 'Curl',
              targetSets: 4,
              logMode: 'weightReps',
            ),
          ],
        ),
      ],
    );

    // 2 min of holds + 4 sets * 2.5 min = 12.
    expect(estimateWorkoutMinutes(day), 12);
  });
}
