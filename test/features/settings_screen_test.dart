import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitness_tracker/data/database/app_database.dart';
import 'package:fitness_tracker/features/settings/settings_screen.dart';
import 'package:fitness_tracker/main.dart';

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
    await tester.tap(find.text('Delete saved data'));
    await tester.pumpAndSettle();
    expect(find.text('How much data should be deleted?'), findsOneWidget);
    expect(find.text('Last 1 hour'), findsOneWidget);
    await tester.tap(find.text('Last 1 day'));
    await tester.pumpAndSettle();
    expect(find.text('Confirm deletion'), findsOneWidget);
    expect(find.text('Delete data'), findsOneWidget);
  });
}
