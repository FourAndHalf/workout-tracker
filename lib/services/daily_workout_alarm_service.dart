import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class DailyWorkoutAlarmSettings {
  final bool enabled;
  final TimeOfDay time;

  const DailyWorkoutAlarmSettings({
    this.enabled = false,
    this.time = const TimeOfDay(hour: 18, minute: 0),
  });

  DailyWorkoutAlarmSettings copyWith({bool? enabled, TimeOfDay? time}) {
    return DailyWorkoutAlarmSettings(
      enabled: enabled ?? this.enabled,
      time: time ?? this.time,
    );
  }
}

class DailyWorkoutAlarmService {
  static const _notificationId = 45;
  static const _enabledKey = 'daily_workout_alarm_enabled';
  static const _hourKey = 'daily_workout_alarm_hour';
  static const _minuteKey = 'daily_workout_alarm_minute';

  final FlutterLocalNotificationsPlugin _notifications;
  SharedPreferences? _preferences;

  DailyWorkoutAlarmService({FlutterLocalNotificationsPlugin? notifications})
      : _notifications = notifications ?? FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));
    await _notifications.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@drawable/ic_launcher_brand'),
      ),
    );
    _preferences ??= await SharedPreferences.getInstance();
  }

  Future<DailyWorkoutAlarmSettings> loadSettings() async {
    _preferences ??= await SharedPreferences.getInstance();
    return DailyWorkoutAlarmSettings(
      enabled: _preferences!.getBool(_enabledKey) ?? false,
      time: TimeOfDay(
        hour: _preferences!.getInt(_hourKey) ?? 18,
        minute: _preferences!.getInt(_minuteKey) ?? 0,
      ),
    );
  }

  Future<void> update(DailyWorkoutAlarmSettings settings) async {
    await initialize();
    await _preferences!.setBool(_enabledKey, settings.enabled);
    await _preferences!.setInt(_hourKey, settings.time.hour);
    await _preferences!.setInt(_minuteKey, settings.time.minute);

    if (!settings.enabled) {
      await _notifications.cancel(_notificationId);
      return;
    }

    final android = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.requestNotificationsPermission();

    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      settings.time.hour,
      settings.time.minute,
    );
    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    await _notifications.zonedSchedule(
      _notificationId,
      'Workout time',
      'Your 45-minute workout plan is ready.',
      scheduled,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_workout',
          'Daily workout',
          channelDescription: 'Daily workout reminders',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }
}
