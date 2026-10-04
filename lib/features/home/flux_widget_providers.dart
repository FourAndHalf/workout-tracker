import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/models/program_model.dart';
import '../../main.dart';
import '../../services/flux_widget_service.dart';
import '../nutrition/nutrition_screen.dart';
import '../program/program_providers.dart';
import 'home_providers.dart';

/// Daily calorie burn used by the Kinetic Flux widgets (Settings).
final dailyBurnKcalProvider = FutureProvider<int>((ref) async {
  final preferences = await SharedPreferences.getInstance();
  return preferences.getInt(dailyBurnPreferenceKey) ?? defaultDailyBurnKcal;
});

/// Latest widget content, recomputed whenever any of its sources change.
final fluxWidgetDataProvider = FutureProvider<FluxWidgetData>((ref) async {
  final analytics = await ref.watch(dashboardAnalyticsProvider.future);
  final dailyBurn = await ref.watch(dailyBurnKcalProvider.future);
  final mealPlans = await ref.watch(mealPlansProvider.future);
  final next = await ref.watch(nextWorkoutDayProvider.future);
  final program = await ref.watch(currentProgramProvider.future);
  final sessions = await ref
      .watch(workoutRepositoryProvider)
      .getCompletedSessions();

  final now = DateTime.now();
  final plannedKcal = mealPlans
      .where((meal) => meal.dayOfWeek == now.weekday)
      .fold<double>(0, (total, meal) => total + meal.calories);

  DayModel? nextDay;
  if (next != null) {
    for (final week in program.weeks) {
      for (final day in week.days) {
        if (day.id == next.dayId) nextDay = day;
      }
    }
  }

  return FluxWidgetData.compute(
    now: now,
    consumedKcal: plannedKcal.round(),
    dailyBurnKcal: dailyBurn,
    completedSessions: sessions,
    streak: analytics.currentStreak,
    trainedToday: analytics.trainedToday,
    nextWorkoutName: next?.dayName,
    nextWorkoutMinutes: nextDay == null ? 0 : estimateWorkoutMinutes(nextDay),
    nextWorkoutUri: next == null
        ? null
        : 'fitnesstracker:///programs/${next.programId}/${next.dayId}',
  );
});
