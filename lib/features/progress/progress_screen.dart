import 'dart:io';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;

import '../../core/theme/app_colors.dart';
import '../../core/widgets/empty_state.dart';
import '../../data/database/app_database.dart';
import '../../data/repositories/workout_repository.dart';
import '../../data/repositories/progress_repository.dart';
import '../../main.dart';
import '../home/home_providers.dart';

class ProgressScreen extends ConsumerStatefulWidget {
  /// When true, renders without its own app bar (hosted by [ProgressHubScreen]).
  final bool embedded;

  const ProgressScreen({super.key, this.embedded = false});

  @override
  ConsumerState<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends ConsumerState<ProgressScreen> {
  String? _exercise;
  late DateTimeRange _range = DateTimeRange(
    start: DateTime.now().subtract(const Duration(days: 90)),
    end: DateTime.now(),
  );

  @override
  Widget build(BuildContext context) {
    final repository = ref.watch(workoutRepositoryProvider);
    return Scaffold(
      appBar: widget.embedded ? null : AppBar(title: const Text('Progress')),
      body: FutureBuilder<List<String>>(
        future: repository.getExerciseNames(),
        builder: (context, namesSnapshot) {
          if (!namesSnapshot.hasData)
            return const Center(child: CircularProgressIndicator());
          final names = namesSnapshot.data!;
          if (names.isEmpty)
            return const EmptyState(
              icon: Icons.show_chart_rounded,
              message: 'Log a workout to see your progress',
              subtitle: 'Your strength and volume trends will show up here.',
            );
          final selected = names.contains(_exercise) ? _exercise! : names.first;
          if (_exercise != selected)
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) setState(() => _exercise = selected);
            });
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              DropdownButtonFormField<String>(
                value: selected,
                decoration: const InputDecoration(labelText: 'Exercise'),
                items: names
                    .map(
                      (name) =>
                          DropdownMenuItem(value: name, child: Text(name)),
                    )
                    .toList(),
                onChanged: (value) => setState(() => _exercise = value),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () async {
                  final selected = await showDateRangePicker(
                    context: context,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                    initialDateRange: _range,
                  );
                  if (selected != null) setState(() => _range = selected);
                },
                icon: const Icon(Icons.date_range_outlined),
                label: Text(
                  '${_shortDate(_range.start)} - ${_shortDate(_range.end)}',
                ),
              ),
              const SizedBox(height: 20),
              FutureBuilder<List<ExerciseLog>>(
                future: repository.getExerciseHistory(selected),
                builder: (context, snapshot) {
                  final logs = (snapshot.data ?? const <ExerciseLog>[]).where(
                    (log) =>
                        !log.loggedAt.isBefore(_range.start) &&
                        !log.loggedAt.isAfter(
                          _range.end.add(const Duration(days: 1)),
                        ),
                  );
                  return _StrengthCard(logs: logs.toList());
                },
              ),
              const SizedBox(height: 12),
              FutureBuilder<List<WeeklyVolume>>(
                future: repository.getWeeklyVolumes(),
                builder: (context, snapshot) =>
                    _VolumeCard(volumes: snapshot.data ?? const []),
              ),
              const SizedBox(height: 12),
              Consumer(
                builder: (context, ref, _) {
                  final streak = ref
                      .watch(dashboardAnalyticsProvider)
                      .value
                      ?.currentStreak;
                  return _StreakCard(streak: streak ?? 0);
                },
              ),
              const SizedBox(height: 12),
              FutureBuilder<List<WorkoutSession>>(
                future: repository.getCompletedSessions(),
                builder: (context, snapshot) {
                  final sessions = snapshot.data ?? const <WorkoutSession>[];
                  return Column(
                    children: [
                      _WorkoutTypeDonutCard(sessions: sessions),
                      const SizedBox(height: 12),
                      _AverageDurationCard(sessions: sessions),
                      const SizedBox(height: 12),
                      _CaloriesCard(sessions: sessions),
                    ],
                  );
                },
              ),
              const SizedBox(height: 12),
              FutureBuilder<Set<DateTime>>(
                future: repository.getWorkoutDates(),
                builder: (context, snapshot) =>
                    _FrequencyCard(dates: snapshot.data ?? const {}),
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
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: LinearProgressIndicator(),
        ),
      );
    _checkIns ??= repository.getCheckIns();
    return FutureBuilder<List<ProgressCheckIn>>(
      future: _checkIns,
      builder: (context, snapshot) {
        final entries = snapshot.data ?? const <ProgressCheckIn>[];
        final latest = entries.isEmpty ? null : entries.first;
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Weekly check-in',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'Track your body changes once a week.',
                  style: TextStyle(
                    color: context.colors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 14),
                if (latest != null)
                  Row(
                    children: [
                      _CheckInValue(
                        label: 'Weight',
                        value: '${latest.weightKg.toStringAsFixed(1)} kg',
                      ),
                      _CheckInValue(
                        label: 'Body fat',
                        value: '${latest.fatPercent.toStringAsFixed(1)}%',
                      ),
                      _CheckInValue(
                        label: 'Week',
                        value: _shortDate(latest.date),
                      ),
                    ],
                  )
                else
                  Text(
                    'No weekly check-ins yet.',
                    style: TextStyle(color: context.colors.textSecondary),
                  ),
                if (latest?.photoPath != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 14),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        File(latest!.photoPath!),
                        height: 180,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                const SizedBox(height: 14),
                FilledButton.icon(
                  onPressed: () => _addCheckIn(context, repository),
                  icon: const Icon(Icons.add_a_photo_outlined),
                  label: const Text('Add this week\'s check-in'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _addCheckIn(
    BuildContext context,
    ProgressRepository repository,
  ) async {
    final weightController = TextEditingController();
    final fatController = TextEditingController();
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
  const _CheckInValue({required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        Text(
          label,
          style: TextStyle(color: context.colors.textSecondary, fontSize: 11),
        ),
      ],
    ),
  );
}

String _shortDate(DateTime date) => '${date.day}/${date.month}';

class _StrengthCard extends StatelessWidget {
  final List<ExerciseLog> logs;
  const _StrengthCard({required this.logs});
  @override
  Widget build(BuildContext context) {
    final points = <FlSpot>[];
    var maxWeight = 0.0;
    for (var i = 0; i < logs.length; i++) {
      final weight = logs[i].weight ?? 0;
      if (weight > maxWeight) maxWeight = weight;
      points.add(FlSpot(i.toDouble(), weight));
    }
    return _ChartCard(
      title: 'Strength trend',
      subtitle: '${maxWeight.toStringAsFixed(1)} kg best',
      child: SizedBox(
        height: 190,
        child: points.isEmpty
            ? const Center(child: Text('No weighted sets yet'))
            : LineChart(
                LineChartData(
                  minY: 0,
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 36,
                        getTitlesWidget: (value, meta) => Text(
                          value.toStringAsFixed(0),
                          style: TextStyle(
                            fontSize: 10,
                            color: context.colors.textMuted,
                          ),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 20,
                        interval: (points.length / 4)
                            .clamp(1, double.infinity)
                            .floorToDouble(),
                        getTitlesWidget: (value, meta) => Text(
                          '${value.toInt() + 1}',
                          style: TextStyle(
                            fontSize: 10,
                            color: context.colors.textMuted,
                          ),
                        ),
                      ),
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: points,
                      isCurved: true,
                      color: context.colors.primary,
                      barWidth: 3,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: context.colors.primary.withValues(alpha: 0.12),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _VolumeCard extends StatelessWidget {
  final List<WeeklyVolume> volumes;
  const _VolumeCard({required this.volumes});
  @override
  Widget build(BuildContext context) => _ChartCard(
    title: 'Weekly volume',
    subtitle: 'Weight × reps',
    child: SizedBox(
      height: 190,
      child: BarChart(
        BarChartData(
          maxY: _maxVolume(volumes),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 36,
                getTitlesWidget: (value, meta) => Text(
                  value.toStringAsFixed(0),
                  style: TextStyle(
                    fontSize: 10,
                    color: context.colors.textMuted,
                  ),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 24,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= volumes.length) {
                    return const SizedBox.shrink();
                  }
                  final date = volumes[index].start;
                  return Text(
                    '${date.day}/${date.month}',
                    style: TextStyle(
                      fontSize: 10,
                      color: context.colors.textMuted,
                    ),
                  );
                },
              ),
            ),
          ),
          barGroups: [
            for (var i = 0; i < volumes.length; i++)
              BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: volumes[i].volume,
                    color: context.colors.secondary,
                    width: 12,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ],
              ),
          ],
        ),
      ),
    ),
  );
}

class _FrequencyCard extends StatelessWidget {
  final Set<DateTime> dates;
  const _FrequencyCard({required this.dates});
  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final start = DateTime(
      today.year,
      today.month,
      today.day,
    ).subtract(const Duration(days: 27));
    return _ChartCard(
      title: 'Consistency',
      subtitle: '${dates.length} workout days recorded',
      child: GridView.count(
        crossAxisCount: 7,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 5,
        crossAxisSpacing: 5,
        children: [
          for (var i = 0; i < 28; i++)
            Builder(
              builder: (_) {
                final date = start.add(Duration(days: i));
                final active = dates.contains(date);
                return Container(
                  decoration: BoxDecoration(
                    color: active
                        ? context.colors.primary
                        : context.colors.border,
                    borderRadius: BorderRadius.circular(3),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;
  const _ChartCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(color: context.colors.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    ),
  );
}

class _StreakCard extends StatelessWidget {
  final int streak;
  const _StreakCard({required this.streak});
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(
            Icons.local_fire_department_rounded,
            color: context.colors.warning,
            size: 36,
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$streak',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Day streak',
                style: TextStyle(
                  color: context.colors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
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

class _WorkoutTypeDonutCard extends StatelessWidget {
  final List<WorkoutSession> sessions;
  const _WorkoutTypeDonutCard({required this.sessions});
  @override
  Widget build(BuildContext context) {
    final counts = <String, int>{};
    for (final session in sessions) {
      counts[session.dayName] = (counts[session.dayName] ?? 0) + 1;
    }
    final entries = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final palette = [
      context.colors.primary,
      context.colors.supersetBlock,
      context.colors.triSetBlock,
      context.colors.giantSetBlock,
      context.colors.dropSetBlock,
      context.colors.secondary,
    ];

    return _ChartCard(
      title: 'Workout type breakdown',
      subtitle: '${sessions.length} sessions logged',
      child: entries.isEmpty
          ? const Center(child: Text('No completed workouts yet'))
          : SizedBox(
              height: 190,
              child: Row(
                children: [
                  Expanded(
                    child: PieChart(
                      PieChartData(
                        centerSpaceRadius: 40,
                        sectionsSpace: 2,
                        sections: [
                          for (var i = 0; i < entries.length; i++)
                            PieChartSectionData(
                              value: entries[i].value.toDouble(),
                              color: palette[i % palette.length],
                              radius: 40,
                              showTitle: false,
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (var i = 0; i < entries.length; i++)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              children: [
                                Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: palette[i % palette.length],
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '${entries[i].key} (${entries[i].value})',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: context.colors.textSecondary,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _AverageDurationCard extends StatelessWidget {
  final List<WorkoutSession> sessions;
  const _AverageDurationCard({required this.sessions});
  @override
  Widget build(BuildContext context) {
    final durations = sessions
        .where((s) => s.finishedAt != null)
        .map((s) => s.finishedAt!.difference(s.startedAt).inMinutes)
        .where((minutes) => minutes > 0)
        .toList();
    final average = durations.isEmpty
        ? 0
        : (durations.reduce((a, b) => a + b) / durations.length).round();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              Icons.timer_outlined,
              color: context.colors.secondary,
              size: 32,
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  durations.isEmpty ? '--' : '$average min',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Average workout time',
                  style: TextStyle(
                    color: context.colors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
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
    final weekly = _bucketCaloriesByWeek(sessions);
    final maxCalories = weekly.fold<double>(
      0,
      (value, item) => item.calories > value ? item.calories : value,
    );

    return _ChartCard(
      title: 'Estimated calories burned',
      subtitle: 'Rough estimate from workout duration',
      child: SizedBox(
        height: 190,
        child: BarChart(
          BarChartData(
            maxY: maxCalories == 0 ? 100 : maxCalories * 1.2,
            gridData: const FlGridData(show: false),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 36,
                  getTitlesWidget: (value, meta) => Text(
                    value.toStringAsFixed(0),
                    style: TextStyle(
                      fontSize: 10,
                      color: context.colors.textMuted,
                    ),
                  ),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 24,
                  getTitlesWidget: (value, meta) {
                    final index = value.toInt();
                    if (index < 0 || index >= weekly.length) {
                      return const SizedBox.shrink();
                    }
                    final date = weekly[index].start;
                    return Text(
                      '${date.day}/${date.month}',
                      style: TextStyle(
                        fontSize: 10,
                        color: context.colors.textMuted,
                      ),
                    );
                  },
                ),
              ),
            ),
            barGroups: [
              for (var i = 0; i < weekly.length; i++)
                BarChartGroupData(
                  x: i,
                  barRods: [
                    BarChartRodData(
                      toY: weekly[i].calories,
                      color: context.colors.warning,
                      width: 12,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

double _maxVolume(List<WeeklyVolume> volumes) {
  final max = volumes.fold<double>(
    0,
    (value, item) => item.volume > value ? item.volume : value,
  );
  return max == 0 ? 10 : max * 1.2;
}
