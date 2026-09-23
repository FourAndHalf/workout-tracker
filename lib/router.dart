import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'features/home/home_screen.dart';
import 'features/home/main_navigation_scaffold.dart';
import 'features/program/program_list_screen.dart';
import 'features/program/day_detail_screen.dart';
import 'features/history/session_detail_screen.dart';
import 'features/progress/progress_hub_screen.dart';
import 'features/nutrition/nutrition_screen.dart';
import 'features/settings/settings_screen.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return MainNavigationScaffold(
          navigationShell: navigationShell,
          currentLocation: state.uri.toString(),
        );
      },
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => const HomeScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/programs',
              builder: (context, state) => const ProgramListScreen(),
              routes: [
                GoRoute(
                  path: ':programId/:dayId',
                  builder: (context, state) {
                    final programId = state.pathParameters['programId']!;
                    final dayId = state.pathParameters['dayId']!;
                    return DayDetailScreen(programId: programId, dayId: dayId);
                  },
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/progress',
              builder: (context, state) => const ProgressHubScreen(),
            ),
            // History lives under the Progress tab; the URL is unchanged.
            GoRoute(
              path: '/history/:sessionId',
              builder: (context, state) {
                final sessionId = int.parse(state.pathParameters['sessionId']!);
                return SessionDetailScreen(sessionId: sessionId);
              },
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/nutrition',
              builder: (context, state) => const NutritionScreen(),
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
  ],
);
