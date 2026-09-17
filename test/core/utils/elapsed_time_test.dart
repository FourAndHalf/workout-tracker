import 'package:fitness_tracker/core/utils/elapsed_time.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('elapsedSecondsSince', () {
    test('returns the wall-clock difference in seconds', () {
      final start = DateTime(2026, 1, 1, 10, 0, 0);
      final now = DateTime(2026, 1, 1, 10, 1, 5);
      expect(elapsedSecondsSince(start, now: now), 65);
    });

    test('is unaffected by a long gap with no ticks, e.g. screen off', () {
      // Simulates the screen being off for 10 minutes: no periodic ticks
      // fired, but the wall-clock difference is still correct once the UI
      // resumes and recomputes from the stored start time.
      final start = DateTime(2026, 1, 1, 10, 0, 0);
      final resumed = start.add(const Duration(minutes: 10));
      expect(elapsedSecondsSince(start, now: resumed), 600);
    });

    test('clamps to zero if now is before start', () {
      final start = DateTime(2026, 1, 1, 10, 0, 0);
      final now = start.subtract(const Duration(seconds: 5));
      expect(elapsedSecondsSince(start, now: now), 0);
    });
  });
}
