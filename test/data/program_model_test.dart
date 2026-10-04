import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:fitness_tracker/data/models/program_model.dart';

void main() {
  group('ProgramModel Deserialization Tests', () {
    test('Parses program_full.json correctly', () {
      final file = File('assets/programs/program_full.json');
      expect(
        file.existsSync(),
        isTrue,
        reason: 'assets/programs/program_full.json must exist',
      );

      final jsonString = file.readAsStringSync();
      final Map<String, dynamic> jsonMap = jsonDecode(jsonString);

      final program = ProgramModel.fromJson(jsonMap);

      expect(program.programId, equals('ffts-4week'));
      expect(program.programName, equals('4 Week Program'));
      expect(program.weeks.length, equals(4));

      final week1 = program.weeks.first;
      expect(week1.number, equals(1));
      expect(week1.title, equals('Fucked From The Start'));
      expect(week1.days.length, equals(5));

      // Day 1: Arms
      final armsDay = week1.days.firstWhere((d) => d.id == 'w1-arms');
      expect(armsDay.name, equals('Arms'));
      expect(armsDay.blocks.length, equals(8));

      // Check Rest Pause Block (Arms Block 1)
      final rpBlock = armsDay.blocks.first;
      expect(rpBlock.type, equals('restPause'));
      expect(rpBlock.exercises.first.logMode, equals('cumulative'));
      expect(rpBlock.exercises.first.repTarget, equals(100));

      // Check Superset Block (Arms Block 2)
      final ssBlock = armsDay.blocks[1];
      expect(ssBlock.type, equals('superset'));
      expect(ssBlock.exercises.length, equals(2));

      // Check Failure Log Mode (Arms Block 4)
      final failureBlock = armsDay.blocks[3];
      expect(failureBlock.exercises.first.logMode, equals('failure'));

      // Check Incomplete Prescription Flag
      expect(rpBlock.exercises.first.prescriptionComplete, isFalse);
    });

    test('Parses the complete four-week program and bonus day', () {
      final file = File('assets/programs/program_full.json');
      expect(file.existsSync(), isTrue);
      final program = ProgramModel.fromJson(
        jsonDecode(file.readAsStringSync()) as Map<String, dynamic>,
      );

      expect(program.weeks.length, equals(4));
      expect(program.weeks.expand((week) => week.days).length, equals(20));
      expect(program.bonusDay?.title, equals('Say Uncle!'));
      expect(program.openItems, isNotEmpty);
      final scalarScheme = program.weeks[1].days
          .expand((day) => day.blocks)
          .expand((block) => block.exercises)
          .firstWhere((exercise) => exercise.id == 'w2-ch-03')
          .repScheme;
      expect(scalarScheme, equals([20]));
    });

    test('Serializes to JSON and back cleanly', () {
      final file = File('assets/programs/program_full.json');
      final jsonString = file.readAsStringSync();
      final Map<String, dynamic> originalMap = jsonDecode(jsonString);

      final program = ProgramModel.fromJson(originalMap);
      final reserializedMap = program.toJson();

      final reParsedProgram = ProgramModel.fromJson(reserializedMap);
      expect(reParsedProgram.programId, equals(program.programId));
      expect(
        reParsedProgram.weeks.first.days.length,
        equals(program.weeks.first.days.length),
      );
    });

    test('Normalizes the simple track format (reps, targetReps, duration)', () {
      ExerciseModel parse(Map<String, dynamic> extra) => ExerciseModel.fromJson(
        {'id': 'e', 'order': 1, 'name': 'Move', 'targetSets': 3, ...extra},
      );

      final reps = parse({'targetReps': 8, 'logMode': 'reps'});
      expect(reps.logMode, 'repsOnly');
      expect(reps.repScheme, [8, 8, 8]);

      final hold = parse({'durationSeconds': 30, 'logMode': 'time'});
      expect(hold.logMode, 'time');
      expect(hold.repScheme, [30]);
      expect(hold.repUnit, 'sec');

      final explicit = parse({
        'repScheme': [60],
        'repUnit': 'sec',
        'logMode': 'time',
      });
      expect(explicit.repScheme, [60]);
    });

    test('Uses a configured exercise video or a Shorts search fallback', () {
      final configured = ExerciseModel(
        id: 'configured',
        order: 1,
        name: 'Bench Press',
        targetSets: 3,
        logMode: 'weightReps',
        videoUrl: 'https://youtube.com/shorts/example',
      );
      final fallback = ExerciseModel(
        id: 'fallback',
        order: 2,
        name: 'Cable Row',
        targetSets: 3,
        logMode: 'weightReps',
      );

      expect(
        configured.exerciseVideoUri.toString(),
        'https://youtube.com/shorts/example',
      );
      expect(fallback.exerciseVideoUri.host, 'www.youtube.com');
      expect(fallback.exerciseVideoUri.path, '/results');
      expect(
        fallback.exerciseVideoUri.queryParameters['search_query'],
        contains('Cable Row'),
      );
      expect(
        fallback.exerciseVideoUri.queryParameters['search_query'],
        contains('shorts'),
      );
    });
  });
}
