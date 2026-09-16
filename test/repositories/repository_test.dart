import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:fitness_tracker/data/database/app_database.dart';
import 'package:fitness_tracker/data/repositories/workout_repository.dart';
import 'package:fitness_tracker/data/repositories/nutrition_repository.dart';

void main() {
  late AppDatabase db;
  late WorkoutRepository workoutRepo;
  late NutritionRepository nutritionRepo;

  setUp(() {
    // In-memory SQLite database for unit testing
    db = AppDatabase(NativeDatabase.memory());
    workoutRepo = WorkoutRepository(db);
    nutritionRepo = NutritionRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('WorkoutRepository Unit Tests', () {
    test('Starts, logs sets, and finishes a workout session', () async {
      final sessionId = await workoutRepo.startSession(
        programId: 'ffts-4week',
        weekId: 'w1',
        dayId: 'w1-arms',
        dayName: 'Arms',
      );

      expect(sessionId, greaterThan(0));

      final activeSession = await workoutRepo.getActiveSession();
      expect(activeSession, isNotNull);
      expect(activeSession!.dayName, equals('Arms'));

      // Log a weightReps set
      final logId1 = await workoutRepo.logExerciseSet(
        sessionId: sessionId,
        blockId: 'w1-arms-b2',
        exerciseId: 'w1-arms-tri-02',
        exerciseName: 'Incline Skull Crush',
        blockType: 'superset',
        logMode: 'weightReps',
        setNumber: 1,
        weight: 30.0,
        reps: 20,
      );
      expect(logId1, greaterThan(0));

      // Log a cumulative restPause set
      final logId2 = await workoutRepo.logExerciseSet(
        sessionId: sessionId,
        blockId: 'w1-arms-b1',
        exerciseId: 'w1-arms-tri-01',
        exerciseName: 'Rope Extensions',
        blockType: 'restPause',
        logMode: 'cumulative',
        setNumber: 1,
        reps: 30,
        targetReps: 100,
      );
      expect(logId2, greaterThan(0));

      final logs = await workoutRepo.getLogsForSession(sessionId);
      expect(logs.length, equals(2));
      expect(logs.first.weight, equals(30.0));
      expect(logs.last.targetReps, equals(100));

      // Finish session
      await workoutRepo.finishSession(sessionId, notes: 'Great arm pump!');
      final activeAfterFinish = await workoutRepo.getActiveSession();
      expect(activeAfterFinish, isNull);

      final completedSessions = await workoutRepo.getCompletedSessions();
      expect(completedSessions.length, equals(1));
      expect(completedSessions.first.notes, equals('Great arm pump!'));
    });
  });

  group('NutritionRepository Unit Tests', () {
    test('Clears saved user data while keeping the program table', () async {
      await workoutRepo.startSession(
        programId: 'program',
        weekId: 'week',
        dayId: 'day',
        dayName: 'Arms',
      );
      await nutritionRepo.addFoodPhoto(filePath: '/missing/photo.jpg');
      await nutritionRepo.setSupplementTaken(
        date: DateTime.now(),
        supplement: 'Protein powder',
        taken: true,
      );
      await nutritionRepo.addMealPlan(
        dayOfWeek: 1,
        mealName: 'Test meal',
        ingredients: 'Rice',
        calories: 100,
        proteinG: 5,
        carbsG: 10,
        fatG: 2,
      );

      await nutritionRepo.clearUserData();

      expect(await workoutRepo.getCompletedSessions(), isEmpty);
      expect(await nutritionRepo.getPhotosForDate(DateTime.now()), isEmpty);
      expect(await nutritionRepo.getTakenSupplements(DateTime.now()), isEmpty);
      expect(await nutritionRepo.getMealPlans(), isEmpty);
    });

    test('Seeds a complete Kerala meal plan for all seven days', () async {
      await nutritionRepo.ensureDefaultKeralaMealPlan();
      final meals = await nutritionRepo.getMealPlans();

      expect(meals.length, greaterThanOrEqualTo(35));
      expect(
        meals.map((meal) => meal.dayOfWeek).toSet(),
        equals({1, 2, 3, 4, 5, 6, 7}),
      );
      expect(meals.any((meal) => meal.mealName.contains('Puttu')), isTrue);
      expect(meals.any((meal) => meal.mealName.contains('Matta rice')), isTrue);
      expect(
        meals.where((meal) => meal.videoUrl != null).length,
        greaterThan(0),
      );
    });

    test('Tracks daily supplement intake independently by date', () async {
      final today = DateTime(2026, 9, 16);
      await nutritionRepo.setSupplementTaken(
        date: today,
        supplement: 'Protein powder',
        taken: true,
      );

      expect(
        await nutritionRepo.getTakenSupplements(today),
        contains('Protein powder'),
      );
      expect(
        await nutritionRepo.getTakenSupplements(
          today.add(const Duration(days: 1)),
        ),
        isEmpty,
      );

      await nutritionRepo.setSupplementTaken(
        date: today,
        supplement: 'Protein powder',
        taken: false,
      );
      expect(await nutritionRepo.getTakenSupplements(today), isEmpty);
    });

    test('Stores food photos and updates daily nutrition summary', () async {
      final photoId = await nutritionRepo.addFoodPhoto(
        filePath: '/storage/emulated/0/Pictures/meal1.jpg',
        mealLabel: 'Lunch',
      );
      expect(photoId, greaterThan(0));

      final date = DateTime.now();
      final photosToday = await nutritionRepo.getPhotosForDate(date);
      expect(photosToday.length, equals(1));
      expect(photosToday.first.mealLabel, equals('Lunch'));

      final todayStr =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      await nutritionRepo.saveDailyNutrition(
        dateStr: todayStr,
        totalCalories: 650.0,
        proteinG: 45.0,
        carbsG: 60.0,
        fatG: 20.0,
        status: 'completed',
      );

      final nutrition = await nutritionRepo.getNutritionForDate(todayStr);
      expect(nutrition, isNotNull);
      expect(nutrition!.totalCalories, equals(650.0));
      expect(nutrition.proteinG, equals(45.0));
      expect(nutrition.status, equals('completed'));
    });
  });
}
