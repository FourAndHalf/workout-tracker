import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class DailyWorkoutAlarmService {
  static const _activeWorkoutNotificationId = 46;
  static const activeWorkoutSetAction = 'complete_workout_set';
  static Future<void> Function()? _activeWorkoutActionHandler;

  final FlutterLocalNotificationsPlugin _notifications;

  DailyWorkoutAlarmService({FlutterLocalNotificationsPlugin? notifications})
    : _notifications = notifications ?? FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
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

  String _formatClock(DateTime dateTime) {
    final hour = dateTime.hour % 12 == 0 ? 12 : dateTime.hour % 12;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = dateTime.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }
}
