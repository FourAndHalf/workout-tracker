import 'package:fitness_tracker/core/theme/app_theme.dart';
import 'package:fitness_tracker/core/widgets/sliding_segmented_control.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';


void main() {
  testWidgets('renders labels and reports taps', (tester) async {
    int? selected;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: Scaffold(
          body: SlidingSegmentedControl(
            labels: const ['Stats', 'History'],
            position: 0,
            onSelected: (i) => selected = i,
          ),
        ),
      ),
    );

    expect(find.text('Stats'), findsOneWidget);
    await tester.tap(find.text('History'));
    expect(selected, 1);
  });
}
