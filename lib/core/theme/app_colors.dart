import 'package:flutter/material.dart';

/// "Kinetic Obsidian" color tokens (see design/DESIGN.md), resolved by brightness through
/// [ThemeExtension]. Read them with `context.colors`.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.background,
    required this.surface,
    required this.card,
    required this.border,
    required this.primary,
    required this.secondary,
    required this.tertiary,
    required this.success,
    required this.onSuccess,
    required this.warning,
    required this.error,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.straightBlock,
    required this.supersetBlock,
    required this.triSetBlock,
    required this.giantSetBlock,
    required this.dropSetBlock,
    required this.restPauseBlock,
  });

  // Backgrounds: canvas, inset (level 2), card (level 1), hairline border
  final Color background;
  final Color surface;
  final Color card;
  final Color border;

  // Accents
  final Color primary;
  final Color secondary;
  final Color tertiary;
  final Color success;
  final Color onSuccess;
  final Color warning;
  final Color error;

  // Text
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;

  // Block Badges
  final Color straightBlock;
  final Color supersetBlock;
  final Color triSetBlock;
  final Color giantSetBlock;
  final Color dropSetBlock;
  final Color restPauseBlock;

  static const dark = AppColors(
    background: Color(0xFF0F1218),
    surface: Color(0xFF202632),
    card: Color(0xFF181C24),
    border: Color(0x14FFFFFF),
    primary: Color(0xFF3B82F6),
    secondary: Color(0xFF94A3B8),
    tertiary: Color(0xFF64748B),
    success: Color(0xFF10B981),
    onSuccess: Color(0xFFFFFFFF),
    warning: Color(0xFFF59E0B),
    error: Color(0xFFFFB4AB),
    textPrimary: Color(0xFFF9FAFB),
    textSecondary: Color(0xFF94A3B8),
    textMuted: Color(0xFF64748B),
    straightBlock: Color(0xFF94A3B8),
    supersetBlock: Color(0xFF3B82F6),
    triSetBlock: Color(0xFFBC8CFF),
    giantSetBlock: Color(0xFFF778BA),
    dropSetBlock: Color(0xFFF59E0B),
    restPauseBlock: Color(0xFF10B981),
  );

  static const light = AppColors(
    background: Color(0xFFF3F5F8),
    surface: Color(0xFFEAEEF3),
    card: Color(0xFFFFFFFF),
    border: Color(0x1A0F1218),
    primary: Color(0xFF2563EB),
    secondary: Color(0xFF475569),
    tertiary: Color(0xFF64748B),
    success: Color(0xFF059669),
    onSuccess: Color(0xFFFFFFFF),
    warning: Color(0xFFD97706),
    error: Color(0xFFBA1A1A),
    textPrimary: Color(0xFF0F1218),
    textSecondary: Color(0xFF475569),
    textMuted: Color(0xFF64748B),
    straightBlock: Color(0xFF475569),
    supersetBlock: Color(0xFF2563EB),
    triSetBlock: Color(0xFF8250DF),
    giantSetBlock: Color(0xFFBF3989),
    dropSetBlock: Color(0xFFD97706),
    restPauseBlock: Color(0xFF059669),
  );

  @override
  AppColors copyWith({
    Color? background,
    Color? surface,
    Color? card,
    Color? border,
    Color? primary,
    Color? secondary,
    Color? tertiary,
    Color? success,
    Color? onSuccess,
    Color? warning,
    Color? error,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? straightBlock,
    Color? supersetBlock,
    Color? triSetBlock,
    Color? giantSetBlock,
    Color? dropSetBlock,
    Color? restPauseBlock,
  }) {
    return AppColors(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      card: card ?? this.card,
      border: border ?? this.border,
      primary: primary ?? this.primary,
      secondary: secondary ?? this.secondary,
      tertiary: tertiary ?? this.tertiary,
      success: success ?? this.success,
      onSuccess: onSuccess ?? this.onSuccess,
      warning: warning ?? this.warning,
      error: error ?? this.error,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      straightBlock: straightBlock ?? this.straightBlock,
      supersetBlock: supersetBlock ?? this.supersetBlock,
      triSetBlock: triSetBlock ?? this.triSetBlock,
      giantSetBlock: giantSetBlock ?? this.giantSetBlock,
      dropSetBlock: dropSetBlock ?? this.dropSetBlock,
      restPauseBlock: restPauseBlock ?? this.restPauseBlock,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppColors(
      background: l(background, other.background),
      surface: l(surface, other.surface),
      card: l(card, other.card),
      border: l(border, other.border),
      primary: l(primary, other.primary),
      secondary: l(secondary, other.secondary),
      tertiary: l(tertiary, other.tertiary),
      success: l(success, other.success),
      onSuccess: l(onSuccess, other.onSuccess),
      warning: l(warning, other.warning),
      error: l(error, other.error),
      textPrimary: l(textPrimary, other.textPrimary),
      textSecondary: l(textSecondary, other.textSecondary),
      textMuted: l(textMuted, other.textMuted),
      straightBlock: l(straightBlock, other.straightBlock),
      supersetBlock: l(supersetBlock, other.supersetBlock),
      triSetBlock: l(triSetBlock, other.triSetBlock),
      giantSetBlock: l(giantSetBlock, other.giantSetBlock),
      dropSetBlock: l(dropSetBlock, other.dropSetBlock),
      restPauseBlock: l(restPauseBlock, other.restPauseBlock),
    );
  }
}

extension AppColorsContext on BuildContext {
  /// Falls back to the dark palette when no [AppTheme] is installed.
  AppColors get colors =>
      Theme.of(this).extension<AppColors>() ?? AppColors.dark;
}
