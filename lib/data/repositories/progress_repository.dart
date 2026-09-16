import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class ProgressCheckIn {
  final DateTime date;
  final double weightKg;
  final double fatPercent;
  final String? photoPath;

  const ProgressCheckIn({
    required this.date,
    required this.weightKg,
    required this.fatPercent,
    this.photoPath,
  });

  Map<String, dynamic> toJson() => {
    'date': date.toIso8601String(),
    'weightKg': weightKg,
    'fatPercent': fatPercent,
    'photoPath': photoPath,
  };

  factory ProgressCheckIn.fromJson(Map<String, dynamic> json) =>
      ProgressCheckIn(
        date: DateTime.parse(json['date'] as String),
        weightKg: (json['weightKg'] as num).toDouble(),
        fatPercent: (json['fatPercent'] as num).toDouble(),
        photoPath: json['photoPath'] as String?,
      );
}

class ProgressRepository {
  static const _key = 'weekly_progress_check_ins';
  final SharedPreferences preferences;

  ProgressRepository(this.preferences);

  Future<List<ProgressCheckIn>> getCheckIns() async {
    final values = preferences.getStringList(_key) ?? [];
    final entries = values
        .map(
          (value) => ProgressCheckIn.fromJson(
            jsonDecode(value) as Map<String, dynamic>,
          ),
        )
        .toList();
    entries.sort((a, b) => b.date.compareTo(a.date));
    return entries;
  }

  Future<void> saveCheckIn(ProgressCheckIn checkIn) async {
    final entries = await getCheckIns();
    entries.removeWhere(
      (entry) => _weekStart(entry.date) == _weekStart(checkIn.date),
    );
    entries.add(checkIn);
    await preferences.setStringList(
      _key,
      entries.map((entry) => jsonEncode(entry.toJson())).toList(),
    );
  }

  DateTime _weekStart(DateTime date) {
    final day = DateTime(date.year, date.month, date.day);
    return day.subtract(Duration(days: day.weekday - 1));
  }
}
