import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const themeModePreferenceKey = 'theme_mode';

/// Dark is the default; anything unrecognised falls back to it.
ThemeMode parseThemeMode(String? value) {
  return ThemeMode.values.firstWhere(
    (mode) => mode.name == value,
    orElse: () => ThemeMode.dark,
  );
}

/// Overridden in `main()` with the stored value so the first frame already
/// uses the right theme.
final initialThemeModeProvider = Provider<ThemeMode>((ref) => ThemeMode.dark);

class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ref.watch(initialThemeModeProvider);

  Future<void> setMode(ThemeMode mode) async {
    state = mode;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(themeModePreferenceKey, mode.name);
  }
}

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);
