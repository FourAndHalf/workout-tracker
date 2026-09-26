import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_card.dart';
import '../../../data/models/program_model.dart';

/// The live logging state/callbacks for an exercise mid-workout. Passing
/// this to [ExerciseTile] switches it from the plain read-only preview
/// (used when just browsing a program) into an interactive logging card,
/// without changing the tile's own visual shell.
class ActiveExerciseLogState {
  final int currentSetNumber;
  final List<Map<String, dynamic>> loggedSets;
  final List<int> restPauseChunks;
  final void Function({
    double? weight,
    int? reps,
    bool hitFailure,
    int? durationSeconds,
  })
  onLogSet;
  final void Function(int chunkReps) onAddChunk;

  const ActiveExerciseLogState({
    required this.currentSetNumber,
    required this.loggedSets,
    required this.restPauseChunks,
    required this.onLogSet,
    required this.onAddChunk,
  });
}

class ExerciseTile extends StatefulWidget {
  final ExerciseModel exercise;
  final ActiveExerciseLogState? activeState;

  const ExerciseTile({super.key, required this.exercise, this.activeState});

  @override
  State<ExerciseTile> createState() => _ExerciseTileState();
}

class _ExerciseTileState extends State<ExerciseTile> {
  final TextEditingController _weightController = TextEditingController(
    text: '40',
  );
  final TextEditingController _repsController = TextEditingController(
    text: '20',
  );
  final TextEditingController _timeController = TextEditingController(
    text: '60',
  );
  final TextEditingController _chunkController = TextEditingController(
    text: '20',
  );
  bool _hitFailure = false;

