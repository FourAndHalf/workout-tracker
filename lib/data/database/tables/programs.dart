import 'package:drift/drift.dart';

class Programs extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get sourceNote => text().nullable()();
  TextColumn get jsonData => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
