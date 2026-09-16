import 'dart:io';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;

import '../../core/theme/app_colors.dart';
import '../../data/database/app_database.dart';
import '../../data/repositories/workout_repository.dart';
import '../../data/repositories/progress_repository.dart';
import '../../main.dart';

class ProgressScreen extends ConsumerStatefulWidget {
  const ProgressScreen({super.key});

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
      appBar: AppBar(title: const Text('Progress')),
      body: FutureBuilder<List<String>>(
        future: repository.getExerciseNames(),
        builder: (context, namesSnapshot) {
          if (!namesSnapshot.hasData)
            return const Center(child: CircularProgressIndicator());
          final names = namesSnapshot.data!;
          if (names.isEmpty)
            return const Center(
              child: Text('Log a workout to see your progress.'),
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
    final repository = ref.watch(progressRepositoryProvider).valueOrNull;
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
                const Text(
                  'Track your body changes once a week.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
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
                  const Text(
                    'No weekly check-ins yet.',
                    style: TextStyle(color: AppColors.textSecondary),
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
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final photo = await _picker.pickImage(
                            source: ImageSource.camera,
                          );
                          if (photo != null)
                            setDialogState(() => _photo = photo);
                        },
                        icon: const Icon(Icons.camera_alt_outlined),
                        label: const Text('Camera'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final photo = await _picker.pickImage(
                            source: ImageSource.gallery,
                          );
                          if (photo != null)
                            setDialogState(() => _photo = photo);
                        },
                        icon: const Icon(Icons.photo_library_outlined),
                        label: const Text('Gallery'),
                      ),
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
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
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
                  titlesData: const FlTitlesData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: points,
                      isCurved: true,
                      color: AppColors.primary,
                      barWidth: 3,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: AppColors.primary.withValues(alpha: 0.12),
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
          titlesData: const FlTitlesData(show: false),
          barGroups: [
            for (var i = 0; i < volumes.length; i++)
              BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: volumes[i].volume,
                    color: AppColors.secondary,
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
                    color: active ? AppColors.primary : AppColors.border,
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
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    ),
  );
}

double _maxVolume(List<WeeklyVolume> volumes) {
  final max = volumes.fold<double>(
    0,
    (value, item) => item.volume > value ? item.volume : value,
  );
  return max == 0 ? 10 : max * 1.2;
}
