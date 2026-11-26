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
String shortDateLabel(DateTime date) =>
    '${date.day} ${_months[date.month - 1]}';

/// The shared top bar of the main tabs: today's date as a small muted line
/// above the large page [title], actions on the right.
class DayAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget> actions;

  /// Overridable so tests don't depend on the wall clock.
  final DateTime? today;

  const DayAppBar({
    super.key,
    required this.title,
    this.actions = const [],
    this.today,
  });

  @override
  Size get preferredSize => const Size.fromHeight(88);

  @override
  Widget build(BuildContext context) {
    final date = today ?? DateTime.now();
    final textTheme = Theme.of(context).textTheme;
    return AppBar(
      toolbarHeight: preferredSize.height,
      titleSpacing: 16,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${weekdayLabel(date)}, ${shortDateLabel(date)}',
            style: textTheme.labelMedium?.copyWith(
              color: context.colors.textMuted,
            ),
          ),
          const SizedBox(height: 2),
          Text(title, style: textTheme.headlineMedium),
        ],
      ),
      actions: [
        for (final action in actions)
          Padding(padding: const EdgeInsets.only(left: 8), child: action),
        const SizedBox(width: 16),
      ],
    );
  }
}
