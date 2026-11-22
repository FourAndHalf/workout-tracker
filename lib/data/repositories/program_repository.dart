import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:drift/drift.dart';

import '../database/app_database.dart';
import '../models/program_model.dart';

class ProgramRepository {
  final AppDatabase db;

  ProgramRepository(this.db);

  static const defaultProgramId = 'ffts-4week';

  /// Bundled workout tracks, keyed by programId.
  static const bundledProgramAssets = {
    defaultProgramId: 'assets/programs/program_full.json',
    'mobility-10min': 'assets/programs/mobility_10min.json',
    'badminton-mobility-strength-12wk':
        'assets/programs/badminton_mobility_strength.json',
    'endurance-run-8wk': 'assets/programs/endurance_run_8wk.json',
  };

  /// Gym and home training splits, browsed from the Explore tab. They are kept
  /// apart from [bundledProgramAssets] so the Programs track switcher stays
  /// short; a split shows there once you pick it.
  static const bundledSplitAssets = {
    'split-gym-full-3': 'assets/programs/split_gym_full_3.json',
    'split-gym-ul-4': 'assets/programs/split_gym_ul_4.json',
    'split-gym-hybrid-5': 'assets/programs/split_gym_hybrid_5.json',
    'split-gym-ppl-6': 'assets/programs/split_gym_ppl_6.json',
    'split-home-full-3': 'assets/programs/split_home_full_3.json',
    'split-home-ul-4': 'assets/programs/split_home_ul_4.json',
    'split-home-ppl-6': 'assets/programs/split_home_ppl_6.json',
    'split-home-bodyweight-3': 'assets/programs/split_home_bodyweight_3.json',
  };

  /// Load the complete bundled program and upgrade an older cached week-one copy.
  Future<ProgramModel> loadDefaultProgram() =>
      loadBundledProgram(defaultProgramId);

  /// Load a bundled track by programId (falling back to the default) and
  /// refresh its cached copy in SQLite.
  Future<ProgramModel> loadBundledProgram(String programId) async {
    final assetPath =
        bundledProgramAssets[programId] ??
        bundledSplitAssets[programId] ??
        bundledProgramAssets[defaultProgramId]!;
    final jsonString = await rootBundle.loadString(assetPath);
    final bundledJson = jsonDecode(jsonString) as Map<String, dynamic>;
    final bundledProgram = ProgramModel.fromJson(bundledJson);
    await saveProgram(bundledProgram, jsonString);
    return bundledProgram;
  }

  /// Every bundled track, in the order they are listed in the switcher.
  Future<List<ProgramModel>> loadBundledPrograms() =>
      Future.wait(bundledProgramAssets.keys.map(loadBundledProgram));

  /// Every bundled gym and home split, in browsing order.
  Future<List<ProgramModel>> loadBundledSplits() =>
      Future.wait(bundledSplitAssets.keys.map(loadBundledProgram));

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
