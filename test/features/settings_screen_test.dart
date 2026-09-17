import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:fitness_tracker/data/database/app_database.dart';
import 'package:fitness_tracker/data/repositories/backup_repository.dart';
import 'package:fitness_tracker/features/settings/settings_screen.dart';
import 'package:fitness_tracker/main.dart';

class MockBackupRepository extends Mock implements BackupRepository {}

void main() {
  testWidgets('Settings exposes a confirmed delete-data action', (
    tester,
  ) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

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
