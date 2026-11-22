import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons_600.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/day_app_bar.dart';
import '../../core/widgets/ledger.dart';
import '../../core/widgets/tag_pill.dart';
import '../../data/models/program_model.dart';
import '../../core/utils/workout_estimate.dart';
import '../workout/providers/active_workout_session_notifier.dart';
import '../workout/start_workout.dart';
import 'program_providers.dart';

class ProgramListScreen extends ConsumerWidget {
  const ProgramListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final programAsync = ref.watch(currentProgramProvider);

    return Scaffold(
      appBar: const DayAppBar(title: 'Programs'),
      body: programAsync.when(
        data: (program) {
          final sessionsAsync = ref.watch(completedWorkoutSessionsProvider);
          final sessions = sessionsAsync.value ?? const [];
          final week = program.weeks[activeWeekIndex(program, sessions)];
          final completedDays = sessions
              .where((session) => session.weekId == week.id)
              .map((session) => session.dayId)
              .toSet();
          final colors = context.colors;
          final textTheme = Theme.of(context).textTheme;
          final nextDayId = nextWorkoutFor(program, sessions)?.dayId;
          final active = ref.watch(activeWorkoutSessionProvider);
          // Rest days are listed but never counted or started.
          final trainingDays = week.trainingDays;
          final doneCount = trainingDays
              .where((day) => completedDays.contains(day.id))
              .length;
          final totalDays = trainingDays.length;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            children: [
              const _TrackSwitcher(),
              AppCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Week ${week.number} of ${program.weeks.length}',
                            style: textTheme.bodySmall?.copyWith(
                              color: colors.textSecondary,
                            ),
                          ),
                        ),
                        Text(
                          '$doneCount/$totalDays done',
                          style: AppText.metricTable.copyWith(fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(program.programName, style: textTheme.headlineSmall),
                    const SizedBox(height: 4),
                    Text(
                      'Week ${week.number}: "${week.title}"',
                      style: textTheme.bodyMedium?.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                    if (week.focus != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        week.focus!,
                        style: textTheme.bodySmall?.copyWith(
                          color: colors.textMuted,
                        ),
                      ),
                    ],
                    if (program.sourceNote != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        program.sourceNote!,
                        style: textTheme.bodySmall?.copyWith(
                          color: colors.textMuted,
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    SegmentProgress(total: totalDays, filled: doneCount),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              ModuleHeader(
                'Weekly Training Split',
                subtitle:
                    '$totalDays sessions · tap a day to preview, Start to train',
              ),
              const SizedBox(height: 12),
              for (final day in week.days)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _DayCard(
                    day: day,
                    isCompleted: completedDays.contains(day.id),
                    isToday: day.id == nextDayId,
                    isRunning: active?.dayId == day.id,
                    onTap: () => context.push(
                      '/programs/${program.programId}/${day.id}',
                    ),
                    onStart: () => startWorkoutAndOpen(
                      context,
                      ref,
                      programId: program.programId,
                      week: week,
                      day: day,
                    ),
                  ),
                ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) =>
            Center(child: Text('Error loading program: $err')),
      ),
    );
  }
}

class _DayCard extends StatelessWidget {
  final DayModel day;
  final bool isCompleted;
  final bool isToday;
  final bool isRunning;
  final VoidCallback onTap;
  final VoidCallback onStart;

  const _DayCard({
    required this.day,
    required this.isCompleted,
    required this.isToday,
    required this.isRunning,
    required this.onTap,
    required this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final exercises = day.blocks.fold<int>(
      0,
      (total, block) => total + block.exercises.length,
    );
    final minutes = estimateWorkoutMinutes(day);
    final emphasised = isToday || isRunning;

    final Widget trailing;
    if (day.isRestDay) {
      trailing = Icon(LucideIcons600.moon, size: 18, color: colors.textMuted);
    } else if (isRunning) {
      trailing = _PillButton(label: 'Resume', onPressed: onStart);
    } else if (isToday) {
      trailing = _PillButton(label: 'Start', onPressed: onStart);
    } else if (isCompleted) {
      trailing = StatusBadge(
        'Done',
        icon: LucideIcons600.check,
        foreground: colors.success,
        background: colors.successContainer,
      );
    } else {
      trailing = Icon(LucideIcons600.chevronRight, color: colors.textMuted);
    }

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
      borderColor: emphasised ? colors.primary : null,
      borderWidth: emphasised ? 1.5 : 1,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: emphasised || isCompleted
                  ? colors.primary
                  : colors.surface,
            ),
            child: isCompleted && !emphasised
                ? Icon(LucideIcons600.check, size: 18, color: colors.onPrimary)
                : Text(
                    '${day.order}',
                    style: AppText.metricTable.copyWith(
                      color: emphasised ? colors.onPrimary : colors.textPrimary,
                    ),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        day.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.titleMedium,
                      ),
                    ),
                    if (day.needsReview == true) ...[
                      const SizedBox(width: 8),
                      TagPill('Review', color: colors.warning),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  day.isRestDay
                      ? 'Rest day · nothing to log'
                      : '$exercises exercises · ~$minutes min',
                  style: textTheme.bodySmall?.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          trailing,
        ],
      ),
    );
  }
}

class _PillButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const _PillButton({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) => ElevatedButton.icon(
    style: ElevatedButton.styleFrom(
      minimumSize: const Size(0, 40),
      padding: const EdgeInsets.symmetric(horizontal: 14),
    ),
    icon: const Icon(LucideIcons600.play, size: 18),
    label: Text(label),
    onPressed: onPressed,
  );
}

/// The bundled workout tracks as one row of chips: every option visible,
/// one tap to switch. Each track keeps its own progress because sessions are
/// filtered by programId.
class _TrackSwitcher extends ConsumerWidget {
  const _TrackSwitcher();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tracks = ref.watch(availableProgramsProvider).value;
    if (tracks == null) return const SizedBox.shrink();
    final selectedId = ref.watch(selectedProgramIdProvider);
    // Gym and home splits are browsed in Explore; the one you picked shows
    // here as its own chip so you can see it is active.
    final selectedSplit = ref.watch(currentProgramProvider).value;
    final programs = [
      ...tracks,
      if (selectedSplit != null &&
          selectedSplit.isSplit &&
          selectedSplit.programId == selectedId)
        selectedSplit,
    ];
    if (programs.length < 2) return const SizedBox.shrink();

    void select(String programId) {
      if (programId == selectedId) return;
      if (ref.read(activeWorkoutSessionProvider) != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Finish your active workout before switching.'),
          ),
        );
        return;
      }
      HapticFeedback.selectionClick();
      ref.read(selectedProgramIdProvider.notifier).select(programId);
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final program in programs) ...[
              ChoiceChip(
                key: ValueKey('track-${program.programId}'),
                label: Text(
                  program.programName,
                  style: TextStyle(
                    color: program.programId == selectedId
                        ? context.colors.onPrimary
                        : context.colors.textPrimary,
                  ),
                ),
                selected: program.programId == selectedId,
                showCheckmark: false,
                onSelected: (_) => select(program.programId),
              ),
              const SizedBox(width: 8),
            ],
            ActionChip(
              key: const ValueKey('track-splits'),
              avatar: Icon(
                LucideIcons600.compass,
                size: 16,
                color: context.colors.textPrimary,
              ),
              label: const Text('Gym & home splits'),
              onPressed: () => context.go('/explore?tab=splits'),
            ),
          ],
        ),
      ),
    );
  }
}
