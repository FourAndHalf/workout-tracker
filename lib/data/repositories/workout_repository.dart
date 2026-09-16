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
    return await db.into(db.workoutSessions).insert(
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
    await (db.update(db.workoutSessions)..where((s) => s.id.equals(sessionId))).write(
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
    String? notes,
  }) async {
    return await db.into(db.exerciseLogs).insert(
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

  /// Get max weight history for a specific exercise over time
  Future<List<ExerciseLog>> getMaxWeightLogsForExercise(String exerciseId) async {
    return (db.select(db.exerciseLogs)
          ..where((l) => l.exerciseId.equals(exerciseId) & l.weight.isNotNull())
          ..orderBy([(l) => OrderingTerm.desc(l.weight)]))
        .get();
  }
}
