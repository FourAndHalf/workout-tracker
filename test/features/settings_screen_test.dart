import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fitness_tracker/data/database/app_database.dart';
import 'package:fitness_tracker/data/repositories/backup_repository.dart';
import 'package:fitness_tracker/features/settings/settings_screen.dart';
import 'package:fitness_tracker/main.dart';
import 'package:fitness_tracker/services/flux_widget_service.dart';

class MockBackupRepository extends Mock implements BackupRepository {}

void main() {
  testWidgets('Settings exposes a confirmed delete-data action', (
    tester,
  ) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    // Tall enough that the whole (lazily built) settings list is on screen.
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: const MaterialApp(home: SettingsScreen()),
      ),
    );

    expect(find.text('Delete saved data'), findsOneWidget);
    expect(find.text('Weekly shopping list'), findsOneWidget);
    await tester.tap(find.text('Delete saved data'));
    await tester.pumpAndSettle();
    expect(find.text('Delete saved data'), findsNWidgets(2));
    expect(find.byType(DropdownButtonFormField<Duration>), findsOneWidget);
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('Confirm deletion'), findsOneWidget);
    expect(find.text('Delete data'), findsOneWidget);
  });

  testWidgets('Daily calorie burn can be edited for the widgets', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: const MaterialApp(home: SettingsScreen()),
      ),
    );
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump();

    expect(find.textContaining('$defaultDailyBurnKcal kcal'), findsOneWidget);
    await tester.tap(find.text('Daily calorie burn'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '2800');
    await tester.tap(find.text('Save'));
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pumpAndSettle();

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt(dailyBurnPreferenceKey), 2800);
  });

  testWidgets('Backup card triggers a Google Drive backup on tap', (
    tester,
  ) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final repository = MockBackupRepository();
    when(() => repository.isSignedIn()).thenAnswer((_) async => true);
    when(() => repository.createBackup()).thenAnswer((_) async {});

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          backupRepositoryProvider.overrideWith((ref) async => repository),
        ],
        child: const MaterialApp(home: SettingsScreen()),
      ),
    );

    expect(find.text('Back up to Google Drive'), findsOneWidget);
    await tester.tap(find.text('Back up to Google Drive'));
    await tester.pumpAndSettle();

    verify(() => repository.createBackup()).called(1);
    expect(find.text('Backup complete'), findsOneWidget);
  });
}
