import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitness_tracker/features/workout/providers/active_workout_session_notifier.dart';

void main() {
  test('starts with null state', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(activeWorkoutSessionProvider), isNull);
  });

  test('start() sets banner info with correct dayId/dayName/startTime', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final startTime = DateTime(2026, 1, 1, 9, 0, 0);

    container
        .read(activeWorkoutSessionProvider.notifier)
        .start(dayId: 'w1-arms', dayName: 'Arms', startTime: startTime);

    final info = container.read(activeWorkoutSessionProvider);
    expect(info, isNotNull);
    expect(info!.dayId, 'w1-arms');
    expect(info.dayName, 'Arms');
    expect(info.startTime, startTime);
  });

  test('clear() resets state to null', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container
        .read(activeWorkoutSessionProvider.notifier)
        .start(dayId: 'w1-arms', dayName: 'Arms', startTime: DateTime.now());
    container.read(activeWorkoutSessionProvider.notifier).clear();

    expect(container.read(activeWorkoutSessionProvider), isNull);
  });
}
