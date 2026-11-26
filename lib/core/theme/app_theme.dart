import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Corner radii from design/DESIGN.md ("Shapes").
abstract final class AppRadius {
  static const sm = 8.0; // chips, badges
  static const md = 14.0; // inputs, list groups, tooltips
  static const lg = 20.0; // standard cards, nested panels
  static const xl = 28.0; // hero module, sheets
}

/// Quiet depth: light modules sit on a hairline with one wide, faint shadow;
/// dark modules use the hairline alone.
abstract final class AppShadows {
  static List<BoxShadow> module(Brightness brightness) =>
      brightness == Brightness.dark
      ? const []
      : const [
          BoxShadow(
            color: Color(0x08151515),
            blurRadius: 1,
            offset: Offset(0, 1),
          ),
          BoxShadow(
            color: Color(0x0A151515),
            blurRadius: 32,
            offset: Offset(0, 12),
          ),
        ];

  static List<BoxShadow> raised(Brightness brightness) =>
      brightness == Brightness.dark
      ? const []
      : const [
          BoxShadow(
            color: Color(0x0D151515),
            blurRadius: 3,
            offset: Offset(0, 1),
          ),
        ];
}

/// Type roles that don't map onto a Material text style. Text is set in
/// Geist ([family]); figures (weights, reps, times, paces) in JetBrains Mono
/// ([mono]) so columns of numbers line up. Colors are left unset so they
/// inherit from the surrounding theme.
abstract final class AppText {
  static const family = 'Geist';
  static const mono = 'JetBrains Mono';
  static const _tabular = [FontFeature.tabularFigures()];

  static const metricHero = TextStyle(
    fontFamily: mono,
    fontSize: 32,
    height: 38 / 32,
    fontWeight: FontWeight.w500,
    letterSpacing: -1.44,
    fontFeatures: _tabular,
  );
  static const metricCard = TextStyle(
    fontFamily: mono,
    fontSize: 18,
    height: 24 / 18,
    fontWeight: FontWeight.w500,
    letterSpacing: -0.54,
    fontFeatures: _tabular,
  );
  static const metricTable = TextStyle(
    fontFamily: mono,
    fontSize: 13,
    height: 18 / 13,
    fontWeight: FontWeight.w500,
    letterSpacing: -0.13,
    fontFeatures: _tabular,
  );
  static const metricDelta = TextStyle(
    fontFamily: mono,
    fontSize: 10,
    height: 12 / 10,
    fontWeight: FontWeight.w600,
    fontFeatures: _tabular,
  );
  static const labelUppercase = TextStyle(
    fontFamily: family,
    fontSize: 10,
    height: 12 / 10,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.9,
  );
}

class AppTheme {
  static ThemeData get darkTheme => _build(Brightness.dark, AppColors.dark);
  static ThemeData get lightTheme => _build(Brightness.light, AppColors.light);

