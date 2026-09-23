import 'package:flutter_riverpod/legacy.dart';

class ActiveWorkoutBannerInfo {
  final String dayId;
  final String dayName;
  final DateTime startTime;

  const ActiveWorkoutBannerInfo({
    required this.dayId,
    required this.dayName,
    required this.startTime,
  });
}

class ActiveWorkoutSessionNotifier extends StateNotifier<ActiveWorkoutBannerInfo?> {
  ActiveWorkoutSessionNotifier() : super(null);

  void start({
    required String dayId,
    required String dayName,
    required DateTime startTime,
  }) {
    state = ActiveWorkoutBannerInfo(
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
    StateNotifierProvider<ActiveWorkoutSessionNotifier, ActiveWorkoutBannerInfo?>(
      (ref) => ActiveWorkoutSessionNotifier(),
    );
