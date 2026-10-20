import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/theme/app_theme.dart';
import 'core/theme/theme_mode_provider.dart';
import 'core/widgets/app_logo.dart';
import 'core/widgets/splash_reveal.dart';
import 'data/repositories/backup_repository.dart';
import 'data/repositories/program_repository.dart';
import 'features/onboarding/restore_gate_screen.dart';
import 'features/program/program_providers.dart';
import 'router.dart';

class AppStartupConfig {
  final bool needsRestoreCheck;
  final ThemeMode themeMode;
  final String selectedProgramId;

  const AppStartupConfig({
    required this.needsRestoreCheck,
    required this.themeMode,
    required this.selectedProgramId,
  });
}

Future<AppStartupConfig> loadAppStartupConfig() async {
  try {
    final preferences = await SharedPreferences.getInstance().timeout(
      const Duration(seconds: 3),
    );
    return AppStartupConfig(
      needsRestoreCheck:
          !(preferences.getBool(BackupRepository.firstLaunchRestoreCheckKey) ??
              false),
      themeMode: parseThemeMode(preferences.getString(themeModePreferenceKey)),
      selectedProgramId:
          preferences.getString(selectedProgramPreferenceKey) ??
          ProgramRepository.defaultProgramId,
    );
  } catch (_) {
    // A platform preference failure must not keep Android's native splash up.
    return const AppStartupConfig(
      needsRestoreCheck: false,
      themeMode: ThemeMode.dark,
      selectedProgramId: ProgramRepository.defaultProgramId,
    );
  }
}

class FitnessTrackerApp extends StatefulWidget {
  /// A non-null value keeps the lightweight synchronous path used by tests
  /// and embedded callers. Production passes null to bootstrap after runApp.
  final bool? needsRestoreCheck;

  const FitnessTrackerApp({super.key, this.needsRestoreCheck = false});

  @override
  State<FitnessTrackerApp> createState() => _FitnessTrackerAppState();
}

class _FitnessTrackerAppState extends State<FitnessTrackerApp> {
  late final Future<AppStartupConfig>? _startup =
      widget.needsRestoreCheck == null ? loadAppStartupConfig() : null;

  @override
  Widget build(BuildContext context) {
    if (_startup != null) {
      return FutureBuilder<AppStartupConfig>(
        future: _startup,
        builder: (context, snapshot) {
          final config = snapshot.data;
          if (config == null) return const _StartupLoadingApp();
          return ProviderScope(
            overrides: [
              initialThemeModeProvider.overrideWithValue(config.themeMode),
              initialProgramIdProvider.overrideWithValue(
                config.selectedProgramId,
              ),
            ],
            child: _ConfiguredFitnessTrackerApp(
              needsRestoreCheck: config.needsRestoreCheck,
            ),
          );
        },
      );
    }

    return _ConfiguredFitnessTrackerApp(
      needsRestoreCheck: widget.needsRestoreCheck!,
    );
  }
}

class _StartupLoadingApp extends StatelessWidget {
  const _StartupLoadingApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fitness',
      theme: AppTheme.darkTheme,
      debugShowCheckedModeBanner: false,
      home: const Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppLogo(size: 96),
              SizedBox(height: 24),
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConfiguredFitnessTrackerApp extends ConsumerStatefulWidget {
  final bool needsRestoreCheck;

  const _ConfiguredFitnessTrackerApp({required this.needsRestoreCheck});

  @override
  ConsumerState<_ConfiguredFitnessTrackerApp> createState() =>
      _ConfiguredFitnessTrackerAppState();
}

class _ConfiguredFitnessTrackerAppState
    extends ConsumerState<_ConfiguredFitnessTrackerApp> {
  late bool _needsRestoreCheck = widget.needsRestoreCheck;

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    if (_needsRestoreCheck) {
      return MaterialApp(
        title: 'Fitness',
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
      title: 'Fitness',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
      builder: (context, child) => SplashReveal(child: child!),
    );
  }
}
