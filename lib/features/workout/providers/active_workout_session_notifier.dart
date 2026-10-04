import 'package:flutter_riverpod/legacy.dart';

class ActiveWorkoutBannerInfo {
  final String programId;
  final String dayId;
  final String dayName;
  final DateTime startTime;

  const ActiveWorkoutBannerInfo({
    this.programId = 'ffts-4week',
    required this.dayId,
    required this.dayName,
    required this.startTime,
  });
}

class ActiveWorkoutSessionNotifier
    extends StateNotifier<ActiveWorkoutBannerInfo?> {
  ActiveWorkoutSessionNotifier() : super(null);

  void start({
    String programId = 'ffts-4week',
    required String dayId,
    required String dayName,
    required DateTime startTime,
  }) {
    state = ActiveWorkoutBannerInfo(
      programId: programId,
      dayId: dayId,
      dayName: dayName,
      startTime: startTime,
    );
  }

  void clear() {
    state = null;
  }
}

final activeWorkoutSessionProvider =
    StateNotifierProvider<
      ActiveWorkoutSessionNotifier,
      ActiveWorkoutBannerInfo?
    >((ref) => ActiveWorkoutSessionNotifier());
