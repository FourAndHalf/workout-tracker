import 'package:fitness_tracker/core/theme/app_colors.dart';
import 'package:fitness_tracker/core/theme/app_theme.dart';
import 'package:fitness_tracker/core/widgets/ledger.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) => MaterialApp(
  theme: AppTheme.lightTheme,
  home: Scaffold(body: Center(child: child)),
);

void main() {
  testWidgets('DeltaPill pairs the semantic color with a glyph', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(const Column(children: [DeltaPill(12), DeltaPill(-4)])),
    );

    final up = tester.widget<Text>(find.text('▲ 12%'));
    final down = tester.widget<Text>(find.text('▼ 4%'));
    expect(up.style?.color, AppColors.light.success);
    expect(down.style?.color, AppColors.light.error);
  });

  testWidgets('ThinBarChart floats the callout over the highlighted bar', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        const SizedBox(
          width: 300,
          child: ThinBarChart(
            values: [1, 4, 2],
            labels: ['a', 'b', 'c'],
            highlightIndex: 2,
            callout: '+12%',
          ),
        ),
      ),
    );

    expect(find.byType(CalloutPill), findsOneWidget);
    expect(find.text('+12%'), findsOneWidget);
    expect(find.text('b'), findsOneWidget);
  });

  testWidgets('GaugeArc, SegmentProgress and DotMatrix render', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const SizedBox(
          width: 300,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GaugeArc(value: 0.5, child: Text('2/4')),
              SegmentProgress(total: 3, filled: 1),
              DotMatrix(
                columns: [
                  [true, false],
                  [false, true],
                ],
              ),
              Sparkline([1, 3, 2]),
            ],
          ),
        ),
      ),
    );

    expect(find.text('2/4'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(SegmentProgress),
        matching: find.byType(AnimatedContainer),
      ),
      findsNWidgets(3),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('RoundIconButton exposes its tooltip and fires', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      _wrap(
        RoundIconButton(
          icon: Icons.settings_outlined,
          tooltip: 'Settings',
          onPressed: () => taps++,
        ),
      ),
    );

    await tester.tap(find.byTooltip('Settings'));
    expect(taps, 1);
  });
}
