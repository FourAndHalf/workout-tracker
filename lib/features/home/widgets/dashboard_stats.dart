import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons_600.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/day_app_bar.dart';
import '../../../core/widgets/ledger.dart';
import '../home_providers.dart';

/// The dashboard below the "Today" hero: a KPI strip, the current week
/// against the goal, the volume trend, consistency, recent personal records
/// and the next milestone.
class DashboardStats extends StatelessWidget {
  final DashboardAnalytics data;
  final DateTime now;

  const DashboardStats({super.key, required this.data, required this.now});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _KpiStrip(data: data),
      const SizedBox(height: _gutter),
      _WeekModule(data: data, today: now.weekday),
      const SizedBox(height: _gutter),
      _VolumeModule(data: data),
      const SizedBox(height: _gutter),
      _ConsistencyModule(data: data, now: now),
      const SizedBox(height: _gutter),
      _RecordsModule(data: data),
      const SizedBox(height: _gutter),
      _MilestoneModule(totalWorkouts: data.totalWorkouts),
    ],
  );
}

const _gutter = 14.0;

/// `12,345` style digit grouping.
String groupThousands(num value) {
  final digits = value.round().abs().toString();
  final buffer = StringBuffer(value < 0 ? '-' : '');
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(',');
    buffer.write(digits[i]);
  }
  return buffer.toString();
}

/// Volume in kg, compacted to tonnes past 10 t.
String compactKg(double kg) => kg >= 10000
    ? '${(kg / 1000).toStringAsFixed(1)}t'
    : '${groupThousands(kg)} kg';

String _kg(double kg) =>
    '${kg == kg.roundToDouble() ? kg.toStringAsFixed(0) : kg.toStringAsFixed(1)} kg';

/// Percentage change against last week (to date), or null when there is no
/// baseline.
int? volumeTrend(double thisWeek, double lastWeek) =>
    lastWeek <= 0 ? null : ((thisWeek - lastWeek) / lastWeek * 100).round();

/// One short, contextual sentence to keep the user on track.
String dashboardNudge(DashboardAnalytics data) {
  const goal = DashboardAnalytics.weeklyGoal;
  final since = data.daysSinceLastWorkout;
  if (since == null) {
    return 'Every streak starts with day one. Log your first workout.';
  }
  if (data.trainedToday) {
    return 'Nice work today. Refuel and recover.';
  }
  if (data.workoutsThisWeek >= goal) {
    return 'Weekly goal met. Anything extra is a bonus.';
  }
  if (data.currentStreak > 0) {
    return 'Train today to keep your ${data.currentStreak}-day streak alive.';
  }
  if (since >= 3) {
    return "It's been $since days. A short session still counts.";
  }
  final left = goal - data.workoutsThisWeek;
  return '$left more ${left == 1 ? 'workout' : 'workouts'} to hit your weekly goal.';
}

class _KpiStrip extends StatelessWidget {
  final DashboardAnalytics data;

  const _KpiStrip({required this.data});

  @override
  Widget build(BuildContext context) {
    final trend = volumeTrend(data.volumeThisWeek, data.volumeLastWeekToDate);
    final volumes = data.weeklyVolumes.length > 8
        ? data.weeklyVolumes.sublist(data.weeklyVolumes.length - 8)
        : data.weeklyVolumes;
    final tiles = [
      _KpiTile(
        label: 'Streak',
        value:
            '${data.currentStreak} ${data.currentStreak == 1 ? 'day' : 'days'}',
        caption: 'Best ${data.bestStreak}',
      ),
      _KpiTile(
        label: 'Sessions',
        value: '${data.workoutsThisWeek}/${DashboardAnalytics.weeklyGoal}',
        caption: 'Weekly goal',
      ),
      _KpiTile(
        label: 'Volume',
        value: compactKg(data.volumeThisWeek),
        badge: trend == null ? null : DeltaPill(trend),
        caption: trend == null ? 'So far this week' : null,
        sparkline: volumes.any((v) => v > 0) ? volumes : null,
      ),
      _KpiTile(
        label: 'Sets',
        value: '${data.setsThisWeek}',
        caption: '${data.minutesThisWeek} min trained',
      ),
    ];
    final divider = context.colors.divider;
    Widget row(Widget a, Widget b) => IntrinsicHeight(
      child: Row(
        children: [
          Expanded(child: a),
          VerticalDivider(width: 33, thickness: 1, color: divider),
          Expanded(child: b),
        ],
      ),
    );
    // A 2 × 2 grid: every figure stays whole on a phone, nothing scrolls
    // sideways out of view.
    return AppCard(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      child: Column(
        children: [
          row(tiles[0], tiles[1]),
          Divider(height: 29, color: divider),
          row(tiles[2], tiles[3]),
        ],
      ),
    );
  }
}

