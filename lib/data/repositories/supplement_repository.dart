import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class SupplementItem {
  final String id;
  final String name;
  final String? photoPath;

  const SupplementItem({required this.id, required this.name, this.photoPath});

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'photoPath': photoPath,
  };

  factory SupplementItem.fromJson(Map<String, dynamic> json) => SupplementItem(
    id: json['id'] as String,
    name: json['name'] as String,
    photoPath: json['photoPath'] as String?,
  );
}

class SupplementRepository {
  static const _supplementsKey = 'settings_supplements';
  static const _notesKey = 'history_daily_notes';
  final SharedPreferences preferences;

  SupplementRepository(this.preferences);

  Future<List<SupplementItem>> getSupplements() async {
    final values = preferences.getStringList(_supplementsKey) ?? [];
    return values
        .map(
          (value) => SupplementItem.fromJson(
            jsonDecode(value) as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  Future<void> saveSupplement(SupplementItem supplement) async {
    final supplements = await getSupplements();
    supplements.removeWhere((item) => item.id == supplement.id);
    supplements.add(supplement);
    await preferences.setStringList(
      _supplementsKey,
      supplements.map((item) => jsonEncode(item.toJson())).toList(),
    );
  }

  Future<void> deleteSupplement(String id) async {
    final supplements = await getSupplements();
    supplements.removeWhere((item) => item.id == id);
    await preferences.setStringList(
      _supplementsKey,
      supplements.map((item) => jsonEncode(item.toJson())).toList(),
    );
  }

  Future<String> getNote(DateTime date) async {
    final raw = preferences.getString(_notesKey);
    if (raw == null) return '';
    final values = jsonDecode(raw) as Map<String, dynamic>;
    return values[_dateKey(date)] as String? ?? '';
  }

  Future<void> saveNote(DateTime date, String note) async {
    final raw = preferences.getString(_notesKey);
    final values = raw == null
        ? <String, dynamic>{}
        : jsonDecode(raw) as Map<String, dynamic>;
    if (note.trim().isEmpty) {
      values.remove(_dateKey(date));
    } else {
      values[_dateKey(date)] = note.trim();
    }
    await preferences.setString(_notesKey, jsonEncode(values));
  }

  String _dateKey(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}
