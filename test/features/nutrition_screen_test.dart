import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitness_tracker/data/database/app_database.dart';
import 'package:fitness_tracker/features/nutrition/nutrition_screen.dart';
import 'package:fitness_tracker/main.dart';

void main() {
  testWidgets('NutritionScreen exposes camera and gallery photo actions', (
    tester,
  ) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: const MaterialApp(home: NutritionScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Take photo'), findsOneWidget);
    expect(find.text('Choose from gallery'), findsOneWidget);
    expect(find.text('No meals logged today'), findsOneWidget);
  });
}
