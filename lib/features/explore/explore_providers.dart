import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../data/models/library_model.dart';
import '../../data/models/program_model.dart';
import '../../main.dart';

/// The bundled muscle and exercise library.
final libraryProvider = FutureProvider<LibraryModel>((ref) async {
  final raw = await rootBundle.loadString('assets/library/library.json');
  return LibraryModel.fromJson(jsonDecode(raw) as Map<String, dynamic>);
});

/// Gym or home picks for the muscle library and the splits list.
final exploreSettingProvider = StateProvider<TrainSetting>(
  (ref) => TrainSetting.gym,
);

/// The muscle group picked in Explore.
final exploreMuscleProvider = StateProvider<String>((ref) => 'chest');

/// The part of that muscle (null = all parts).
final exploreRegionProvider = StateProvider<String?>((ref) => null);

/// Every bundled gym and home split.
final exploreSplitsProvider = FutureProvider<List<ProgramModel>>((ref) {
  return ref.watch(programRepositoryProvider).loadBundledSplits();
});
