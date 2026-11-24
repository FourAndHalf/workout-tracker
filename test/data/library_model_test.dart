import 'dart:convert';
import 'dart:io';

import 'package:fitness_tracker/data/models/library_model.dart';
import 'package:fitness_tracker/data/models/program_model.dart';
import 'package:fitness_tracker/data/repositories/program_repository.dart';
import 'package:flutter_test/flutter_test.dart';

LibraryModel _library() => LibraryModel.fromJson(
  jsonDecode(File('assets/library/library.json').readAsStringSync())
      as Map<String, dynamic>,
);

ProgramModel _split(String id) => ProgramModel.fromJson(
  jsonDecode(File(ProgramRepository.bundledSplitAssets[id]!).readAsStringSync())
      as Map<String, dynamic>,
);

void main() {
  final library = _library();

  group('Explore library', () {
    test('covers the main muscle groups with several parts each', () {
      expect(
        library.muscles.map((m) => m.id),
        containsAll([
          'chest',
          'shoulders',
          'back',
          'biceps',
          'triceps',
          'core',
          'glutes',
          'quads',
          'hamstrings',
          'calves',
        ]),
      );
      expect(library.muscles.length, greaterThanOrEqualTo(12));
      expect(library.exercises.length, greaterThan(150));
      for (final muscle in library.muscles) {
        expect(muscle.regions, isNotEmpty, reason: muscle.id);
        expect(muscle.summary, isNotEmpty, reason: muscle.id);
        expect(
          {for (final r in muscle.regions) r.id}.length,
          muscle.regions.length,
          reason: '${muscle.id} region ids are unique',
        );
      }
    });

    test('every muscle has picks for both gym and home', () {
      for (final muscle in library.muscles) {
        for (final setting in TrainSetting.values) {
          expect(
            muscle.overview(setting, limit: 3),
            hasLength(greaterThanOrEqualTo(3)),
            reason: '${muscle.id} ${setting.name}',
          );
          for (final region in muscle.regions) {
            expect(
              region.picks(setting),
              hasLength(greaterThanOrEqualTo(2)),
              reason: '${muscle.id}/${region.id} ${setting.name}',
            );
            expect(region.note, isNotEmpty, reason: region.id);
          }
        }
      }
    });

    test('every pick points at a real exercise with photos on disk', () {
      for (final muscle in library.muscles) {
        for (final region in muscle.regions) {
          for (final setting in TrainSetting.values) {
            for (final pick in region.picks(setting)) {
              final exercise = library.exercises[pick.exerciseId];
              expect(exercise, isNotNull, reason: pick.exerciseId);
              expect(pick.sets, inInclusiveRange(2, 5));
              expect(pick.reps, matches(RegExp(r'^\d+–\d+s?$')));
            }
          }
        }
      }
      for (final e in library.exercises.values) {
        expect(e.cue, isNotEmpty, reason: e.id);
        expect(e.steps, isNotEmpty, reason: e.id);
        expect(e.images, isNotEmpty, reason: e.id);
        for (final path in e.imageAssets) {
          expect(File(path).existsSync(), isTrue, reason: path);
        }
      }
    });

    test('home picks avoid barbells, cables and machines', () {
      const gymOnly = {'Barbell', 'Cable', 'Machine', 'EZ-bar', 'Dip bars'};
      for (final muscle in library.muscles) {
        for (final region in muscle.regions) {
          for (final pick in region.home) {
            final e = library.exercises[pick.exerciseId]!;
            // A few bodyweight moves are tagged with gym equipment in the
            // source data; the app relabels them.
            expect(
              gymOnly.contains(e.equipment) && e.id != 'Dips_-_Chest_Version',
              isFalse,
              reason: '${e.id} (${e.equipment}) in home picks of ${region.id}',
            );
          }
        }
      }
    });

    test('overview takes the best of each part without repeats', () {
      final chest = library.muscle('chest')!;
      final overview = chest.overview(TrainSetting.gym);
      expect(overview.length, 6);
      expect({for (final p in overview) p.exerciseId}.length, 6);
      // Each part's first pick is in, in order.
      expect(
        overview.first.exerciseId,
        chest.regions.first.gym.first.exerciseId,
      );
      expect(
        overview.map((p) => p.exerciseId),
        containsAll([for (final r in chest.regions) r.gym.first.exerciseId]),
      );
    });

    test('search matches names and equipment', () {
      expect(library.search('curl').length, greaterThan(10));
      expect(
        library.search('romanian deadlift').map((e) => e.id),
        contains('Romanian_Deadlift'),
      );
      expect(library.search('band'), isNotEmpty);
      expect(library.search('   '), isEmpty);
      expect(library.search('zzzzqq'), isEmpty);
    });

    test('credits the photo source and cites studies', () {
      expect(library.photoCredit, contains('free-exercise-db'));
      expect(library.photoCredit, contains('public domain'));
      expect(library.references.length, greaterThanOrEqualTo(8));
      for (final r in library.references) {
        expect(Uri.parse(r.url).scheme, 'https');
      }
    });
  });

  group('Gym and home splits', () {
    final ids = ProgramRepository.bundledSplitAssets.keys.toList();

    test('there are four gym and four home splits', () {
      final splits = ids.map(_split).toList();
      expect(splits.where((s) => s.setting == 'gym'), hasLength(4));
      expect(splits.where((s) => s.setting == 'home'), hasLength(4));
      expect(splits.every((s) => s.isSplit), isTrue);
      expect(splits.map((s) => s.programId), ids);
    });

    for (final id in ids) {
      test('$id is a four-week block built from library exercises', () {
        final split = _split(id);
        expect(split.weeks, hasLength(4));
        expect(split.daysPerWeek, split.weeks.first.days.length);
        expect(split.description, isNotEmpty);

        final allowed = <String>{
          for (final m in library.muscles)
            for (final r in m.regions)
              for (final p in r.picks(
                split.setting == 'gym' ? TrainSetting.gym : TrainSetting.home,
              ))
                p.exerciseId,
        };
        final seen = <String>{};
        for (final week in split.weeks) {
          expect(week.focus, isNotEmpty);
          expect(week.days, hasLength(split.daysPerWeek!));
          for (final day in week.days) {
            final exercises = day.blocks.expand((b) => b.exercises).toList();
            expect(exercises.length, inInclusiveRange(5, 8), reason: day.id);
            expect(day.muscles, isNotEmpty, reason: day.id);
            expect(day.estimatedDurationSeconds, inInclusiveRange(1800, 4800));
            for (final block in day.blocks) {
              expect(block.restSeconds, greaterThan(0));
              if (block.type == 'superset') {
                expect(block.exercises.length, 2);
              }
            }
            for (final e in exercises) {
              expect(seen.add(e.id), isTrue, reason: 'duplicate id ${e.id}');
              expect(library.exercises, contains(e.libraryId), reason: e.id);
              // Gym days use gym picks, home days only home picks.
              expect(allowed, contains(e.libraryId), reason: '$id ${e.id}');
              expect(e.instructions, isNotEmpty);
              expect(e.prescription, isNotEmpty);
              expect(['weightReps', 'repsOnly', 'time'], contains(e.logMode));
              if (e.logMode == 'time') expect(e.repScheme, isNotNull);
            }
          }
        }
      });

      test('$id progresses through the block and deloads in week 4', () {
        final split = _split(id);
        int sets(WeekModel w) => w.days
            .expand((d) => d.blocks)
            .fold<int>(0, (t, b) => t + b.targetSets * b.exercises.length);
        final totals = split.weeks.map(sets).toList();
        expect(totals[0], totals[1]);
        expect(totals[2], greaterThan(totals[1]));
        expect(totals[3], lessThan(totals[0] * 0.75));
      });

      test('$id trains the big muscles in the 8-30 hard-set range', () {
        final split = _split(id);
        expect(split.weeklySets, isNotEmpty);
        for (final entry in split.weeklySets.entries) {
          final w = entry.value;
          expect(w.effective, greaterThanOrEqualTo(w.direct));
          expect(w.effective, lessThanOrEqualTo(w.direct + w.indirect));
        }
        for (final big in ['chest', 'back', 'quads']) {
          final w = split.weeklySets[big]!;
          expect(w.effective, inInclusiveRange(6, 30), reason: '$id $big');
        }
      });
    }

    test(
      'push/pull/legs and upper/lower reach 10-20 sets on the main muscles',
      () {
        for (final id in [
          'split-gym-ul-4',
          'split-gym-hybrid-5',
          'split-gym-ppl-6',
          'split-home-ul-4',
        ]) {
          final w = _split(id).weeklySets;
          for (final m in [
            'chest',
            'back',
            'quads',
            'hamstrings',
            'biceps',
            'triceps',
          ]) {
            expect(w[m]!.effective, inInclusiveRange(10, 25), reason: '$id $m');
          }
        }
      },
    );

    test('splits do not change the original tracks', () {
      expect(
        ProgramRepository.bundledProgramAssets.keys,
        isNot(contains('split-gym-ppl-6')),
      );
      expect(ProgramRepository.bundledProgramAssets, hasLength(4));
    });
  });

  test('splits can be selected and loaded by id', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    // Asset lookup falls through to the split map.
    expect(
      ProgramRepository.bundledSplitAssets['split-home-bodyweight-3'],
      endsWith('split_home_bodyweight_3.json'),
    );
  });
}
