import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:fitness_tracker/app.dart';
import 'package:fitness_tracker/core/theme/app_theme.dart';
import 'package:fitness_tracker/data/database/app_database.dart';
import 'package:fitness_tracker/data/models/library_model.dart';
import 'package:fitness_tracker/data/models/program_model.dart';
import 'package:fitness_tracker/data/repositories/program_repository.dart';
import 'package:fitness_tracker/features/explore/explore_providers.dart';
import 'package:fitness_tracker/features/explore/explore_screen.dart';
import 'package:fitness_tracker/features/explore/widgets/body_figure.dart';
import 'package:fitness_tracker/features/explore/widgets/exercise_detail.dart';
import 'package:fitness_tracker/features/program/program_providers.dart';
import 'package:fitness_tracker/main.dart';
import 'package:fitness_tracker/router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _library = LibraryModel.fromJson(
  jsonDecode(File('assets/library/library.json').readAsStringSync())
      as Map<String, dynamic>,
);

String _name(String id) => _library.exercises[id]!.name;

/// Asset loading never completes under the test clock, so programs and the
/// library are read from disk instead.
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

final _overrides = [
  libraryProvider.overrideWith((ref) async => _library),
  exploreSplitsProvider.overrideWith(
    (ref) async => [
      for (final id in ProgramRepository.bundledSplitAssets.keys) _program(id),
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
];

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pump(const Duration(milliseconds: 300));
}

Future<ProviderContainer> _openExplore(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({});
  tester.view.physicalSize = const Size(430, 3200);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  final db = AppDatabase(NativeDatabase.memory());
  addTearDown(db.close);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [databaseProvider.overrideWithValue(db), ..._overrides],
      child: const FitnessTrackerApp(),
    ),
  );
  await _settle(tester);
  await tester.tap(
    find.descendant(
      of: find.byType(NavigationBar),
      matching: find.text('Explore'),
    ),
  );
  await _settle(tester);
  return ProviderScope.containerOf(tester.element(find.byType(ExploreScreen)));
}

Future<void> _pickMuscle(WidgetTester tester, String id) async {
  final chip = find.byKey(ValueKey('muscle-$id'));
  await tester.ensureVisible(chip);
  await tester.tap(chip);
  await _settle(tester);
}

