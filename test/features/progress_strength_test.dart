import 'package:fitness_tracker/data/database/app_database.dart';
import 'package:fitness_tracker/features/progress/progress_screen.dart';
import 'package:flutter_test/flutter_test.dart';

ExerciseLog _log(int id, double? weight, DateTime at) => ExerciseLog(
  id: id,
  sessionId: 1,
  blockId: 'b',
  exerciseId: 'squat',
  exerciseName: 'Squat',
  blockType: 'straight',
  logMode: 'weightReps',
  setNumber: 1,
  weight: weight,
  reps: 5,
  targetReps: 5,
  hitFailure: false,
  durationSeconds: null,
  notes: null,
  loggedAt: at,
);

void main() {
  final now = DateTime(2026, 10, 20, 12);
  final logs = [
    _log(1, 100, DateTime(2026, 10, 18, 8)),
    _log(2, 105, DateTime(2026, 10, 18, 8, 10)),
    _log(3, null, DateTime(2026, 10, 18, 8, 20)), // unweighted: ignored
    _log(4, 95, DateTime(2026, 10, 1, 8)),
    _log(5, 80, DateTime(2026, 5, 1, 8)), // outside 3M
  ];

  test('dailyBestWeights keeps each day\'s heaviest set, oldest first', () {
    expect(dailyBestWeights(logs, range: StrengthRange.quarter, now: now), [
      (DateTime(2026, 10, 1), 95.0),
      (DateTime(2026, 10, 18), 105.0),
    ]);
  });

  test('dailyBestWeights honours the one-tap range', () {
    expect(
      dailyBestWeights(logs, range: StrengthRange.month, now: now),
      hasLength(2),
    );
    expect(dailyBestWeights(logs, range: StrengthRange.all, now: now).first, (
      DateTime(2026, 5, 1),
      80.0,
    ));
  });
}
