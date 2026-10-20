import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/day_app_bar.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/ledger.dart';
import '../../data/database/app_database.dart';
import '../../main.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  /// When true, renders without its own app bar (hosted by [ProgressHubScreen]).
  final bool embedded;

  const HistoryScreen({super.key, this.embedded = false});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  late Future<List<WorkoutSession>> _sessions;
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);

  @override
  void initState() {
    super.initState();
    _sessions = ref.read(workoutRepositoryProvider).getCompletedSessions();
  }

  void _refresh() {
    setState(() {
      _sessions = ref.read(workoutRepositoryProvider).getCompletedSessions();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.embedded
          ? null
          : AppBar(title: const Text('Workout History')),
      body: FutureBuilder<List<WorkoutSession>>(
        future: _sessions,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Unable to load workout history'));
          }
          final sessions = snapshot.data ?? const <WorkoutSession>[];
          if (sessions.isEmpty) {
            return RefreshIndicator(
              onRefresh: () async => _refresh(),
              child: ListView(
                children: [
                  const SizedBox(height: 160),
                  EmptyState(
                    icon: Icons.event_available_outlined,
                    message: 'Complete a workout to see it here',
                    subtitle: 'Your training history and calendar will fill in as you go.',
                    actionLabel: 'Choose a workout',
                    onAction: () => GoRouter.maybeOf(context)?.go('/programs'),
                  ),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => _refresh(),
            child: _CalendarView(
              month: _month,
              sessions: sessions,
              onPrevious: () => setState(
                () => _month = DateTime(_month.year, _month.month - 1),
              ),
              onNext: () => setState(
                () => _month = DateTime(_month.year, _month.month + 1),
              ),
              onDayTap: (date, daySessions) => daySessions.length == 1
                  // One session that day: go straight to it.
                  ? context.push('/history/${daySessions.single.id}')
                  : _showDayDetails(context, date, daySessions),
              onSessionTap: (session) => context.push('/history/${session.id}'),
            ),
          );
        },
      ),
    );
  }

  Future<void> _showDayDetails(
    BuildContext context,
    DateTime date,
    List<WorkoutSession> sessions,
  ) async {
    final repository = ref.read(workoutRepositoryProvider);
    final notesRepository = await ref.read(supplementRepositoryProvider.future);
    final noteController = TextEditingController(
      text: await notesRepository.getNote(date),
    );
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${_monthName(date.month)} ${date.day}, ${date.year}'),
        content: SizedBox(
          width: double.maxFinite,
          child: FutureBuilder<List<List<ExerciseLog>>>(
            future: Future.wait(
              sessions.map(
                (session) => repository.getLogsForSession(session.id),
              ),
            ),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const SizedBox(
                  height: 80,
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final logs = snapshot.data!.expand((items) => items).toList();
              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: noteController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Stock and supplement note',
                        hintText: 'Protein ran out, bought creatine...',
                      ),
                    ),
                    const SizedBox(height: 14),
                    ...sessions.map(
                      (session) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          session.dayName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    if (logs.isEmpty)
                      const Text('No exercises were logged on this day.'),
                    ...logs.map(
                      (log) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        title: Text(log.exerciseName),
                        subtitle: Text(_logSummary(log)),
                        trailing: log.hitFailure
                            ? Icon(
                                Icons.flag,
                                color: context.colors.warning,
                                size: 18,
                              )
                            : null,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          FilledButton(
            onPressed: () async {
              await notesRepository.saveNote(date, noteController.text);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Save note'),
          ),
        ],
      ),
    );
  }
}

class _CalendarView extends StatelessWidget {
  final DateTime month;
  final List<WorkoutSession> sessions;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final void Function(DateTime date, List<WorkoutSession> sessions) onDayTap;
  final ValueChanged<WorkoutSession> onSessionTap;

  const _CalendarView({
    required this.month,
    required this.sessions,
    required this.onPrevious,
    required this.onNext,
    required this.onDayTap,
    required this.onSessionTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final firstWeekday = DateTime(month.year, month.month, 1).weekday;
    final now = DateTime.now();
    final byDay = <int, List<WorkoutSession>>{};
    final monthSessions = <WorkoutSession>[];
    for (final session in sessions) {
      if (session.startedAt.year == month.year &&
          session.startedAt.month == month.month) {
        byDay.putIfAbsent(session.startedAt.day, () => []).add(session);
        monthSessions.add(session);
      }
    }
    final minutes = monthSessions.fold<int>(
      0,
      (total, s) => s.finishedAt == null
          ? total
          : total + s.finishedAt!.difference(s.startedAt).inMinutes,
    );
    final cells = <Widget>[
      for (final label in ['M', 'T', 'W', 'T', 'F', 'S', 'S'])
        Center(
          child: Text(
            label,
            style: textTheme.bodySmall?.copyWith(color: colors.textSecondary),
          ),
        ),
      for (var i = 1; i < firstWeekday; i++) const SizedBox(),
      for (var day = 1; day <= daysInMonth; day++)
        _DayCell(
          day: day,
          sessions: byDay[day] ?? const [],
          isToday:
              now.year == month.year &&
              now.month == month.month &&
              now.day == day,
          onTap: () => onDayTap(
            DateTime(month.year, month.month, day),
            byDay[day] ?? const [],
          ),
        ),
    ];
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      children: [
        AppCard(
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${_monthName(month.month)} ${month.year}',
                      style: textTheme.titleMedium,
                    ),
                  ),
                  RoundIconButton(
                    tooltip: 'Previous month',
                    icon: Icons.chevron_left_rounded,
                    size: 36,
                    onPressed: onPrevious,
                  ),
                  const SizedBox(width: 8),
                  RoundIconButton(
                    tooltip: 'Next month',
                    icon: Icons.chevron_right_rounded,
                    size: 36,
                    onPressed: onNext,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              GridView.count(
                crossAxisCount: 7,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 6,
                crossAxisSpacing: 6,
                children: cells,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        ModuleHeader(
          'Sessions',
          subtitle:
              '${monthSessions.length} in ${_monthName(month.month)} · $minutes min trained',
        ),
        const SizedBox(height: 10),
        if (monthSessions.isEmpty)
          AppCard(
            flat: true,
            color: colors.surface,
            child: Text(
              'No sessions this month. Tap a day to add a note.',
              style: textTheme.bodyMedium?.copyWith(
                color: colors.textSecondary,
              ),
            ),
          )
        else
          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Column(
              children: [
                for (var i = 0; i < monthSessions.length; i++) ...[
                  if (i > 0) Divider(indent: 52, color: colors.divider),
                  _SessionTile(
                    session: monthSessions[i],
                    onTap: () => onSessionTap(monthSessions[i]),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class _DayCell extends StatelessWidget {
  final int day;
  final List<WorkoutSession> sessions;
  final bool isToday;
  final VoidCallback onTap;
  const _DayCell({
    required this.day,
    required this.sessions,
    required this.isToday,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final trained = sessions.isNotEmpty;
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: trained ? colors.primary : Colors.transparent,
          border: isToday && !trained
              ? Border.all(color: colors.primary, width: 1.5)
              : null,
        ),
        child: Text(
          '$day',
          style: AppText.metricTable.copyWith(
            fontSize: 12,
            color: trained ? colors.onPrimary : colors.textPrimary,
          ),
        ),
      ),
    );
  }
}

class _SessionTile extends StatelessWidget {
  final WorkoutSession session;
  final VoidCallback onTap;
  const _SessionTile({required this.session, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final date = session.startedAt;
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        height: 60,
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: colors.raised,
                shape: BoxShape.circle,
                border: Border.all(color: colors.border),
              ),
              child: Text('${date.day}', style: AppText.metricTable),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    session.dayName,
                    style: textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    '${weekdayLabel(date)} · ${_timeLabel(date)}',
                    style: textTheme.bodySmall?.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Text(_duration(session), style: AppText.metricTable),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right_rounded, color: colors.textMuted),
          ],
        ),
      ),
    );
  }
}

String _timeLabel(DateTime date) =>
    '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

String _monthName(int month) => const [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
][month - 1];
String _duration(WorkoutSession session) => session.finishedAt == null
    ? 'In progress'
    : '${session.finishedAt!.difference(session.startedAt).inMinutes} min';

String _logSummary(ExerciseLog log) {
  final parts = <String>[];
  if (log.weight != null) parts.add('${log.weight!.toStringAsFixed(1)} kg');
  if (log.reps != null) parts.add('${log.reps} reps');
  if (log.durationSeconds != null) parts.add('${log.durationSeconds}s');
  return parts.isEmpty ? 'Logged' : parts.join('  •  ');
}
