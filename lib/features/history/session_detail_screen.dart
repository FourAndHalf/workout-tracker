import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/day_app_bar.dart';
import '../../core/widgets/ledger.dart';
import '../../data/database/app_database.dart';
import '../../data/repositories/workout_repository.dart';
import '../../main.dart';
import '../home/widgets/dashboard_stats.dart' show compactKg;

class _SessionData {
  final WorkoutSession session;
  final List<ExerciseLog> logs;

  /// Best set per exercise in the previous session with the same name.
  final Map<String, ExerciseLog> previousBest;
  final DateTime? previousDate;

  const _SessionData({
    required this.session,
    required this.logs,
    required this.previousBest,
    required this.previousDate,
  });
}

Future<_SessionData?> _load(WorkoutRepository repository, int sessionId) async {
  final sessions = await repository.getCompletedSessions();
  final session = sessions.where((item) => item.id == sessionId).firstOrNull;
  if (session == null) return null;
  final logs = await repository.getLogsForSession(sessionId);
  final previous = sessions
      .where(
        (item) =>
            item.dayName == session.dayName &&
            item.startedAt.isBefore(session.startedAt),
      )
      .firstOrNull;
  final previousBest = <String, ExerciseLog>{};
  if (previous != null) {
    for (final log in await repository.getLogsForSession(previous.id)) {
      final current = previousBest[log.exerciseName];
      if (current == null || (log.weight ?? 0) > (current.weight ?? 0)) {
        previousBest[log.exerciseName] = log;
      }
    }
  }
  return _SessionData(
    session: session,
    logs: logs,
    previousBest: previousBest,
    previousDate: previous?.startedAt,
  );
}

class SessionDetailScreen extends ConsumerWidget {
  final int sessionId;

  const SessionDetailScreen({super.key, required this.sessionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repository = ref.watch(workoutRepositoryProvider);
    return Scaffold(
      appBar: AppBar(),
      body: FutureBuilder<_SessionData?>(
        future: _load(repository, sessionId),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snapshot.data;
          if (data == null) {
            return const Center(child: Text('Session not found'));
          }
          return _SessionBody(data: data);
        },
      ),
    );
  }
}

class _SessionBody extends StatelessWidget {
  final _SessionData data;

