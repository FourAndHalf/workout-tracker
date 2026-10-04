import 'package:drift/native.dart';
import 'package:fitness_tracker/data/database/app_database.dart';
import 'package:fitness_tracker/data/repositories/program_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late ProgramRepository repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = ProgramRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('loadBundledPrograms loads and caches every bundled track', () async {
    final programs = await repo.loadBundledPrograms();

    expect(
      programs.map((p) => p.programId),
      ProgramRepository.bundledProgramAssets.keys,
    );
    expect((await repo.getAllPrograms()).length, programs.length);
  });

  test('mobility track is ten 60-second timed blocks in one day', () async {
    final program = await repo.loadBundledProgram('mobility-10min');

    expect(program.programName, '10 Min Mobility');
    expect(program.weeks, hasLength(1));
    final day = program.weeks.single.days.single;
    expect(day.blocks, hasLength(10));
    for (final block in day.blocks) {
      final exercise = block.exercises.single;
      expect(exercise.logMode, 'time');
      expect(exercise.repScheme, [60]);
    }
    expect(day.blocks.first.name, 'Deep Squat Hold');
    expect(day.blocks.last.name, 'Shoulder Mobility');
  });

  test('unknown programId falls back to the default program', () async {
    final program = await repo.loadBundledProgram('does-not-exist');

    expect(program.programId, ProgramRepository.defaultProgramId);
  });
}
