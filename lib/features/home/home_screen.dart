import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_card.dart';
import '../../services/streak_widget_service.dart';
import '../program/program_providers.dart';
import 'home_providers.dart';
import 'widgets/dashboard_stats.dart';

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
              data: (data) => DashboardStats(data: data, now: now),
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
