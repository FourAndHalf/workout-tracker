import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_card.dart';
import '../../../data/models/program_model.dart';
import 'exercise_tile.dart';

class BlockCard extends StatelessWidget {
  final BlockModel block;
  final int blockIndex;

  const BlockCard({super.key, required this.block, required this.blockIndex});

  Color _getBlockBadgeColor(String type) {
    switch (type) {
      case 'superset':
        return AppColors.supersetBlock;
      case 'triSet':
        return AppColors.triSetBlock;
      case 'giantSet':
        return AppColors.giantSetBlock;
      case 'dropSet':
        return AppColors.dropSetBlock;
      case 'restPause':
        return AppColors.restPauseBlock;
      case 'straight':
      default:
        return AppColors.straightBlock;
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
      case 'straight':
      default:
        return 'STRAIGHT';
    }
  }

  @override
  Widget build(BuildContext context) {
    final badgeColor = _getBlockBadgeColor(block.type);
    final badgeText = _getBlockBadgeText(block.type);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: AppCard(
        padding: EdgeInsets.zero,
        borderColor: block.type == 'straight'
            ? AppColors.border
            : badgeColor.withValues(alpha: 0.5),
        borderWidth: block.type == 'straight' ? 1 : 1.5,
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(11),
                topRight: Radius.circular(11),
              ),
              border: Border(
                bottom: BorderSide(
                  color: AppColors.border.withValues(alpha: 0.5),
                ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: badgeColor, width: 1),
                  ),
                  child: Text(
                    badgeText,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: badgeColor,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    block.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                Text(
                  '${block.targetSets} Sets',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          if (block.instructions != null && block.instructions!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    size: 14,
                    color: AppColors.warning,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      block.instructions!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.warning,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: block.exercises
                  .map((e) => ExerciseTile(exercise: e))
                  .toList(),
            ),
          ),
        ],
        ),
      ),
    );
  }
}
