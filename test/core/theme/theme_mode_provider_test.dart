import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fitness_tracker/core/theme/theme_mode_provider.dart';
import 'package:fitness_tracker/data/database/app_database.dart';
import 'package:fitness_tracker/features/settings/settings_screen.dart';
import 'package:fitness_tracker/main.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('parseThemeMode', () {
    test('parses stored names and defaults to dark', () {
      expect(parseThemeMode('light'), ThemeMode.light);
      expect(parseThemeMode('system'), ThemeMode.system);
      expect(parseThemeMode('dark'), ThemeMode.dark);
      expect(parseThemeMode(null), ThemeMode.dark);
      expect(parseThemeMode('bogus'), ThemeMode.dark);
    });
  });

  group('themeModeProvider', () {
    test('starts from the initial value and persists changes', () async {
      final container = ProviderContainer(
        overrides: [initialThemeModeProvider.overrideWithValue(ThemeMode.light)],
      );
      addTearDown(container.dispose);

      expect(container.read(themeModeProvider), ThemeMode.light);
      await container.read(themeModeProvider.notifier).setMode(ThemeMode.system);

      expect(container.read(themeModeProvider), ThemeMode.system);
      final preferences = await SharedPreferences.getInstance();
      expect(preferences.getString(themeModePreferenceKey), 'system');
    });
  });

  testWidgets('Settings appearance selector changes the theme mode', (
    tester,
  ) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final container = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(db)],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: SettingsScreen()),
      ),
    );

    expect(container.read(themeModeProvider), ThemeMode.dark);
    await tester.tap(find.text('Light'));
    await tester.pumpAndSettle();
    expect(container.read(themeModeProvider), ThemeMode.light);
  });
}
