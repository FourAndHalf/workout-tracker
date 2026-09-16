import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitness_tracker/services/daily_workout_alarm_service.dart';

void main() {
  test('alarm settings copyWith preserves values', () {
    const initial = DailyWorkoutAlarmSettings(
      enabled: true,
      time: TimeOfDay(hour: 7, minute: 30),
    );

    final updated = initial.copyWith(enabled: false);

    expect(updated.enabled, isFalse);
    expect(updated.time, const TimeOfDay(hour: 7, minute: 30));
    expect(updated.tuneId, 'morning_energy');

    final tuned = initial.copyWith(tuneId: 'beast_mode');
    expect(tuned.tuneId, 'beast_mode');
  });
}
