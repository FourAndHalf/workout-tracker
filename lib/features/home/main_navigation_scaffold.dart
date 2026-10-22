import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons_400.dart';
import 'package:lucide_icons_flutter/lucide_icons_600.dart';

import '../workout/widgets/active_workout_banner.dart';

class MainNavigationScaffold extends StatelessWidget {
  final StatefulNavigationShell navigationShell;
  final String currentLocation;

  const MainNavigationScaffold({
    super.key,
    required this.navigationShell,
    required this.currentLocation,
  });

  /// The dayId of the day-detail page at the current route, if any. Derived
  /// straight from the URL rather than widget lifecycle, since branches in
  /// a [StatefulShellRoute.indexedStack] stay mounted (never disposed) when
  /// switching tabs, so a day-detail page can't reliably signal "I'm no
  /// longer visible" from its own initState/dispose.
  String? get _visibleDayId {
    final segments = Uri.parse(currentLocation).pathSegments;
    if (segments.length >= 3 && segments[0] == 'programs') {
      return segments[2];
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Home shows its own "Go back to workout" card instead.
          if (navigationShell.currentIndex != 0)
            ActiveWorkoutBanner(visibleDayId: _visibleDayId),
          Expanded(child: navigationShell),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) {
          navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          );
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(LucideIcons400.house),
            selectedIcon: Icon(LucideIcons600.house),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(LucideIcons400.calendarDays),
            selectedIcon: Icon(LucideIcons600.calendarDays),
            label: 'Programs',
          ),
          NavigationDestination(
            icon: Icon(LucideIcons400.chartLine),
            selectedIcon: Icon(LucideIcons600.chartLine),
            label: 'Progress',
          ),
          NavigationDestination(
            icon: Icon(LucideIcons400.utensils),
            selectedIcon: Icon(LucideIcons600.utensils),
            label: 'Nutrition',
          ),
        ],
      ),
    );
  }
}
