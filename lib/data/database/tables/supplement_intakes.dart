import 'package:drift/drift.dart';

class SupplementIntakes extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get date => text()();
  TextColumn get supplement => text()();
  DateTimeColumn get takenAt => dateTime().withDefault(currentDateAndTime)();
}
