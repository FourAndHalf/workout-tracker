import 'package:flutter_test/flutter_test.dart';
import 'package:fitness_tracker/services/daily_workout_alarm_service.dart';

void main() {
  test('lock-screen set action has a stable identifier', () {
    expect(
      DailyWorkoutAlarmService.activeWorkoutSetAction,
      'complete_workout_set',
    );
  });
}
