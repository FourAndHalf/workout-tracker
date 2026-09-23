import 'package:home_widget/home_widget.dart';

/// Publishes the current workout streak to the Android launcher widget.
class StreakWidgetService {
  static const streakKey = 'streak';
  static const androidWidgetName = 'FitnessWidgetProvider';

  final Future<void> Function(String key, int value) _save;
  final Future<void> Function(String androidName) _refresh;

  StreakWidgetService({
    Future<void> Function(String key, int value)? save,
    Future<void> Function(String androidName)? refresh,
  }) : _save = save ?? ((k, v) => HomeWidget.saveWidgetData<int>(k, v)),
       _refresh =
           refresh ?? ((name) => HomeWidget.updateWidget(androidName: name));

  Future<void> updateStreak(int streak) async {
    await _save(streakKey, streak);
    await _refresh(androidWidgetName);
  }
}
