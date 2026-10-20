import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/database/app_database.dart';
import '../../main.dart';

class MotivationQuote {
  final String quote;
  final String source;

  const MotivationQuote({required this.quote, required this.source});
}

const _motivationQuotes = [
  MotivationQuote(
    quote: 'We are what we repeatedly do. Excellence is a habit.',
    source: 'Aristotle',
  ),
  MotivationQuote(
    quote: 'The secret of getting ahead is getting started.',
    source: 'Mark Twain',
  ),
  MotivationQuote(
    quote: 'It is never too late to be what you might have been.',
    source: 'George Eliot',
  ),
  MotivationQuote(
    quote: 'The body achieves what the mind believes.',
    source: 'Napoleon Hill',
  ),
  MotivationQuote(
    quote: 'Small disciplines repeated with consistency lead to great achievements.',
    source: 'John C. Maxwell',
  ),
  MotivationQuote(
    quote: 'Success is the sum of small efforts, repeated day in and day out.',
    source: 'Robert Collier',
  ),
  MotivationQuote(
    quote: 'The difference between try and triumph is just a little umph!',
    source: 'Marvin Phillips',
  ),
];

/// "Good morning" / "Good afternoon" / "Good evening" for the header.
String greetingFor(DateTime now) => now.hour < 12
    ? 'Good morning'
    : now.hour < 17
    ? 'Good afternoon'
    : 'Good evening';

MotivationQuote dailyMotivationQuote(DateTime date) {
  final dayNumber = DateTime(
    date.year,
    date.month,
    date.day,
  ).difference(DateTime(2024, 1, 1)).inDays;
  return _motivationQuotes[dayNumber.abs() % _motivationQuotes.length];
}

/// An exercise whose best weight beat every earlier session's best.
class PersonalRecord {
  final String exerciseName;
  final double weight;
  final double previousBest;
  final DateTime achievedAt;

  const PersonalRecord({
    required this.exerciseName,
    required this.weight,
    required this.previousBest,
    required this.achievedAt,
  });
}

/// Total-workout milestones; past the list, every 50 workouts is one.
int nextWorkoutMilestone(int totalWorkouts) {
  const steps = [1, 5, 10, 25, 50, 75, 100];
  for (final step in steps) {
    if (totalWorkouts < step) return step;
  }
  return (totalWorkouts ~/ 50 + 1) * 50;
}

class DashboardAnalytics {
  final int workoutsThisWeek;
  final int setsThisWeek;
  final double volumeThisWeek;
  final int currentStreak;
  final String? latestWorkoutName;
  final String? topExerciseName;
  final double? topExerciseWeight;

  /// Sessions per week the dashboard treats as "on track".
  static const weeklyGoal = 4;

  /// Weekdays (1 = Monday ... 7 = Sunday) trained in the current week.
  final Set<int> trainedWeekdays;
  final bool trainedToday;
  final double volumeLastWeek;

  /// Last week's volume up to the same point in the week as [now], so a
  /// half-finished week is compared like for like.
  final double volumeLastWeekToDate;
  final int bestStreak;
  final int? daysSinceLastWorkout;

  /// Number of weeks the trend charts cover.
  static const trendWeeks = 12;

  final int totalWorkouts;

  /// Oldest first; the last entry is the current week.
  final List<DateTime> weekStarts;
  final List<double> weeklyVolumes;
  final List<int> weeklySessions;

  /// Calendar days (midnight) with at least one completed workout.
  final Set<DateTime> trainingDays;
  final int minutesThisWeek;

  /// Most recent first, at most three, from the last 30 days.
  final List<PersonalRecord> personalRecords;

  const DashboardAnalytics({
    required this.workoutsThisWeek,
    required this.setsThisWeek,
    required this.volumeThisWeek,
    required this.currentStreak,
    this.latestWorkoutName,
    this.topExerciseName,
    this.topExerciseWeight,
    this.trainedWeekdays = const {},
    this.trainedToday = false,
    this.volumeLastWeek = 0,
    this.volumeLastWeekToDate = 0,
    this.bestStreak = 0,
    this.daysSinceLastWorkout,
    this.totalWorkouts = 0,
    this.weekStarts = const [],
    this.weeklyVolumes = const [],
    this.weeklySessions = const [],
    this.trainingDays = const {},
    this.minutesThisWeek = 0,
    this.personalRecords = const [],
  });

  /// Share of the last [trendWeeks] weeks that reached [weeklyGoal].
  double get goalHitRate => weeklySessions.isEmpty
      ? 0
      : weeklySessions.where((count) => count >= weeklyGoal).length /
            weeklySessions.length;

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
    // A streak stays alive until a full day passes without training, so if
    // today is still empty we count back from yesterday.
    var streak = 0;
    var streakDay = workoutDates.contains(today)
        ? today
        : today.subtract(const Duration(days: 1));
    while (workoutDates.contains(streakDay)) {
      streak++;
      streakDay = streakDay.subtract(const Duration(days: 1));
    }