class _KpiTile extends StatelessWidget {
  final String label;
  final String value;
  final String? caption;
  final Widget? badge;
  final List<double>? sparkline;

  const _KpiTile({
    required this.label,
    required this.value,
    this.caption,
    this.badge,
    this.sparkline,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: textTheme.bodySmall?.copyWith(color: colors.textSecondary),
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(value, style: AppText.metricCard),
              if (sparkline != null) ...[
                const SizedBox(width: 12),
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Sparkline(sparkline!, width: 44, height: 16),
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),
          if (badge != null)
            badge!
          else if (caption != null)
            Text(
              caption!,
              style: textTheme.bodySmall?.copyWith(color: colors.textSecondary),
            ),
        ],
      ),
    );
  }
}

class _WeekModule extends StatelessWidget {
  static const _letters = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  final DashboardAnalytics data;
  final int today;

  const _WeekModule({required this.data, required this.today});

  String? get _lastWorkoutLine {
    final name = data.latestWorkoutName;
    final since = data.daysSinceLastWorkout;
    if (name == null || since == null) return null;
    final when = since == 0
        ? 'today'
        : since == 1
        ? 'yesterday'
        : '$since days ago';
    return 'Last workout: $name · $when';
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    const goal = DashboardAnalytics.weeklyGoal;
    final met = data.workoutsThisWeek >= goal;
    final lastLine = _lastWorkoutLine;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('This week', style: textTheme.titleMedium),
                    const SizedBox(height: 6),
                    Text(dashboardNudge(data), style: textTheme.bodyMedium),
                    if (lastLine != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        lastLine,
                        style: textTheme.bodySmall?.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              GaugeArc(
                value: data.workoutsThisWeek / goal,
                size: 84,
                color: met ? colors.success : null,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${data.workoutsThisWeek}/$goal',
                      style: AppText.metricCard,
                    ),
                    Text(
                      'goal',
                      style: textTheme.bodySmall?.copyWith(
                        color: colors.textSecondary,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (var day = 1; day <= 7; day++)
                _DayDot(
                  letter: _letters[day - 1],
                  trained: data.trainedWeekdays.contains(day),
                  isToday: day == today,
                  isFuture: day > today,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DayDot extends StatelessWidget {
  final String letter;
  final bool trained;
  final bool isToday;
  final bool isFuture;

  const _DayDot({
    required this.letter,
    required this.trained,
    required this.isToday,
    required this.isFuture,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      children: [
        Text(
          letter,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isToday ? FontWeight.w600 : FontWeight.w400,
            color: isToday ? colors.textPrimary : colors.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: trained
                ? colors.primary
                : isFuture
                ? Colors.transparent
                : colors.surface,
            border: Border.all(
              // Today is "now", so its ring is the coral accent.
              color: trained
                  ? colors.primary
                  : isToday
                  ? colors.accent
                  : colors.border,
              width: isToday && !trained ? 1.5 : 1,
            ),
          ),
          child: trained
              ? Icon(LucideIcons600.check, size: 16, color: colors.onPrimary)
              : null,
        ),
      ],
    );
  }
}

class _VolumeModule extends StatelessWidget {
  final DashboardAnalytics data;

  const _VolumeModule({required this.data});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final volumes = data.weeklyVolumes;
    final hasData = volumes.any((v) => v > 0);
    final trend = volumeTrend(data.volumeThisWeek, data.volumeLastWeekToDate);
    final axisStyle = textTheme.bodySmall?.copyWith(
      color: colors.textSecondary,
      fontSize: 10,
    );
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ModuleHeader(
            'Training volume',
            subtitle: 'Weight × reps, last ${volumes.length} weeks',
            trailing: trend == null ? null : DeltaPill(trend),
          ),
          const SizedBox(height: 16),
          if (!hasData)
            Text(
              'Log weighted sets to see your volume trend.',
              style: textTheme.bodyMedium?.copyWith(
                color: colors.textSecondary,
              ),
            )
          else ...[
            ThinBarChart(
              values: volumes,
              highlightIndex: volumes.length - 1,
              callout: compactKg(volumes.last),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  data.weekStarts.isEmpty
                      ? ''
                      : shortDateLabel(data.weekStarts.first),
                  style: axisStyle,
                ),
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

class _ConsistencyModule extends StatelessWidget {
  final DashboardAnalytics data;
  final DateTime now;

  const _ConsistencyModule({required this.data, required this.now});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final today = DateTime(now.year, now.month, now.day);
    final columns = <List<bool>>[];
    var trainedDays = 0;
    for (final start in data.weekStarts) {
      final column = <bool>[];
      for (var d = 0; d < 7; d++) {
        final day = DateTime(start.year, start.month, start.day + d);
        final trained = !day.isAfter(today) && data.trainingDays.contains(day);
        if (trained) trainedDays++;
        column.add(trained);
      }
      columns.add(column);
    }
    final weeksMet = (data.goalHitRate * data.weekStarts.length).round();
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ModuleHeader(
            'Consistency',
            subtitle:
                '$trainedDays training days · goal met $weeksMet of ${data.weekStarts.length} weeks',
          ),
          const SizedBox(height: 16),
          if (columns.isNotEmpty)
            DotMatrix(
              columns: columns,
              dot: 10,
              gap: 5,
              highlightColumn: columns.length - 1,
            ),
          const SizedBox(height: 4),
          Text(
            'Each column is a week, Monday at the top.',
            style: textTheme.bodySmall?.copyWith(
              color: colors.textSecondary,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecordsModule extends StatelessWidget {
  final DashboardAnalytics data;

  const _RecordsModule({required this.data});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final records = data.personalRecords;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ModuleHeader('Personal records', subtitle: 'Last 30 days'),
          const SizedBox(height: 8),
          if (records.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                data.topExerciseName == null
                    ? 'Beat a previous best weight and it will show up here.'
                    : 'Heaviest lift this week: ${data.topExerciseName} at ${_kg(data.topExerciseWeight!)}. Beat a previous best to set a record.',
                style: textTheme.bodyMedium?.copyWith(
                  color: colors.textSecondary,
                ),
              ),
            )
          else
            for (var i = 0; i < records.length; i++) ...[
              if (i > 0) Divider(indent: 48, color: colors.divider),
              SizedBox(
                height: 56,
                child: Row(
                  children: [
                    const IconChip(LucideIcons600.trophy),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            records[i].exerciseName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            'Was ${_kg(records[i].previousBest)} · ${shortDateLabel(records[i].achievedAt)}',
                            style: textTheme.bodySmall?.copyWith(
                              color: colors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          _kg(records[i].weight),
                          style: AppText.metricTable,
                        ),
                        const SizedBox(height: 2),
                        DeltaPill(
                          1,
                          label: _kg(
                            records[i].weight - records[i].previousBest,
                          ),
                        ),
                      ],
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

/// The screen's one champagne element: progress to the next total-workout
/// milestone.
class _MilestoneModule extends StatelessWidget {
  final int totalWorkouts;

  const _MilestoneModule({required this.totalWorkouts});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final target = nextWorkoutMilestone(totalWorkouts);
    final left = target - totalWorkouts;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Next milestone', style: textTheme.titleMedium),
              ),
              StatusBadge(
                '$target ${target == 1 ? 'workout' : 'workouts'}',
                icon: LucideIcons600.award,
                foreground: colors.tertiary,
                background: colors.tertiaryContainer,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text('$totalWorkouts', style: AppText.metricHero),
              const SizedBox(width: 8),
              Text(
                'workouts logged',
                style: textTheme.bodyMedium?.copyWith(
                  color: colors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: target == 0 ? 0 : totalWorkouts / target,
              minHeight: 6,
              color: colors.tertiary,
              backgroundColor: colors.track,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$left to go',
            style: textTheme.bodySmall?.copyWith(color: colors.textSecondary),
          ),
        ],
      ),
    );
  }
}
