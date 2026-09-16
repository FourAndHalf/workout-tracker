import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import 'tables/programs.dart';
import 'tables/workout_sessions.dart';
import 'tables/exercise_logs.dart';
import 'tables/food_photos.dart';
import 'tables/daily_nutrition.dart';
import 'tables/supplement_intakes.dart';
import 'tables/meal_plans.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    Programs,
    WorkoutSessions,
    ExerciseLogs,
    FoodPhotos,
    DailyNutrition,
    DailyNutritionPhotos,
    SupplementIntakes,
    MealPlans,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? e]) : super(e ?? _openConnection());

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      if (from < 2) await m.createTable(supplementIntakes);
      if (from < 3) await m.createTable(mealPlans);
    },
  );

  Future<void> clearUserData() async {
    await transaction(() async {
      await delete(dailyNutritionPhotos).go();
      await delete(exerciseLogs).go();
      await delete(workoutSessions).go();
      await delete(foodPhotos).go();
      await delete(dailyNutrition).go();
      await delete(supplementIntakes).go();
      await delete(mealPlans).go();
    });
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'fitness_tracker.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
