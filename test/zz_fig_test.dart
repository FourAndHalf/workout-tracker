import 'dart:io';
import 'dart:ui' as ui;
import 'package:fitness_tracker/core/theme/app_theme.dart';
import 'package:fitness_tracker/features/explore/widgets/body_figure.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final dark in [true, false]) {
    testWidgets('render figure ${dark ? 'dark' : 'light'}', (tester) async {
      tester.view.physicalSize = const Size(1360, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      final key = GlobalKey();
      Widget fig(String view, String m, String? r) => Padding(
        padding: const EdgeInsets.all(4),
        child: SizedBox(width: 160, child: BodyFigure(muscleId: m, regionId: r, view: view, onSelectMuscle: (_) {})),
      );
      await tester.pumpWidget(MaterialApp(
        theme: dark ? AppTheme.darkTheme : AppTheme.lightTheme,
        home: Scaffold(body: RepaintBoundary(key: key, child: Container(
          color: dark ? const Color(0xFF0B0E12) : const Color(0xFFF1F1F3),
          child: Wrap(children: [
            fig('front', 'shoulders', 'side-delts'), fig('front', 'chest', 'upper-chest'),
            fig('front', 'biceps', 'long-head'), fig('front', 'core', 'abs'),
            fig('front', 'quads', 'rectus-femoris'), fig('front', 'hips', 'adductors'),
            fig('front', 'forearms', 'flexors'), fig('front', 'chest', null),
            fig('back', 'glutes', 'glute-max'), fig('back', 'back', 'lats'),
            fig('back', 'triceps', 'long-head'), fig('back', 'traps', 'upper-traps'),
            fig('back', 'hamstrings', 'curl'), fig('back', 'calves', 'gastrocnemius'),
            fig('back', 'lower-back', 'erectors'), fig('back', 'shoulders', 'rear-delts'),
          ]),
        ))),
      ));
      await tester.pump(const Duration(seconds: 1));
      await tester.runAsync(() async {
        final b = key.currentContext!.findRenderObject() as RenderRepaintBoundary;
        final img = await b.toImage(pixelRatio: 1.0);
        final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
        File('/tmp/claude-0/-home-user-workout-tracker/722beafb-55a2-5ee7-9a44-4b2ae75b293f/scratchpad/app/fig_${dark ? 'dark' : 'light'}.png').writeAsBytesSync(bytes!.buffer.asUint8List());
      });
    });
  }
}
