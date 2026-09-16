import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/empty_state.dart';
import '../../data/database/app_database.dart';
import '../../main.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  late Future<List<WorkoutSession>> _sessions;
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  bool _calendar = true;

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
      appBar: AppBar(
        title: const Text('Workout History'),
        actions: [
          IconButton(
            tooltip: _calendar ? 'Show list' : 'Show calendar',
            icon: Icon(
              _calendar
                  ? Icons.view_list_outlined
                  : Icons.calendar_month_outlined,
            ),
            onPressed: () => setState(() => _calendar = !_calendar),
          ),
        ],
      ),
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
                children: const [
                  SizedBox(height: 160),
                  EmptyState(
                    icon: Icons.event_available_outlined,
                    message: 'Complete a workout to see it here',
                    subtitle:
                        'Your training history and calendar will fill in as you go.',
                  ),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => _refresh(),
            child: _calendar
                ? _CalendarView(
                    month: _month,
                    sessions: sessions,
                    onPrevious: () => setState(
                      () => _month = DateTime(_month.year, _month.month - 1),
                    ),
                    onNext: () => setState(
                      () => _month = DateTime(_month.year, _month.month + 1),
                    ),
                    onDayTap: (date, daySessions) =>
                        _showDayDetails(context, date, daySessions),
                    onSessionTap: (session) =>
                        context.push('/history/${session.id}'),
                  )
                : _SessionList(
                    sessions: sessions,
                    onSessionTap: (session) =>
                        context.push('/history/${session.id}'),
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
                            ? const Icon(
                                Icons.flag,
                                color: AppColors.warning,
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
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final firstWeekday = DateTime(month.year, month.month, 1).weekday;
    final byDay = <int, List<WorkoutSession>>{};
    for (final session in sessions) {
      if (session.startedAt.year == month.year &&
          session.startedAt.month == month.month) {
        byDay.putIfAbsent(session.startedAt.day, () => []).add(session);
      }
    }
    final cells = <Widget>[
      for (final label in ['M', 'T', 'W', 'T', 'F', 'S', 'S'])
        Center(
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      for (var i = 1; i < firstWeekday; i++) const SizedBox(),
      for (var day = 1; day <= daysInMonth; day++)
        _DayCell(
          day: day,
          sessions: byDay[day] ?? const [],
          onTap: () => onDayTap(
            DateTime(month.year, month.month, day),
            byDay[day] ?? const [],
          ),
        ),
    ];
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              onPressed: onPrevious,
              icon: const Icon(Icons.chevron_left),
            ),
            Text(
              '${_monthName(month.month)} ${month.year}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            IconButton(
              onPressed: onNext,
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
        const SizedBox(height: 8),
        GridView.count(
          crossAxisCount: 7,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          children: cells,
        ),
        const SizedBox(height: 20),
        Text(
          '${sessions.length} completed session${sessions.length == 1 ? '' : 's'}',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 8),
        ...sessions
            .take(3)
            .map(
              (session) => _SessionTile(
                session: session,
                onTap: () => onSessionTap(session),
              ),
            ),
      ],
    );
  }
}

class _DayCell extends StatelessWidget {
  final int day;
  final List<WorkoutSession> sessions;
  final VoidCallback onTap;
  const _DayCell({
    required this.day,
    required this.sessions,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(8),
    child: Container(
      decoration: BoxDecoration(
        color: sessions.isEmpty
            ? AppColors.card
            : AppColors.primary.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: sessions.isEmpty ? AppColors.border : AppColors.primary,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('$day'),
          if (sessions.isNotEmpty)
            const Icon(Icons.check_circle, size: 13, color: AppColors.primary),
        ],
      ),
    ),
  );
}

class _SessionList extends StatelessWidget {
  final List<WorkoutSession> sessions;
  final ValueChanged<WorkoutSession> onSessionTap;
  const _SessionList({required this.sessions, required this.onSessionTap});
  @override
  Widget build(BuildContext context) => ListView.separated(
    padding: const EdgeInsets.all(16),
    itemCount: sessions.length,
    separatorBuilder: (_, __) => const SizedBox(height: 8),
    itemBuilder: (_, index) => _SessionTile(
      session: sessions[index],
      onTap: () => onSessionTap(sessions[index]),
    ),
  );
}

class _SessionTile extends StatelessWidget {
  final WorkoutSession session;
  final VoidCallback onTap;
  const _SessionTile({required this.session, required this.onTap});
  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      onTap: onTap,
      leading: const Icon(Icons.fitness_center),
      title: Text(session.dayName),
      subtitle: Text(
        '${_dateLabel(session.startedAt)}  •  ${_duration(session)}',
      ),
      trailing: const Icon(Icons.chevron_right),
    ),
  );
}

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
String _dateLabel(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
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
