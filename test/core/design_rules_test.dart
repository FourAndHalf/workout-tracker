import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:fitness_tracker/app.dart';
import 'package:fitness_tracker/core/theme/app_colors.dart';
import 'package:fitness_tracker/core/widgets/accent.dart';
import 'package:fitness_tracker/core/widgets/app_card.dart';
import 'package:fitness_tracker/data/database/app_database.dart';
import 'package:fitness_tracker/data/models/library_model.dart';
import 'package:fitness_tracker/data/models/program_model.dart';
import 'package:fitness_tracker/data/repositories/program_repository.dart';
import 'package:fitness_tracker/features/explore/explore_providers.dart';
import 'package:fitness_tracker/features/program/program_providers.dart';
import 'package:fitness_tracker/main.dart';
import 'package:fitness_tracker/router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Enforces design/DESIGN.md › Coral accent across every screen:
/// at most one coral main action per screen, and coral in the places the
/// adoption table (§9) says it belongs.

final _library = LibraryModel.fromJson(
  jsonDecode(File('assets/library/library.json').readAsStringSync())
      as Map<String, dynamic>,
);

ProgramModel _program(String id) {
  final path =
      ProgramRepository.bundledProgramAssets[id] ??
      ProgramRepository.bundledSplitAssets[id] ??
      ProgramRepository.bundledProgramAssets[ProgramRepository
          .defaultProgramId]!;
  return ProgramModel.fromJson(
    jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>,
  );
}

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pump(const Duration(milliseconds: 300));
}

Future<void> _tab(WidgetTester tester, String label) async {
  await tester.tap(
    find.descendant(of: find.byType(NavigationBar), matching: find.text(label)),
  );
  await _settle(tester);
}

/// Enabled coral main-action buttons on screen right now.
List<AccentButton> _mainActions() => find
    .byType(AccentButton)
    .evaluate()
    .map((e) => e.widget as AccentButton)
    .where((b) => b.onPressed != null)
    .toList();

void _atMostOne(String screen) {
  final actions = _mainActions();
  expect(
    actions.length,
    lessThanOrEqualTo(1),
    reason:
        '$screen shows ${actions.length} coral main actions '
        '(${actions.map((a) => a.label).join(', ')}); DESIGN.md allows one',
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    appRouter.go('/');
  });

  testWidgets('every screen has at most one coral main action, in place', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          libraryProvider.overrideWith((ref) async => _library),
          exploreSplitsProvider.overrideWith(
            (ref) async => [
              for (final id in ProgramRepository.bundledSplitAssets.keys)
                _program(id),
            ],
          ),
          availableProgramsProvider.overrideWith(
            (ref) async => [
              for (final id in ProgramRepository.bundledProgramAssets.keys)
                _program(id),
            ],
          ),
          currentProgramProvider.overrideWith(
            (ref) async => _program(ref.watch(selectedProgramIdProvider)),
          ),
        ],
        child: const FitnessTrackerApp(),
      ),
    );
    await _settle(tester);
    final colors = Theme.of(tester.element(find.byType(NavigationBar)))
        .extension<AppColors>()!;

    // Home: Start workout is the main action.
    _atMostOne('Home');
    expect(_mainActions().single.label, 'Start workout');

    // Programs: the next day offers the coral Start; the selected track is a
    // coral chip; the next day's card has a coral border.
    await _tab(tester, 'Programs');
    _atMostOne('Programs');
    expect(_mainActions().single.label, 'Start');
    final selectedChips = find
        .byType(AccentChip)
        .evaluate()
        .where((e) => (e.widget as AccentChip).selected);
    expect(selectedChips, hasLength(1));
    final nextDay = tester.widget<AppCard>(
      find.ancestor(of: find.text('Start'), matching: find.byType(AppCard)),
    );
    expect(nextDay.borderColor, colors.accent);

    // Day preview: Start <day> Workout. Live: Finish workout, with a coral
    // progress bar.
    // Open the next day's card by its order disc, not the Start pill.
    final nextDayCard = find.ancestor(
      of: find.text('Start'),
      matching: find.byType(AppCard),
    );
    await tester.tap(
      find.descendant(of: nextDayCard, matching: find.byType(Text)).first,
    );
    await _settle(tester);
    _atMostOne('Day preview');
    expect(_mainActions().single.label, startsWith('Start '));
    await tester.tap(find.text(_mainActions().single.label));
    await _settle(tester);
    _atMostOne('Live workout');
    expect(_mainActions().single.label, 'Finish workout');
    final progress = tester.widget<LinearProgressIndicator>(
      find.byType(LinearProgressIndicator).first,
    );
    expect(progress.color, colors.accent);
    await tester.tap(find.text('Finish workout'));
    await _settle(tester);

    // Explore: no main action on the muscle library; one on a split.
    await _tab(tester, 'Explore');
    _atMostOne('Explore muscles');
    await tester.tap(find.text('Splits'));
    await _settle(tester);
    _atMostOne('Explore splits');
    await tester.tap(find.byKey(const ValueKey('split-split-gym-ul-4')));
    await _settle(tester);
    _atMostOne('Split detail');
    expect(_mainActions().single.label, 'Use this split');

    // Progress and Nutrition: never more than one.
    await _tab(tester, 'Progress');
    _atMostOne('Progress');
    await _tab(tester, 'Nutrition');
    _atMostOne('Nutrition');
    final camera = tester.widget<AppCard>(
      find.ancestor(of: find.text('Snap Meal'), matching: find.byType(AppCard)),
    );
    expect(camera.gradient, accentGradient(colors));
  });

  testWidgets('a disabled main action is a quiet outline, not coral', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(extensions: const [AppColors.dark]),
        home: const Scaffold(
          body: AccentButton(label: 'Current split', onPressed: null),
        ),
      ),
    );
    final box = tester.widget<AnimatedContainer>(
      find.descendant(
        of: find.byType(AccentButton),
        matching: find.byType(AnimatedContainer),
      ),
    );
    final decoration = box.decoration! as BoxDecoration;
    expect(decoration.gradient, isNull);
    expect(decoration.boxShadow, isNull);
    expect(decoration.border, isNotNull);
  });

  testWidgets('a selected chip is solid ink, never coral, and has no glow', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(extensions: const [AppColors.light]),
        home: Scaffold(
          body: AccentChip(label: 'Shoulders', selected: true, onTap: () {}),
        ),
      ),
    );
    final box = tester.widget<AnimatedContainer>(
      find.descendant(
        of: find.byType(AccentChip),
        matching: find.byType(AnimatedContainer),
      ),
    );
    final decoration = box.decoration! as BoxDecoration;
    expect(decoration.color, AppColors.light.primary);
    expect(decoration.gradient, isNull);
    expect(decoration.boxShadow, isNull);
  });
}