  @override
  void dispose() {
    _weightController.dispose();
    _repsController.dispose();
    _timeController.dispose();
    _chunkController.dispose();
    super.dispose();
  }

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
    final exercise = widget.exercise;
    if (exercise.repTarget != null) {
      return '${exercise.targetSets} Sets · Target: ${exercise.repTarget} reps';
    }
    if (exercise.repScheme != null && exercise.repScheme!.isNotEmpty) {
      final unit = exercise.repUnit != null ? ' ${exercise.repUnit}' : '';
      return '${exercise.targetSets} Sets · (${exercise.repScheme!.join(", ")})$unit';
    }
    return '${exercise.targetSets} Sets';
  }

  Future<void> _openExerciseVideo(BuildContext context) async {
    if (await launchUrl(
      widget.exercise.exerciseVideoUri,
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

  void _submitSet() {
    final active = widget.activeState!;
    final weight = double.tryParse(_weightController.text);
    final reps = int.tryParse(_repsController.text);
    final duration = int.tryParse(_timeController.text);

    active.onLogSet(
      weight: weight,
      reps: reps,
      hitFailure: _hitFailure,
      durationSeconds: duration,
    );
  }

  void _submitChunk() {
    final active = widget.activeState!;
    final val = int.tryParse(_chunkController.text);
    if (val != null && val > 0) {
      active.onAddChunk(val);
      _chunkController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final exercise = widget.exercise;
    final active = widget.activeState;

    if (active == null) {
      return _buildTile(
        context,
        child: null,
        borderColor: null,
        borderWidth: 1,
      );
    }

    if (exercise.logMode == 'cumulative') {
      return _buildTile(
        context,
        borderColor: null,
        borderWidth: 1,
        child: _buildCumulativeBody(active, exercise.repTarget ?? 100),
      );
    }

    final isDone = active.currentSetNumber > exercise.targetSets;
    return _buildTile(
      context,
      borderColor: isDone ? context.colors.primary : null,
      borderWidth: isDone ? 1.5 : 1,
      child: _buildSetLoggerBody(active, isDone),
    );
  }

  Widget _buildTile(
    BuildContext context, {
    required Widget? child,
    required Color? borderColor,
    required double borderWidth,
  }) {
    final exercise = widget.exercise;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AppCard(
        padding: const EdgeInsets.all(12),
        color: context.colors.surface,
        borderColor:
            borderColor ?? context.colors.border.withValues(alpha: 0.5),
        borderWidth: borderWidth,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: context.colors.card,
                  child: Icon(
                    _getLogModeIcon(exercise.logMode),
                    size: 16,
                    color: context.colors.primary,
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
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: context.colors.textPrimary,
                                ),
                              ),
                            ),
                          ),
                          if (widget.activeState != null)
                            IconButton(
                              tooltip:
                                  'Watch ${exercise.name} on YouTube Shorts',
                              icon: const Icon(Icons.open_in_new_rounded),
                              color: context.colors.primary,
                              onPressed: () => _openExerciseVideo(context),
                              visualDensity: VisualDensity.compact,
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatSetsReps(),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: context.colors.secondary,
                        ),
                      ),
                      if (exercise.prescription != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          exercise.prescription!,
                          style: TextStyle(
                            fontSize: 11,
                            color: context.colors.textSecondary,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            if (child != null) ...[const SizedBox(height: 12), child],
          ],
        ),
      ),
    );
  }

  Widget _buildSetLoggerBody(ActiveExerciseLogState active, bool isDone) {
    final exercise = widget.exercise;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            'Set ${active.currentSetNumber > exercise.targetSets ? exercise.targetSets : active.currentSetNumber} / ${exercise.targetSets}',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: isDone ? context.colors.primary : context.colors.secondary,
            ),
          ),
        ),
        const SizedBox(height: 8),

        if (active.loggedSets.isNotEmpty) ...[
          Column(
            children: active.loggedSets.asMap().entries.map((entry) {
              final idx = entry.key + 1;
              final set = entry.value;
              final weightStr = set['weight'] != null
                  ? '${set['weight']} kg'
                  : '';
              final repsStr = set['reps'] != null ? '${set['reps']} reps' : '';
              final failureStr = set['hitFailure'] == true
                  ? ' \u{1F525} Failure'
                  : '';

              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle_rounded,
                      color: context.colors.primary,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Set $idx: $weightStr $repsStr$failureStr',
                      style: TextStyle(
                        fontSize: 13,
                        color: context.colors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
        ],

        if (!isDone) ...[
          if (exercise.logMode == 'weightReps' || exercise.logMode == 'failure')
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _weightController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Weight (kg)',
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _repsController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Reps',
                      isDense: true,
                    ),
                  ),
                ),
              ],
            ),

          if (exercise.logMode == 'repsOnly')
            TextField(
              controller: _repsController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Reps',
                isDense: true,
              ),
            ),

          if (exercise.logMode == 'time')
            TextField(
              controller: _timeController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Duration (seconds)',
                isDense: true,
              ),
            ),

          if (exercise.logMode == 'failure') ...[
            const SizedBox(height: 10),
            SwitchListTile(
              value: _hitFailure,
              onChanged: (val) => setState(() => _hitFailure = val),
              title: Text(
                'Hit Failure \u{1F525}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: context.colors.error,
                ),
              ),
              contentPadding: EdgeInsets.zero,
              dense: true,
            ),
          ],

          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.check_rounded),
              label: Text(
                'Log Set ${active.currentSetNumber}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              onPressed: _submitSet,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCumulativeBody(ActiveExerciseLogState active, int targetReps) {
    final total = active.restPauseChunks.fold(0, (sum, val) => sum + val);
    final progress = targetReps > 0
        ? (total / targetReps).clamp(0.0, 1.0)
        : 0.0;
    final isComplete = total >= targetReps;

    return Column(
      children: [
        Row(
          children: [
            SizedBox(
              width: 56,
              height: 56,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 5,
                    backgroundColor: context.colors.border,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isComplete
                          ? context.colors.primary
                          : context.colors.secondary,
                    ),
                  ),
                  Text(
                    '$total',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isComplete
                          ? context.colors.primary
                          : context.colors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isComplete
                        ? 'TARGET REACHED! \u{1F389}'
                        : 'REST-PAUSE PROGRESS',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isComplete
                          ? context.colors.primary
                          : context.colors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$total / $targetReps Reps Completed',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (active.restPauseChunks.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Chunks: ${active.restPauseChunks.join(" → ")}',
                      style: TextStyle(
                        fontSize: 11,
                        color: context.colors.textMuted,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

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
    );
  }
}
