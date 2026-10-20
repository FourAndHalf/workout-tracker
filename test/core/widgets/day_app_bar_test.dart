import 'package:fitness_tracker/core/widgets/day_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('formats weekday and short date', () {
    final thursday = DateTime(2026, 9, 24);
    expect(weekdayLabel(thursday), 'Thursday');
    expect(shortDateLabel(thursday), '24 Sep');
    expect(weekdayLabel(DateTime(2026, 9, 21)), 'Monday');
    expect(weekdayLabel(DateTime(2026, 9, 27)), 'Sunday');
  });

  testWidgets('DayAppBar shows the title, the date and its actions', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          appBar: DayAppBar(
            title: 'Programs',
            today: DateTime(2026, 9, 24),
            actions: const [Icon(Icons.settings_outlined)],
          ),
        ),
      ),
    );

    expect(find.text('Programs'), findsOneWidget);
    expect(find.text('Thursday, 24 Sep'), findsOneWidget);
    expect(find.byIcon(Icons.settings_outlined), findsOneWidget);
  });
}
