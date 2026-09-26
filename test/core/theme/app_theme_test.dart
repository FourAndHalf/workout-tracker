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

    test('uses Kinetic Obsidian canvas colors for the scaffold', () {
      expect(
        AppTheme.darkTheme.scaffoldBackgroundColor,
        const Color(0xFF0F1218),
      );
      expect(
        AppTheme.lightTheme.scaffoldBackgroundColor,
        const Color(0xFFF3F5F8),
      );
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

    testWidgets('context.colors falls back to dark without AppTheme', (
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
      expect(seen, AppColors.dark);
    });
  });
}
