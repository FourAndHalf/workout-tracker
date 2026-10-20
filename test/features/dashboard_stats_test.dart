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
      sessions: [for (var i = 0; i < days.length; i++) _session(i, days[i])],
      logs: const [],
      now: now,
    );

void main() {
  trendTests();
  paceTests();

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

ExerciseLog _log(int id, String name, double weight, int reps, DateTime at) =>
    ExerciseLog(
      id: id,
      sessionId: 1,
      blockId: 'b',
      exerciseId: name,
      exerciseName: name,
      blockType: 'straight',
      logMode: 'weightReps',
      setNumber: 1,
      weight: weight,
      reps: reps,
      targetReps: reps,
      hitFailure: false,
      durationSeconds: null,
      notes: null,
      loggedAt: at,
    );

void trendTests() {
  final now = DateTime(2026, 9, 16, 18); // Wednesday

  test('weekly trend series end with the current week', () {
    final analytics = DashboardAnalytics.fromData(
      sessions: [
        _session(1, DateTime(2026, 9, 15, 7)),
        _session(2, DateTime(2026, 9, 8, 7)),
        _session(3, DateTime(2026, 9, 9, 7)),
      ],
      logs: [
        _log(1, 'Squat', 100, 5, DateTime(2026, 9, 15, 7)),
        _log(2, 'Squat', 90, 5, DateTime(2026, 9, 8, 7)),
        // Older than the 12-week window: ignored.
        _log(3, 'Squat', 50, 5, DateTime(2026, 1, 5)),
      ],
      now: now,
    );

    expect(analytics.weekStarts, hasLength(DashboardAnalytics.trendWeeks));
    expect(analytics.weekStarts.last, DateTime(2026, 9, 14));
    expect(analytics.weekStarts.first, DateTime(2026, 6, 29));
    expect(analytics.weeklyVolumes.last, 500);
    expect(analytics.weeklyVolumes[10], 450);
    expect(analytics.weeklySessions.last, 1);
    expect(analytics.weeklySessions[10], 2);
    expect(analytics.totalWorkouts, 3);
    expect(analytics.minutesThisWeek, 60);
    expect(analytics.trainingDays, contains(DateTime(2026, 9, 9)));
    expect(analytics.goalHitRate, 0);
  });

  test('personal records need a baseline and a heavier later set', () {
    final analytics = DashboardAnalytics.fromData(
      sessions: const [],
      logs: [
        _log(1, 'Bench', 60, 5, DateTime(2026, 8, 1)),
        _log(2, 'Bench', 65, 5, DateTime(2026, 9, 1)),
        _log(3, 'Bench', 70, 3, DateTime(2026, 9, 10)),
        _log(4, 'Row', 50, 8, DateTime(2026, 9, 12)), // baseline only
        _log(5, 'Curl', 20, 8, DateTime(2026, 6, 1)),
        _log(6, 'Curl', 18, 8, DateTime(2026, 9, 14)), // not heavier
      ],
      now: now,
    );

    expect(analytics.personalRecords, hasLength(1));
    final record = analytics.personalRecords.single;
    expect(record.exerciseName, 'Bench');
    expect(record.weight, 70);
    expect(record.previousBest, 60);
    expect(record.achievedAt, DateTime(2026, 9, 10));
  });

  test('nextWorkoutMilestone steps up then counts in fifties', () {
    expect(nextWorkoutMilestone(0), 1);
    expect(nextWorkoutMilestone(1), 5);
    expect(nextWorkoutMilestone(24), 25);
    expect(nextWorkoutMilestone(100), 150);
    expect(nextWorkoutMilestone(149), 150);
  });

  test('number formatting groups thousands and compacts tonnes', () {
    expect(groupThousands(1234567), '1,234,567');
    expect(groupThousands(999), '999');
    expect(compactKg(4500), '4,500 kg');
    expect(compactKg(12400), '12.4t');
  });
}

void paceTests() {
  test('volume trend compares against last week up to the same moment', () {
    // Tuesday noon: last week had 500 kg by Tuesday noon, 1,500 kg overall.
    final analytics = DashboardAnalytics.fromData(
      sessions: const [],
      logs: [
        _log(1, 'Squat', 100, 5, DateTime(2026, 9, 8, 8)),
        _log(2, 'Squat', 100, 10, DateTime(2026, 9, 10, 8)),
        _log(3, 'Squat', 100, 6, DateTime(2026, 9, 15, 8)),
      ],
      now: DateTime(2026, 9, 15, 12),
    );

    expect(analytics.volumeLastWeek, 1500);
    expect(analytics.volumeLastWeekToDate, 500);
    expect(
      volumeTrend(analytics.volumeThisWeek, analytics.volumeLastWeekToDate),
      20,
    );
  });
}
