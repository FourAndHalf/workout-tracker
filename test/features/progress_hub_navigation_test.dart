import 'package:drift/native.dart';
import 'package:fitness_tracker/app.dart';
import 'package:fitness_tracker/core/widgets/day_app_bar.dart';
import 'package:fitness_tracker/data/database/app_database.dart';
import 'package:fitness_tracker/features/home/home_providers.dart';
import 'package:fitness_tracker/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('bottom nav has 4 tabs and History lives under Progress', (
    tester,
  ) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: const FitnessTrackerApp(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    final bar = find.byType(NavigationBar);
    expect(bar, findsOneWidget);
    expect(
      find.descendant(of: bar, matching: find.byType(NavigationDestination)),
      findsNWidgets(4),
    );
    expect(
      find.descendant(of: bar, matching: find.text('History')),
      findsNothing,
    );

    // Every tab but Home shares the same day header; Home opens with its own
    // greeting instead.
    for (final tab in ['Programs', 'Progress', 'Nutrition']) {
      await tester.tap(find.descendant(of: bar, matching: find.text(tab)));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(DayAppBar), findsOneWidget, reason: tab);
    }
    await tester.tap(find.descendant(of: bar, matching: find.text('Home')));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(DayAppBar), findsNothing);
    expect(find.text(greetingFor(DateTime.now())), findsOneWidget);

    await tester.tap(find.descendant(of: bar, matching: find.text('Progress')));
    await tester.pumpAndSettle();
    expect(find.text('Stats'), findsOneWidget);
    expect(find.text('History'), findsOneWidget);

    await tester.tap(find.text('History'));
    await tester.pumpAndSettle();
    expect(find.text('Complete a workout to see it here'), findsOneWidget);
    // With no sessions yet, History shows only its empty state and a way
    // to go train.
    expect(find.text('Choose a workout'), findsOneWidget);
  });
}
