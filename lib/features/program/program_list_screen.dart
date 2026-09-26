import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/day_app_bar.dart';
import '../../core/widgets/tag_pill.dart';
import '../../data/models/program_model.dart';
import 'program_providers.dart';

class ProgramListScreen extends ConsumerWidget {
  const ProgramListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final programAsync = ref.watch(currentProgramProvider);

    return Scaffold(
      appBar: const DayAppBar(),
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
          final nextDayId = nextWorkoutFor(program, sessions)?.dayId;
          final doneCount = week.days
              .where((day) => completedDays.contains(day.id))
              .length;
          final totalDays = week.days.length;
          final progress = totalDays == 0 ? 0.0 : doneCount / totalDays;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              AppCard(
                borderColor: colors.primary.withValues(alpha: 0.3),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        TagPill('Program', color: colors.primary),
                        const Spacer(),
                        TagPill(
                          'Week ${week.number} of ${program.weeks.length}',
                          color: colors.textSecondary,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      program.programName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Week ${week.number}: "${week.title}"',
                      style: TextStyle(
                        fontSize: 14,
                        color: colors.textSecondary,
                      ),
                    ),
                    if (program.sourceNote != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        program.sourceNote!,
                        style: TextStyle(
                          fontSize: 11,
                          color: colors.textMuted,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    Divider(color: colors.border),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Week completion',
                          style: TextStyle(
                            fontSize: 13,
                            color: colors.textSecondary,
                          ),
                        ),
                        Text(
                          '$doneCount of $totalDays done (${(progress * 100).round()}%)',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: colors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 8,
                        backgroundColor: colors.surface,
                        color: colors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              const Text(
                'Weekly Training Split',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '$totalDays sessions',
                style: TextStyle(fontSize: 12, color: colors.textSecondary),
              ),
              const SizedBox(height: 12),
              for (final day in week.days)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _DayCard(
                    day: day,
                    isCompleted: completedDays.contains(day.id),
                    isToday: day.id == nextDayId,
                    onTap: () => context.push(
                      '/programs/${program.programId}/${day.id}',
                    ),
                  ),
                ),
            ],
          );
        },
        loading: () => Center(
          child: CircularProgressIndicator(color: context.colors.primary),
        ),
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
  final VoidCallback onTap;

  const _DayCard({
    required this.day,
    required this.isCompleted,
    required this.isToday,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final exercises = [for (final block in day.blocks) ...block.exercises];
    final accent = isCompleted
        ? colors.success
        : isToday
        ? colors.primary
        : colors.textSecondary;
    return AppCard(
      onTap: onTap,
      borderColor: isToday ? colors.primary : null,
      borderWidth: isToday ? 1.5 : 1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isToday
                      ? colors.primary
                      : accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: isToday
                      ? null
                      : Border.all(color: accent.withValues(alpha: 0.3)),
                ),
                child: Text(
                  '${day.order}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: isToday ? Colors.white : accent,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      day.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${day.blocks.length} Blocks \u00B7 ${exercises.length} Exercises',
                      style: TextStyle(
                        fontSize: 12,
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (isCompleted)
                TagPill('Completed', color: colors.success)
              else if (isToday)
                TagPill('Today', color: colors.primary)
              else
                TagPill('Upcoming', color: colors.textMuted),
            ],
          ),
          if (exercises.isNotEmpty || day.needsReview == true) ...[
            const SizedBox(height: 12),
            Divider(color: colors.border, height: 1),
            const SizedBox(height: 10),
            Row(
              children: [
                if (exercises.isNotEmpty)
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        text: 'Primary: ',
                        style: TextStyle(fontSize: 12, color: colors.textMuted),
                        children: [
                          TextSpan(
                            text: exercises.first.name,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: colors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                if (day.needsReview == true) ...[
                  const SizedBox(width: 8),
                  TagPill('Review', color: colors.warning),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}
