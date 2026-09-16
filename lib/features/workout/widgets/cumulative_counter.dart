import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class CumulativeCounter extends StatefulWidget {
  final int targetReps;
  final List<int> loggedChunks;
  final Function(int chunkReps) onAddChunk;

  const CumulativeCounter({
    super.key,
    required this.targetReps,
    required this.loggedChunks,
    required this.onAddChunk,
  });

  @override
  State<CumulativeCounter> createState() => _CumulativeCounterState();
}

class _CumulativeCounterState extends State<CumulativeCounter> {
  final TextEditingController _chunkController = TextEditingController(
    text: '20',
  );

  int get totalLogged => widget.loggedChunks.fold(0, (sum, val) => sum + val);

  @override
  void dispose() {
    _chunkController.dispose();
    super.dispose();
  }

  void _submitChunk() {
    final val = int.tryParse(_chunkController.text);
    if (val != null && val > 0) {
      widget.onAddChunk(val);
      _chunkController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = totalLogged;
    final progress = widget.targetReps > 0
        ? (total / widget.targetReps).clamp(0.0, 1.0)
        : 0.0;
    final isComplete = total >= widget.targetReps;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isComplete ? AppColors.primary : AppColors.border,
          width: isComplete ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              SizedBox(
                width: 64,
                height: 64,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 6,
                      backgroundColor: AppColors.border,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isComplete ? AppColors.primary : AppColors.secondary,
                      ),
                    ),
                    Text(
                      '$total',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isComplete
                            ? AppColors.primary
                            : AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isComplete ? 'TARGET REACHED! 🎉' : 'REST-PAUSE PROGRESS',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isComplete
                            ? AppColors.primary
                            : AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$total / ${widget.targetReps} Reps Completed',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (widget.loggedChunks.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Chunks: ${widget.loggedChunks.join(" → ")}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (!isComplete)
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _chunkController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Reps in chunk',
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                  icon: const Icon(Icons.add_rounded, size: 20),
                  label: const Text(
                    'Add Chunk',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  onPressed: _submitChunk,
                ),
              ],
            ),
        ],
      ),
    );
  }
}
