import 'package:fitness_tracker/services/streak_widget_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('saves the streak then refreshes the widget', () async {
    final calls = <String>[];
    final service = StreakWidgetService(
      save: (key, value) async => calls.add('save $key=$value'),
      refresh: (name) async => calls.add('refresh $name'),
    );

    await service.updateStreak(5);

    expect(calls, ['save streak=5', 'refresh FitnessWidgetProvider']);
  });
}
