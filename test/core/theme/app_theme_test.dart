import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitness_tracker/core/theme/app_colors.dart';
import 'package:fitness_tracker/core/theme/app_theme.dart';

void main() {
  group('AppTheme', () {
    test('dark and light themes carry their matching palette', () {
      expect(AppTheme.darkTheme.brightness, Brightness.dark);
      expect(AppTheme.lightTheme.brightness, Brightness.light);
      expect(AppTheme.darkTheme.extension<AppColors>(), AppColors.dark);
      expect(AppTheme.lightTheme.extension<AppColors>(), AppColors.light);
    });

    test('uses Pearl Ledger canvas colors for the scaffold', () {
      expect(
        AppTheme.darkTheme.scaffoldBackgroundColor,
        const Color(0xFF0F0F11),
      );
      expect(
        AppTheme.lightTheme.scaffoldBackgroundColor,
        const Color(0xFFE8E8EA),
      );
    });

    test('sets JetBrains Mono everywhere and a charcoal primary', () {
      final theme = AppTheme.lightTheme;
      expect(theme.textTheme.bodyMedium?.fontFamily, AppText.family);
      expect(theme.textTheme.displayLarge?.fontFamily, AppText.family);
      expect(theme.colorScheme.primary, const Color(0xFF2A2A2D));
      expect(theme.colorScheme.onPrimary, Colors.white);
      // The anchor inverts to light on the graphite theme.
      expect(AppTheme.darkTheme.colorScheme.primary, const Color(0xFFECECEE));
    });
  });

  group('AppColors', () {
    test('lerp interpolates between palettes and copyWith overrides', () {
      final mid = AppColors.dark.lerp(AppColors.light, 1);
      expect(mid.background, AppColors.light.background);
      expect(AppColors.dark.copyWith(primary: Colors.red).primary, Colors.red);
    });

    testWidgets('context.colors follows the active theme', (tester) async {
      late AppColors seen;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Builder(
            builder: (context) {
              seen = context.colors;
              return const SizedBox();
            },
          ),
        ),
      );
      expect(seen, AppColors.light);
    });

    testWidgets('context.colors falls back to light without AppTheme', (
      tester,
    ) async {
      late AppColors seen;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              seen = context.colors;
              return const SizedBox();
            },
          ),
        ),
      );
      expect(seen, AppColors.light);
    });
  });
}
