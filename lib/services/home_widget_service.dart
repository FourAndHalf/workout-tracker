import 'package:home_widget/home_widget.dart';

import '../features/home/home_providers.dart';

/// How a day reads in the widget's 7-day strip.
enum WidgetDayState { done, missed, today, upcoming }

/// Days of content published ahead, so the widget can roll over at midnight
/// without the app running.
const homeWidgetDaysAhead = 7;

String _isoDate(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';

/// Everything the launcher widget displays, pre-formatted so the native side
/// only has to put strings into views. It holds one entry per day
/// (`day0_` = today ... `day6_`), each keyed by its date; the widget picks
/// the entry matching the current date.
class HomeWidgetData {
  final Map<String, String> values;

  const HomeWidgetData(this.values);

  /// The strip covers Monday to Sunday of the week containing each day, like
  /// the "This week" module on the Home tab. [trainingDays] holds midnight
  /// dates; days after [now] are assumed untrained until the app republishes.
  factory HomeWidgetData.compute({
    required DateTime now,
    required Set<DateTime> trainingDays,
    required MotivationQuote Function(DateTime date) quoteFor,
  }) {
    final values = <String, String>{};
    for (var offset = 0; offset < homeWidgetDaysAhead; offset++) {
      final today = DateTime(now.year, now.month, now.day + offset);
      final monday = today.subtract(Duration(days: today.weekday - 1));
      final states = <WidgetDayState>[];
      for (var i = 0; i < 7; i++) {
        final day = DateTime(monday.year, monday.month, monday.day + i);
        states.add(
          day.isAfter(today)
              ? WidgetDayState.upcoming
              : trainingDays.contains(day)
              ? WidgetDayState.done
              : day == today
              ? WidgetDayState.today
              : WidgetDayState.missed,
        );
      }
      final quote = quoteFor(today);
      values['day${offset}_date'] = _isoDate(today);
      values['day${offset}_quote'] = '“${quote.quote}”';
      values['day${offset}_source'] = '— ${quote.source}';
      values['day${offset}_states'] = states.map((s) => s.name).join(',');
    }
    return HomeWidgetData(values);
  }
}

/// Publishes [HomeWidgetData] to the quote + week and quote-only widgets.
class HomeWidgetService {
  static const androidWidgetNames = [
    'QuoteWeekWidgetProvider',
    'QuoteWidgetProvider',
  ];

  final Future<void> Function(String key, String value) _save;
  final Future<void> Function(String androidName) _refresh;

  HomeWidgetService({
    Future<void> Function(String key, String value)? save,
    Future<void> Function(String androidName)? refresh,
  }) : _save = save ?? ((k, v) => HomeWidget.saveWidgetData<String>(k, v)),
       _refresh =
           refresh ?? ((name) => HomeWidget.updateWidget(androidName: name));

  Future<void> publish(HomeWidgetData data) async {
    for (final entry in data.values.entries) {
      await _save(entry.key, entry.value);
    }
    for (final name in androidWidgetNames) {
      await _refresh(name);
    }
  }
}
