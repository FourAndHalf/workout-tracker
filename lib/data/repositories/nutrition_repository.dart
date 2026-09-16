import 'package:drift/drift.dart';

import '../database/app_database.dart';

class NutritionRepository {
  final AppDatabase db;

  NutritionRepository(this.db);

  static String dateKey(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  Future<Set<String>> getTakenSupplements(DateTime date) async {
    final rows = await (db.select(
      db.supplementIntakes,
    )..where((item) => item.date.equals(dateKey(date)))).get();
    return rows.map((item) => item.supplement).toSet();
  }

  Future<void> setSupplementTaken({
    required DateTime date,
    required String supplement,
    required bool taken,
  }) async {
    final day = dateKey(date);
    final query = db.select(db.supplementIntakes)
      ..where(
        (item) => item.date.equals(day) & item.supplement.equals(supplement),
      );
    final existing = await query.getSingleOrNull();

    if (taken && existing == null) {
      await db
          .into(db.supplementIntakes)
          .insert(
            SupplementIntakesCompanion.insert(
              date: day,
              supplement: supplement,
            ),
          );
    } else if (!taken && existing != null) {
      await (db.delete(
        db.supplementIntakes,
      )..where((item) => item.id.equals(existing.id))).go();
    }
  }

  Future<List<MealPlan>> getMealPlans() {
    return (db.select(
      db.mealPlans,
    )..orderBy([(meal) => OrderingTerm.asc(meal.dayOfWeek)])).get();
  }

  Future<int> addMealPlan({
    required int dayOfWeek,
    required String mealName,
    required String ingredients,
    required double calories,
    required double proteinG,
    required double carbsG,
    required double fatG,
    String? videoUrl,
  }) {
    return db
        .into(db.mealPlans)
        .insert(
          MealPlansCompanion.insert(
            dayOfWeek: dayOfWeek,
            mealName: mealName,
            ingredients: ingredients,
            calories: calories,
            proteinG: proteinG,
            carbsG: carbsG,
            fatG: fatG,
            videoUrl: Value(videoUrl),
          ),
        );
  }

  Future<void> updateMealPlan({
    required int id,
    required int dayOfWeek,
    required String mealName,
    required String ingredients,
    required double calories,
    required double proteinG,
    required double carbsG,
    required double fatG,
    String? videoUrl,
  }) async {
    await (db.update(db.mealPlans)..where((meal) => meal.id.equals(id))).write(
      MealPlansCompanion(
        dayOfWeek: Value(dayOfWeek),
        mealName: Value(mealName),
        ingredients: Value(ingredients),
        calories: Value(calories),
        proteinG: Value(proteinG),
        carbsG: Value(carbsG),
        fatG: Value(fatG),
        videoUrl: Value(videoUrl),
      ),
    );
  }

  Future<void> deleteMealPlan(int id) async {
    await (db.delete(db.mealPlans)..where((meal) => meal.id.equals(id))).go();
  }

  /// Save captured food photo
  Future<int> addFoodPhoto({
    required String filePath,
    Uint8List? thumbnail,
    String? mealLabel,
  }) async {
    return await db
        .into(db.foodPhotos)
        .insert(
          FoodPhotosCompanion.insert(
            filePath: filePath,
            thumbnail: Value(thumbnail),
            capturedAt: Value(DateTime.now()),
            mealLabel: Value(mealLabel),
          ),
        );
  }

  /// Fetch food photos captured on a specific date (YYYY-MM-DD or DateTime)
  Future<List<FoodPhoto>> getPhotosForDate(DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

    return (db.select(db.foodPhotos)
          ..where((p) => p.capturedAt.isBetweenValues(startOfDay, endOfDay))
          ..orderBy([(p) => OrderingTerm.asc(p.capturedAt)]))
        .get();
  }

  /// Create or update daily nutrition summary
  Future<int> saveDailyNutrition({
    required String dateStr, // YYYY-MM-DD
    String? analysisJson,
    double? totalCalories,
    double? proteinG,
    double? carbsG,
    double? fatG,
    required String status,
  }) async {
    final existing = await (db.select(
      db.dailyNutrition,
    )..where((n) => n.date.equals(dateStr))).getSingleOrNull();

    if (existing != null) {
      await (db.update(
        db.dailyNutrition,
      )..where((n) => n.id.equals(existing.id))).write(
        DailyNutritionCompanion(
          analysisJson: Value(analysisJson),
          totalCalories: Value(totalCalories),
          proteinG: Value(proteinG),
          carbsG: Value(carbsG),
          fatG: Value(fatG),
          analyzedAt: Value(DateTime.now()),
          status: Value(status),
        ),
      );
      return existing.id;
    } else {
      return await db
          .into(db.dailyNutrition)
          .insert(
            DailyNutritionCompanion.insert(
              date: dateStr,
              analysisJson: Value(analysisJson),
              totalCalories: Value(totalCalories),
              proteinG: Value(proteinG),
              carbsG: Value(carbsG),
              fatG: Value(fatG),
              analyzedAt: Value(DateTime.now()),
              status: Value(status),
            ),
          );
    }
  }

  /// Get daily nutrition summary for date string (YYYY-MM-DD)
  Future<DailyNutritionData?> getNutritionForDate(String dateStr) async {
    return (db.select(
      db.dailyNutrition,
    )..where((n) => n.date.equals(dateStr))).getSingleOrNull();
  }
}
