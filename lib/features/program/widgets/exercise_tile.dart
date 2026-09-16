import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/program_model.dart';

class ExerciseTile extends StatelessWidget {
  final ExerciseModel exercise;

  const ExerciseTile({
    super.key,
    required this.exercise,
  });

  IconData _getLogModeIcon(String logMode) {
    switch (logMode) {
      case 'cumulative':
        return Icons.donut_large_rounded;
      case 'failure':
        return Icons.local_fire_department_rounded;
      case 'time':
        return Icons.timer_outlined;
      case 'repsOnly':
        return Icons.accessibility_new_rounded;
      case 'weightReps':
      default:
        return Icons.fitness_center_rounded;
    }
  }

  String _formatSetsReps() {
    if (exercise.repTarget != null) {
      return '${exercise.targetSets} Sets \u00B7 Target: ${exercise.repTarget} reps';
    }
    if (exercise.repScheme != null && exercise.repScheme!.isNotEmpty) {
      final unit = exercise.repUnit != null ? ' ${exercise.repUnit}' : '';
      return '${exercise.targetSets} Sets \u00B7 (${exercise.repScheme!.join(", ")})$unit';
    }
    return '${exercise.targetSets} Sets';
  }

  Future<void> _openExerciseVideo(BuildContext context) async {
    if (await launchUrl(
      exercise.exerciseVideoUri,
      mode: LaunchMode.externalApplication,
    )) {
      return;
    }
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to open YouTube Shorts.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border.withValues(alpha:0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.card,
            child: Icon(
              _getLogModeIcon(exercise.logMode),
              size: 16,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => _openExerciseVideo(context),
                        child: Text(
                          exercise.name,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                            decoration: TextDecoration.underline,
                            decorationColor: AppColors.textMuted,
                          ),
                        ),
                      ),
                    ),
                    if (!exercise.prescriptionComplete)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withValues(alpha:0.15),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: AppColors.warning, width: 0.5),
                        ),
                        child: const Text(
                          'Incomplete',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppColors.warning,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  _formatSetsReps(),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.secondary,
                  ),
                ),
                if (exercise.prescription != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    exercise.prescription!,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                      fontStyle: FontStyle.italic,
                    ),
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
