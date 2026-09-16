import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class DailyWorkoutAlarmSettings {
  final bool enabled;
  final TimeOfDay time;
  final String tuneId;

  const DailyWorkoutAlarmSettings({
    this.enabled = false,
    this.time = const TimeOfDay(hour: 18, minute: 0),
    this.tuneId = 'morning_energy',
  });

  DailyWorkoutAlarmSettings copyWith({
    bool? enabled,
    TimeOfDay? time,
    String? tuneId,
  }) {
    return DailyWorkoutAlarmSettings(
      enabled: enabled ?? this.enabled,
      time: time ?? this.time,
      tuneId: tuneId ?? this.tuneId,
    );
  }
}

class WorkoutAlarmTune {
  final String id;
  final String title;
  final String artist;
  final String spotifyUrl;

  const WorkoutAlarmTune({
    required this.id,
    required this.title,
    required this.artist,
    required this.spotifyUrl,
  });
}

const workoutAlarmTunes = [
  WorkoutAlarmTune(
    id: 'morning_energy',
    title: 'Morning Energy',
    artist: 'Spotify workout mix',
    spotifyUrl: 'https://open.spotify.com/playlist/37i9dQZF1DX76Wlfdnj7AP',
  ),
  WorkoutAlarmTune(
    id: 'beast_mode',
    title: 'Beast Mode',
    artist: 'Spotify workout mix',
    spotifyUrl: 'https://open.spotify.com/playlist/37i9dQZF1DX70RN3TfijkP',
  ),
  WorkoutAlarmTune(
    id: 'focus_flow',
    title: 'Focus Flow',
    artist: 'Spotify instrumental mix',
    spotifyUrl: 'https://open.spotify.com/playlist/37i9dQZF1DWZeKCadgRdKQ',
  ),
];

class DailyWorkoutAlarmService {
  static const _notificationId = 45;
  static const _activeWorkoutNotificationId = 46;
  static const activeWorkoutSetAction = 'complete_workout_set';
  static Future<void> Function()? _activeWorkoutActionHandler;
  static const _enabledKey = 'daily_workout_alarm_enabled';
  static const _hourKey = 'daily_workout_alarm_hour';
  static const _minuteKey = 'daily_workout_alarm_minute';
  static const _tuneKey = 'daily_workout_alarm_tune';

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
      onDidReceiveNotificationResponse: (response) async {
        if (response.actionId == activeWorkoutSetAction) {
          await _activeWorkoutActionHandler?.call();
        }
      },
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
      tuneId: _preferences!.getString(_tuneKey) ?? 'morning_energy',
    );
  }

  Future<void> update(DailyWorkoutAlarmSettings settings) async {
    await initialize();
    await _preferences!.setBool(_enabledKey, settings.enabled);
    await _preferences!.setInt(_hourKey, settings.time.hour);
    await _preferences!.setInt(_minuteKey, settings.time.minute);
    await _preferences!.setString(_tuneKey, settings.tuneId);

    if (!settings.enabled) {
      await _notifications.cancel(_notificationId);
      return;
    }

    final android = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
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
      'Your 45-minute workout plan is ready. Tune: ${_tuneName(settings.tuneId)}.',
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

  Future<void> startWorkoutTimer(
    DateTime startedAt, {
    required String workoutName,
    required DateTime targetEndAt,
    required String currentSet,
    required String nextExercise,
  }) async {
    await updateWorkoutTimer(
      startedAt,
      workoutName: workoutName,
      targetEndAt: targetEndAt,
      currentSet: currentSet,
      nextExercise: nextExercise,
    );
  }

  Future<void> updateWorkoutTimer(
    DateTime startedAt, {
    required String workoutName,
    required DateTime targetEndAt,
    required String currentSet,
    required String nextExercise,
  }) async {
    try {
      await initialize();
      await _notifications.show(
        _activeWorkoutNotificationId,
        workoutName,
        'Target ${_formatClock(targetEndAt)}  •  $currentSet  •  Next: $nextExercise',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'active_workout',
            'Active workout',
            channelDescription: 'Live workout timer',
            importance: Importance.low,
            priority: Priority.low,
            ongoing: true,
            autoCancel: false,
            onlyAlertOnce: true,
            showWhen: true,
            usesChronometer: true,
            chronometerCountDown: false,
            visibility: NotificationVisibility.public,
            category: AndroidNotificationCategory.progress,
            actions: [
              AndroidNotificationAction(
                activeWorkoutSetAction,
                'Complete set',
                cancelNotification: false,
              ),
            ],
          ),
        ),
        payload: startedAt.millisecondsSinceEpoch.toString(),
      );
    } catch (_) {
      // Notification support can be unavailable in tests or restricted devices.
    }
  }

  void setActiveWorkoutActionHandler(Future<void> Function()? handler) {
    _activeWorkoutActionHandler = handler;
  }

  Future<void> stopWorkoutTimer() async {
    try {
      await initialize();
      await _notifications.cancel(_activeWorkoutNotificationId);
    } catch (_) {
      // There is nothing to cancel when notification support is unavailable.
    }
  }

  String _tuneName(String id) => workoutAlarmTunes
      .firstWhere(
        (tune) => tune.id == id,
        orElse: () => workoutAlarmTunes.first,
      )
      .title;

  String _formatClock(DateTime dateTime) {
    final hour = dateTime.hour % 12 == 0 ? 12 : dateTime.hour % 12;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = dateTime.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }
}
