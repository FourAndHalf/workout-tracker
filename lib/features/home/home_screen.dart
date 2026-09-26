import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/day_app_bar.dart';
import '../../services/streak_widget_service.dart';
import '../program/program_providers.dart';
import '../workout/providers/active_workout_session_notifier.dart';
import 'home_providers.dart';
import 'widgets/dashboard_stats.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analytics = ref.watch(dashboardAnalyticsProvider);
    ref.listen(dashboardAnalyticsProvider, (_, next) {
      final data = next.value;
      if (data != null) {
        StreakWidgetService().updateStreak(data.currentStreak).ignore();
      }
    });
    final nextWorkout = ref.watch(nextWorkoutDayProvider).value;
    final now = DateTime.now();
    final quote = dailyMotivationQuote(now);

    return Scaffold(
      appBar: DayAppBar(
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
      body: Column(
        children: [
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => ref.refresh(dashboardAnalyticsProvider.future),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  _QuoteCard(quote: quote),
                  const SizedBox(height: 12),
                  _StartWorkoutCard(next: nextWorkout),
                  const SizedBox(height: 24),
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
          ),
        ],
      ),
    );
  }
}

class _StartWorkoutCard extends ConsumerWidget {
  final NextWorkoutInfo? next;

  const _StartWorkoutCard({required this.next});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final next = this.next;
    final active = ref.watch(activeWorkoutSessionProvider);
    final resuming = active != null;
    final enabled = resuming || next != null;
    final accent = resuming ? colors.primary : colors.success;
    final fill = enabled ? accent : colors.surface;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: enabled
            ? [
                BoxShadow(
                  color: accent.withValues(alpha: 0.25),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ]
            : null,
      ),
      child: Material(
        color: fill,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: resuming
              ? () => context.push('/programs/ffts-4week/${active.dayId}')
              : next == null
              ? null
              : () => context.push('/programs/${next.programId}/${next.dayId}'),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.play_arrow_rounded,
                    size: 32,
                    color: enabled ? Colors.white : colors.textMuted,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        resuming
                            ? 'Go back to ${active.dayName} Workout'
                            : next == null
                            ? 'No workout due'
                            : 'Start ${next.dayName} Workout',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                          color: enabled ? Colors.white : colors.textMuted,
                        ),
                      ),
                      if (resuming) ...[
                        const SizedBox(height: 4),
                        const Text(
                          'Tap to return',
                          style: TextStyle(fontSize: 13, color: Colors.white70),
                        ),
                      ] else if (next != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Week ${next.weekNumber} \u00B7 ${next.exerciseCount} Exercises',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (enabled)
                  const Icon(Icons.chevron_right_rounded, color: Colors.white),
              ],
            ),
          ),
        ),
      ),
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