  const _SessionBody({required this.data});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final session = data.session;
    final logs = data.logs;
    final volume = logs.fold<double>(
      0,
      (total, log) => total + (log.weight ?? 0) * (log.reps ?? 0),
    );
    final byExercise = <String, List<ExerciseLog>>{};
    for (final log in logs) {
      byExercise.putIfAbsent(log.exerciseName, () => []).add(log);
    }
    final date = session.startedAt;
    final summary = [
      ('Duration', _duration(session)),
      ('Sets', '${logs.length}'),
      ('Volume', volume > 0 ? compactKg(volume) : '—'),
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      children: [
        Text(session.dayName, style: textTheme.headlineSmall),
        const SizedBox(height: 2),
        Text(
          '${weekdayLabel(date)}, ${shortDateLabel(date)} ${date.year} · ${_time(date)}',
          style: textTheme.bodyMedium?.copyWith(color: colors.textSecondary),
        ),
        if (session.notes?.isNotEmpty == true) ...[
          const SizedBox(height: 12),
          Text(session.notes!, style: textTheme.bodyMedium),
        ],
        const SizedBox(height: 16),
        AppCard(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
          child: IntrinsicHeight(
            child: Row(
              children: [
                for (var i = 0; i < summary.length; i++) ...[
                  if (i > 0) VerticalDivider(width: 1, color: colors.border),
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          summary[i].$1,
                          style: textTheme.bodySmall?.copyWith(
                            color: colors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(summary[i].$2, style: AppText.metricCard),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        if (data.previousDate != null) ...[
          const SizedBox(height: 8),
          Text(
            'Changes compared with ${shortDateLabel(data.previousDate!)}',
            style: textTheme.bodySmall?.copyWith(color: colors.textSecondary),
          ),
        ],
        const SizedBox(height: 12),
        if (logs.isEmpty)
          Text(
            'No sets were logged for this session.',
            style: textTheme.bodyMedium?.copyWith(color: colors.textSecondary),
          ),
        for (final entry in byExercise.entries) ...[
          _ExerciseLedger(
            name: entry.key,
            logs: entry.value,
            previousBest: data.previousBest[entry.key],
            hasPrevious: data.previousDate != null,
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

/// One exercise's sets as a ledger: tabular columns in an inner panel, with
/// the change in best weight against the previous session.
class _ExerciseLedger extends StatelessWidget {
  final String name;
  final List<ExerciseLog> logs;
  final ExerciseLog? previousBest;
  final bool hasPrevious;

  const _ExerciseLedger({
    required this.name,
    required this.logs,
    required this.previousBest,
    required this.hasPrevious,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final best = logs.fold<double>(
      0,
      (max, log) => (log.weight ?? 0) > max ? log.weight! : max,
    );
    final previous = previousBest?.weight;
    final change = previous == null || best == 0 ? null : best - previous;
    final timed = logs.every((log) => log.durationSeconds != null);

    Widget? badge;
    if (hasPrevious && previousBest == null) {
      badge = StatusBadge(
        'New',
        foreground: colors.info,
        background: colors.infoContainer,
      );
    } else if (change != null && change != 0) {
      badge = DeltaPill(change > 0 ? 1 : -1, label: _kg(change.abs()));
    }

    final header = AppText.labelUppercase.copyWith(color: colors.textSecondary);
    final cell = AppText.metricTable.copyWith(fontWeight: FontWeight.w400);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ModuleHeader(
            name,
            subtitle: '${logs.length} ${logs.length == 1 ? 'set' : 'sets'}',
            trailing: badge,
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    SizedBox(width: 44, child: Text('SET', style: header)),
                    Expanded(
                      child: Text(
                        timed ? 'TIME' : 'KG',
                        textAlign: TextAlign.right,
                        style: header,
                      ),
                    ),
                    if (!timed)
                      Expanded(
                        child: Text(
                          'REPS',
                          textAlign: TextAlign.right,
                          style: header,
                        ),
                      ),
                    const SizedBox(width: 28),
                  ],
                ),
                const SizedBox(height: 6),
                for (final log in logs)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 44,
                          child: Text(
                            log.setNumber.toString().padLeft(2, '0'),
                            style: cell.copyWith(color: colors.textSecondary),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            timed
                                ? _clock(log.durationSeconds!)
                                : log.weight == null
                                ? '—'
                                : _number(log.weight!),
                            textAlign: TextAlign.right,
                            style: cell,
                          ),
                        ),
                        if (!timed)
                          Expanded(
                            child: Text(
                              log.reps == null ? '—' : '${log.reps}',
                              textAlign: TextAlign.right,
                              style: cell,
                            ),
                          ),
                        SizedBox(
                          width: 28,
                          child: log.hitFailure
                              ? Tooltip(
                                  message: 'Reached failure',
                                  child: Icon(
                                    Icons.flag_outlined,
                                    size: 14,
                                    color: colors.warning,
                                  ),
                                )
                              : null,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          if (previous != null) ...[
            const SizedBox(height: 8),
            Text(
              'Previous best ${_kg(previous)}',
              style: textTheme.bodySmall?.copyWith(color: colors.textSecondary),
            ),
          ],
        ],
      ),
    );
  }
}

String _number(double value) => value == value.roundToDouble()
    ? value.toStringAsFixed(0)
    : value.toStringAsFixed(1);

String _kg(double kg) => '${_number(kg)} kg';

String _clock(int seconds) =>
    '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';

String _time(DateTime date) =>
    '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

String _duration(WorkoutSession session) => session.finishedAt == null
    ? 'In progress'
    : '${session.finishedAt!.difference(session.startedAt).inMinutes} min';
