import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:drift/drift.dart';

import '../database/app_database.dart';
import '../models/program_model.dart';

class ProgramRepository {
  final AppDatabase db;

  ProgramRepository(this.db);

  /// Load the complete bundled program and upgrade an older cached week-one copy.
  Future<ProgramModel> loadDefaultProgram() async {
    final jsonString = await rootBundle.loadString(
      'assets/programs/program_full.json',
    );
    final bundledJson = jsonDecode(jsonString) as Map<String, dynamic>;
    final bundledProgram = ProgramModel.fromJson(bundledJson);
    final existing = await (db.select(
      db.programs,
    )..where((p) => p.id.equals('ffts-4week'))).getSingleOrNull();
    if (existing != null) {
      final jsonMap = jsonDecode(existing.jsonData) as Map<String, dynamic>;
      final existingProgram = ProgramModel.fromJson(jsonMap);
      if (existingProgram.weeks.length >= bundledProgram.weeks.length) {
        return existingProgram;
      }
      await saveProgram(bundledProgram, jsonString);
      return bundledProgram;
    }

    await saveProgram(bundledProgram, jsonString);
    return bundledProgram;
  }

  /// Save or update a program in SQLite
  Future<void> saveProgram(ProgramModel program, String rawJson) async {
    await db
        .into(db.programs)
        .insertOnConflictUpdate(
          ProgramsCompanion.insert(
            id: program.programId,
            name: program.programName,
            sourceNote: Value(program.sourceNote),
            jsonData: rawJson,
            createdAt: Value(DateTime.now()),
          ),
        );
  }

  /// Fetch all programs from database
  Future<List<ProgramModel>> getAllPrograms() async {
    final rows = await db.select(db.programs).get();
    return rows.map((r) {
      final jsonMap = jsonDecode(r.jsonData) as Map<String, dynamic>;
      return ProgramModel.fromJson(jsonMap);
    }).toList();
  }

  /// Fetch program by ID
  Future<ProgramModel?> getProgramById(String id) async {
    final row = await (db.select(
      db.programs,
    )..where((p) => p.id.equals(id))).getSingleOrNull();
    if (row == null) return null;
    final jsonMap = jsonDecode(row.jsonData) as Map<String, dynamic>;
    return ProgramModel.fromJson(jsonMap);
  }
}
