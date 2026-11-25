import 'package:drift/native.dart';
import 'package:fitness_tracker/data/database/app_database.dart';
import 'package:fitness_tracker/data/models/program_model.dart';
import 'package:fitness_tracker/features/program/program_list_screen.dart';
import 'package:fitness_tracker/features/program/program_providers.dart';
import 'package:fitness_tracker/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fitness_tracker/core/widgets/accent.dart';

ProgramModel _program(String id, String name) => ProgramModel(
  schemaVersion: 1,
  programId: id,
  programName: name,
  weeks: [
    WeekModel(
      number: 1,
      id: '$id-w1',
      title: 'Week',
      days: [DayModel(id: '$id-d1', name: 'Day', order: 1, blocks: const [])],
    ),
  ],
);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('tapping a track chip switches the selected track', (
    tester,
  ) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final programs = [_program('a', 'Track A'), _program('b', 'Track B')];

    final container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        initialProgramIdProvider.overrideWithValue('a'),
        availableProgramsProvider.overrideWith((ref) async => programs),
        currentProgramProvider.overrideWith((ref) async {
          final id = ref.watch(selectedProgramIdProvider);
          return programs.firstWhere((p) => p.programId == id);
        }),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: ProgramListScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(container.read(selectedProgramIdProvider), 'a');

    expect(find.widgetWithText(AccentChip, 'Track A'), findsOneWidget);
    expect(find.widgetWithText(AccentChip, 'Track B'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('track-b')));
    await tester.pumpAndSettle();

    expect(container.read(selectedProgramIdProvider), 'b');
  });
}
