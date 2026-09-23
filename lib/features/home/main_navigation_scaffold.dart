import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.fitness_center_outlined),
            selectedIcon: Icon(Icons.fitness_center),
            label: 'Programs',
          ),
          NavigationDestination(
            icon: Icon(Icons.show_chart_outlined),
            selectedIcon: Icon(Icons.show_chart),
            label: 'Progress',
          ),
          NavigationDestination(
            icon: Icon(Icons.restaurant_outlined),
            selectedIcon: Icon(Icons.restaurant),
            label: 'Nutrition',
          ),
        ],
      ),
    );
  }
}
