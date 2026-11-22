import '../../data/models/program_model.dart';

/// Rough session length for the widget's Start button: timed exercises use
/// their duration, everything else ~2.5 min per set (work plus rest).
int estimateWorkoutMinutes(DayModel day) {
  var seconds = 0.0;
  for (final block in day.blocks) {
    for (final exercise in block.exercises) {
      final scheme = exercise.repScheme;
      if (exercise.logMode == 'time' && scheme != null && scheme.isNotEmpty) {
        seconds += exercise.targetSets * (scheme.first ?? 30);
      } else {
        seconds += exercise.targetSets * 150;
      }
    }
  }
  return (seconds / 60).round();
}
