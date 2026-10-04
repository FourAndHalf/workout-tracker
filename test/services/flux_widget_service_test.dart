import 'package:fitness_tracker/data/database/app_database.dart';
import 'package:fitness_tracker/data/models/program_model.dart';
import 'package:fitness_tracker/services/flux_widget_service.dart';
import 'package:flutter_test/flutter_test.dart';

WorkoutSession _session(DateTime start, int minutes) => WorkoutSession(
  id: start.millisecondsSinceEpoch,
  programId: 'p',
  weekId: 'w1',
  dayId: 'd1',
  dayName: 'Arms',
  startedAt: start,
  finishedAt: start.add(Duration(minutes: minutes)),
);

FluxWidgetData _compute({
  int consumed = 1840,
  int burn = 2400,
  List<WorkoutSession> sessions = const [],
  int streak = 18,
  bool trainedToday = false,
  String? next = 'Arms',
}) => FluxWidgetData.compute(
  now: DateTime(2026, 10, 4, 14, 5),
  consumedKcal: consumed,
  dailyBurnKcal: burn,
  completedSessions: sessions,
  streak: streak,
  trainedToday: trainedToday,
  nextWorkoutName: next,
  nextWorkoutMinutes: 52,
  nextWorkoutUri: next == null ? null : 'fitnesstracker:///programs/p/d1',
);

void main() {
  group('FluxWidgetData.compute', () {
    test('shows a deficit from today\'s burn and workout minutes', () {
      // 2400 base + 40 min * 7 = 2680 burned; 1840 - 2680 = -840.
      final data = _compute(sessions: [_session(DateTime(2026, 10, 4, 7), 40)])
          .values;

      expect(data['flux_net'], '-840');
      expect(data['flux_net_label'], 'Deficit Mode');
      expect(data['flux_compact_label'], 'KCAL DEFICIT');
      expect(data['flux_burned'], '2,680');
      expect(data['flux_consumed'], '1,840');
      expect(data['flux_burned_pct'], 100);
      expect(data['flux_consumed_pct'], 69);
      expect(data['flux_compact_sub'], '2.68k out · 1.84k planned');
    });

    test('ignores workouts from other days', () {
      final data = _compute(sessions: [_session(DateTime(2026, 10, 3, 7), 60)])
          .values;

      expect(data['flux_burned'], '2,400');
    });

    test('shows a surplus with a plus sign', () {
      final data = _compute(consumed: 2700).values;

      expect(data['flux_net'], '+300');
      expect(data['flux_net_label'], 'Surplus Mode');
      expect(data['flux_compact_pct'], 100);
    });

    test('derives streak labels and the 21-day target', () {
      final data = _compute().values;

      expect(data['flux_status'], 'ON TRACK');
      expect(data['flux_streak_day'], 'Day 18');
      expect(data['flux_streak_chip'], '18D');
      expect(data['flux_streak_short'], '18d');
      expect(data['flux_target'], 'Target: 21-Day Habit (86%)');
      expect(data['flux_shield'], 'Streak Shield Active');
    });

    test('hides the shield once today is trained or there is no streak', () {
      expect(_compute(trainedToday: true).values['flux_shield'], '');
      final fresh = _compute(streak: 0).values;
      expect(fresh['flux_shield'], '');
      expect(fresh['flux_status'], 'GET STARTED');
    });

    test('caps the habit progress at 100%', () {
      expect(
        _compute(streak: 30).values['flux_target'],
        'Target: 21-Day Habit (100%)',
      );
    });

    test('points the start button at the next workout', () {
      final data = _compute().values;

      expect(data['flux_today'], 'Today: Arms');
      expect(data['flux_start'], 'Start 52m workout');
      expect(data['flux_start_uri'], 'fitnesstracker:///programs/p/d1');
      expect(data['flux_updated'], 'Updated 2:05 PM');
    });

    test('falls back to opening the app with no workout', () {
      final data = _compute(next: null).values;

      expect(data['flux_start'], 'Open app');
      expect(data['flux_start_uri'], 'fitnesstracker:///');
    });
  });

  test('estimateWorkoutMinutes counts timed exercises by duration', () {
    ExerciseModel timed(int seconds) => ExerciseModel(
      id: 't$seconds',
      order: 1,
      name: 'Hold',
      targetSets: 1,
      repScheme: [seconds],
      logMode: 'time',
    );
    final day = DayModel(
      id: 'd',
      name: 'Day',
      order: 1,
      blocks: [
        BlockModel(
          id: 'b',
          name: 'B',
          type: 'straight',
          targetSets: 1,
          exercises: [
            timed(60),
            timed(60),
            ExerciseModel(
              id: 'lift',
              order: 3,
              name: 'Curl',
              targetSets: 4,
              logMode: 'weightReps',
            ),
          ],
        ),
      ],
    );

    // 2 min of holds + 4 sets * 2.5 min = 12.
    expect(estimateWorkoutMinutes(day), 12);
  });

  test('publish saves every value then refreshes both widgets', () async {
    final calls = <String>[];
    final service = FluxWidgetService(
      save: (key, value) async => calls.add('save $key=$value'),
      refresh: (name) async => calls.add('refresh $name'),
    );

    await service.publish(
      const FluxWidgetData({'flux_net': '-5', 'flux_x': 3}),
    );

    expect(calls, [
      'save flux_net=-5',
      'save flux_x=3',
      'refresh FluxWidgetProvider',
      'refresh FluxCompactWidgetProvider',
    ]);
  });
}
