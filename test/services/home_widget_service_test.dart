import 'package:fitness_tracker/features/home/home_providers.dart';
import 'package:fitness_tracker/services/home_widget_service.dart';
import 'package:flutter_test/flutter_test.dart';

const _quote = MotivationQuote(quote: 'Keep going.', source: 'Someone');

void main() {
  group('HomeWidgetData.compute', () {
    test('formats the quote and its source', () {
      final data = HomeWidgetData.compute(
        now: DateTime(2026, 10, 24),
        trainingDays: const {},
        quote: _quote,
      ).values;
      expect(data['quote_text'], '“Keep going.”');
      expect(data['quote_source'], '— Someone');
    });

    test('marks Monday-Sunday as done, missed, today and upcoming', () {
      // Thursday 2026-10-22: Mon + Wed trained, Tue missed, Thu not yet.
      final data = HomeWidgetData.compute(
        now: DateTime(2026, 10, 22, 9),
        trainingDays: {DateTime(2026, 10, 19), DateTime(2026, 10, 21)},
        quote: _quote,
      ).values;
      expect(
        data['week_states'],
        'done,missed,done,today,upcoming,upcoming,upcoming',
      );
    });

    test('today counts as done once trained', () {
      final data = HomeWidgetData.compute(
        now: DateTime(2026, 10, 25), // Sunday
        trainingDays: {DateTime(2026, 10, 25)},
        quote: _quote,
      ).values;
      expect(
        data['week_states'],
        'missed,missed,missed,missed,missed,missed,done',
      );
    });
  });

  test(
    'HomeWidgetService saves each value then refreshes the widget',
    () async {
      final calls = <String>[];
      final service = HomeWidgetService(
        save: (key, value) async => calls.add('save $key=$value'),
        refresh: (name) async => calls.add('refresh $name'),
      );

      await service.publish(const HomeWidgetData({'quote_text': 'a'}));

      expect(calls, ['save quote_text=a', 'refresh QuoteWeekWidgetProvider']);
    },
  );
}
