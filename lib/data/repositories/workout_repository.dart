import 'package:drift/drift.dart';

import '../database/app_database.dart';

class WorkoutRepository {
  final AppDatabase db;

  WorkoutRepository(this.db);

  /// Start a new workout session
  Future<int> startSession({
    required String programId,
    required String weekId,
    required String dayId,
    required String dayName,
  }) async {
    return await db
        .into(db.workoutSessions)
        .insert(
          WorkoutSessionsCompanion.insert(
            programId: programId,
            weekId: weekId,
            dayId: dayId,
            dayName: dayName,
            startedAt: Value(DateTime.now()),
          ),
        );
  }

  /// Finish an active workout session
  Future<void> finishSession(int sessionId, {String? notes}) async {
    await (db.update(
      db.workoutSessions,
    )..where((s) => s.id.equals(sessionId))).write(
      WorkoutSessionsCompanion(
        finishedAt: Value(DateTime.now()),
        notes: Value(notes),
      ),
    );
  }

  /// Get active session (if any)
  Future<WorkoutSession?> getActiveSession() async {
    return (db.select(db.workoutSessions)
          ..where((s) => s.finishedAt.isNull())
          ..orderBy([(s) => OrderingTerm.desc(s.startedAt)])
          ..limit(1))
        .getSingleOrNull();
  }

  /// Log a single set for an exercise
  Future<int> logExerciseSet({
    required int sessionId,
    required String blockId,
    required String exerciseId,
    required String exerciseName,
    required String blockType,
    required String logMode,
    required int setNumber,
    double? weight,
    int? reps,
    int? targetReps,
    bool hitFailure = false,
    int? durationSeconds,
    double? distanceMeters,
    String? notes,
  }) async {
    return await db
        .into(db.exerciseLogs)
        .insert(
          ExerciseLogsCompanion.insert(
            sessionId: sessionId,
            blockId: blockId,
            exerciseId: exerciseId,
            exerciseName: exerciseName,
            blockType: blockType,
            logMode: logMode,
            setNumber: setNumber,
            weight: Value(weight),
            reps: Value(reps),
            targetReps: Value(targetReps),
            hitFailure: Value(hitFailure),
            durationSeconds: Value(durationSeconds),
            distanceMeters: Value(distanceMeters),
            notes: Value(notes),
            loggedAt: Value(DateTime.now()),
          ),
        );
  }

  /// Get all exercise logs for a given session
  Future<List<ExerciseLog>> getLogsForSession(int sessionId) async {
    return (db.select(db.exerciseLogs)
          ..where((l) => l.sessionId.equals(sessionId))
          ..orderBy([(l) => OrderingTerm.asc(l.loggedAt)]))
        .get();
  }

  /// Get past completed sessions (sorted newest first)
  Future<List<WorkoutSession>> getCompletedSessions() async {
    return (db.select(db.workoutSessions)
          ..where((s) => s.finishedAt.isNotNull())
          ..orderBy([(s) => OrderingTerm.desc(s.startedAt)]))
        .get();
  }

  /// Get every persisted exercise log for dashboard analytics.
  Future<List<ExerciseLog>> getAllExerciseLogs() async {
    return (db.select(
      db.exerciseLogs,
    )..orderBy([(l) => OrderingTerm.desc(l.loggedAt)])).get();
  }

  /// Get max weight history for a specific exercise over time
  Future<List<ExerciseLog>> getMaxWeightLogsForExercise(
    String exerciseId,
  ) async {
    return (db.select(db.exerciseLogs)
          ..where((l) => l.exerciseId.equals(exerciseId) & l.weight.isNotNull())
          ..orderBy([(l) => OrderingTerm.desc(l.weight)]))
        .get();
  }

  Future<List<String>> getExerciseNames() async {
    final logs = await (db.select(
      db.exerciseLogs,
    )..orderBy([(log) => OrderingTerm.asc(log.exerciseName)])).get();
    return logs.map((log) => log.exerciseName).toSet().toList();
  }

  Future<List<ExerciseLog>> getExerciseHistory(String exerciseName) {
    return (db.select(db.exerciseLogs)
          ..where((log) => log.exerciseName.equals(exerciseName))
          ..orderBy([(log) => OrderingTerm.asc(log.loggedAt)]))
        .get();
  }

