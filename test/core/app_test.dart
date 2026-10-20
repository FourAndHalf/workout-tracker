import 'package:fitness_tracker/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test(
    'loads persisted startup settings without blocking app startup',
    () async {
      SharedPreferences.setMockInitialValues({
        'backup_first_launch_restore_check_done': true,
        'theme_mode': 'light',
        'selected_program_id': 'mobility-10min',
      });

      final config = await loadAppStartupConfig();

      expect(config.needsRestoreCheck, isFalse);
      expect(config.themeMode, ThemeMode.light);
      expect(config.selectedProgramId, 'mobility-10min');
    },
  );
}
