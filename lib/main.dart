import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/theme/theme_mode_provider.dart';
import 'data/database/app_database.dart';
import 'data/repositories/backup_repository.dart';
import 'data/repositories/program_repository.dart';
import 'data/repositories/workout_repository.dart';
import 'data/repositories/nutrition_repository.dart';
import 'data/repositories/progress_repository.dart';
import 'data/repositories/supplement_repository.dart';
import 'services/backup_archive_service.dart';
import 'services/daily_workout_alarm_service.dart';
import 'services/google_drive_backup_service.dart';

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

final progressRepositoryProvider = FutureProvider<ProgressRepository>((
  ref,
) async {
  return ProgressRepository(await SharedPreferences.getInstance());
});

final supplementRepositoryProvider = FutureProvider<SupplementRepository>((
  ref,
) async {
  return SupplementRepository(await SharedPreferences.getInstance());
});

final dailyWorkoutAlarmServiceProvider = Provider<DailyWorkoutAlarmService>((
  ref,
) {
  return DailyWorkoutAlarmService();
});

final backupRepositoryProvider = FutureProvider<BackupRepository>((ref) async {
  final db = ref.watch(databaseProvider);
  final preferences = await SharedPreferences.getInstance();
  final progressRepository = await ref.watch(progressRepositoryProvider.future);
  final supplementRepository = await ref.watch(supplementRepositoryProvider.future);
  final docsDir = await getApplicationDocumentsDirectory();
  final databaseFile = File(p.join(docsDir.path, 'fitness_tracker.sqlite'));

  return BackupRepository(
    database: db,
    databaseFile: databaseFile,
    preferences: preferences,
    progressRepository: progressRepository,
    supplementRepository: supplementRepository,
    archiveService: BackupArchiveService(),
    driveService: GoogleDriveBackupService(),
  );
});

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DailyWorkoutAlarmService().initialize();

  final preferences = await SharedPreferences.getInstance();
  final needsRestoreCheck =
      !(preferences.getBool(BackupRepository.firstLaunchRestoreCheckKey) ?? false);

  final themeMode = parseThemeMode(
    preferences.getString(themeModePreferenceKey),
  );

  runApp(
    ProviderScope(
      overrides: [initialThemeModeProvider.overrideWithValue(themeMode)],
      child: FitnessTrackerApp(needsRestoreCheck: needsRestoreCheck),
    ),
  );
}
