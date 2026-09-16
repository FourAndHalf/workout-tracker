import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/models/program_model.dart';

class SetLoggerCard extends StatefulWidget {
  final ExerciseModel exercise;
  final int currentSetNumber;
  final List<Map<String, dynamic>> loggedSets;
  final Function({
    double? weight,
    int? reps,
    bool hitFailure,
    int? durationSeconds,
  })
  onLogSet;

  const SetLoggerCard({
    super.key,
    required this.exercise,
    required this.currentSetNumber,
    required this.loggedSets,
    required this.onLogSet,
  });

  @override
  State<SetLoggerCard> createState() => _SetLoggerCardState();
}

class _SetLoggerCardState extends State<SetLoggerCard> {
  final TextEditingController _weightController = TextEditingController(
    text: '40',
  );
  final TextEditingController _repsController = TextEditingController(
    text: '20',
  );
  final TextEditingController _timeController = TextEditingController(
    text: '60',
  );
  bool _hitFailure = false;

  @override
  void dispose() {
    _weightController.dispose();
    _repsController.dispose();
    _timeController.dispose();
    super.dispose();
  }

  void _submit() {
    final weight = double.tryParse(_weightController.text);
    final reps = int.tryParse(_repsController.text);
    final duration = int.tryParse(_timeController.text);

    widget.onLogSet(
      weight: weight,
      reps: reps,
      hitFailure: _hitFailure,
      durationSeconds: duration,
    );
  }

  Future<void> _openExerciseVideo() async {
    if (await launchUrl(
          widget.exercise.exerciseVideoUri,
          mode: LaunchMode.externalApplication,
        ) ||
        !mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Unable to open YouTube Shorts.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDone = widget.currentSetNumber > widget.exercise.targetSets;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDone ? AppColors.primary : AppColors.border,
          width: isDone ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.exercise.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Watch ${widget.exercise.name} on YouTube Shorts',
                icon: const Icon(Icons.open_in_new_rounded),
                color: AppColors.primary,
                onPressed: _openExerciseVideo,
                visualDensity: VisualDensity.compact,
              ),
              Text(
                'Set ${widget.currentSetNumber > widget.exercise.targetSets ? widget.exercise.targetSets : widget.currentSetNumber} / ${widget.exercise.targetSets}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isDone ? AppColors.primary : AppColors.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Previously logged sets list
          if (widget.loggedSets.isNotEmpty) ...[
            Column(
              children: widget.loggedSets.asMap().entries.map((entry) {
                final idx = entry.key + 1;
                final set = entry.value;
                final weightStr = set['weight'] != null
                    ? '${set['weight']} kg'
                    : '';
                final repsStr = set['reps'] != null
                    ? '${set['reps']} reps'
                    : '';
                final failureStr = set['hitFailure'] == true
                    ? ' 🔥 Failure'
                    : '';

                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.check_circle_rounded,
                        color: AppColors.primary,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Set $idx: $weightStr $repsStr$failureStr',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
          ],

          // Active Input Row (if not all sets done)
          if (!isDone) ...[
            if (widget.exercise.logMode == 'weightReps' ||
                widget.exercise.logMode == 'failure')
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

            if (widget.exercise.logMode == 'repsOnly')
              TextField(
                controller: _repsController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Reps',
                  isDense: true,
                ),
              ),

            if (widget.exercise.logMode == 'time')
              TextField(
                controller: _timeController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Duration (seconds)',
                  isDense: true,
                ),
              ),

            if (widget.exercise.logMode == 'failure') ...[
              const SizedBox(height: 10),
              SwitchListTile(
                value: _hitFailure,
                onChanged: (val) => setState(() => _hitFailure = val),
                title: const Text(
                  'Hit Failure 🔥',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.error,
                  ),
                ),
                contentPadding: EdgeInsets.zero,
                dense: true,
              ),
            ],

            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.background,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: const Icon(Icons.check_rounded),
                label: Text(
                  'Log Set ${widget.currentSetNumber}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                onPressed: _submit,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
