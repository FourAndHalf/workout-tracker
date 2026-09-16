import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/database/app_database.dart';
import '../../main.dart';

class DashboardAnalytics {
  final int workoutsThisWeek;
  final int setsThisWeek;
  final double volumeThisWeek;
  final int currentStreak;
  final String? latestWorkoutName;
  final String? topExerciseName;
  final double? topExerciseWeight;

  const DashboardAnalytics({
    required this.workoutsThisWeek,
    required this.setsThisWeek,
    required this.volumeThisWeek,
    required this.currentStreak,
    this.latestWorkoutName,
    this.topExerciseName,
    this.topExerciseWeight,
  });

  factory DashboardAnalytics.fromData({
    required List<WorkoutSession> sessions,
    required List<ExerciseLog> logs,
    required DateTime now,
  }) {
    final today = DateTime(now.year, now.month, now.day);
    final weekStart = today.subtract(Duration(days: today.weekday - 1));
    final sessionsThisWeek = sessions
        .where((session) => !session.startedAt.isBefore(weekStart))
        .toList();
    final logsThisWeek = logs
        .where((log) => !log.loggedAt.isBefore(weekStart))
        .toList();
    final weightsByExercise = <String, double>{};

    for (final log in logsThisWeek) {
      final weight = log.weight;
      if (weight != null &&
          weight > (weightsByExercise[log.exerciseName] ?? 0)) {
        weightsByExercise[log.exerciseName] = weight;
      }
    }

    String? topExerciseName;
    double? topExerciseWeight;
    for (final entry in weightsByExercise.entries) {
      if (topExerciseWeight == null || entry.value > topExerciseWeight) {
        topExerciseName = entry.key;
        topExerciseWeight = entry.value;
      }
    }

    final workoutDates = sessions
        .map(
          (session) => DateTime(
            session.startedAt.year,
            session.startedAt.month,
            session.startedAt.day,
          ),
        )
        .toSet();
    var streak = 0;
    var streakDay = today;
    while (workoutDates.contains(streakDay)) {
      streak++;
      streakDay = streakDay.subtract(const Duration(days: 1));
    }

    return DashboardAnalytics(
      workoutsThisWeek: sessionsThisWeek.length,
      setsThisWeek: logsThisWeek.length,
      volumeThisWeek: logsThisWeek.fold<double>(
        0,
        (total, log) => total + ((log.weight ?? 0) * (log.reps ?? 0)),
      ),
      currentStreak: streak,
      latestWorkoutName: sessions.isEmpty ? null : sessions.first.dayName,
      topExerciseName: topExerciseName,
      topExerciseWeight: topExerciseWeight,
    );
  }
}

final dashboardAnalyticsProvider = FutureProvider<DashboardAnalytics>((
  ref,
) async {
  final repository = ref.watch(workoutRepositoryProvider);
  final sessions = await repository.getCompletedSessions();
  final logs = await repository.getAllExerciseLogs();

  return DashboardAnalytics.fromData(
    sessions: sessions,
    logs: logs,
    now: DateTime.now(),
  );
});
