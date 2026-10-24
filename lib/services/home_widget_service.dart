import 'package:home_widget/home_widget.dart';

import '../features/home/home_providers.dart';

/// How a day reads in the widget's 7-day strip.
enum WidgetDayState { done, missed, today, upcoming }

/// Everything the launcher widget displays, pre-formatted so the native side
/// only has to put strings into views.
class HomeWidgetData {
  final Map<String, String> values;

  const HomeWidgetData(this.values);

  /// The strip covers Monday to Sunday of the week containing [now], like the
  /// "This week" module on the Home tab. [trainingDays] holds midnight dates.
  factory HomeWidgetData.compute({
    required DateTime now,
    required Set<DateTime> trainingDays,
    required MotivationQuote quote,
  }) {
    final today = DateTime(now.year, now.month, now.day);
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
    return HomeWidgetData({
      'quote_text': '“${quote.quote}”',
      'quote_source': '— ${quote.source}',
      'week_states': states.map((state) => state.name).join(','),
    });
  }
}

/// Publishes [HomeWidgetData] to the quote + week Android launcher widget.
class HomeWidgetService {
  static const androidWidgetName = 'QuoteWeekWidgetProvider';

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
    await _refresh(androidWidgetName);
  }
}
