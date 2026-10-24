import 'package:fitness_tracker/features/home/home_providers.dart';
import 'package:fitness_tracker/services/home_widget_service.dart';
import 'package:flutter_test/flutter_test.dart';

MotivationQuote _quoteFor(DateTime date) =>
    MotivationQuote(quote: 'Day ${date.day}.', source: 'Someone');

void main() {
  group('HomeWidgetData.compute', () {
    test('publishes a dated quote for each of the next 7 days', () {
      final data = HomeWidgetData.compute(
        now: DateTime(2026, 10, 24, 15),
        trainingDays: const {},
        quoteFor: _quoteFor,
      ).values;
      expect(data['day0_date'], '2026-10-24');
      expect(data['day0_quote'], '“Day 24.”');
      expect(data['day0_source'], '— Someone');
      expect(data['day1_date'], '2026-10-25');
      expect(data['day1_quote'], '“Day 25.”');
      expect(data['day6_date'], '2026-10-30');
    });

    test('marks Monday-Sunday as done, missed, today and upcoming', () {
      // Thursday 2026-10-22: Mon + Wed trained, Tue missed, Thu not yet.
      final data = HomeWidgetData.compute(
        now: DateTime(2026, 10, 22, 9),
        trainingDays: {DateTime(2026, 10, 19), DateTime(2026, 10, 21)},
        quoteFor: _quoteFor,
      ).values;
      expect(
        data['day0_states'],
        'done,missed,done,today,upcoming,upcoming,upcoming',
      );
    });

    test('today counts as done once trained', () {
      final data = HomeWidgetData.compute(
        now: DateTime(2026, 10, 25), // Sunday
        trainingDays: {DateTime(2026, 10, 25)},
        quoteFor: _quoteFor,
      ).values;
      expect(
        data['day0_states'],
        'missed,missed,missed,missed,missed,missed,done',
      );
    });

    test('later days roll over: an untrained today becomes missed', () {
      // Sunday 2026-10-25 untrained; by Monday the new week starts fresh.
      final data = HomeWidgetData.compute(
        now: DateTime(2026, 10, 25),
        trainingDays: const {},
        quoteFor: _quoteFor,
      ).values;
      expect(
        data['day0_states'],
        'missed,missed,missed,missed,missed,missed,today',
      );
      expect(
        data['day1_states'],
        'today,upcoming,upcoming,upcoming,upcoming,upcoming,upcoming',
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

      await service.publish(const HomeWidgetData({'day0_date': 'a'}));

      expect(calls, ['save day0_date=a', 'refresh QuoteWeekWidgetProvider']);
    },
  );
}
