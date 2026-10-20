import 'dart:io';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/day_app_bar.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/ledger.dart';
import '../../data/database/app_database.dart';
import '../../data/repositories/workout_repository.dart';
import '../../data/repositories/progress_repository.dart';
import '../../main.dart';
import '../home/home_providers.dart';
import '../home/widgets/dashboard_stats.dart' show compactKg, groupThousands;

/// One-tap time windows for the strength chart (replacing a date picker).
enum StrengthRange {
  month('1M', 30),
  quarter('3M', 90),
  half('6M', 182),
  all('All', null);

  const StrengthRange(this.label, this.days);
  final String label;
  final int? days;
}

/// Each day's heaviest set for one exercise, oldest first, within [range].
List<(DateTime, double)> dailyBestWeights(
  List<ExerciseLog> logs, {
  required StrengthRange range,
  required DateTime now,
}) {
  final days = range.days;
  final since = days == null
      ? null
      : DateTime(now.year, now.month, now.day - days);
  final best = <DateTime, double>{};
  for (final log in logs) {
    final weight = log.weight;
    if (weight == null || weight <= 0) continue;
    if (since != null && log.loggedAt.isBefore(since)) continue;
    final day = DateTime(
      log.loggedAt.year,
      log.loggedAt.month,
      log.loggedAt.day,
    );
    if (weight > (best[day] ?? 0)) best[day] = weight;
  }
  final entries = best.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
  return [for (final e in entries) (e.key, e.value)];
}

class ProgressScreen extends ConsumerStatefulWidget {
  /// When true, renders without its own app bar (hosted by [ProgressHubScreen]).
  final bool embedded;

  const ProgressScreen({super.key, this.embedded = false});