void main() {
  setUp(() => appRouter.go('/'));

  testWidgets('opens on Chest with ranked gym picks and a start-here tag', (
    tester,
  ) async {
    await _openExplore(tester);

    expect(find.byKey(const Key('muscleTitle')), findsOneWidget);
    expect(find.text('Chest'), findsWidgets);
    // The first part of the muscle is selected by default.
    final upper = _library.muscle('chest')!.regions.first;
    final first = upper.gym.first;
    expect(find.text(_name(first.exerciseId)), findsOneWidget);
    expect(find.text('TOP PICK'), findsOneWidget);
    expect(find.text(first.prescription), findsWidgets);
    expect(find.text('${upper.gym.length} PICKS · GYM'), findsOneWidget);
    expect(find.text('PRIMARY'), findsWidgets);
    // Photos and steps stay folded away until a card is opened.
    expect(find.byKey(const Key('exerciseCue')), findsNothing);
  });

  testWidgets('a part of the muscle shows its own picks and the reason why', (
    tester,
  ) async {
    await _openExplore(tester);
    final mid = _library.muscle('chest')!.region('mid-chest')!;

    await tester.tap(find.byKey(const ValueKey('region-mid-chest')));
    await _settle(tester);
    for (final pick in mid.gym) {
      expect(find.text(_name(pick.exerciseId)), findsOneWidget);
    }
    expect(find.textContaining('Sternal head'), findsOneWidget);

    // The evidence note sits behind the latin name.
    expect(find.byKey(const Key('regionNote')), findsNothing);
    await tester.tap(find.byKey(const Key('aboutToggle')));
    await _settle(tester);
    expect(find.byKey(const Key('regionNote')), findsOneWidget);
    expect(find.text(mid.note), findsOneWidget);

    // The note follows the selected part.
    await tester.tap(find.byKey(const ValueKey('region-upper-chest')));
    await _settle(tester);
    expect(find.textContaining('30°'), findsOneWidget);

    await tester.tap(find.byKey(const Key('aboutToggle')));
    await _settle(tester);
    expect(find.byKey(const Key('regionNote')), findsNothing);
  });

  testWidgets('switching to Home swaps in equipment-free picks', (
    tester,
  ) async {
    final container = await _openExplore(tester);
    await _pickMuscle(tester, 'shoulders');
    await tester.tap(find.byKey(const ValueKey('region-side-delts')));
    await _settle(tester);
    final side = _library.muscle('shoulders')!.region('side-delts')!;

    expect(find.text(_name(side.gym.first.exerciseId)), findsOneWidget);
    final gymOnly = side.gym
        .map((p) => p.exerciseId)
        .where((id) => !side.home.any((h) => h.exerciseId == id));
    expect(gymOnly, isNotEmpty);

    await tester.tap(find.byKey(const ValueKey('toggle-home')));
    await _settle(tester);

    expect(container.read(exploreSettingProvider), TrainSetting.home);
    for (final id in gymOnly) {
      expect(find.text(_name(id)), findsNothing, reason: id);
    }
    expect(find.text(_name(side.home.first.exerciseId)), findsOneWidget);
    expect(find.textContaining('resistance bands'), findsOneWidget);
  });

  testWidgets('opening a card shows photos, the cue, steps and muscles', (
    tester,
  ) async {
    await _openExplore(tester);
    final first = _library.muscle('chest')!.regions.first.gym.first;
    final exercise = _library.exercises[first.exerciseId]!;

    await tester.tap(find.text(exercise.name));
    await _settle(tester);

    expect(find.byKey(const Key('exerciseCue')), findsOneWidget);
    expect(find.text(exercise.cue), findsOneWidget);
    expect(find.text('START'), findsOneWidget);
    expect(find.text('FINISH'), findsOneWidget);
    expect(find.text('1.'), findsOneWidget);
    expect(find.text(exercise.steps.first), findsOneWidget);
    expect(find.byKey(const Key('watchFormVideos')), findsOneWidget);

    await tester.tap(find.text(exercise.name));
    await _settle(tester);
    expect(find.byKey(const Key('exerciseCue')), findsNothing);
  });

  testWidgets('choosing a muscle that lives on the back flips the figure', (
    tester,
  ) async {
    final container = await _openExplore(tester);
    String view() => tester.widget<BodyFigure>(find.byType(BodyFigure)).view;

    await _pickMuscle(tester, 'glutes');
    expect(container.read(exploreMuscleProvider), 'glutes');
    expect(find.text('Glutes'), findsWidgets);
    expect(view(), 'back');

    await tester.tap(find.byKey(const ValueKey('toggle-front')));
    await _settle(tester);
    expect(view(), 'front');

    // Rear delts only show from behind.
    await _pickMuscle(tester, 'shoulders');
    await tester.tap(find.byKey(const ValueKey('region-rear-delts')));
    await _settle(tester);
    expect(view(), 'back');

    await _pickMuscle(tester, 'chest');
    expect(view(), 'front');
  });

  testWidgets('search finds exercises by name or equipment', (tester) async {
    await _openExplore(tester);

    await tester.enterText(find.byKey(const Key('exerciseSearch')), 'romanian');
    await _settle(tester);
    expect(find.text(_name('Romanian_Deadlift')), findsOneWidget);
    expect(find.textContaining('result'), findsOneWidget);
    expect(find.byKey(const ValueKey('muscle-chest')), findsNothing);

    await tester.enterText(find.byKey(const Key('exerciseSearch')), 'zzzzqq');
    await _settle(tester);
    expect(find.textContaining('Nothing matches'), findsOneWidget);

    await tester.tap(find.byTooltip('Clear search'));
    await _settle(tester);
    expect(find.byKey(const ValueKey('muscle-chest')), findsOneWidget);
  });

  testWidgets('tapping the body figure selects the muscle under the finger', (
    tester,
  ) async {
    String? picked;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 200,
              child: BodyFigure(
                muscleId: 'chest',
                regionId: null,
                view: 'front',
                onSelectMuscle: (id) => picked = id,
              ),
            ),
          ),
        ),
      ),
    );
    final box = tester.getRect(find.byType(BodyFigure));
    Offset at(double x, double y) =>
        box.topLeft + Offset(x / 100 * box.width, y / 220 * box.height);

    await tester.tapAt(at(40, 48));
    expect(picked, 'chest');
    await tester.tapAt(at(40, 135));
    expect(picked, 'quads');
    await tester.tapAt(at(50, 80));
    expect(picked, 'core');
    // Empty space does nothing.
    picked = null;
    await tester.tapAt(at(5, 5));
    expect(picked, isNull);
  });

  test('every muscle and part can be found on the figure', () {
    for (final muscle in _library.muscles) {
      expect(
        BodyFigure.viewFor(muscle.id, null),
        isNotNull,
        reason: '${muscle.id} is not drawn',
      );
      for (final region in muscle.regions) {
        expect(
          BodyFigure.viewFor(muscle.id, region.id),
          isNotNull,
          reason: '${muscle.id}/${region.id} is not drawn',
        );
      }
    }
    expect(BodyFigure.viewFor('chest', 'upper-chest'), 'front');
    expect(BodyFigure.viewFor('shoulders', 'rear-delts'), 'back');
    expect(BodyFigure.viewFor('triceps', null), 'back');
    expect(BodyFigure.viewFor('glutes', 'glute-med'), 'back');
    expect(BodyFigure.hitTest('back', const Offset(40, 118)), 'glutes');
    expect(BodyFigure.hitTest('back', const Offset(38, 190)), 'calves');
    expect(BodyFigure.hitTest('back', const Offset(60, 75)), 'back');
    expect(BodyFigure.hitTest('front', const Offset(1, 1)), isNull);
  });

  testWidgets('the exercise sheet opens from anywhere in the app', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 2200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: _overrides,
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () =>
                    showExerciseDetailSheet(context, 'Romanian_Deadlift'),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await _settle(tester);

    expect(find.text(_name('Romanian_Deadlift')), findsOneWidget);
    expect(find.text('BARBELL · INTERMEDIATE'), findsOneWidget);
    expect(
      find.text(_library.exercises['Romanian_Deadlift']!.cue),
      findsOneWidget,
    );
    expect(find.text('Hamstrings'), findsOneWidget);
  });

  group('splits', () {
    Future<void> openSplits(WidgetTester tester) async {
      await tester.tap(find.text('Splits'));
      await _settle(tester);
    }

    testWidgets('list gym splits first, then home, and filter by days', (
      tester,
    ) async {
      await _openExplore(tester);
      await openSplits(tester);

      expect(find.text('Training splits'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('split-split-gym-full-3')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('split-split-gym-ul-4')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('split-split-home-full-3')),
        findsNothing,
      );

      await tester.tap(find.byKey(const ValueKey('toggle-home')));
      await _settle(tester);
      expect(
        find.byKey(const ValueKey('split-split-home-full-3')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('split-split-gym-ul-4')), findsNothing);

      await tester.tap(find.byKey(const ValueKey('days-4')));
      await _settle(tester);
      expect(
        find.byKey(const ValueKey('split-split-home-ul-4')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('split-split-home-full-3')),
        findsNothing,
      );
    });

    testWidgets('a split shows its week, volume and can be started', (
      tester,
    ) async {
      final container = await _openExplore(tester);
      await openSplits(tester);

      await tester.tap(find.byKey(const ValueKey('split-split-gym-ppl-6')));
      await _settle(tester);

      expect(find.text('Gym Push / Pull / Legs'), findsOneWidget);
      expect(find.text('Use this split'), findsOneWidget);
      expect(find.text('Your week'), findsOneWidget);
      expect(find.text('Push A'), findsOneWidget);
      expect(find.text('Legs B'), findsOneWidget);

      // A day opens to show its exercises and prescriptions.
      await tester.tap(find.text('Push A'));
      await _settle(tester);
      expect(
        find.text(_name('Barbell_Bench_Press_-_Medium_Grip')),
        findsOneWidget,
      );
      expect(find.text('4 × 5–8'), findsOneWidget);

      // An exercise opens its photos and steps.
      await tester.tap(find.text(_name('Barbell_Bench_Press_-_Medium_Grip')));
      await _settle(tester);
      expect(
        find.text(_library.exercises['Barbell_Bench_Press_-_Medium_Grip']!.cue),
        findsOneWidget,
      );
      await tester.tapAt(const Offset(10, 10));
      await _settle(tester);

      await tester.scrollUntilVisible(
        find.byKey(const Key('weeklySets')),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Weekly sets per muscle'), findsOneWidget);
      expect(find.text('Chest'), findsWidgets);
      await tester.scrollUntilVisible(
        find.text('The four-week block'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('The four-week block'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.byKey(const Key('useSplit')),
        -300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.byKey(const Key('useSplit')));
      await _settle(tester);

      expect(container.read(selectedProgramIdProvider), 'split-gym-ppl-6');
      // It lands on Programs with the split's first week.
      expect(find.text('Gym Push / Pull / Legs'), findsWidgets);
      expect(find.text('Week 1 of 4'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('track-split-gym-ppl-6')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('track-splits')), findsOneWidget);
    });

    testWidgets('the Programs switcher links back to the splits', (
      tester,
    ) async {
      await _openExplore(tester);
      await tester.tap(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text('Programs'),
        ),
      );
      await _settle(tester);

      await tester.tap(find.byKey(const ValueKey('track-splits')));
      await _settle(tester);

      expect(find.text('Training splits'), findsOneWidget);
      expect(find.byKey(const Key('exerciseSearch')), findsNothing);
    });
  });
}
