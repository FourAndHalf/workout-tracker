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

    expect(find.byTooltip('Shopping list'), findsOneWidget);

    await tester.tap(find.text('Daily log'));
    await tester.pumpAndSettle();
    expect(find.text('Take photo'), findsOneWidget);
    expect(find.text('Choose from gallery'), findsOneWidget);
    expect(find.text('No meals logged today'), findsOneWidget);

    await tester.tap(find.text('Meal plan'));
    await tester.pumpAndSettle();
    expect(find.text('Weekly meals'), findsOneWidget);
    expect(find.text('Select day'), findsOneWidget);
    expect(find.byType(DropdownButtonFormField<int>), findsOneWidget);
    expect(find.text('Cooking video'), findsOneWidget);

    await tester.tap(find.byTooltip('Shopping list'));
    await tester.pumpAndSettle();
    expect(find.text('Weekly shopping list'), findsOneWidget);
    expect(find.text('Rice flour'), findsOneWidget);
    expect(find.byTooltip('Edit item'), findsWidgets);
    expect(find.byTooltip('Remove item'), findsWidgets);
  });
}
