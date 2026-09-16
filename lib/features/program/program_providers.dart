import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../main.dart';
import '../../data/models/program_model.dart';

final currentProgramProvider = FutureProvider<ProgramModel>((ref) async {
  final repo = ref.watch(programRepositoryProvider);
  return repo.loadDefaultProgram();
});

final selectedDayIdProvider = StateProvider<String?>((ref) => null);
