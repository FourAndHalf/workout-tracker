import 'package:flutter/material.dart';

/// "Pearl Ledger" color tokens (see design/DESIGN.md), resolved by brightness
/// through [ThemeExtension]. Read them with `context.colors`.
///
/// Hierarchy comes from tone, not hue: [primary] is the single charcoal
/// anchor, and the semantic colors ([success], [error], [warning], [info])
/// only ever appear small (a delta, a badge, a dot).
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.background,
    required this.surface,
    required this.card,
    required this.raised,
    required this.border,
    required this.divider,
    required this.primary,
    required this.onPrimary,
    required this.primaryPressed,
    required this.secondary,
    required this.tertiary,
    required this.tertiaryContainer,
    required this.success,
    required this.successContainer,
    required this.onSuccess,
    required this.warning,
    required this.warningContainer,
    required this.error,
    required this.errorContainer,
    required this.info,
    required this.infoContainer,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.track,
    required this.barMuted,
    required this.heroStart,
    required this.heroEnd,
    required this.straightBlock,
    required this.supersetBlock,
    required this.triSetBlock,
    required this.giantSetBlock,
    required this.dropSetBlock,
    required this.restPauseBlock,
  });

  // Surfaces: canvas, inner panel, module, raised control, hairlines
  final Color background;
  final Color surface;
  final Color card;
  final Color raised;
  final Color border;
  final Color divider;

  // Charcoal anchor
  final Color primary;
  final Color onPrimary;
  final Color primaryPressed;
  final Color secondary;

  // Champagne accent: milestones only, at most one per screen
  final Color tertiary;
  final Color tertiaryContainer;

  // Semantic (meaning only)
  final Color success;
  final Color successContainer;
  final Color onSuccess;
  final Color warning;
  final Color warningContainer;
  final Color error;
  final Color errorContainer;
  final Color info;
  final Color infoContainer;

  // Text
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;

  // Data visualization: empty dots / gauge track, inactive bars
  final Color track;
  final Color barMuted;

  // The one decorative surface per screen (hero module gradient)
  final Color heroStart;
  final Color heroEnd;

  // Block badges: muted tones, never saturated
  final Color straightBlock;
  final Color supersetBlock;
  final Color triSetBlock;
  final Color giantSetBlock;
  final Color dropSetBlock;
  final Color restPauseBlock;

  static const light = AppColors(
    background: Color(0xFFE8E8EA),
    surface: Color(0xFFECECEE),
    card: Color(0xFFF1F1F3),
    raised: Color(0xFFFFFFFF),
    border: Color(0xFFDADADD),
    divider: Color(0xFFE0E0E3),
    primary: Color(0xFF2A2A2D),
    onPrimary: Color(0xFFFFFFFF),
    primaryPressed: Color(0xFF3A3A3D),
    secondary: Color(0xFF5E5E63),
    tertiary: Color(0xFF7A6A47),
    tertiaryContainer: Color(0xFFEDE6D6),
    success: Color(0xFF23784A),
    successContainer: Color(0xFFDDF0E4),
    onSuccess: Color(0xFFFFFFFF),
    warning: Color(0xFF8A5A0F),
    warningContainer: Color(0xFFF6E7CC),
    error: Color(0xFFB33A35),
    errorContainer: Color(0xFFF9DEDC),
    info: Color(0xFF3F5F80),
    infoContainer: Color(0xFFDFE8F1),
    textPrimary: Color(0xFF1C1C1E),
    textSecondary: Color(0xFF626267),
    textMuted: Color(0xFF6E6E73),
    track: Color(0xFFD4D4D8),
    barMuted: Color(0xFFC9C9CD),
    heroStart: Color(0xFFF6F4EF),
    heroEnd: Color(0xFFE9E6DE),
    straightBlock: Color(0xFF626267),
    supersetBlock: Color(0xFF3F5F80),
    triSetBlock: Color(0xFF5E5E63),
    giantSetBlock: Color(0xFF7A6A47),
    dropSetBlock: Color(0xFF8A5A0F),
    restPauseBlock: Color(0xFF23784A),
  );

  static const dark = AppColors(
    background: Color(0xFF0F0F11),
    surface: Color(0xFF1C1C1F),
    card: Color(0xFF161618),
    raised: Color(0xFF232326),
    border: Color(0xFF2C2C30),
    divider: Color(0xFF2C2C30),
    primary: Color(0xFFECECEE),
    onPrimary: Color(0xFF161618),
    primaryPressed: Color(0xFFC8C8CC),
    secondary: Color(0xFFA0A0A6),
    tertiary: Color(0xFFCDBB92),
    tertiaryContainer: Color(0xFF2B2619),
    success: Color(0xFF5BBF86),
    successContainer: Color(0xFF16291E),
    onSuccess: Color(0xFF0F0F11),
    warning: Color(0xFFD9A54A),
    warningContainer: Color(0xFF2E2414),
    error: Color(0xFFE5726B),
    errorContainer: Color(0xFF331A18),
    info: Color(0xFF8FB0D3),
    infoContainer: Color(0xFF1A2430),
    textPrimary: Color(0xFFECECEE),
    textSecondary: Color(0xFFA0A0A6),
    textMuted: Color(0xFF8E8E94),
    track: Color(0xFF2C2C30),
    barMuted: Color(0xFF3A3A3F),
    heroStart: Color(0xFF232326),
    heroEnd: Color(0xFF1A1A1C),
    straightBlock: Color(0xFFA0A0A6),
    supersetBlock: Color(0xFF8FB0D3),
    triSetBlock: Color(0xFFA0A0A6),
    giantSetBlock: Color(0xFFCDBB92),
    dropSetBlock: Color(0xFFD9A54A),
    restPauseBlock: Color(0xFF5BBF86),
  );

  @override
  AppColors copyWith({
    Color? background,
    Color? surface,
    Color? card,
    Color? raised,
    Color? border,
    Color? divider,
    Color? primary,
    Color? onPrimary,
    Color? primaryPressed,
    Color? secondary,
    Color? tertiary,
    Color? tertiaryContainer,
    Color? success,
    Color? successContainer,
    Color? onSuccess,
    Color? warning,
    Color? warningContainer,
    Color? error,
    Color? errorContainer,
    Color? info,
    Color? infoContainer,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? track,
    Color? barMuted,
    Color? heroStart,
    Color? heroEnd,
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
      raised: raised ?? this.raised,
      border: border ?? this.border,
      divider: divider ?? this.divider,
      primary: primary ?? this.primary,
      onPrimary: onPrimary ?? this.onPrimary,
      primaryPressed: primaryPressed ?? this.primaryPressed,
      secondary: secondary ?? this.secondary,
      tertiary: tertiary ?? this.tertiary,
      tertiaryContainer: tertiaryContainer ?? this.tertiaryContainer,
      success: success ?? this.success,
      successContainer: successContainer ?? this.successContainer,
      onSuccess: onSuccess ?? this.onSuccess,
      warning: warning ?? this.warning,
      warningContainer: warningContainer ?? this.warningContainer,
      error: error ?? this.error,
      errorContainer: errorContainer ?? this.errorContainer,
      info: info ?? this.info,
      infoContainer: infoContainer ?? this.infoContainer,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      track: track ?? this.track,
      barMuted: barMuted ?? this.barMuted,
      heroStart: heroStart ?? this.heroStart,
      heroEnd: heroEnd ?? this.heroEnd,
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
      raised: l(raised, other.raised),
      border: l(border, other.border),
      divider: l(divider, other.divider),
      primary: l(primary, other.primary),
      onPrimary: l(onPrimary, other.onPrimary),
      primaryPressed: l(primaryPressed, other.primaryPressed),
      secondary: l(secondary, other.secondary),
      tertiary: l(tertiary, other.tertiary),
      tertiaryContainer: l(tertiaryContainer, other.tertiaryContainer),
      success: l(success, other.success),
      successContainer: l(successContainer, other.successContainer),
      onSuccess: l(onSuccess, other.onSuccess),
      warning: l(warning, other.warning),
      warningContainer: l(warningContainer, other.warningContainer),
      error: l(error, other.error),
      errorContainer: l(errorContainer, other.errorContainer),
      info: l(info, other.info),
      infoContainer: l(infoContainer, other.infoContainer),
      textPrimary: l(textPrimary, other.textPrimary),
      textSecondary: l(textSecondary, other.textSecondary),
      textMuted: l(textMuted, other.textMuted),
      track: l(track, other.track),
      barMuted: l(barMuted, other.barMuted),
      heroStart: l(heroStart, other.heroStart),
      heroEnd: l(heroEnd, other.heroEnd),
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
  /// Falls back to the dark (default) palette when no [AppTheme] is
  /// installed.
  AppColors get colors =>
      Theme.of(this).extension<AppColors>() ?? AppColors.dark;
}
