import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import 'program_providers.dart';

class ProgramListScreen extends ConsumerWidget {
  const ProgramListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final programAsync = ref.watch(currentProgramProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Workout Program')),
      body: programAsync.when(
        data: (program) {
          final sessionsAsync = ref.watch(completedWorkoutSessionsProvider);
          final sessions = sessionsAsync.valueOrNull ?? const [];
          final week = program.weeks[activeWeekIndex(program, sessions)];
          final completedDays = sessions
              .where((session) => session.weekId == week.id)
              .map((session) => session.dayId)
              .toSet();
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: context.colors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: context.colors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        program.programName,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: context.colors.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Week ${week.number}: "${week.title}"',
                        style: TextStyle(
                          fontSize: 14,
                          color: context.colors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (program.sourceNote != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          program.sourceNote!,
                          style: TextStyle(
                            fontSize: 11,
                            color: context.colors.textMuted,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                Text(
                  'Training Days',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: context.colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),

                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: week.days.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final day = week.days[index];
                    final exerciseCount = day.blocks.fold<int>(
                      0,
                      (prev, block) => prev + block.exercises.length,
                    );

                    final isCompleted = completedDays.contains(day.id);
                    return Card(
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        leading: CircleAvatar(
                          backgroundColor: context.colors.surface,
                          child: Text(
                            '${day.order}',
                            style: TextStyle(
                              color: context.colors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Row(
                          children: [
                            Text(
                              day.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            if (isCompleted) ...[
                              const SizedBox(width: 8),
                              Icon(
                                Icons.check_circle,
                                color: context.colors.primary,
                                size: 18,
                              ),
                            ],
                            if (day.needsReview == true) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: context.colors.warning.withValues(
                                    alpha: 0.15,
                                  ),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: context.colors.warning,
                                    width: 0.5,
                                  ),
                                ),
                                child: Text(
                                  'Review',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: context.colors.warning,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        subtitle: Text(
                          '${day.blocks.length} Blocks \u00B7 $exerciseCount Exercises',
                          style: TextStyle(
                            fontSize: 12,
                            color: context.colors.textSecondary,
                          ),
                        ),
                        trailing: isCompleted
                            ? Text(
                                'Done',
                                style: TextStyle(
                                  color: context.colors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            : Icon(
                                Icons.chevron_right,
                                color: context.colors.textMuted,
                              ),
                        onTap: () {
                          context.push(
                            '/programs/${program.programId}/${day.id}',
                          );
                        },
                      ),
                    );
                  },
                ),
              ],
            ),
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