  @override
  ConsumerState<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends ConsumerState<ProgressScreen> {
  String? _exercise;
  StrengthRange _range = StrengthRange.quarter;

  @override
  Widget build(BuildContext context) {
    final repository = ref.watch(workoutRepositoryProvider);
    return Scaffold(
      appBar: widget.embedded ? null : AppBar(title: const Text('Progress')),
      body: FutureBuilder<List<String>>(
        future: repository.getExerciseNames(),
        builder: (context, namesSnapshot) {
          if (!namesSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final names = namesSnapshot.data!;
          if (names.isEmpty) {
            return EmptyState(
              icon: Icons.show_chart_outlined,
              message: 'Log a workout to see your progress',
              subtitle: 'Your strength and volume trends will show up here.',
              actionLabel: 'Choose a workout',
              onAction: () => GoRouter.maybeOf(context)?.go('/programs'),
            );
          }
          final selected = names.contains(_exercise) ? _exercise! : names.first;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            children: [
              FutureBuilder<List<WorkoutSession>>(
                future: repository.getCompletedSessions(),
                builder: (context, snapshot) => _SummaryStrip(
                  sessions: snapshot.data ?? const <WorkoutSession>[],
                ),
              ),
              const SizedBox(height: 12),
              FutureBuilder<List<ExerciseLog>>(
                future: repository.getExerciseHistory(selected),
                builder: (context, snapshot) => _StrengthCard(
                  names: names,
                  selected: selected,
                  onExercise: (value) => setState(() => _exercise = value),
                  range: _range,
                  onRange: (value) => setState(() => _range = value),
                  points: dailyBestWeights(
                    snapshot.data ?? const <ExerciseLog>[],
                    range: _range,
                    now: DateTime.now(),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              FutureBuilder<List<WeeklyVolume>>(
                future: repository.getWeeklyVolumes(),
                builder: (context, snapshot) =>
                    _VolumeCard(volumes: snapshot.data ?? const []),
              ),
              const SizedBox(height: 12),
              FutureBuilder<List<WorkoutSession>>(
                future: repository.getCompletedSessions(),
                builder: (context, snapshot) {
                  final sessions = snapshot.data ?? const <WorkoutSession>[];
                  return Column(
                    children: [
                      _WorkoutTypeCard(sessions: sessions),
                      const SizedBox(height: 12),
                      _CaloriesCard(sessions: sessions),
                    ],
                  );
                },
              ),
              const SizedBox(height: 12),
              const _WeeklyCheckInCard(),
            ],
          );
        },
      ),
    );
  }
}

class _WeeklyCheckInCard extends ConsumerStatefulWidget {
  const _WeeklyCheckInCard();
  @override
  ConsumerState<_WeeklyCheckInCard> createState() => _WeeklyCheckInCardState();
}

class _WeeklyCheckInCardState extends ConsumerState<_WeeklyCheckInCard> {
  Future<List<ProgressCheckIn>>? _checkIns;
  final _picker = ImagePicker();
  XFile? _photo;

  @override
  Widget build(BuildContext context) {
    final repository = ref.watch(progressRepositoryProvider).value;
    if (repository == null)
      return const AppCard(child: LinearProgressIndicator());
    _checkIns ??= repository.getCheckIns();
    return FutureBuilder<List<ProgressCheckIn>>(
      future: _checkIns,
      builder: (context, snapshot) {
        final entries = snapshot.data ?? const <ProgressCheckIn>[];
        final latest = entries.isEmpty ? null : entries.first;
        final colors = context.colors;
        return AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ModuleHeader(
                'Weekly check-in',
                subtitle: latest == null
                    ? 'Track body changes once a week.'
                    : 'Last check-in ${shortDateLabel(latest.date)}',
                trailing: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 36),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  onPressed: () => _addCheckIn(context, repository, latest),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Check in'),
                ),
              ),
              const SizedBox(height: 16),
              if (latest != null)
                Row(
                  children: [
                    _CheckInValue(
                      label: 'Weight',
                      value: '${latest.weightKg.toStringAsFixed(1)} kg',
                      delta: entries.length > 1
                          ? latest.weightKg - entries[1].weightKg
                          : null,
                      unit: 'kg',
                    ),
                    _CheckInValue(
                      label: 'Body fat',
                      value: '${latest.fatPercent.toStringAsFixed(1)}%',
                      delta: entries.length > 1
                          ? latest.fatPercent - entries[1].fatPercent
                          : null,
                      unit: '%',
                    ),
                  ],
                )
              else
                Text(
                  'No check-ins yet. It takes ten seconds.',
                  style: Theme.of(context).textTheme.bodyMedium
                      ?.copyWith(color: colors.textSecondary),
                ),
              if (latest?.photoPath != null)
                Padding(
                  padding: const EdgeInsets.only(top: 14),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    child: Image.file(
                      File(latest!.photoPath!),
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _addCheckIn(
    BuildContext context,
    ProgressRepository repository,
    ProgressCheckIn? latest,
  ) async {
    // Prefilled with last week's numbers: most weeks only need a nudge.
    final weightController = TextEditingController(
      text: latest?.weightKg.toStringAsFixed(1) ?? '',
    );
    final fatController = TextEditingController(
      text: latest?.fatPercent.toStringAsFixed(1) ?? '',
    );
    _photo = null;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Weekly check-in'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: weightController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(labelText: 'Weight (kg)'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: fatController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(labelText: 'Body fat (%)'),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    IconButton.outlined(
                      tooltip: 'Take photo',
                      onPressed: () async {
                        final photo = await _picker.pickImage(
                          source: ImageSource.camera,
                        );
                        if (photo != null) setDialogState(() => _photo = photo);
                      },
                      icon: const Icon(Icons.camera_alt_outlined),
                    ),
                    const SizedBox(width: 8),
                    IconButton.outlined(
                      tooltip: 'Choose from gallery',
                      onPressed: () async {
                        final photo = await _picker.pickImage(
                          source: ImageSource.gallery,
                        );
                        if (photo != null) setDialogState(() => _photo = photo);
                      },
                      icon: const Icon(Icons.photo_library_outlined),
                    ),
                  ],
                ),
                if (_photo != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      path.basename(_photo!.path),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final weight = double.tryParse(weightController.text);
                final fat = double.tryParse(fatController.text);
                if (weight == null || fat == null) return;
                await repository.saveCheckIn(
                  ProgressCheckIn(
                    date: DateTime.now(),
                    weightKg: weight,
                    fatPercent: fat,
                    photoPath: _photo?.path,
                  ),
                );
                if (dialogContext.mounted) Navigator.pop(dialogContext);
                if (mounted)
                  setState(() => _checkIns = repository.getCheckIns());
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CheckInValue extends StatelessWidget {
  final String label;
  final String value;
  final double? delta;
  final String unit;
  const _CheckInValue({
    required this.label,
    required this.value,
    required this.unit,
    this.delta,
  });
  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final delta = this.delta;
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: colors.textSecondary),
          ),
          const SizedBox(height: 4),
          Text(value, style: AppText.metricCard),
          if (delta != null && delta != 0) ...[
            const SizedBox(height: 4),
            // Body changes are neutral: no gain/loss coloring, just the glyph.
            StatusBadge(
              '${delta > 0 ? '▲' : '▼'} ${delta.abs().toStringAsFixed(1)} $unit',
              foreground: colors.textSecondary,
              background: colors.surface,
            ),
          ],
        ],
      ),
    );
  }
}

class _SummaryStrip extends ConsumerWidget {
  final List<WorkoutSession> sessions;
  const _SummaryStrip({required this.sessions});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final streak = ref.watch(dashboardAnalyticsProvider).value?.currentStreak;
    final durations = sessions
        .where((s) => s.finishedAt != null)
        .map((s) => s.finishedAt!.difference(s.startedAt).inMinutes)
        .where((minutes) => minutes > 0)
        .toList();
    final average = durations.isEmpty
        ? null
        : (durations.reduce((a, b) => a + b) / durations.length).round();
    final items = [
      ('Day streak', '${streak ?? 0}'),
      ('Avg workout', average == null ? '—' : '$average min'),
      ('Sessions', '${sessions.length}'),
    ];
    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
      child: IntrinsicHeight(
        child: Row(
          children: [
            for (var i = 0; i < items.length; i++) ...[
              if (i > 0) VerticalDivider(width: 1, color: colors.border),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      items[i].$1,
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(color: colors.textSecondary),
                    ),
                    const SizedBox(height: 4),
                    Text(items[i].$2, style: AppText.metricCard),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

String _kg(double kg) =>
    '${kg == kg.roundToDouble() ? kg.toStringAsFixed(0) : kg.toStringAsFixed(1)} kg';

class _StrengthCard extends StatelessWidget {
  final List<String> names;
  final String selected;
  final ValueChanged<String> onExercise;
  final StrengthRange range;
  final ValueChanged<StrengthRange> onRange;
  final List<(DateTime, double)> points;

  const _StrengthCard({
    required this.names,
    required this.selected,
    required this.onExercise,
    required this.range,
    required this.onRange,
    required this.points,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final best = points.isEmpty
        ? null
        : points.map((p) => p.$2).reduce((a, b) => a > b ? a : b);
    final change = points.length < 2 ? null : points.last.$2 - points.first.$2;
    final axisStyle = textTheme.bodySmall?.copyWith(
      color: colors.textSecondary,
      fontSize: 10,
    );
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Strength trend', style: textTheme.titleMedium),
              ),
              _ExercisePicker(
                names: names,
                selected: selected,
                onSelected: onExercise,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(best == null ? '—' : _kg(best), style: AppText.metricHero),
              const SizedBox(width: 10),
              if (change != null && change != 0)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: DeltaPill(
                    change > 0 ? 1 : -1,
                    label: _kg(change.abs()),
                  ),
                ),
            ],
          ),
          Text('Best set in range', style: axisStyle),
          const SizedBox(height: 16),
          SizedBox(
            height: 150,
            child: points.length < 2
                ? Center(
                    child: Text(
                      points.isEmpty
                          ? 'No weighted sets in this range'
                          : 'Log another session to see a trend',
                      style: textTheme.bodyMedium?.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  )
                : LineChart(
                    LineChartData(
                      gridData: const FlGridData(show: false),
                      borderData: FlBorderData(show: false),
                      titlesData: const FlTitlesData(show: false),
                      lineTouchData: LineTouchData(
                        touchTooltipData: LineTouchTooltipData(
                          getTooltipColor: (_) => colors.primary,
                          tooltipBorderRadius: BorderRadius.circular(999),
                          getTooltipItems: (spots) => [
                            for (final spot in spots)
                              LineTooltipItem(
                                '${_kg(spot.y)} · ${shortDateLabel(points[spot.x.toInt()].$1)}',
                                AppText.metricDelta.copyWith(
                                  color: colors.onPrimary,
                                ),
                              ),
                          ],
                        ),
                      ),
                      lineBarsData: [
                        LineChartBarData(
                          spots: [
                            for (var i = 0; i < points.length; i++)
                              FlSpot(i.toDouble(), points[i].$2),
                          ],
                          color: colors.primary,
                          barWidth: 1.5,
                          dotData: FlDotData(
                            checkToShowDot: (spot, bar) =>
                                spot.x == points.length - 1,
                            getDotPainter: (spot, percent, bar, index) =>
                                FlDotCirclePainter(
                                  radius: 3.5,
                                  color: colors.primary,
                                  strokeWidth: 0,
                                ),
                          ),
                          belowBarData: BarAreaData(
                            show: true,
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                colors.primary.withValues(alpha: 0.08),
                                colors.primary.withValues(alpha: 0),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
          if (points.length >= 2) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(shortDateLabel(points.first.$1), style: axisStyle),
                Text(shortDateLabel(points.last.$1), style: axisStyle),
              ],
            ),
          ],
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<StrengthRange>(
              showSelectedIcon: false,
              segments: [
                for (final option in StrengthRange.values)
                  ButtonSegment(value: option, label: Text(option.label)),
              ],
              selected: {range},
              onSelectionChanged: (value) => onRange(value.first),
            ),
          ),
        ],
      ),
    );
  }
}

/// The selected exercise as a raised pill ("Back Squat ▾") opening a menu.
class _ExercisePicker extends StatelessWidget {
  final List<String> names;
  final String selected;
  final ValueChanged<String> onSelected;

  const _ExercisePicker({
    required this.names,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return PopupMenuButton<String>(
      tooltip: 'Choose exercise',
      initialValue: selected,
      onSelected: onSelected,
      color: colors.raised,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      itemBuilder: (context) => [
        for (final name in names) PopupMenuItem(value: name, child: Text(name)),
      ],
      child: Container(
        constraints: const BoxConstraints(maxWidth: 190),
        height: 36,
        padding: const EdgeInsets.only(left: 12, right: 6),
        decoration: BoxDecoration(
          color: colors.raised,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: colors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                selected,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ),
            Icon(
              Icons.expand_more_rounded,
              size: 18,
              color: colors.textPrimary,
            ),
          ],
        ),
      ),
    );
  }
}

class _VolumeCard extends StatelessWidget {
  final List<WeeklyVolume> volumes;
  const _VolumeCard({required this.volumes});
  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final axisStyle = Theme.of(context).textTheme.bodySmall
        ?.copyWith(color: colors.textSecondary, fontSize: 10);
    final values = [for (final v in volumes) v.volume];
    final total = values.fold<double>(0, (a, b) => a + b);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ModuleHeader(
            'Weekly volume',
            subtitle:
                'Weight × reps · ${compactKg(total)} over ${volumes.length} weeks',
          ),
          const SizedBox(height: 16),
          if (values.isEmpty || total == 0)
            Text(
              'No weighted sets yet.',
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: colors.textSecondary),
            )
          else ...[
            ThinBarChart(
              values: values,
              highlightIndex: values.length - 1,
              callout: compactKg(values.last),
              barWidth: 8,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(shortDateLabel(volumes.first.start), style: axisStyle),
                Text(
                  'This week',
                  style: axisStyle?.copyWith(color: colors.textPrimary),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Approximate calories for a completed session, from its duration alone.
/// This is a rough motivational estimate (moderate resistance training,
/// ~7 kcal/min), not a medically precise calculation.
int _estimatedCalories(WorkoutSession session) {
  final finishedAt = session.finishedAt;
  if (finishedAt == null) return 0;
  final minutes = finishedAt.difference(session.startedAt).inMinutes;
  if (minutes <= 0) return 0;
  return (minutes * 7).round();
}

/// Session counts per workout name, as one tonal stacked bar (design
/// "Category distribution") with labelled rows beneath.
class _WorkoutTypeCard extends StatelessWidget {
  final List<WorkoutSession> sessions;
  const _WorkoutTypeCard({required this.sessions});
  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final counts = <String, int>{};
    for (final session in sessions) {
      counts[session.dayName] = (counts[session.dayName] ?? 0) + 1;
    }
    final entries = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final total = sessions.length;
    // Tone steps from charcoal to light gray; the largest share is darkest.
    Color tone(int i) => Color.lerp(
      colors.primary,
      colors.track,
      entries.length <= 1 ? 0 : i / (entries.length - 1),
    )!;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ModuleHeader(
            'Workout type breakdown',
            subtitle: '$total sessions logged',
          ),
          const SizedBox(height: 16),
          if (entries.isEmpty)
            Text(
              'No completed workouts yet',
              style: textTheme.bodyMedium?.copyWith(
                color: colors.textSecondary,
              ),
            )
          else ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: SizedBox(
                height: 12,
                child: Row(
                  children: [
                    for (var i = 0; i < entries.length; i++)
                      Expanded(
                        flex: entries[i].value,
                        child: Container(
                          margin: EdgeInsets.only(
                            right: i == entries.length - 1 ? 0 : 2,
                          ),
                          color: tone(i),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            for (var i = 0; i < entries.length; i++)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: tone(i),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '${entries[i].key} (${entries[i].value})',
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodyMedium,
                      ),
                    ),
                    Text(
                      '${(entries[i].value * 100 / total).round()}%',
                      style: AppText.metricTable.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _WeeklyCalories {
  final DateTime start;
  final double calories;
  const _WeeklyCalories({required this.start, required this.calories});
}

List<_WeeklyCalories> _bucketCaloriesByWeek(
  List<WorkoutSession> sessions, {
  int weeks = 8,
}) {
  final today = DateTime.now();
  final currentWeekStart = DateTime(
    today.year,
    today.month,
    today.day,
  ).subtract(Duration(days: today.weekday - 1));

  final buckets = <DateTime, double>{
    for (var i = weeks - 1; i >= 0; i--)
      currentWeekStart.subtract(Duration(days: i * 7)): 0,
  };

  for (final session in sessions) {
    final sessionDay = DateTime(
      session.startedAt.year,
      session.startedAt.month,
      session.startedAt.day,
    );
    final weekStart = sessionDay.subtract(
      Duration(days: sessionDay.weekday - 1),
    );
    if (buckets.containsKey(weekStart)) {
      buckets[weekStart] = buckets[weekStart]! + _estimatedCalories(session);
    }
  }

  return buckets.entries
      .map((entry) => _WeeklyCalories(start: entry.key, calories: entry.value))
      .toList()
    ..sort((a, b) => a.start.compareTo(b.start));
}

class _CaloriesCard extends StatelessWidget {
  final List<WorkoutSession> sessions;
  const _CaloriesCard({required this.sessions});
  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final weekly = _bucketCaloriesByWeek(sessions);
    final values = [for (final w in weekly) w.calories];
    final axisStyle = Theme.of(context).textTheme.bodySmall
        ?.copyWith(color: colors.textSecondary, fontSize: 10);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ModuleHeader(
            'Estimated calories burned',
            subtitle: 'Rough estimate from workout duration',
          ),
          const SizedBox(height: 16),
          ThinBarChart(
            values: values,
            highlightIndex: values.length - 1,
            callout: '${groupThousands(values.last)} kcal',
            barWidth: 8,
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(shortDateLabel(weekly.first.start), style: axisStyle),
              Text(
                'This week',
                style: axisStyle?.copyWith(color: colors.textPrimary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