  static ThemeData _build(Brightness brightness, AppColors c) {
    const pill = StadiumBorder();
    final base = ThemeData(
      brightness: brightness,
      useMaterial3: true,
      fontFamily: AppText.family,
    );
    final textTheme = base.textTheme
        .copyWith(
          displayLarge: const TextStyle(
            fontSize: 40,
            height: 44 / 40,
            fontWeight: FontWeight.w600,
            letterSpacing: -1.6,
          ),
          displayMedium: const TextStyle(
            fontSize: 34,
            height: 40 / 34,
            fontWeight: FontWeight.w600,
            letterSpacing: -1.2,
          ),
          headlineMedium: const TextStyle(
            fontSize: 30,
            height: 36 / 30,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.9,
          ),
          headlineSmall: const TextStyle(
            fontSize: 24,
            height: 30 / 24,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.6,
          ),
          titleLarge: const TextStyle(
            fontSize: 19,
            height: 24 / 19,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.4,
          ),
          titleMedium: const TextStyle(
            fontSize: 16,
            height: 22 / 16,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.2,
          ),
          titleSmall: const TextStyle(
            fontSize: 14,
            height: 20 / 14,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.1,
          ),
          bodyLarge: const TextStyle(fontSize: 16, height: 24 / 16),
          bodyMedium: const TextStyle(fontSize: 14, height: 20 / 14),
          bodySmall: const TextStyle(fontSize: 12, height: 16 / 12),
          labelLarge: const TextStyle(
            fontSize: 15,
            height: 20 / 15,
            fontWeight: FontWeight.w500,
            letterSpacing: -0.1,
          ),
          labelMedium: const TextStyle(
            fontSize: 12,
            height: 16 / 12,
            fontWeight: FontWeight.w500,
          ),
          labelSmall: const TextStyle(
            fontSize: 11,
            height: 14 / 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.6,
          ),
        )
        .apply(
          fontFamily: AppText.family,
          bodyColor: c.textPrimary,
          displayColor: c.textPrimary,
        );

    final inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.md),
      borderSide: BorderSide(color: c.border),
    );

    return base.copyWith(
      scaffoldBackgroundColor: c.background,
      extensions: [c],
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: c.primary,
        onPrimary: c.onPrimary,
        secondary: c.secondary,
        onSecondary: c.onPrimary,
        tertiary: c.tertiary,
        onTertiary: c.onPrimary,
        tertiaryContainer: c.tertiaryContainer,
        surface: c.card,
        onSurface: c.textPrimary,
        onSurfaceVariant: c.textSecondary,
        surfaceContainerLowest: c.raised,
        surfaceContainerLow: c.card,
        surfaceContainer: c.surface,
        surfaceContainerHigh: c.surface,
        surfaceContainerHighest: c.divider,
        error: c.error,
        onError: c.onPrimary,
        errorContainer: c.errorContainer,
        outline: c.textMuted,
        outlineVariant: c.border,
      ),
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: c.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: c.textPrimary),
        titleTextStyle: textTheme.titleLarge?.copyWith(color: c.textPrimary),
      ),
      cardTheme: CardThemeData(
        color: c.card,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: c.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        height: 70,
        indicatorColor: c.track,
        indicatorShape: pill,
        iconTheme: WidgetStateProperty.resolveWith(
          (s) => IconThemeData(
            size: 22,
            color: s.contains(WidgetState.selected)
                ? c.textPrimary
                : c.textMuted,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (s) => textTheme.labelMedium?.copyWith(
            fontSize: 11,
            fontWeight: s.contains(WidgetState.selected)
                ? FontWeight.w600
                : FontWeight.w500,
            color: s.contains(WidgetState.selected)
                ? c.textPrimary
                : c.textMuted,
          ),
        ),
      ),
      dividerTheme: DividerThemeData(color: c.divider, thickness: 1, space: 1),
      chipTheme: ChipThemeData(
        backgroundColor: c.raised,
        selectedColor: c.primary,
        side: BorderSide(color: c.border),
        shape: const StadiumBorder(),
        labelStyle: textTheme.labelMedium?.copyWith(color: c.textPrimary),
        secondaryLabelStyle: textTheme.labelMedium?.copyWith(
          color: c.onPrimary,
        ),
        checkmarkColor: c.onPrimary,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: c.raised,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: c.raised,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        modalBarrierColor: const Color(0x52151515),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.xl),
          ),
        ),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: c.textSecondary,
        textColor: c.textPrimary,
        minTileHeight: 56,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: c.primary,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: c.onPrimary),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? c.onPrimary : c.raised,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? c.primary : c.track,
        ),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: c.primary,
        linearTrackColor: c.track,
        circularTrackColor: c.track,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.raised,
        labelStyle: textTheme.labelMedium?.copyWith(color: c.textSecondary),
        floatingLabelStyle: textTheme.labelMedium?.copyWith(
          color: c.textSecondary,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        border: inputBorder,
        enabledBorder: inputBorder,
        focusedBorder: inputBorder.copyWith(
          borderSide: BorderSide(color: c.primary, width: 1.5),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: c.primary,
        foregroundColor: c.onPrimary,
        elevation: 0,
        shape: const CircleBorder(),
      ),
      // Primary: ink pill, 48px.
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: c.primary,
          foregroundColor: c.onPrimary,
          disabledBackgroundColor: c.surface,
          disabledForegroundColor: c.textMuted,
          elevation: 0,
          minimumSize: const Size(64, 48),
          shape: pill,
          textStyle: textTheme.labelLarge,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: c.primary,
          foregroundColor: c.onPrimary,
          disabledBackgroundColor: c.surface,
          disabledForegroundColor: c.textMuted,
          minimumSize: const Size(64, 48),
          shape: pill,
          textStyle: textTheme.labelLarge,
        ),
      ),
      // Secondary: raised pill with a hairline border.
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: c.textPrimary,
          backgroundColor: c.raised,
          side: BorderSide(color: c.border),
          minimumSize: const Size(64, 48),
          shape: pill,
          textStyle: textTheme.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: c.textPrimary,
          shape: pill,
          textStyle: textTheme.labelLarge,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(foregroundColor: c.textPrimary),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          backgroundColor: c.surface,
          selectedBackgroundColor: brightness == Brightness.dark
              ? c.barMuted
              : c.raised,
          selectedForegroundColor: c.textPrimary,
          foregroundColor: c.textSecondary,
          side: BorderSide.none,
          shape: pill,
        ),
      ),
    );
  }
}
