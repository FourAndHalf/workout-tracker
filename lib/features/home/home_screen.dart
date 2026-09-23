import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_card.dart';
import '../../services/streak_widget_service.dart';
import '../program/program_providers.dart';
import 'home_providers.dart';

const _greetings = [
  "Let's get after it",
  'Ready to train?',
  'Make today count',
  'Time to move',
  'Stay consistent',
  'Show up. Lift. Repeat.',
  'Strong start today',
];

/// A short greeting that changes once per day.
String dailyGreeting(DateTime date) {
  final dayOfYear = date.difference(DateTime(date.year)).inDays;
  return _greetings[dayOfYear % _greetings.length];
}

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analytics = ref.watch(dashboardAnalyticsProvider);
    ref.listen(dashboardAnalyticsProvider, (_, next) {
      final data = next.valueOrNull;
      if (data != null) {
        StreakWidgetService().updateStreak(data.currentStreak).ignore();
      }
    });
    final nextWorkout = ref.watch(nextWorkoutDayProvider).valueOrNull;
    final now = DateTime.now();
    final quote = dailyMotivationQuote(now);

    return Scaffold(
      appBar: AppBar(
        title: Text(dailyGreeting(now)),
        actions: [
          IconButton(
            tooltip: 'Open Spotify',
            icon: const Icon(Icons.music_note_rounded),
            onPressed: () => launchUrl(
              Uri.parse('https://open.spotify.com/'),
              mode: LaunchMode.externalApplication,
            ),
          ),
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
            _QuoteCard(quote: quote),
            const SizedBox(height: 24),
            SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.play_arrow_rounded),
                label: Text(
                  nextWorkout == null
                      ? 'No workout due'
                      : 'Start ${nextWorkout.dayName} Workout',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onPressed: nextWorkout == null
                    ? null
                    : () => context.push(
                        '/programs/${nextWorkout.programId}/${nextWorkout.dayId}',
                      ),
              ),
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
          Icon(
            Icons.format_quote_rounded,
            color: context.colors.warning,
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
                  style: TextStyle(
                    fontSize: 11,
                    color: context.colors.textMuted,
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
        ? context.colors.primary.withValues(alpha: 0.10)
        : context.colors.surface,
    borderColor: highlight
        ? context.colors.primary.withValues(alpha: 0.4)
        : null,
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
                color: context.colors.primary,
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
                  Icon(icon, size: 18, color: context.colors.primary),
                  Icon(
                    Icons.arrow_outward_rounded,
                    size: 14,
                    color: context.colors.textMuted,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                  color: highlight
                      ? context.colors.primary
                      : context.colors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: context.colors.textSecondary,
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
        Icon(Icons.trending_up_rounded, color: context.colors.secondary),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Training volume',
              style: TextStyle(
                fontSize: 12,
                color: context.colors.textSecondary,
              ),
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
            style: TextStyle(fontSize: 11, color: context.colors.textSecondary),
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
    color: context.colors.surface,
    padding: const EdgeInsets.all(14),
    child: Row(
      children: [
        Icon(Icons.history_rounded, color: context.colors.primary),
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
    color: context.colors.surface,
    padding: const EdgeInsets.all(20),
    child: Center(
      child: Text(
        message,
        style: TextStyle(color: context.colors.textSecondary),
      ),
    ),
  );
}
