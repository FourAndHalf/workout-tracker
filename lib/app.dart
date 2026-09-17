import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'features/onboarding/restore_gate_screen.dart';
import 'router.dart';

class FitnessTrackerApp extends StatefulWidget {
  final bool needsRestoreCheck;

  const FitnessTrackerApp({super.key, this.needsRestoreCheck = false});

  @override
  State<FitnessTrackerApp> createState() => _FitnessTrackerAppState();
}

class _FitnessTrackerAppState extends State<FitnessTrackerApp> {
  late bool _needsRestoreCheck = widget.needsRestoreCheck;

  @override
  Widget build(BuildContext context) {
    if (_needsRestoreCheck) {
      return MaterialApp(
        title: 'Fitness Tracker',
        theme: AppTheme.darkTheme,
        debugShowCheckedModeBanner: false,
        home: RestoreGateScreen(
          onDone: () => setState(() => _needsRestoreCheck = false),
        ),
      );
    }

    return MaterialApp.router(
      title: 'Fitness Tracker',
      theme: AppTheme.darkTheme,
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
    );
  }
}
