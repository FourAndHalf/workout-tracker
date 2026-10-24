import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons_600.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/day_app_bar.dart';
import '../../core/widgets/ledger.dart';
import '../../services/home_widget_service.dart';
import '../program/program_providers.dart';
import '../workout/providers/active_workout_session_notifier.dart';
import '../workout/start_workout.dart';
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
        final now = DateTime.now();
        HomeWidgetService()
            .publish(
              HomeWidgetData.compute(
                now: now,
                trainingDays: data.trainingDays,
                quote: dailyMotivationQuote(now),
              ),
            )
            .ignore();
      }
    });
    final nextWorkout = ref.watch(nextWorkoutDayProvider).value;
    final now = DateTime.now();
    final quote = dailyMotivationQuote(now);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () => ref.refresh(dashboardAnalyticsProvider.future),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Header(now: now),
                const SizedBox(height: 20),
                _TodayCard(
                  next: nextWorkout,
                  trainedToday: analytics.value?.trainedToday ?? false,
                ),
                const SizedBox(height: 12),
                analytics.when(
                  loading: () => const SizedBox(
                    height: 160,
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (error, _) =>
                      const _AnalyticsMessage('Analytics unavailable'),
                  data: (data) => DashboardStats(data: data, now: now),
                ),
                const SizedBox(height: 12),
                _QuoteCard(quote: quote),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Greeting in `headline-xl-mobile` with the date beneath, actions right.
class _Header extends StatelessWidget {
  final DateTime now;

  const _Header({required this.now});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(greetingFor(now), style: textTheme.headlineSmall),
              const SizedBox(height: 2),
              Text(
                '${weekdayLabel(now)}, ${shortDateLabel(now)}',
                style: textTheme.bodyMedium?.copyWith(
                  color: context.colors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        RoundIconButton(
          tooltip: 'Open Spotify',
          icon: LucideIcons600.music,
          onPressed: () => launchUrl(
            Uri.parse('https://open.spotify.com/'),
            mode: LaunchMode.externalApplication,
          ),
        ),
        const SizedBox(width: 8),
        RoundIconButton(
          tooltip: 'Settings',
          icon: LucideIcons600.settings,
          onPressed: () => context.push('/settings'),
        ),
      ],
    );
  }
}

/// The hero module: the session to do next (or the one in progress), on the
/// screen's one decorative pearl gradient.
class _TodayCard extends ConsumerWidget {
  final NextWorkoutInfo? next;
  final bool trainedToday;

  const _TodayCard({required this.next, required this.trainedToday});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final next = this.next;
    final active = ref.watch(activeWorkoutSessionProvider);
    final resuming = active != null;

    final String eyebrow;
    final String title;
    final String? details;
    if (resuming) {
      eyebrow = 'In progress';
      title = active.dayName;
      details = 'Pick up where you left off';
    } else if (next != null) {
      eyebrow = trainedToday ? 'Up next' : "Today's session";
      title = next.dayName;
      details = [
        'Week ${next.weekNumber}',
        '${next.exerciseCount} exercises',
        if (next.estimatedMinutes > 0) '~${next.estimatedMinutes} min',
      ].join(' · ');
    } else {
      eyebrow = 'Today';
      title = 'No workout due';
      details = null;
    }

    final program = ref.watch(currentProgramProvider).value;
    final VoidCallback? onStart = resuming
        ? () => context.push('/programs/${active.programId}/${active.dayId}')
        : next == null || program == null
        ? null
        : () {
            final (week, day) = locateDay(program, next.dayId);
            startWorkoutAndOpen(
              context,
              ref,
              programId: next.programId,
              week: week,
              day: day,
            );
          };

    return AppCard(
      radius: AppRadius.xl,
      padding: const EdgeInsets.all(20),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [colors.heroStart, colors.heroEnd],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  eyebrow,
                  style: textTheme.bodySmall?.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ),
              if (resuming)
                StatusBadge(
                  'Live',
                  icon: LucideIcons600.circle,
                  foreground: colors.info,
                  background: colors.infoContainer,
                )
              else if (trainedToday)
                StatusBadge(
                  'Trained today',
                  icon: LucideIcons600.check,
                  foreground: colors.success,
                  background: colors.successContainer,
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(title, style: textTheme.headlineSmall),
          if (details != null) ...[
            const SizedBox(height: 4),
            Text(
              details,
              style: textTheme.bodyMedium?.copyWith(
                color: colors.textSecondary,
              ),
            ),
          ],
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  icon: Icon(
                    resuming ? LucideIcons600.arrowRight : LucideIcons600.play,
                  ),
                  label: Text(resuming ? 'Resume workout' : 'Start workout'),
                  onPressed: onStart,
                ),
              ),
              if (!resuming && next != null) ...[
                const SizedBox(width: 8),
                RoundIconButton(
                  icon: LucideIcons600.listChecks,
                  tooltip: 'Preview ${next.dayName}',
                  size: 48,
                  onPressed: () =>
                      context.push('/programs/${next.programId}/${next.dayId}'),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _QuoteCard extends StatelessWidget {
  final MotivationQuote quote;

  const _QuoteCard({required this.quote});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    return AppCard(
      flat: true,
      color: colors.surface,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(LucideIcons600.quote, color: colors.textSecondary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(quote.quote, style: textTheme.bodyMedium),
                const SizedBox(height: 6),
                Text(
                  quote.source,
                  style: textTheme.bodySmall?.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AnalyticsMessage extends StatelessWidget {
  final String message;

  const _AnalyticsMessage(this.message);

  @override
  Widget build(BuildContext context) => AppCard(
    flat: true,
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