    final sortedDates = workoutDates.toList()..sort();
    var bestStreak = 0;
    var run = 0;
    DateTime? previous;
    for (final date in sortedDates) {
      run = previous != null && date.difference(previous).inDays == 1
          ? run + 1
          : 1;
      if (run > bestStreak) bestStreak = run;
      previous = date;
    }

    final lastWeekStart = weekStart.subtract(const Duration(days: 7));
    final volumeLastWeek = logs
        .where(
          (log) =>
              !log.loggedAt.isBefore(lastWeekStart) &&
              log.loggedAt.isBefore(weekStart),
        )
        .fold<double>(
          0,
          (total, log) => total + ((log.weight ?? 0) * (log.reps ?? 0)),
        );
    final trainedWeekdays = {
      for (final session in sessionsThisWeek) session.startedAt.weekday,
    };
    final lastDate = sortedDates.isEmpty ? null : sortedDates.last;

    double volumeOf(ExerciseLog log) => (log.weight ?? 0) * (log.reps ?? 0);
    final weekStarts = [
      for (var i = trendWeeks - 1; i >= 0; i--)
        DateTime(weekStart.year, weekStart.month, weekStart.day - 7 * i),
    ];
    int weekIndexOf(DateTime at) {
      for (var i = weekStarts.length - 1; i >= 0; i--) {
        if (!at.isBefore(weekStarts[i])) return i;
      }
      return -1;
    }

    final weeklyVolumes = List<double>.filled(trendWeeks, 0);
    for (final log in logs) {
      final index = weekIndexOf(log.loggedAt);
      if (index >= 0) weeklyVolumes[index] += volumeOf(log);
    }
    final lastWeekCutoff = lastWeekStart.add(now.difference(weekStart));
    final volumeLastWeekToDate = logs
        .where(
          (log) =>
              !log.loggedAt.isBefore(lastWeekStart) &&
              log.loggedAt.isBefore(lastWeekCutoff),
        )
        .fold<double>(0, (total, log) => total + volumeOf(log));
    final weeklySessions = List<int>.filled(trendWeeks, 0);
    for (final session in sessions) {
      final index = weekIndexOf(session.startedAt);
      if (index >= 0) weeklySessions[index]++;
    }

    final minutesThisWeek = sessionsThisWeek.fold<int>(0, (total, session) {
      final finished = session.finishedAt;
      if (finished == null) return total;
      return total + finished.difference(session.startedAt).inMinutes;
    });

    return DashboardAnalytics(
      workoutsThisWeek: sessionsThisWeek.length,
      setsThisWeek: logsThisWeek.length,
      volumeThisWeek: logsThisWeek.fold<double>(
        0,
        (total, log) => total + volumeOf(log),
      ),
      currentStreak: streak,
      latestWorkoutName: sessions.isEmpty ? null : sessions.first.dayName,
      topExerciseName: topExerciseName,
      topExerciseWeight: topExerciseWeight,
      trainedWeekdays: trainedWeekdays,
      trainedToday: workoutDates.contains(today),
      volumeLastWeek: volumeLastWeek,
      volumeLastWeekToDate: volumeLastWeekToDate,
      bestStreak: bestStreak,
      daysSinceLastWorkout: lastDate == null
          ? null
          : today.difference(lastDate).inDays,
      totalWorkouts: sessions.length,
      weekStarts: weekStarts,
      weeklyVolumes: weeklyVolumes,
      weeklySessions: weeklySessions,
      trainingDays: workoutDates,
      minutesThisWeek: minutesThisWeek,
      personalRecords: _recentPersonalRecords(logs, today),
    );
  }

  static List<PersonalRecord> _recentPersonalRecords(
    List<ExerciseLog> logs,
    DateTime today,
  ) {
    final since = DateTime(today.year, today.month, today.day - 30);
    final weighted = logs.where((log) => (log.weight ?? 0) > 0).toList()
      ..sort((a, b) => a.loggedAt.compareTo(b.loggedAt));
    final best = <String, double>{};
    final records = <String, PersonalRecord>{};
    for (final log in weighted) {
      final weight = log.weight!;
      final previous = best[log.exerciseName];
      // The first weight logged is a baseline, not a record.
      if (previous != null && weight > previous) {
        if (!log.loggedAt.isBefore(since)) {
          records[log.exerciseName] = PersonalRecord(
            exerciseName: log.exerciseName,
            weight: weight,
            previousBest: records[log.exerciseName]?.previousBest ?? previous,
            achievedAt: log.loggedAt,
          );
        }
      }
      if (previous == null || weight > previous) {
        best[log.exerciseName] = weight;
      }
    }
    final sorted = records.values.toList()
      ..sort((a, b) => b.achievedAt.compareTo(a.achievedAt));
    return sorted.take(3).toList();
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
