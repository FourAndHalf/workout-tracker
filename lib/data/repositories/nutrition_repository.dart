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

  Future<void> ensureDefaultKeralaMealPlan() async {
    final existing = await getMealPlans();
    final isOldSampleOnly =
        existing.isNotEmpty &&
        existing.every((meal) => meal.mealName == 'Chicken quinoa bowl');
    if (existing.isNotEmpty && !isOldSampleOnly) return;
    if (existing.isNotEmpty) {
      await db.delete(db.mealPlans).go();
    }
    for (final meal in _defaultKeralaMeals) {
      await addMealPlan(
        dayOfWeek: meal.dayOfWeek,
        mealName: meal.mealName,
        ingredients: meal.ingredients,
        calories: meal.calories,
        proteinG: meal.proteinG,
        carbsG: meal.carbsG,
        fatG: meal.fatG,
        videoUrl: meal.videoUrl,
      );
    }
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

class _DefaultMealPlan {
  final int dayOfWeek;
  final String mealName;
  final String ingredients;
  final double calories;
  final double proteinG;
  final double carbsG;
  final double fatG;
  final String? videoUrl;

  const _DefaultMealPlan({
    required this.dayOfWeek,
    required this.mealName,
    required this.ingredients,
    required this.calories,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    this.videoUrl,
  });
}

String _recipeShorts(String query) =>
    'https://www.youtube.com/results?search_query=${Uri.encodeQueryComponent('$query Kerala recipe shorts')}';

final _defaultKeralaMeals = <_DefaultMealPlan>[
  _DefaultMealPlan(
    dayOfWeek: 1,
    mealName: 'Puttu, kadala curry & banana',
    ingredients: 'Rice puttu, black chickpeas, coconut, banana',
    calories: 560,
    proteinG: 21,
    carbsG: 87,
    fatG: 14,
    videoUrl: _recipeShorts('puttu kadala curry'),
  ),
  _DefaultMealPlan(
    dayOfWeek: 1,
    mealName: 'Papaya, peanuts & buttermilk',
    ingredients: 'Papaya, roasted peanuts, spiced buttermilk',
    calories: 260,
    proteinG: 10,
    carbsG: 29,
    fatG: 12,
  ),
  _DefaultMealPlan(
    dayOfWeek: 1,
    mealName: 'Matta rice fish curry lunch',
    ingredients:
        'Kerala matta rice, sardine fish curry, beans thoran, cucumber',
    calories: 720,
    proteinG: 39,
    carbsG: 86,
    fatG: 24,
    videoUrl: _recipeShorts('Kerala fish curry matta rice'),
  ),
  _DefaultMealPlan(
    dayOfWeek: 1,
    mealName: 'Tender coconut & boiled eggs',
    ingredients: 'Tender coconut water, two boiled eggs',
    calories: 220,
    proteinG: 14,
    carbsG: 17,
    fatG: 10,
  ),
  _DefaultMealPlan(
    dayOfWeek: 1,
    mealName: 'Appam, chicken stew & salad',
    ingredients: 'Appam, lean chicken stew, cabbage and carrot salad',
    calories: 640,
    proteinG: 42,
    carbsG: 66,
    fatG: 21,
    videoUrl: _recipeShorts('Kerala appam chicken stew'),
  ),
  _DefaultMealPlan(
    dayOfWeek: 2,
    mealName: 'Idiyappam, egg roast & fruit',
    ingredients: 'Idiyappam, two egg Kerala roast, guava',
    calories: 580,
    proteinG: 25,
    carbsG: 79,
    fatG: 17,
    videoUrl: _recipeShorts('Kerala idiyappam egg roast'),
  ),
  _DefaultMealPlan(
    dayOfWeek: 2,
    mealName: 'Guava, cashews & curd',
    ingredients: 'Guava, cashews, plain curd',
    calories: 280,
    proteinG: 12,
    carbsG: 30,
    fatG: 13,
  ),
  _DefaultMealPlan(
    dayOfWeek: 2,
    mealName: 'Matta rice, avial & grilled pearl spot',
    ingredients: 'Matta rice, avial, grilled karimeen, cucumber pachadi',
    calories: 730,
    proteinG: 43,
    carbsG: 79,
    fatG: 25,
    videoUrl: _recipeShorts('Kerala avial karimeen'),
  ),
  _DefaultMealPlan(
    dayOfWeek: 2,
    mealName: 'Banana, protein powder & almonds',
    ingredients: 'Nendran banana, protein powder, almonds',
    calories: 330,
    proteinG: 28,
    carbsG: 35,
    fatG: 10,
  ),
  _DefaultMealPlan(
    dayOfWeek: 2,
    mealName: 'Chapati, green gram curry & thoran',
    ingredients: 'Whole wheat chapati, cherupayar curry, cabbage thoran',
    calories: 590,
    proteinG: 25,
    carbsG: 79,
    fatG: 17,
    videoUrl: _recipeShorts('Kerala green gram curry chapati'),
  ),
  _DefaultMealPlan(
    dayOfWeek: 3,
    mealName: 'Dosa, sambar & coconut chutney',
    ingredients: 'Fermented dosa, sambar, coconut chutney, orange',
    calories: 570,
    proteinG: 19,
    carbsG: 83,
    fatG: 16,
    videoUrl: _recipeShorts('Kerala dosa sambar'),
  ),
  _DefaultMealPlan(
    dayOfWeek: 3,
    mealName: 'Seasonal fruit & walnuts',
    ingredients: 'Pineapple or watermelon, walnuts, unsweetened tea',
    calories: 230,
    proteinG: 5,
    carbsG: 27,
    fatG: 12,
  ),
  _DefaultMealPlan(
    dayOfWeek: 3,
    mealName: 'Kerala fish curry meals',
    ingredients: 'Matta rice, meen curry, beetroot thoran, moru curry',
    calories: 750,
    proteinG: 40,
    carbsG: 91,
    fatG: 23,
    videoUrl: _recipeShorts('Kerala fish curry meals'),
  ),
  _DefaultMealPlan(
    dayOfWeek: 3,
    mealName: 'Boiled corn & buttermilk',
    ingredients: 'Boiled corn, spiced buttermilk, roasted gram',
    calories: 290,
    proteinG: 11,
    carbsG: 43,
    fatG: 8,
  ),
  _DefaultMealPlan(
    dayOfWeek: 3,
    mealName: 'Kanji, payar thoran & egg',
    ingredients: 'Rice kanji, green gram thoran, one boiled egg, pickle',
    calories: 520,
    proteinG: 25,
    carbsG: 70,
    fatG: 14,
    videoUrl: _recipeShorts('Kerala kanji payar'),
  ),
  _DefaultMealPlan(
    dayOfWeek: 4,
    mealName: 'Appam, vegetable stew & eggs',
    ingredients: 'Appam, coconut milk vegetable stew, two boiled eggs',
    calories: 610,
    proteinG: 26,
    carbsG: 72,
    fatG: 23,
    videoUrl: _recipeShorts('Kerala appam vegetable stew'),
  ),
  _DefaultMealPlan(
    dayOfWeek: 4,
    mealName: 'Apple, banana & pumpkin seeds',
    ingredients: 'Apple, small banana, pumpkin seeds',
    calories: 260,
    proteinG: 8,
    carbsG: 39,
    fatG: 9,
  ),
  _DefaultMealPlan(
    dayOfWeek: 4,
    mealName: 'Matta rice chicken curry',
    ingredients: 'Matta rice, lean chicken curry, beans thoran, salad',
    calories: 730,
    proteinG: 46,
    carbsG: 82,
    fatG: 23,
    videoUrl: _recipeShorts('Kerala chicken curry matta rice'),
  ),
  _DefaultMealPlan(
    dayOfWeek: 4,
    mealName: 'Curd, cucumber & peanuts',
    ingredients: 'Plain curd, cucumber, roasted peanuts, curry leaves',
    calories: 250,
    proteinG: 13,
    carbsG: 18,
    fatG: 14,
  ),
  _DefaultMealPlan(
    dayOfWeek: 4,
    mealName: 'Chapati, kadala curry & salad',
    ingredients: 'Chapati, black chickpea curry, tomato onion salad',
    calories: 580,
    proteinG: 24,
    carbsG: 79,
    fatG: 16,
    videoUrl: _recipeShorts('Kerala kadala curry chapati'),
  ),
  _DefaultMealPlan(
    dayOfWeek: 5,
    mealName: 'Puttu, green gram & papaya',
    ingredients: 'Rice puttu, green gram curry, papaya',
    calories: 550,
    proteinG: 22,
    carbsG: 88,
    fatG: 12,
    videoUrl: _recipeShorts('Kerala puttu green gram'),
  ),
  _DefaultMealPlan(
    dayOfWeek: 5,
    mealName: 'Orange, almonds & buttermilk',
    ingredients: 'Orange, almonds, spiced buttermilk',
    calories: 240,
    proteinG: 9,
    carbsG: 26,
    fatG: 12,
  ),
  _DefaultMealPlan(
    dayOfWeek: 5,
    mealName: 'Rice, prawns thoran & moru',
    ingredients: 'Matta rice, prawns thoran, moru curry, greens',
    calories: 700,
    proteinG: 42,
    carbsG: 82,
    fatG: 20,
    videoUrl: _recipeShorts('Kerala prawns thoran'),
  ),
  _DefaultMealPlan(
    dayOfWeek: 5,
    mealName: 'Nendran banana & boiled eggs',
    ingredients: 'Steamed nendran banana, two boiled eggs',
    calories: 310,
    proteinG: 15,
    carbsG: 38,
    fatG: 11,
  ),
  _DefaultMealPlan(
    dayOfWeek: 5,
    mealName: 'Idiyappam, fish molee & salad',
    ingredients: 'Idiyappam, light fish molee, cucumber salad',
    calories: 620,
    proteinG: 38,
    carbsG: 73,
    fatG: 19,
    videoUrl: _recipeShorts('Kerala fish molee idiyappam'),
  ),
  _DefaultMealPlan(
    dayOfWeek: 6,
    mealName: 'Dosa, sambar & egg bhurji',
    ingredients: 'Dosa, vegetable sambar, egg bhurji, banana',
    calories: 610,
    proteinG: 28,
    carbsG: 82,
    fatG: 18,
    videoUrl: _recipeShorts('Kerala dosa egg bhurji'),
  ),
  _DefaultMealPlan(
    dayOfWeek: 6,
    mealName: 'Mango or seasonal fruit & cashews',
    ingredients: 'Seasonal Kerala fruit, cashews, plain curd',
    calories: 290,
    proteinG: 10,
    carbsG: 35,
    fatG: 13,
  ),
  _DefaultMealPlan(
    dayOfWeek: 6,
    mealName: 'Matta rice, beef ularthiyathu & thoran',
    ingredients: 'Matta rice, lean beef ularthiyathu, cabbage thoran, salad',
    calories: 780,
    proteinG: 48,
    carbsG: 78,
    fatG: 29,
    videoUrl: _recipeShorts('Kerala beef ularthiyathu'),
  ),
  _DefaultMealPlan(
    dayOfWeek: 6,
    mealName: 'Protein shake & banana',
    ingredients: 'Protein powder, milk or water, banana, cinnamon',
    calories: 320,
    proteinG: 29,
    carbsG: 39,
    fatG: 7,
  ),
  _DefaultMealPlan(
    dayOfWeek: 6,
    mealName: 'Kanji, fish fry & cucumber',
    ingredients: 'Rice kanji, pan-seared fish, cucumber, small pickle',
    calories: 560,
    proteinG: 36,
    carbsG: 65,
    fatG: 16,
    videoUrl: _recipeShorts('Kerala kanji fish fry'),
  ),
  _DefaultMealPlan(
    dayOfWeek: 7,
    mealName: 'Kerala vegetable upma & eggs',
    ingredients: 'Vegetable rava upma, two boiled eggs, papaya',
    calories: 560,
    proteinG: 25,
    carbsG: 68,
    fatG: 20,
    videoUrl: _recipeShorts('Kerala vegetable upma'),
  ),
  _DefaultMealPlan(
    dayOfWeek: 7,
    mealName: 'Pineapple, peanuts & tender coconut',
    ingredients: 'Pineapple, roasted peanuts, tender coconut water',
    calories: 250,
    proteinG: 8,
    carbsG: 36,
    fatG: 9,
  ),
  _DefaultMealPlan(
    dayOfWeek: 7,
    mealName: 'Kerala sadya-style lunch',
    ingredients: 'Matta rice, parippu, avial, thoran, olan, curd',
    calories: 760,
    proteinG: 25,
    carbsG: 108,
    fatG: 24,
    videoUrl: _recipeShorts('Kerala sadya avial olan'),
  ),
  _DefaultMealPlan(
    dayOfWeek: 7,
    mealName: 'Boiled tapioca & fish curry',
    ingredients: 'Kappa, sardine curry, onion cucumber salad',
    calories: 410,
    proteinG: 25,
    carbsG: 54,
    fatG: 11,
    videoUrl: _recipeShorts('Kerala kappa fish curry'),
  ),
  _DefaultMealPlan(
    dayOfWeek: 7,
    mealName: 'Chapati, vegetable kurma & curd',
    ingredients: 'Chapati, vegetable kurma, plain curd, greens',
    calories: 570,
    proteinG: 20,
    carbsG: 75,
    fatG: 19,
    videoUrl: _recipeShorts('Kerala vegetable kurma chapati'),
  ),
];
