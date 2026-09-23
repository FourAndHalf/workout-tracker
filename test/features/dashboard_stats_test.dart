import 'package:flutter_test/flutter_test.dart';

import 'package:fitness_tracker/data/database/app_database.dart';
import 'package:fitness_tracker/features/home/home_providers.dart';
import 'package:fitness_tracker/features/home/widgets/dashboard_stats.dart';

WorkoutSession _session(int id, DateTime day) => WorkoutSession(
  id: id,
  programId: 'p',
  weekId: 'w',
  dayId: 'd',
  dayName: 'Arms',
  startedAt: day,
  finishedAt: day.add(const Duration(hours: 1)),
  notes: null,
);

DashboardAnalytics _analytics(List<DateTime> days, DateTime now) =>
    DashboardAnalytics.fromData(
      sessions: [
        for (var i = 0; i < days.length; i++) _session(i, days[i]),
      ],
      logs: const [],
      now: now,
    );

void main() {
  // 2026-09-16 is a Wednesday.
  final now = DateTime(2026, 9, 16, 18);

  test('streak survives an untrained today and tracks the best run', () {
    final analytics = _analytics([
      DateTime(2026, 9, 14),
      DateTime(2026, 9, 15),
      DateTime(2026, 9, 1),
      DateTime(2026, 9, 2),
      DateTime(2026, 9, 3),
    ], now);

    expect(analytics.currentStreak, 2);
    expect(analytics.bestStreak, 3);
    expect(analytics.trainedToday, isFalse);
    expect(analytics.daysSinceLastWorkout, 1);
    expect(analytics.trainedWeekdays, {1, 2});
  });

  test('volumeTrend compares against last week', () {
    expect(volumeTrend(150, 100), 50);
    expect(volumeTrend(50, 100), -50);
    expect(volumeTrend(50, 0), isNull);
  });

  test('dashboardNudge adapts to where the user is', () {
    expect(dashboardNudge(_analytics([], now)), contains('day one'));
    expect(
      dashboardNudge(_analytics([DateTime(2026, 9, 16)], now)),
      contains('recover'),
    );
    expect(
      dashboardNudge(_analytics([DateTime(2026, 9, 15)], now)),
      contains('1-day streak'),
    );
    expect(
      dashboardNudge(_analytics([DateTime(2026, 9, 10)], now)),
      contains('6 days'),
    );
  });
}
