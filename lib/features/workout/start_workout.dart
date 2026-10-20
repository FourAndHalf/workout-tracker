import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/program_model.dart';
import 'providers/active_workout_provider.dart';
import 'providers/active_workout_session_notifier.dart';

/// One tap from anywhere to training: starts [day] and opens its page. If a
/// workout is already running, opens that one instead of starting a second.
void startWorkoutAndOpen(
  BuildContext context,
  WidgetRef ref, {
  required String programId,
  required WeekModel week,
  required DayModel day,
}) {
  final active = ref.read(activeWorkoutSessionProvider);
  if (active != null) {
    context.push('/programs/${active.programId}/${active.dayId}');
    return;
  }
  ref
      .read(activeWorkoutProvider(day.id).notifier)
      .initDay(day, weekId: week.id, programId: programId);
  context.push('/programs/$programId/${day.id}');
}
