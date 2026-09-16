import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/theme/app_colors.dart';
import '../../main.dart';
import '../../services/daily_workout_alarm_service.dart';
import '../home/home_providers.dart';
import '../nutrition/nutrition_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  DailyWorkoutAlarmSettings _alarm = const DailyWorkoutAlarmSettings();
  bool _loadingAlarm = true;
  bool _shoppingListEnabled = true;
  bool _loadingNutritionSettings = true;

  @override
  void initState() {
    super.initState();
    _loadAlarm();
    _loadNutritionSettings();
  }

  Future<void> _loadNutritionSettings() async {
    final preferences = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _shoppingListEnabled =
            preferences.getBool(shoppingListEnabledKey) ?? true;
        _loadingNutritionSettings = false;
      });
    }
  }

  Future<void> _toggleShoppingList(bool enabled) async {
    setState(() => _shoppingListEnabled = enabled);
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(shoppingListEnabledKey, enabled);
    ref.invalidate(shoppingListEnabledProvider);
  }

  Future<void> _loadAlarm() async {
    final alarm = await ref
        .read(dailyWorkoutAlarmServiceProvider)
        .loadSettings();
    if (mounted) {
      setState(() {
        _alarm = alarm;
        _loadingAlarm = false;
      });
    }
  }

  Future<void> _updateAlarm(DailyWorkoutAlarmSettings next) async {
    setState(() => _alarm = next);
    await ref.read(dailyWorkoutAlarmServiceProvider).update(next);
  }

  Future<void> _pickAlarmTime() async {
    final time = await showTimePicker(context: context, initialTime: _alarm.time);
    if (time != null) {
      await _updateAlarm(_alarm.copyWith(time: time, enabled: true));
    }
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final period = await showDialog<Duration>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('How much data should be deleted?'),
        content: const Text(
          'Choose how far back to remove workout and nutrition history. Meal plans and your workout program stay available.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          for (final option in const <MapEntry<String, Duration>>[
            MapEntry('Last 1 hour', Duration(hours: 1)),
            MapEntry('Last 1 day', Duration(days: 1)),
            MapEntry('Last 2 days', Duration(days: 2)),
            MapEntry('Last 1 week', Duration(days: 7)),
          ])
            TextButton(
              onPressed: () => Navigator.pop(context, option.value),
              child: Text(option.key),
            ),
        ],
      ),
    );
    if (period == null || !context.mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm deletion'),
        content: Text(
          'Delete data from the last ${_periodLabel(period)}? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete data'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final since = DateTime.now().subtract(period);
    await ref.read(nutritionRepositoryProvider).clearUserDataSince(since);
    ref.invalidate(dashboardAnalyticsProvider);
    ref.invalidate(todayFoodPhotosProvider);
    ref.invalidate(todaySupplementStatusProvider);
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Saved user data deleted')));
    }
  }

  String _periodLabel(Duration duration) {
    if (duration.inHours == 1) return '1 hour';
    if (duration.inDays == 1) return '1 day';
    if (duration.inDays == 2) return '2 days';
    return '1 week';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Data',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                SwitchListTile.adaptive(
                  secondary: const Icon(Icons.alarm_outlined),
                  title: const Text('Daily workout alarm'),
                  subtitle: Text(
                    _loadingAlarm
                        ? 'Loading alarm settings'
                        : _alarm.enabled
                            ? 'Every day at ${_alarm.time.format(context)}'
                            : 'Alarm is off',
                  ),
                  value: _alarm.enabled,
                  onChanged: _loadingAlarm
                      ? null
                      : (enabled) =>
                            _updateAlarm(_alarm.copyWith(enabled: enabled)),
                ),
                ListTile(
                  leading: const Icon(Icons.schedule_outlined),
                  title: const Text('Workout time'),
                  subtitle: Text(_alarm.time.format(context)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _loadingAlarm ? null : _pickAlarmTime,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Nutrition',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Card(
            child: SwitchListTile.adaptive(
              secondary: const Icon(Icons.shopping_cart_outlined),
              title: const Text('Weekly shopping list'),
              subtitle: const Text('Show the shopping list tab in Nutrition'),
              value: _shoppingListEnabled,
              onChanged: _loadingNutritionSettings
                  ? null
                  : _toggleShoppingList,
            ),
          ),
          const SizedBox(height: 24),
          Card(
            child: ListTile(
              leading: const Icon(Icons.delete_outline, color: AppColors.error),
              title: const Text('Delete saved data'),
              subtitle: const Text('Clear workout and nutrition history'),
              onTap: () => _confirmDelete(context),
            ),
          ),
        ],
      ),
    );
  }
}
