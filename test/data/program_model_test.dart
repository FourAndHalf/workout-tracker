import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:fitness_tracker/data/models/program_model.dart';

void main() {
  group('ProgramModel Deserialization Tests', () {
    test('Parses program_week1.json correctly', () {
      final file = File('assets/programs/program_week1.json');
      expect(
        file.existsSync(),
        isTrue,
        reason: 'assets/programs/program_week1.json must exist',
      );

      final jsonString = file.readAsStringSync();
      final Map<String, dynamic> jsonMap = jsonDecode(jsonString);

      final program = ProgramModel.fromJson(jsonMap);

      expect(program.programId, equals('ffts-4week'));
      expect(program.programName, equals('4 Week Program'));
      expect(program.weeks.length, equals(1));

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

    test('Serializes to JSON and back cleanly', () {
      final file = File('assets/programs/program_week1.json');
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
