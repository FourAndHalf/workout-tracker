import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'data/database/app_database.dart';
import 'data/repositories/program_repository.dart';
import 'data/repositories/workout_repository.dart';
import 'data/repositories/nutrition_repository.dart';
import 'services/daily_workout_alarm_service.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});

final programRepositoryProvider = Provider<ProgramRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return ProgramRepository(db);
});

final workoutRepositoryProvider = Provider<WorkoutRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return WorkoutRepository(db);
});

final nutritionRepositoryProvider = Provider<NutritionRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return NutritionRepository(db);
});

final dailyWorkoutAlarmServiceProvider = Provider<DailyWorkoutAlarmService>((
  ref,
) {
  return DailyWorkoutAlarmService();
});

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DailyWorkoutAlarmService().initialize();

  runApp(const ProviderScope(child: FitnessTrackerApp()));
}
