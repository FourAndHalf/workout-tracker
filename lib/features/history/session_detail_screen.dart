import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../data/database/app_database.dart';
import '../../main.dart';

class SessionDetailScreen extends ConsumerWidget {
  final int sessionId;

  const SessionDetailScreen({super.key, required this.sessionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repository = ref.watch(workoutRepositoryProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Session details')),
      body: FutureBuilder<List<WorkoutSession>>(
        future: repository.getCompletedSessions(),
        builder: (context, sessionSnapshot) {
          if (!sessionSnapshot.hasData)
            return const Center(child: CircularProgressIndicator());
          final session = sessionSnapshot.data!
              .where((item) => item.id == sessionId)
              .firstOrNull;
          if (session == null)
            return const Center(child: Text('Session not found'));
          return FutureBuilder<List<ExerciseLog>>(
            future: repository.getLogsForSession(sessionId),
            builder: (context, logSnapshot) {
              if (!logSnapshot.hasData)
                return const Center(child: CircularProgressIndicator());
              final logs = logSnapshot.data!;
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    session.dayName,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${_dateLabel(session.startedAt)}  •  ${_duration(session)}',
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                  if (session.notes?.isNotEmpty == true)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(session.notes!),
                    ),
                  const SizedBox(height: 20),
                  Text(
                    '${logs.length} logged set${logs.length == 1 ? '' : 's'}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  if (logs.isEmpty)
                    const Text('No sets were logged for this session.'),
                  ...logs.map(
                    (log) => Card(
                      child: ListTile(
                        leading: Text('${log.setNumber}'),
                        title: Text(log.exerciseName),
                        subtitle: Text(_logSummary(log)),
                        trailing: log.hitFailure
                            ? const Icon(Icons.flag, color: AppColors.warning)
                            : null,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  FutureBuilder<List<WorkoutSession>>(
                    future: repository.getCompletedSessions(),
                    builder: (context, previousSnapshot) {
                      final previous = previousSnapshot.data
                          ?.where(
                            (item) =>
                                item.dayName == session.dayName &&
                                item.startedAt.isBefore(session.startedAt),
                          )
                          .firstOrNull;
                      if (previous == null) return const SizedBox.shrink();
                      return FutureBuilder<List<ExerciseLog>>(
                        future: repository.getLogsForSession(previous.id),
                        builder: (context, comparisonSnapshot) {
                          if (!comparisonSnapshot.hasData) {
                            return const LinearProgressIndicator();
                          }
                          final previousByExercise = <String, ExerciseLog>{};
                          for (final previousLog in comparisonSnapshot.data!) {
                            final current =
                                previousByExercise[previousLog.exerciseName];
                            if (current == null ||
                                (previousLog.weight ?? 0) >
                                    (current.weight ?? 0)) {
                              previousByExercise[previousLog.exerciseName] =
                                  previousLog;
                            }
                          }
                          return Card(
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Compared with ${_dateLabel(previous.startedAt)}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  ...logs.map((currentLog) {
                                    final oldLog =
                                        previousByExercise[currentLog
                                            .exerciseName];
                                    if (oldLog == null)
                                      return Text(
                                        '${currentLog.exerciseName}: new exercise',
                                      );
                                    final weightDelta =
                                        (currentLog.weight ?? 0) -
                                        (oldLog.weight ?? 0);
                                    final repsDelta =
                                        (currentLog.reps ?? 0) -
                                        (oldLog.reps ?? 0);
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 4),
                                      child: Text(
                                        '${currentLog.exerciseName}: ${_delta(weightDelta)} kg, ${_delta(repsDelta)} reps',
                                      ),
                                    );
                                  }),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

String _logSummary(ExerciseLog log) {
  final parts = <String>[];
  if (log.weight != null) parts.add('${log.weight!.toStringAsFixed(1)} kg');
  if (log.reps != null) parts.add('${log.reps} reps');
  if (log.durationSeconds != null) parts.add('${log.durationSeconds}s');
  return parts.isEmpty ? 'Logged' : parts.join('  •  ');
}

String _dateLabel(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
String _duration(WorkoutSession session) => session.finishedAt == null
    ? 'In progress'
    : '${session.finishedAt!.difference(session.startedAt).inMinutes} min';

String _delta(num value) => value >= 0 ? '+$value' : '$value';
