import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitness_tracker/data/database/app_database.dart';
import 'package:fitness_tracker/features/nutrition/nutrition_screen.dart';
import 'package:fitness_tracker/main.dart';

void main() {
  suggestionTests();

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
    expect(find.text('Snap Meal'), findsOneWidget);
    expect(find.text('Upload Photo'), findsOneWidget);
    expect(find.text('No meals logged today'), findsOneWidget);

    await tester.tap(find.text('Meal plan'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Planned Meals'), findsOneWidget);
    expect(find.text('Add Meal'), findsOneWidget);
    expect(find.text('DAILY PLANNED TARGET'), findsOneWidget);
    expect(find.text('Video'), findsOneWidget);

    await tester.tap(find.byTooltip('Shopping list'));
    await tester.pumpAndSettle();
    expect(find.text('Shopping list'), findsOneWidget);
    expect(find.byTooltip('Edit item'), findsWidgets);
    expect(find.byTooltip('Remove item'), findsWidgets);
    expect(find.byTooltip('Buy on Blinkit'), findsWidgets);

    // Tapping a row ticks the item off (and does not leave the app).
    String left() => tester.widget<Text>(find.textContaining(' left')).data!;
    final before = left();
    await tester.tap(find.byKey(const ValueKey('shopping-row')).first);
    await tester.pumpAndSettle();
    expect(left(), isNot(before));
  });

  testWidgets('autoCapture opens the camera picker on arrival', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    final pickerCalls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/image_picker'),
          (call) async {
            pickerCalls.add(call);
            return null;
          },
        );
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel('plugins.flutter.io/image_picker'),
            null,
          ),
    );

    final router = GoRouter(
      initialLocation: '/nutrition?capture=camera',
      routes: [
        GoRoute(
          path: '/nutrition',
          builder: (context, state) => NutritionScreen(
            autoCapture: state.uri.queryParameters['capture'] == 'camera',
          ),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(pickerCalls.where((c) => c.method == 'pickImage'), hasLength(1));
    expect(router.routeInformationProvider.value.uri.toString(), '/nutrition');
  });

  testWidgets('taking a photo prompts for a meal label', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    const channel = MethodChannel('plugins.flutter.io/image_picker');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async => '/tmp/none.jpg');
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: const MaterialApp(home: NutritionScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Snap Meal'));
    await tester.pumpAndSettle();

    expect(find.text('Breakfast'), findsOneWidget);
    expect(find.text('Custom label'), findsOneWidget);

    await tester.tap(find.text('Custom label'));
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsOneWidget);
  });
}

void suggestionTests() {
  test('suggestedMealLabel follows the time of day', () {
    expect(suggestedMealLabel(DateTime(2026, 10, 20, 7)), 'Breakfast');
    expect(suggestedMealLabel(DateTime(2026, 10, 20, 13)), 'Lunch');
    expect(suggestedMealLabel(DateTime(2026, 10, 20, 20)), 'Dinner');
    expect(suggestedMealLabel(DateTime(2026, 10, 20, 16, 30)), 'Snack');
    expect(suggestedMealLabel(DateTime(2026, 10, 20, 2)), 'Snack');
  });
}
