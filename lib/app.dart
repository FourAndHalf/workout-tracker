import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_mode_provider.dart';
import 'features/onboarding/restore_gate_screen.dart';
import 'router.dart';

class FitnessTrackerApp extends ConsumerStatefulWidget {
  final bool needsRestoreCheck;

  const FitnessTrackerApp({super.key, this.needsRestoreCheck = false});

  @override
  ConsumerState<FitnessTrackerApp> createState() => _FitnessTrackerAppState();
}

class _FitnessTrackerAppState extends ConsumerState<FitnessTrackerApp> {
  late bool _needsRestoreCheck = widget.needsRestoreCheck;

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    if (_needsRestoreCheck) {
      return MaterialApp(
        title: 'Fitness Tracker',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: themeMode,
        debugShowCheckedModeBanner: false,
        home: RestoreGateScreen(
          onDone: () => setState(() => _needsRestoreCheck = false),
        ),
      );
    }

    return MaterialApp.router(
      title: 'Fitness Tracker',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
    );
  }
}
