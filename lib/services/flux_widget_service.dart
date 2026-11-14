import 'package:home_widget/home_widget.dart';

import '../data/database/app_database.dart';
import '../data/models/program_model.dart';

const dailyBurnPreferenceKey = 'daily_burn_kcal';
const defaultDailyBurnKcal = 2400;

/// Streak length the widgets treat as a completed habit.
const fluxStreakTargetDays = 21;

/// Rough motivational estimate, matching the Progress tab's session estimate.
const _kcalPerWorkoutMinute = 7;

/// Easy-run pace used to size distance work when no duration is authored.
const _estimateSecondsPerKm = 390;

/// Rough session length for the widget's Start button. A duration authored
/// on the day wins. Otherwise timed exercises use their duration and
/// distance work an easy-run pace, each plus the block's rest between sets;
/// bodyweight reps take ~75 s per set and loaded sets ~2.5 min (work plus
/// rest).
int estimateWorkoutMinutes(DayModel day) {
  final authored = day.estimatedDurationSeconds;
  if (authored != null && authored > 0) return (authored / 60).round();

  var seconds = 0.0;
  for (final block in day.blocks) {
    final rest = block.restSeconds ?? 0;
    for (final exercise in block.exercises) {
      final sets = exercise.targetSets;
      final scheme = exercise.repScheme;
      final distance = exercise.distanceMeters;
      if (exercise.logMode == 'time' && scheme != null && scheme.isNotEmpty) {
        seconds += sets * ((scheme.first ?? 30) + rest);
      } else if (exercise.logMode == 'distance' && distance != null) {
        seconds += sets * (distance / 1000 * _estimateSecondsPerKm + rest);
      } else if (exercise.logMode == 'repsOnly') {
        seconds += sets * 75;
      } else {
        seconds += sets * 150;
      }
    }
  }
  return (seconds / 60).round();
}

String _withCommas(int value) => value.toString().replaceAllMapped(
  RegExp(r'\B(?=(\d{3})+(?!\d))'),
  (_) => ',',
);

String _compactKcal(int value) => value >= 1000
    ? '${(value / 1000).toStringAsFixed(2).replaceFirst(RegExp(r'0$'), '')}k'
    : '$value';

String _clockTime(DateTime time) {
  final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
  final minute = time.minute.toString().padLeft(2, '0');
  return '$hour:$minute ${time.hour < 12 ? 'AM' : 'PM'}';
}

/// Everything the "Kinetic Flux" launcher widgets display, pre-formatted so
/// the native side only has to put strings and progress values into views.
class FluxWidgetData {
  final Map<String, Object> values;

  const FluxWidgetData(this.values);

  factory FluxWidgetData.compute({
    required DateTime now,
    required int consumedKcal,
    required int dailyBurnKcal,
    required List<WorkoutSession> completedSessions,
    required int streak,
    required bool trainedToday,
    String? nextWorkoutName,
    int nextWorkoutMinutes = 0,
    String? nextWorkoutUri,
  }) {
    var workoutMinutesToday = 0;
    for (final session in completedSessions) {
      final finished = session.finishedAt;
      if (finished != null &&
          finished.year == now.year &&
          finished.month == now.month &&
          finished.day == now.day) {
        workoutMinutesToday += finished.difference(session.startedAt).inMinutes;
      }
    }

    final burned = dailyBurnKcal + workoutMinutesToday * _kcalPerWorkoutMinute;
    final net = consumedKcal - burned;
    final peak = [burned, consumedKcal, 1].reduce((a, b) => a > b ? a : b);
    final streakPct = (streak * 100 / fluxStreakTargetDays).round().clamp(
      0,
      100,
    );
    final hasWorkout = nextWorkoutName != null;

    return FluxWidgetData({
      'flux_net': net > 0 ? '+$net' : '$net',
      'flux_net_label': net < 0
          ? 'Deficit Mode'
          : net > 0
          ? 'Surplus Mode'
          : 'Balanced',
      'flux_compact_label': net < 0
          ? 'KCAL DEFICIT'
          : net > 0
          ? 'KCAL SURPLUS'
          : 'KCAL EVEN',
      'flux_burned': _withCommas(burned),
      'flux_consumed': _withCommas(consumedKcal),
      'flux_burned_pct': (burned * 100 / peak).round(),
      'flux_consumed_pct': (consumedKcal * 100 / peak).round(),
      'flux_compact_sub':
          '${_compactKcal(burned)} out · ${_compactKcal(consumedKcal)} planned',
      'flux_compact_pct': burned == 0
          ? 0
          : (consumedKcal * 100 / burned).round().clamp(0, 100),
      'flux_status': streak > 0 ? 'ON TRACK' : 'GET STARTED',
      'flux_streak_day': 'Day $streak',
      'flux_streak_chip': '${streak}D',
      'flux_streak_short': '${streak}d',
      'flux_target': 'Target: $fluxStreakTargetDays-Day Habit ($streakPct%)',
      'flux_today': hasWorkout
          ? 'Today: $nextWorkoutName'
          : 'No workout planned',
      'flux_start': hasWorkout
          ? 'Start ${nextWorkoutMinutes}m workout'
          : 'Open app',
      'flux_start_uri': nextWorkoutUri ?? 'fitnesstracker:///',
      'flux_shield': streak > 0 && !trainedToday ? 'Streak Shield Active' : '',
      'flux_updated': 'Updated ${_clockTime(now)}',
    });
  }
}

/// Publishes [FluxWidgetData] to the two Kinetic Flux Android widgets.
class FluxWidgetService {
  static const androidWidgetNames = [
    'FluxWidgetProvider',
    'FluxCompactWidgetProvider',
  ];

  final Future<void> Function(String key, Object value) _save;
  final Future<void> Function(String androidName) _refresh;

  FluxWidgetService({
    Future<void> Function(String key, Object value)? save,
    Future<void> Function(String androidName)? refresh,
  }) : _save =
           save ??
           ((key, value) => value is int
               ? HomeWidget.saveWidgetData<int>(key, value)
               : HomeWidget.saveWidgetData<String>(key, value as String)),
       _refresh =
           refresh ?? ((name) => HomeWidget.updateWidget(androidName: name));

  Future<void> publish(FluxWidgetData data) async {
    for (final entry in data.values.entries) {
      await _save(entry.key, entry.value);
    }
    for (final name in androidWidgetNames) {
      await _refresh(name);
    }
  }
}
