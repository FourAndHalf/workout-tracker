import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons_600.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_card.dart';
import '../../../data/models/program_model.dart';
import 'exercise_tile.dart';

class BlockCard extends StatelessWidget {
  final BlockModel block;
  final int blockIndex;
  final Map<String, ActiveExerciseLogState>? activeExerciseStates;

  const BlockCard({
    super.key,
    required this.block,
    required this.blockIndex,
    this.activeExerciseStates,
  });

  Color _getBlockBadgeColor(BuildContext context, String type) {
    switch (type) {
      case 'superset':
        return context.colors.supersetBlock;
      case 'triSet':
        return context.colors.triSetBlock;
      case 'giantSet':
        return context.colors.giantSetBlock;
      case 'dropSet':
        return context.colors.dropSetBlock;
      case 'restPause':
      case 'recovery':
      case 'cooldown':
        return context.colors.restPauseBlock;
      case 'warmup':
      case 'mobility':
        return context.colors.supersetBlock;
      case 'strength':
        return context.colors.dropSetBlock;
      case 'conditioning':
      case 'circuit':
      case 'intervals':
        return context.colors.triSetBlock;
      case 'endurance':
        return context.colors.giantSetBlock;
      case 'straight':
      default:
        return context.colors.straightBlock;
    }
  }

  String _getBlockBadgeText(String type) {
    switch (type) {
      case 'superset':
        return 'SUPERSET';
      case 'triSet':
        return 'TRI-SET';
      case 'giantSet':
        return 'GIANT SET';
      case 'dropSet':
        return 'DROP SET';
      case 'restPause':
        return 'REST PAUSE';
      case 'warmup':
        return 'WARM-UP';
      case 'mobility':
        return 'MOBILITY';
      case 'strength':
        return 'STRENGTH';
      case 'conditioning':
        return 'CONDITIONING';
      case 'recovery':
        return 'RECOVERY';
      case 'cooldown':
        return 'COOL-DOWN';
      case 'circuit':
        return 'CIRCUIT';
      case 'endurance':
        return 'ENDURANCE';
      case 'intervals':
        return 'INTERVALS';
      case 'straight':
      default:
        return 'STRAIGHT';
    }
  }

  bool _isComplete(BlockModel block) {
    final states = activeExerciseStates;
    if (states == null || block.exercises.isEmpty) return false;
    return block.exercises.every((exercise) {
      final state = states[exercise.id];
      if (state == null) return false;
      if (exercise.logMode == 'cumulative') {
        final total = state.restPauseChunks.fold(0, (sum, v) => sum + v);
        return total >= (exercise.repTarget ?? 100);
      }
      return state.loggedSets.length >= exercise.targetSets;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final badgeColor = _getBlockBadgeColor(context, block.type);
    final isActive = activeExerciseStates != null;
    final complete = _isComplete(block);
    final sets =
        '${block.targetSets} ${block.targetSets == 1 ? 'set' : 'sets'}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: complete ? colors.primary : colors.surface,
                  ),
                  child: complete
                      ? Icon(
                          LucideIcons600.check,
                          size: 16,
                          color: colors.onPrimary,
                        )
                      : Text(
                          (blockIndex + 1).toString().padLeft(2, '0'),
                          style: AppText.metricDelta.copyWith(
                            color: colors.textSecondary,
                          ),
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(block.name, style: textTheme.titleMedium),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          // Straight sets are the default; only special
                          // block types get a badge.
                          if (block.type != 'straight') ...[
                            _BlockBadge(
                              label: _getBlockBadgeText(block.type),
                              color: badgeColor,
                            ),
                            const SizedBox(width: 8),
                          ],
                          Text(
                            sets,
                            style: textTheme.bodySmall?.copyWith(
                              color: colors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            if (block.instructions != null && block.instructions!.isNotEmpty)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(top: 12),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      LucideIcons600.info,
                      size: 14,
                      color: colors.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        block.instructions!,
                        style: textTheme.bodySmall?.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            SizedBox(height: isActive ? 12 : 4),
            for (var i = 0; i < block.exercises.length; i++) ...[
              if (!isActive && i > 0)
                Divider(indent: 48, color: colors.divider),
              ExerciseTile(
                exercise: block.exercises[i],
                activeState: activeExerciseStates?[block.exercises[i].id],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Block type as a small neutral badge with a colored dot, so the type reads
/// without tinting the module.
class _BlockBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _BlockBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    height: 20,
    padding: const EdgeInsets.symmetric(horizontal: 8),
    decoration: BoxDecoration(
      color: context.colors.raised,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      border: Border.all(color: context.colors.border),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: AppText.labelUppercase.copyWith(
            color: context.colors.textPrimary,
          ),
        ),
      ],
    ),
  );
}