  Future<List<WeeklyVolume>> getWeeklyVolumes({int weeks = 8}) async {
    final logs = await getAllExerciseLogs();
    final today = DateTime.now();
    final currentMonday = _startOfWeek(today);
    final volumes = <WeeklyVolume>[];
    for (var index = weeks - 1; index >= 0; index--) {
      final start = currentMonday.subtract(Duration(days: index * 7));
      final end = start.add(const Duration(days: 7));
      final volume = logs
          .where(
            (log) =>
                !log.loggedAt.isBefore(start) && log.loggedAt.isBefore(end),
          )
          .fold<double>(
            0,
            (total, log) => total + ((log.weight ?? 0) * (log.reps ?? 0)),
          );
      volumes.add(WeeklyVolume(start: start, volume: volume));
    }
    return volumes;
  }

  /// Distance and moving time per week from `distance` logs, oldest first.
  Future<List<WeeklyEndurance>> getWeeklyEndurance({
    int weeks = 8,
    DateTime? now,
  }) async {
    final logs = await getAllExerciseLogs();
    final currentMonday = _startOfWeek(now ?? DateTime.now());
    final result = <WeeklyEndurance>[];
    for (var index = weeks - 1; index >= 0; index--) {
      final start = currentMonday.subtract(Duration(days: index * 7));
      final end = start.add(const Duration(days: 7));
      var meters = 0.0;
      var pacedMeters = 0.0;
      var pacedSeconds = 0;
      for (final log in logs) {
        final distance = log.distanceMeters;
        if (distance == null || distance <= 0) continue;
        if (log.loggedAt.isBefore(start) || !log.loggedAt.isBefore(end)) {
          continue;
        }
        meters += distance;
        final seconds = log.durationSeconds;
        if (seconds != null && seconds > 0) {
          pacedMeters += distance;
          pacedSeconds += seconds;
        }
      }
      result.add(
        WeeklyEndurance(
          start: start,
          distanceMeters: meters,
          pacedMeters: pacedMeters,
          pacedSeconds: pacedSeconds,
        ),
      );
    }
    return result;
  }

  Future<Set<DateTime>> getWorkoutDates() async {
    final sessions = await getCompletedSessions();
    return sessions
        .map(
          (session) => DateTime(
            session.startedAt.year,
            session.startedAt.month,
            session.startedAt.day,
          ),
        )
        .toSet();
  }

  DateTime _startOfWeek(DateTime date) {
    final day = DateTime(date.year, date.month, date.day);
    return day.subtract(Duration(days: day.weekday - 1));
  }
}

class WeeklyVolume {
  final DateTime start;
  final double volume;

  const WeeklyVolume({required this.start, required this.volume});
}

class WeeklyEndurance {
  final DateTime start;
  final double distanceMeters;

  /// Distance and time of the logs that carry a duration, for average pace.
  final double pacedMeters;
  final int pacedSeconds;

  const WeeklyEndurance({
    required this.start,
    required this.distanceMeters,
    this.pacedMeters = 0,
    this.pacedSeconds = 0,
  });

  double get distanceKm => distanceMeters / 1000;

  /// Average pace in seconds per km, or null without timed distance.
  double? get paceSecondsPerKm =>
      paceSecondsPerKmFor(pacedMeters, pacedSeconds);
}

/// Seconds per km for a distance covered in [seconds]; null when either
/// is missing.
double? paceSecondsPerKmFor(double? meters, int? seconds) {
  if (meters == null || seconds == null || meters <= 0 || seconds <= 0) {
    return null;
  }
  return seconds / (meters / 1000);
}

/// `5:42 /km`.
String formatPace(double secondsPerKm) {
  final total = secondsPerKm.round();
  return '${total ~/ 60}:${(total % 60).toString().padLeft(2, '0')} /km';
}

/// `400 m` under a kilometre, otherwise `5 km` / `7.5 km`.
String formatDistance(double meters) {
  if (meters < 1000) return '${meters.round()} m';
  final km = meters / 1000;
  final text = km.toStringAsFixed(2).replaceFirst(RegExp(r'\.?0+$'), '');
  return '$text km';
}
