import 'package:drift/drift.dart';
import '../database/app_database.dart';


class NutritionRepository {
  final AppDatabase db;

  NutritionRepository(this.db);

  /// Save captured food photo
  Future<int> addFoodPhoto({
    required String filePath,
    Uint8List? thumbnail,
    String? mealLabel,
  }) async {
    return await db.into(db.foodPhotos).insert(
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
    final existing = await (db.select(db.dailyNutrition)..where((n) => n.date.equals(dateStr))).getSingleOrNull();

    if (existing != null) {
      await (db.update(db.dailyNutrition)..where((n) => n.id.equals(existing.id))).write(
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
      return await db.into(db.dailyNutrition).insert(
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
    return (db.select(db.dailyNutrition)..where((n) => n.date.equals(dateStr))).getSingleOrNull();
  }
}
