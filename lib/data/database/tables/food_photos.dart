import 'package:drift/drift.dart';

class FoodPhotos extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get filePath => text()();
  BlobColumn get thumbnail => blob().nullable()();
  DateTimeColumn get capturedAt => dateTime().withDefault(currentDateAndTime)();
  TextColumn get mealLabel => text().nullable()();
}
