import 'package:drift/drift.dart';

class ExerciseLogs extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get sessionId => integer()();
  TextColumn get blockId => text()();
  TextColumn get exerciseId => text()();
  TextColumn get exerciseName => text()();
  TextColumn get blockType => text()();
  TextColumn get logMode => text()();
  IntColumn get setNumber => integer()();
  RealColumn get weight => real().nullable()();
  IntColumn get reps => integer().nullable()();
  IntColumn get targetReps => integer().nullable()();
  BoolColumn get hitFailure => boolean().withDefault(const Constant(false))();
  IntColumn get durationSeconds => integer().nullable()();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get loggedAt => dateTime().withDefault(currentDateAndTime)();
}
