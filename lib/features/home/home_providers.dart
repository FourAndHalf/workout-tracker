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

MotivationQuote dailyMotivationQuote(DateTime date) {
  final dayNumber = DateTime(
    date.year,
    date.month,
    date.day,
  ).difference(DateTime(2024, 1, 1)).inDays;
  return _motivationQuotes[dayNumber.abs() % _motivationQuotes.length];
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
  final int bestStreak;
  final int? daysSinceLastWorkout;

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
    this.bestStreak = 0,
    this.daysSinceLastWorkout,
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
      trainedWeekdays: trainedWeekdays,
      trainedToday: workoutDates.contains(today),
      volumeLastWeek: volumeLastWeek,
      bestStreak: bestStreak,
      daysSinceLastWorkout: lastDate == null
          ? null
          : today.difference(lastDate).inDays,
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
