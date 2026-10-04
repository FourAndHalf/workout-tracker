import 'package:fitness_tracker/core/theme/app_theme.dart';
import 'package:fitness_tracker/data/models/program_model.dart';
import 'package:fitness_tracker/features/program/widgets/block_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final block = BlockModel(
    id: 'b',
    name: 'Warm-up',
    type: 'warmup',
    targetSets: 1,
    exercises: [
      ExerciseModel(
        id: 'e1',
        order: 1,
        name: 'Ankle Rocks',
        targetSets: 1,
        logMode: 'repsOnly',
      ),
      ExerciseModel(
        id: 'e2',
        order: 2,
        name: 'Deep Squat Hold',
        targetSets: 1,
        logMode: 'time',
        repScheme: [30],
        repUnit: 'sec',
      ),
    ],
  );

  testWidgets('every exercise has a YouTube link before a workout starts', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: Scaffold(
          body: SingleChildScrollView(
            child: BlockCard(block: block, blockIndex: 0),
          ),
        ),
      ),
    );

    expect(find.byTooltip('Watch Ankle Rocks on YouTube Shorts'), findsOne);
    expect(find.byTooltip('Watch Deep Squat Hold on YouTube Shorts'), findsOne);
    expect(find.text('30 sec'), findsOneWidget);
  });

  testWidgets('new block types get their own badge', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: Scaffold(body: BlockCard(block: block, blockIndex: 0)),
      ),
    );

    expect(find.text('WARM-UP'), findsOneWidget);
    expect(find.text('STRAIGHT'), findsNothing);
  });
}
