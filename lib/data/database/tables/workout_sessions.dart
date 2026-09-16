import 'package:drift/drift.dart';

class WorkoutSessions extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get programId => text()();
  TextColumn get weekId => text()();
  TextColumn get dayId => text()();
  TextColumn get dayName => text()();
  DateTimeColumn get startedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get finishedAt => dateTime().nullable()();
  TextColumn get notes => text().nullable()();
}
