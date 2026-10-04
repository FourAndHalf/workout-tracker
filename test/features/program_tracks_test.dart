import 'package:drift/native.dart';
import 'package:fitness_tracker/data/database/app_database.dart';
import 'package:fitness_tracker/data/repositories/workout_repository.dart';
import 'package:fitness_tracker/features/program/program_list_screen.dart';
import 'package:fitness_tracker/features/program/program_providers.dart';
import 'package:fitness_tracker/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  ProviderContainer makeContainer() {
    final container = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(db)],
    );
    addTearDown(container.dispose);
    return container;
  }

  Future<void> completeSession(String programId, String weekId, String dayId) {
    final repo = WorkoutRepository(db);
    return repo
        .startSession(
          programId: programId,
          weekId: weekId,
          dayId: dayId,
          dayName: dayId,
        )
        .then(repo.finishSession);
  }

  test('selection persists to SharedPreferences', () async {
    final container = makeContainer();
    expect(container.read(selectedProgramIdProvider), 'ffts-4week');

    await container
        .read(selectedProgramIdProvider.notifier)
        .select('mobility-10min');

    expect(container.read(selectedProgramIdProvider), 'mobility-10min');
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(selectedProgramPreferenceKey), 'mobility-10min');
  });

  test('progress is tracked separately per track', () async {
    await completeSession('mobility-10min', 'mob-w1', 'mob-w1-routine');
    final container = makeContainer();

    expect(
      await container.read(completedWorkoutSessionsProvider.future),
      isEmpty,
    );

    await container
        .read(selectedProgramIdProvider.notifier)
        .select('mobility-10min');
    final sessions = await container.read(
      completedWorkoutSessionsProvider.future,
    );
    expect(sessions.map((s) => s.dayId), ['mob-w1-routine']);

    await container
        .read(selectedProgramIdProvider.notifier)
        .select('ffts-4week');
    expect(
      await container.read(completedWorkoutSessionsProvider.future),
      isEmpty,
    );
  });

  testWidgets('switcher lists both tracks and changes the shown program', (
    tester,
  ) async {
    await tester.runAsync(() async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [databaseProvider.overrideWithValue(db)],
          child: const MaterialApp(home: ProgramListScreen()),
        ),
      );
      for (var i = 0; i < 20; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 100));
        await tester.pump();
        if (find.text('10 Min Mobility').evaluate().isNotEmpty) break;
      }
    });

    expect(find.text('4 Week Program'), findsWidgets);
    expect(find.text('10 Min Mobility'), findsOneWidget);

    await tester.runAsync(() async {
      await tester.tap(find.text('10 Min Mobility'));
      for (var i = 0; i < 20; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 100));
        await tester.pump();
        if (find.text('Week 1: "Daily Routine"').evaluate().isNotEmpty) break;
      }
    });

    expect(find.text('Week 1: "Daily Routine"'), findsOneWidget);
  });
}
