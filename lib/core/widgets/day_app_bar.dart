import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

const _weekdays = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];

const _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

/// e.g. "Thursday".
String weekdayLabel(DateTime date) => _weekdays[date.weekday - 1];

/// e.g. "24 Sep".
String shortDateLabel(DateTime date) => '${date.day} ${_months[date.month - 1]}';

/// The shared top bar of every main tab: today's weekday over today's date.
class DayAppBar extends StatelessWidget implements PreferredSizeWidget {
  final List<Widget> actions;

  /// Overridable so tests don't depend on the wall clock.
  final DateTime? today;

  const DayAppBar({super.key, this.actions = const [], this.today});

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    final date = today ?? DateTime.now();
    final textTheme = Theme.of(context).textTheme;
    return AppBar(
      toolbarHeight: preferredSize.height,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(weekdayLabel(date), style: textTheme.titleLarge),
          Text(
            shortDateLabel(date),
            style: textTheme.bodySmall?.copyWith(
              color: context.colors.textMuted,
            ),
          ),
        ],
      ),
      actions: actions,
    );
  }
}
