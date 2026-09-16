import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_card.dart';
import 'home_providers.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analytics = ref.watch(dashboardAnalyticsProvider);
    final now = DateTime.now();
    final quote = dailyMotivationQuote(now);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(dashboardAnalyticsProvider.future),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            _TodayHeader(date: now),
            const SizedBox(height: 14),
            _QuoteCard(quote: quote),
            const SizedBox(height: 24),
            const _SectionLabel('Quick actions'),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _ActionTile(
                    icon: Icons.play_arrow_rounded,
                    label: 'Start',
                    color: AppColors.primary,
                    onTap: () => context.push('/workout/w1-arms'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ActionTile(
                    icon: Icons.list_alt_rounded,
                    label: 'Plan',
                    color: AppColors.secondary,
                    onTap: () => context.go('/programs'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ActionTile(
                    icon: Icons.camera_alt_outlined,
                    label: 'Food',
                    color: AppColors.warning,
                    onTap: () => context.go('/nutrition'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ActionTile(
                    icon: Icons.music_note_rounded,
                    label: 'Music',
                    color: AppColors.secondary,
                    onTap: () async {
                      await launchUrl(
                        Uri.parse('https://open.spotify.com/'),
                        mode: LaunchMode.externalApplication,
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const _SectionLabel('Your week at a glance'),
            const SizedBox(height: 10),
            analytics.when(
              loading: () => const SizedBox(
                height: 160,
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, _) =>
                  const _AnalyticsMessage('Analytics unavailable'),
              data: (data) => Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _MetricTile(
                          value: '${data.workoutsThisWeek}',
                          label: 'Workouts',
                          icon: Icons.fitness_center_rounded,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _MetricTile(
                          value: '${data.setsThisWeek}',
                          label: 'Sets',
                          icon: Icons.check_circle_outline_rounded,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _MetricTile(
                          value: '${data.currentStreak}',
                          label: 'Day streak',
                          icon: Icons.local_fire_department_outlined,
                          highlight: true,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _VolumeTile(data: data),
                  const SizedBox(height: 10),
                  _LatestWorkoutTile(data: data),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
  );
}

class _TodayHeader extends StatelessWidget {
  final DateTime date;

  const _TodayHeader({required this.date});

  @override
  Widget build(BuildContext context) {
    final hour = date.hour;
    final greeting = hour < 12
        ? 'Good morning'
        : hour < 17
        ? 'Good afternoon'
        : 'Good evening';
    final weekday = const [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ][date.weekday - 1];
    const months = [
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
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          greeting,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          '$weekday, ${date.day} ${months[date.month - 1]}',
          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

class _QuoteCard extends StatelessWidget {
  final MotivationQuote quote;

  const _QuoteCard({required this.quote});

  @override
  Widget build(BuildContext context) => AppCard(
    padding: const EdgeInsets.fromLTRB(16, 15, 16, 14),
    child: SizedBox(
      width: double.infinity,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.format_quote_rounded,
            color: AppColors.warning,
            size: 23,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  quote.quote,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  quote.source,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textMuted,
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

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => AppCard(
    onTap: onTap,
    padding: const EdgeInsets.all(10),
    child: SizedBox(
      height: 62,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 25),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    ),
  );
}

class _MetricTile extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final bool highlight;

  const _MetricTile({
    required this.value,
    required this.label,
    required this.icon,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) => AppCard(
    color: highlight
        ? AppColors.primary.withValues(alpha: 0.10)
        : AppColors.surface,
    borderColor: highlight ? AppColors.primary.withValues(alpha: 0.4) : null,
    padding: const EdgeInsets.fromLTRB(12, 10, 12, 11),
    child: ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 68),
      child: Stack(
        children: [
          Positioned(
            left: -12,
            top: 0,
            bottom: 0,
            child: Container(
              width: highlight ? 5 : 3,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: const BorderRadius.horizontal(
                  right: Radius.circular(3),
                ),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(icon, size: 18, color: AppColors.primary),
                  const Icon(
                    Icons.arrow_outward_rounded,
                    size: 14,
                    color: AppColors.textMuted,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                  color: highlight ? AppColors.primary : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

class _VolumeTile extends StatelessWidget {
  final DashboardAnalytics data;

  const _VolumeTile({required this.data});

  @override
  Widget build(BuildContext context) => AppCard(
    padding: const EdgeInsets.all(14),
    child: Row(
      children: [
        const Icon(Icons.trending_up_rounded, color: AppColors.secondary),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Training volume',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            Text(
              '${data.volumeThisWeek.toStringAsFixed(0)} kg',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const Spacer(),
        if (data.topExerciseName != null)
          Text(
            '${data.topExerciseName}\n${data.topExerciseWeight!.toStringAsFixed(1)} kg best',
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
      ],
    ),
  );
}

class _LatestWorkoutTile extends StatelessWidget {
  final DashboardAnalytics data;

  const _LatestWorkoutTile({required this.data});

  @override
  Widget build(BuildContext context) => AppCard(
    color: AppColors.surface,
    padding: const EdgeInsets.all(14),
    child: Row(
      children: [
        const Icon(Icons.history_rounded, color: AppColors.primary),
        const SizedBox(width: 12),
        Text(
          data.latestWorkoutName == null
              ? 'No completed workouts yet'
              : 'Last workout\n${data.latestWorkoutName}',
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ],
    ),
  );
}

class _AnalyticsMessage extends StatelessWidget {
  final String message;

  const _AnalyticsMessage(this.message);

  @override
  Widget build(BuildContext context) => AppCard(
    color: AppColors.surface,
    padding: const EdgeInsets.all(20),
    child: Center(
      child: Text(
        message,
        style: const TextStyle(color: AppColors.textSecondary),
      ),
    ),
  );
}
