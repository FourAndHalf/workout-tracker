import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:fitness_tracker/app.dart';
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

/// End to end: pick a split in Explore, start it from Programs, log every
/// set of the first day (straight sets, a superset and a timed plank),
/// finish, and see the next day and the history update.

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

Future<void> _tapNav(WidgetTester tester, String label) async {
  await tester.tap(
    find.descendant(of: find.byType(NavigationBar), matching: find.text(label)),
  );
  await _settle(tester);
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    appRouter.go('/');
  });

  testWidgets('a split can be started and a full session logged', (
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

    // 1. Explore → Splits → Gym Full Body → Use this split.
    await _tapNav(tester, 'Explore');
    await tester.tap(find.text('Splits'));
    await _settle(tester);
    await tester.tap(find.byKey(const ValueKey('split-split-gym-full-3')));
    await _settle(tester);
    await tester.tap(find.byKey(const Key('useSplit')));
    await _settle(tester);

    // 2. Programs shows the split's first day as the one to start.
    expect(find.text('Week 1 of 4'), findsOneWidget);
    expect(find.text('0/3 done'), findsOneWidget);
    final dayA = find.widgetWithText(AppCard, 'Full Body A');
    expect(find.descendant(of: dayA, matching: find.text('Start')), findsOne);
    await tester.tap(find.descendant(of: dayA, matching: find.text('Start')));
    await _settle(tester);
    expect(find.text('Finish workout'), findsOneWidget);

    // 3. Log every set: reps-based sets by their button, the plank by its
    //    countdown. The superset's two exercises each log on their own tile.
    final day = _program('split-gym-full-3').weeks.first.days.first;
    final expectedSets = day.blocks
        .expand((b) => b.exercises)
        .fold<int>(0, (sum, e) => sum + e.targetSets);
    final logButton = find.byWidgetPredicate(
      (w) =>
          w is Text &&
          w.data != null &&
          RegExp(r'^Log Set \d+$').hasMatch(w.data!),
    );
    var guard = 0;
    while (logButton.evaluate().isNotEmpty && guard++ < 60) {
      await tester.ensureVisible(logButton.first);
      await tester.tap(logButton.first);
      await _settle(tester);
    }
    var holds = 0;
    while (find.text('Start').evaluate().isNotEmpty && holds < 10) {
      await tester.ensureVisible(find.text('Start').first);
      await tester.tap(find.text('Start').first);
      await tester.pump(const Duration(seconds: 3));
      await tester.tap(find.text('Log early').first);
      await _settle(tester);
      holds++;
    }
    expect(holds, 3, reason: 'the plank is 3 timed sets');
    expect(logButton, findsNothing, reason: 'every set has been logged');
    expect(find.text('$expectedSets of $expectedSets sets'), findsOneWidget);

    await tester.tap(find.text('Finish workout'));
    await _settle(tester);

    // 4. The session and every set are stored against the split.
    final sessions = await tester.runAsync(
      () => db.select(db.workoutSessions).get(),
    );
    expect(sessions, hasLength(1));
    final session = sessions!.single;
    expect(session.programId, 'split-gym-full-3');
    expect(session.dayId, day.id);
    expect(session.finishedAt, isNotNull);
    final logs = await tester.runAsync(() => db.select(db.exerciseLogs).get());
    expect(logs, hasLength(expectedSets));
    final plank = logs!.where((l) => l.logMode == 'time').toList();
    expect(plank, hasLength(3));
    expect(plank.every((l) => l.durationSeconds == 3), isTrue);
    expect(
      logs.where((l) => l.blockType == 'superset').map((l) => l.exerciseName),
      containsAll([
        _library.exercises['Triceps_Pushdown_-_Rope_Attachment']!.name,
        _library.exercises['Barbell_Curl']!.name,
      ]),
    );
    expect(
      logs
          .where((l) => l.logMode == 'weightReps')
          .every((l) => l.weight != null),
      isTrue,
    );

    // 5. Programs moves on to day B; day A is done.
    await _tapNav(tester, 'Programs');
    expect(find.text('1/3 done'), findsOneWidget);
    expect(
      find.descendant(
        of: find.widgetWithText(AppCard, 'Full Body B'),
        matching: find.text('Start'),
      ),
      findsOne,
    );
    expect(
      find.descendant(
        of: find.widgetWithText(AppCard, 'Full Body A'),
        matching: find.text('Done'),
      ),
      findsOne,
    );

    // 6. History lists the session.
    await _tapNav(tester, 'Progress');
    await tester.tap(find.text('History'));
    await _settle(tester);
    expect(find.text('Full Body A'), findsWidgets);
  });
}
