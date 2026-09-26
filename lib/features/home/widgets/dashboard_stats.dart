import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_card.dart';
import '../home_providers.dart';

const _tabular = [FontFeature.tabularFigures()];

/// The dashboard's "week at a glance": streak + weekly goal ring, a week
/// strip, three headline numbers and a contextual nudge.
class DashboardStats extends StatelessWidget {
  final DashboardAnalytics data;
  final DateTime now;

  const DashboardStats({super.key, required this.data, required this.now});

  @override
  Widget build(BuildContext context) => Column(
    children: [
      _StreakCard(data: data),
      const SizedBox(height: 10),
      _WeekStrip(data: data, today: now.weekday),
      const SizedBox(height: 10),
      Row(
        children: [
          Expanded(
            child: _StatCard(
              icon: Icons.check_circle_outline_rounded,
              color: context.colors.success,
              value: '${data.setsThisWeek}',
              label: 'Sets',
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _StatCard(
              icon: Icons.trending_up_rounded,
              color: context.colors.primary,
              value: _compactKg(data.volumeThisWeek),
              label: 'Training volume',
              trend: volumeTrend(data.volumeThisWeek, data.volumeLastWeek),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _StatCard(
              icon: Icons.emoji_events_outlined,
              color: context.colors.warning,
              value: data.topExerciseWeight == null
                  ? '—'
                  : '${data.topExerciseWeight!.toStringAsFixed(0)} kg',
              label: data.topExerciseName ?? 'Top lift',
            ),
          ),
        ],
      ),
      const SizedBox(height: 10),
      _NudgeCard(message: dashboardNudge(data), latest: data),
    ],
  );
}

String _compactKg(double kg) => kg >= 10000
    ? '${(kg / 1000).toStringAsFixed(1)}t'
    : '${kg.toStringAsFixed(0)} kg';

/// Percentage change against last week, or null when there is no baseline.
int? volumeTrend(double thisWeek, double lastWeek) =>
    lastWeek <= 0 ? null : ((thisWeek - lastWeek) / lastWeek * 100).round();

/// One short, contextual sentence to keep the user on track.
String dashboardNudge(DashboardAnalytics data) {
  const goal = DashboardAnalytics.weeklyGoal;
  final since = data.daysSinceLastWorkout;
  if (since == null) {
    return 'Every streak starts with day one. Log your first workout!';
  }
  if (data.trainedToday) {
    return 'Nice work today. Refuel and recover.';
  }
  if (data.workoutsThisWeek >= goal) {
    return 'Weekly goal smashed. Anything extra is a bonus.';
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

class _StreakCard extends StatelessWidget {
  final DashboardAnalytics data;

  const _StreakCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    const goal = DashboardAnalytics.weeklyGoal;
    final progress = (data.workoutsThisWeek / goal).clamp(0.0, 1.0);

    return AppCard(
      borderColor: colors.warning.withValues(alpha: 0.3),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Icon(
                      Icons.local_fire_department_rounded,
                      color: colors.warning,
                      size: 34,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${data.currentStreak}',
                      style: const TextStyle(
                        fontSize: 40,
                        height: 1,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1.2,
                        fontFeatures: _tabular,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'day streak',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Best: ${data.bestStreak} ${data.bestStreak == 1 ? 'day' : 'days'}',
                  style: TextStyle(fontSize: 12, color: colors.textSecondary),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 84,
            height: 84,
            child: TweenAnimationBuilder<double>(
              tween: Tween(end: progress),
              duration: const Duration(milliseconds: 700),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) => Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox.expand(
                    child: CircularProgressIndicator(
                      value: value,
                      strokeWidth: 8,
                      strokeCap: StrokeCap.round,
                      backgroundColor: colors.border,
                      color: data.workoutsThisWeek >= goal
                          ? colors.success
                          : colors.primary,
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${data.workoutsThisWeek}/$goal',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          fontFeatures: _tabular,
                        ),
                      ),
                      Text(
                        'this week',
                        style: TextStyle(
                          fontSize: 10,
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WeekStrip extends StatelessWidget {
  static const _letters = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  final DashboardAnalytics data;
  final int today;

  const _WeekStrip({required this.data, required this.today});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          for (var day = 1; day <= 7; day++)
            Column(
              children: [
                Text(
                  _letters[day - 1],
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: day == today
                        ? FontWeight.w800
                        : FontWeight.w500,
                    color: day == today
                        ? colors.textPrimary
                        : colors.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: data.trainedWeekdays.contains(day)
                        ? colors.success
                        : Colors.transparent,
                    border: Border.all(
                      color: data.trainedWeekdays.contains(day)
                          ? colors.success
                          : day == today
                          ? colors.primary
                          : colors.textPrimary.withValues(alpha: 0.1),
                      width: day == today ? 2 : 1,
                    ),
                  ),
                  child: data.trainedWeekdays.contains(day)
                      ? Icon(
                          Icons.check_rounded,
                          size: 18,
                          color: colors.onSuccess,
                        )
                      : null,
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String value;
  final String label;
  final int? trend;

  const _StatCard({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
    this.trend,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return AppCard(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, size: 20, color: color),
              if (trend != null)
                Text(
                  '${trend! >= 0 ? '▲' : '▼'} ${trend!.abs()}%',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: trend! >= 0 ? colors.success : colors.error,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
                fontFeatures: _tabular,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 11, color: colors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _NudgeCard extends StatelessWidget {
  final String message;
  final DashboardAnalytics latest;

  const _NudgeCard({required this.message, required this.latest});

  String? get _lastWorkoutLine {
    final name = latest.latestWorkoutName;
    final since = latest.daysSinceLastWorkout;
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
    final lastLine = _lastWorkoutLine;
    return AppCard(
      color: colors.primary.withValues(alpha: 0.15),
      borderColor: colors.primary.withValues(alpha: 0.3),
      child: Row(
        children: [
          Icon(Icons.bolt_rounded, color: colors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (lastLine != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    lastLine,
                    style: TextStyle(fontSize: 12, color: colors.textSecondary),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
