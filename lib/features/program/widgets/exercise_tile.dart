import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons_600.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/ledger.dart';
import '../../../data/models/program_model.dart';
import '../../../data/repositories/workout_repository.dart';
import '../../explore/widgets/exercise_detail.dart';
import '../../workout/widgets/exercise_countdown_timer.dart';

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
    double? distanceMeters,
  })
  onLogSet;
  final void Function(int chunkReps) onAddChunk;

  /// The whole workout is paused: freezes the countdown, blocks logging.
  final bool isPaused;

  const ActiveExerciseLogState({
    required this.currentSetNumber,
    required this.loggedSets,
    required this.restPauseChunks,
    required this.onLogSet,
    required this.onAddChunk,
    this.isPaused = false,
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
  final TextEditingController _chunkController = TextEditingController(
    text: '20',
  );
  final TextEditingController _distanceController = TextEditingController();
  final TextEditingController _minutesController = TextEditingController(
    text: '0',
  );
  final TextEditingController _secondsController = TextEditingController(
    text: '0',
  );
  bool _hitFailure = false;

  @override
  void initState() {
    super.initState();
    final meters = widget.exercise.distanceMeters;
    _distanceController.text = meters == null ? '1' : _kmText(meters / 1000);
    // The pace readout follows the fields as they change.
    for (final controller in [
      _distanceController,
      _minutesController,
      _secondsController,
    ]) {
      controller.addListener(_onDistanceFieldChanged);
    }
  }

  void _onDistanceFieldChanged() {
    if (mounted && widget.exercise.logMode == 'distance') setState(() {});
  }

  static String _kmText(double km) =>
      km.toStringAsFixed(2).replaceFirst(RegExp(r'\.?0+$'), '');

  double? get _enteredMeters {
    final km = double.tryParse(_distanceController.text);
    return km == null || km <= 0 ? null : km * 1000;
  }

  /// Null while the time fields are left at 0:00, which hands timing to the
  /// set clock.
  int? get _enteredSeconds {
    final total =
        (int.tryParse(_minutesController.text) ?? 0) * 60 +
        (int.tryParse(_secondsController.text) ?? 0);
    return total > 0 ? total : null;
  }

  @override
  void dispose() {
    _distanceController.dispose();
    _minutesController.dispose();
    _secondsController.dispose();
    _weightController.dispose();
    _repsController.dispose();
    _chunkController.dispose();
    super.dispose();
  }

  IconData _getLogModeIcon(String logMode) {
    switch (logMode) {
      case 'cumulative':
        return LucideIcons600.donut;
      case 'failure':
        return LucideIcons600.flame;
      case 'time':
        return LucideIcons600.timer;
      case 'distance':
        return LucideIcons600.footprints;
      case 'repsOnly':
        return LucideIcons600.personStanding;
      case 'weightReps':
      default:
        return LucideIcons600.dumbbell;
    }
  }

  String _formatSetsReps() {
    final exercise = widget.exercise;
    final sets =
        '${exercise.targetSets} ${exercise.targetSets == 1 ? 'set' : 'sets'}';
    if (exercise.repTarget != null) {
      return '$sets · target ${exercise.repTarget} reps';
    }
    final perSide = exercise.side == 'each' ? ' each side' : '';
    if (exercise.logMode == 'distance' && exercise.distanceMeters != null) {
      final distance = formatDistance(exercise.distanceMeters!);
      return exercise.targetSets == 1
          ? distance
          : '${exercise.targetSets} × $distance';
    }
    if (exercise.logMode == 'time' &&
        exercise.repScheme != null &&
        exercise.repScheme!.isNotEmpty) {
      final hold =
          '${exercise.repScheme!.first} ${exercise.repUnit ?? 'sec'}$perSide';
      return exercise.targetSets == 1 ? hold : '$sets · $hold';
    }
    if (exercise.repScheme != null && exercise.repScheme!.isNotEmpty) {
      final unit = exercise.repUnit != null ? ' ${exercise.repUnit}' : '';
      return '$sets · ${exercise.repScheme!.join(", ")}$unit';
    }
    return sets;
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
    final mode = widget.exercise.logMode;
    // Only send what this mode's form actually shows; the controllers hold
    // defaults (40 kg / 20 reps) that must not leak into other modes.
    final usesWeight = mode == 'weightReps' || mode == 'failure';
    if (mode == 'distance') {
      final meters = _enteredMeters;
      if (meters == null) return;
      active.onLogSet(distanceMeters: meters, durationSeconds: _enteredSeconds);
      _minutesController.text = '0';
      _secondsController.text = '0';
      return;
    }
    active.onLogSet(
      weight: usesWeight ? double.tryParse(_weightController.text) : null,
      reps: usesWeight || mode == 'repsOnly'
          ? int.tryParse(_repsController.text)
          : null,
      hitFailure: _hitFailure,
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
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: _buildHeader(context, trailing: null),
      );
    }

    final Widget body;
    final bool isDone;
    if (exercise.logMode == 'cumulative') {
      final target = exercise.repTarget ?? 100;
      isDone = active.restPauseChunks.fold(0, (sum, v) => sum + v) >= target;
      body = _buildCumulativeBody(active, target);
    } else {
      isDone = active.currentSetNumber > exercise.targetSets;
      body = _buildSetLoggerBody(active, isDone);
    }

    final colors = context.colors;
    // Exercises inside a block are separated by a hairline, not boxed, so a
    // live block stays one level deep.
    return Container(
      padding: const EdgeInsets.fromLTRB(0, 14, 0, 14),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: colors.divider)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(
            context,
            trailing: isDone
                ? StatusBadge(
                    'Done',
                    icon: LucideIcons600.check,
                    foreground: colors.success,
                    background: colors.successContainer,
                  )
                : null,
          ),
          const SizedBox(height: 12),
          body,
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, {required Widget? trailing}) {
    final exercise = widget.exercise;
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    return Row(
      children: [
        IconChip(_getLogModeIcon(exercise.logMode)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () => _openExerciseVideo(context),
                child: Text(exercise.name, style: textTheme.titleSmall),
              ),
              const SizedBox(height: 2),
              Text(
                _formatSetsReps(),
                style: textTheme.bodySmall?.copyWith(
                  color: colors.textSecondary,
                ),
              ),
              if (exercise.prescription != null) ...[
                const SizedBox(height: 2),
                Text(
                  exercise.prescription!,
                  style: textTheme.bodySmall?.copyWith(color: colors.textMuted),
                ),
              ],
              if (exercise.instructions != null) ...[
                const SizedBox(height: 2),
                Text(
                  exercise.instructions!,
                  style: textTheme.bodySmall?.copyWith(color: colors.textMuted),
                ),
              ],
            ],
          ),
        ),
        if (trailing != null) ...[const SizedBox(width: 8), trailing],
        if (exercise.libraryId != null)
          IconButton(
            key: const Key('exerciseInfo'),
            tooltip: 'Photos and steps for ${exercise.name}',
            icon: const Icon(LucideIcons600.info, size: 20),
            color: colors.textSecondary,
            onPressed: () =>
                showExerciseDetailSheet(context, exercise.libraryId!),
          ),
        IconButton(
          tooltip: 'Watch ${exercise.name} on YouTube Shorts',
          icon: const Icon(LucideIcons600.playCircle, size: 20),
          color: colors.textSecondary,
          onPressed: () => _openExerciseVideo(context),
        ),
      ],
    );
  }

  String _setSummary(int index, Map<String, dynamic> set) {
    final meters = set['distanceMeters'] as double?;
    if (meters != null) {
      final seconds = set['durationSeconds'] as int?;
      final pace = paceSecondsPerKmFor(meters, seconds);
      return [
        'Set $index: ${formatDistance(meters)}',
        if (seconds != null)
          '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}',
        if (pace != null) formatPace(pace),
      ].join(' · ');
    }
    final weightStr = set['weight'] != null ? '${set['weight']} kg' : '';
    final repsStr = set['reps'] != null ? '${set['reps']} reps' : '';
    final failureStr = set['hitFailure'] == true ? ' · failure' : '';
    final seconds = set['durationSeconds'] as int?;
    final timeStr = seconds != null
        ? ' · ${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}'
        : '';
    return 'Set $index: $weightStr $repsStr$failureStr$timeStr'
        .replaceAll(RegExp(r' {2,}'), ' ')
        .replaceFirst(': · ', ': ');
  }

  Widget _buildSetLoggerBody(ActiveExerciseLogState active, bool isDone) {
    final exercise = widget.exercise;
    final colors = context.colors;
    final isTimed = exercise.logMode == 'time';
    final usesWeight =
        exercise.logMode == 'weightReps' || exercise.logMode == 'failure';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: SegmentProgress(
                total: exercise.targetSets,
                filled: active.loggedSets.length.clamp(0, exercise.targetSets),
                height: 4,
              ),
            ),
            if (!isDone) ...[
              const SizedBox(width: 12),
              Text(
                'Set ${active.currentSetNumber}/${exercise.targetSets}',
                style: AppText.metricTable.copyWith(
                  fontSize: 12,
                  color: colors.textSecondary,
                ),
              ),
            ],
          ],
        ),

        if (active.loggedSets.isNotEmpty) ...[
          const SizedBox(height: 10),
          for (final entry in active.loggedSets.asMap().entries)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  Icon(LucideIcons600.check, color: colors.success, size: 14),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _setSummary(entry.key + 1, entry.value),
                      style: AppText.metricTable.copyWith(
                        fontWeight: FontWeight.w400,
                        fontSize: 12,
                        color: colors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],

        if (!isDone) ...[
          const SizedBox(height: 12),
          if (usesWeight)
            Row(
              children: [
                Expanded(
                  child: _StepperField(
                    label: 'Weight (kg)',
                    controller: _weightController,
                    step: 2.5,
                    decimal: true,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _StepperField(
                    label: 'Reps',
                    controller: _repsController,
                    step: 1,
                  ),
                ),
              ],
            ),

          if (exercise.logMode == 'repsOnly')
            _StepperField(label: 'Reps', controller: _repsController, step: 1),

          if (exercise.logMode == 'distance') _buildDistanceFields(),

          if (isTimed)
            ExerciseCountdownTimer(
              // Keyed per set so the countdown starts fresh after each log.
              key: ValueKey('${exercise.id}-${active.currentSetNumber}'),
              targetSeconds: exercise.repScheme?.firstOrNull ?? 60,
              paused: active.isPaused,
              onLog: (seconds) => active.onLogSet(durationSeconds: seconds),
            ),

          if (exercise.logMode == 'failure') ...[
            const SizedBox(height: 4),
            // Its own Material: the tile sits on a coloured panel, which
            // would otherwise hide the switch row's ripple.
            Material(
              type: MaterialType.transparency,
              child: SwitchListTile(
                value: _hitFailure,
                onChanged: (val) => setState(() => _hitFailure = val),
                title: Text(
                  'Reached failure',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                contentPadding: EdgeInsets.zero,
                dense: true,
              ),
            ),
          ],

          if (!isTimed) ...[
            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon: const Icon(LucideIcons600.check, size: 18),
              label: Text('Log Set ${active.currentSetNumber}'),
              onPressed: _submitSet,
            ),
          ],
        ],
      ],
    );
  }

  /// Distance plus the time it took, with the resulting pace. Leaving the
  /// time at 0:00 saves the set clock's elapsed time instead.
  Widget _buildDistanceFields() {
    final colors = context.colors;
    final pace = paceSecondsPerKmFor(_enteredMeters, _enteredSeconds);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _StepperField(
          key: const Key('distanceField'),
          label: 'Distance (km)',
          controller: _distanceController,
          step: 0.1,
          decimal: true,
          decimals: 2,
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _StepperField(
                key: const Key('minutesField'),
                label: 'Time (min)',
                controller: _minutesController,
                step: 1,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StepperField(
                key: const Key('secondsField'),
                label: 'Sec',
                controller: _secondsController,
                step: 5,
                max: 59,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          pace != null
              ? 'Pace ${formatPace(pace)}'
              : 'Leave the time at 0:00 to use the set clock.',
          key: const Key('paceReadout'),
          style: Theme.of(context).textTheme.bodySmall
              ?.copyWith(color: colors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildCumulativeBody(ActiveExerciseLogState active, int targetReps) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final total = active.restPauseChunks.fold(0, (sum, val) => sum + val);
    final progress = targetReps > 0
        ? (total / targetReps).clamp(0.0, 1.0)
        : 0.0;
    final isComplete = total >= targetReps;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            GaugeArc(
              value: progress,
              size: 64,
              stroke: 6,
              color: isComplete ? colors.success : null,
              child: Text('$total', style: AppText.metricTable),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isComplete ? 'Target reached' : 'Rest-pause progress',
                    style: textTheme.bodySmall?.copyWith(
                      color: isComplete ? colors.success : colors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text('$total / $targetReps reps', style: AppText.metricCard),
                  if (active.restPauseChunks.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Chunks ${active.restPauseChunks.join(" → ")}',
                      style: textTheme.bodySmall?.copyWith(
                        color: colors.textMuted,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),

        if (!isComplete) ...[
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: _StepperField(
                  label: 'Reps in chunk',
                  controller: _chunkController,
                  step: 1,
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  icon: const Icon(LucideIcons600.plus, size: 18),
                  label: const Text('Add chunk'),
                  onPressed: _submitChunk,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

/// A 52px numeric input with − / + steppers and its label above, so most
/// sets can be logged without opening the keyboard.
class _StepperField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final double step;
  final bool decimal;

  /// Decimal places kept when [decimal]; trailing zeros are dropped.
  final int decimals;
  final double max;

  const _StepperField({
    super.key,
    required this.label,
    required this.controller,
    required this.step,
    this.decimal = false,
    this.decimals = 1,
    this.max = 9999,
  });

  void _bump(int direction) {
    final current = double.tryParse(controller.text) ?? 0;
    final next = (current + step * direction).clamp(0, max).toDouble();
    controller.text = decimal
        ? next.toStringAsFixed(decimals).replaceFirst(RegExp(r'\.?0+$'), '')
        : next.round().toString();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelMedium
              ?.copyWith(color: colors.textSecondary),
        ),
        const SizedBox(height: 6),
        Container(
          height: 52,
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Row(
            children: [
              _StepButton(
                icon: LucideIcons600.minus,
                tooltip: 'Decrease $label',
                onTap: () => _bump(-1),
              ),
              Expanded(
                child: TextField(
                  controller: controller,
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.numberWithOptions(
                    decimal: decimal,
                  ),
                  style: AppText.metricCard,
                  decoration: const InputDecoration(
                    isDense: true,
                    filled: false,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
              _StepButton(
                icon: LucideIcons600.plus,
                tooltip: 'Increase $label',
                onTap: () => _bump(1),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StepButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _StepButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: tooltip,
    icon: Icon(icon, size: 18),
    color: context.colors.textPrimary,
    onPressed: onTap,
  );
}
