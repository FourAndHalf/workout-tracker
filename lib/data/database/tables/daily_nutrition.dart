import 'package:drift/drift.dart';

class DailyNutrition extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get date => text()();
  TextColumn get analysisJson => text().nullable()();
  RealColumn get totalCalories => real().nullable()();
  RealColumn get proteinG => real().nullable()();
  RealColumn get carbsG => real().nullable()();
  RealColumn get fatG => real().nullable()();
  DateTimeColumn get analyzedAt => dateTime().nullable()();
  TextColumn get status => text().withDefault(const Constant('pending'))();
}

class DailyNutritionPhotos extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get dailyNutritionId => integer()();
  IntColumn get foodPhotoId => integer()();
}
