import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
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
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: navigationShell.currentIndex,
        onTap: (index) {
          navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          );
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home, color: AppColors.primary),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.fitness_center_outlined),
            activeIcon: Icon(Icons.fitness_center, color: AppColors.primary),
            label: 'Programs',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history_outlined),
            activeIcon: Icon(Icons.history, color: AppColors.primary),
            label: 'History',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.show_chart_outlined),
            activeIcon: Icon(Icons.show_chart, color: AppColors.primary),
            label: 'Progress',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.restaurant_outlined),
            activeIcon: Icon(Icons.restaurant, color: AppColors.primary),
            label: 'Nutrition',
          ),
        ],
      ),
    );
  }
}
