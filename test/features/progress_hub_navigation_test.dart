import 'package:drift/native.dart';
import 'package:fitness_tracker/app.dart';
import 'package:fitness_tracker/core/widgets/day_app_bar.dart';
import 'package:fitness_tracker/data/database/app_database.dart';
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

    // Every tab shares the same day header.
    for (final tab in ['Programs', 'Progress', 'Nutrition', 'Home']) {
      await tester.tap(find.descendant(of: bar, matching: find.text(tab)));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(DayAppBar), findsOneWidget, reason: tab);
    }

    await tester.tap(find.descendant(of: bar, matching: find.text('Progress')));
    await tester.pumpAndSettle();
    expect(find.text('Stats'), findsOneWidget);
    expect(find.text('History'), findsOneWidget);

    await tester.tap(find.text('History'));
    await tester.pumpAndSettle();
    expect(find.text('Complete a workout to see it here'), findsOneWidget);
    // Embedded history exposes its calendar/list toggle without an app bar.
    expect(find.byTooltip('Show list'), findsOneWidget);
  });
}
