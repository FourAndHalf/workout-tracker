import 'package:flutter/material.dart';

/// "Paper & Ink" color tokens (see design/DESIGN.md), resolved by brightness
/// through [ThemeExtension]. Read them with `context.colors`.
///
/// Hierarchy comes from tone, not hue: [primary] is the charcoal anchor,
/// [accent] (coral) marks focus and the one main action on a screen, and the
/// semantic colors ([success], [error], [warning], [info]) only ever appear
/// small (a delta, a badge, a dot).
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
    required this.accent,
    required this.accentText,
    required this.accentFill,
    required this.accentFillEnd,
    required this.onAccent,
    required this.accentContainer,
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

  // Coral accent (design/DESIGN.md › Colors › Coral accent). Every pairing
  // below meets WCAG AA; see the contrast table there.
  /// Graphics only: highlights, the current bar, meters, borders, glows.
  final Color accent;

  /// Coral text and small icons on any surface (4.5:1 or better).
  final Color accentText;

  /// Gradient for filled coral controls (main action, selected chip).
  final Color accentFill;
  final Color accentFillEnd;

  /// Text and icons on [accentFill].
  final Color onAccent;

  /// Soft tint behind a selected row or an opened card.
  final Color accentContainer;

  static const light = AppColors(
    background: Color(0xFFF4F4F1),
    surface: Color(0xFFF2F1EE),
    card: Color(0xFFFFFFFF),
    raised: Color(0xFFFFFFFF),
    border: Color(0xFFE5E4E0),
    divider: Color(0xFFECEBE7),
    primary: Color(0xFF151515),
    onPrimary: Color(0xFFFFFFFF),
    primaryPressed: Color(0xFF2E2E2C),
    secondary: Color(0xFF5C5C58),
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
    textPrimary: Color(0xFF151515),
    textSecondary: Color(0xFF5C5C58),
    textMuted: Color(0xFF6A6A66),
    track: Color(0xFFE8E7E3),
    barMuted: Color(0xFFD5D4CF),
    heroStart: Color(0xFFFFFFFF),
    heroEnd: Color(0xFFFFFFFF),
    straightBlock: Color(0xFF5C5C58),
    supersetBlock: Color(0xFF3F5F80),
    triSetBlock: Color(0xFF5C5C58),
    giantSetBlock: Color(0xFF7A6A47),
    dropSetBlock: Color(0xFF8A5A0F),
    restPauseBlock: Color(0xFF23784A),
    accent: Color(0xFFE4572E),
    accentText: Color(0xFFB83A18),
    accentFill: Color(0xFFCC4722),
    accentFillEnd: Color(0xFFBF3F1C),
    onAccent: Color(0xFFFFFFFF),
    accentContainer: Color(0xFFFCEBE4),
  );

  static const dark = AppColors(
    background: Color(0xFF09090A),
    surface: Color(0xFF1C1C1F),
    card: Color(0xFF141416),
    raised: Color(0xFF202023),
    border: Color(0xFF26262A),
    divider: Color(0xFF222226),
    primary: Color(0xFFF2F2EF),
    onPrimary: Color(0xFF141416),
    primaryPressed: Color(0xFFC9C9C5),
    secondary: Color(0xFFA6A6A2),
    tertiary: Color(0xFFCDBB92),
    tertiaryContainer: Color(0xFF2B2619),
    success: Color(0xFF5BBF86),
    successContainer: Color(0xFF16291E),
    onSuccess: Color(0xFF09090A),
    warning: Color(0xFFD9A54A),
    warningContainer: Color(0xFF2E2414),
    error: Color(0xFFE5726B),
    errorContainer: Color(0xFF331A18),
    info: Color(0xFF8FB0D3),
    infoContainer: Color(0xFF1A2430),
    textPrimary: Color(0xFFF2F2EF),
    textSecondary: Color(0xFFA6A6A2),
    textMuted: Color(0xFF8E8E8A),
    track: Color(0xFF26262A),
    barMuted: Color(0xFF36363B),
    heroStart: Color(0xFF1A1A1D),
    heroEnd: Color(0xFF141416),
    straightBlock: Color(0xFFA6A6A2),
    supersetBlock: Color(0xFF8FB0D3),
    triSetBlock: Color(0xFFA6A6A2),
    giantSetBlock: Color(0xFFCDBB92),
    dropSetBlock: Color(0xFFD9A54A),
    restPauseBlock: Color(0xFF5BBF86),
    accent: Color(0xFFFF7A59),
    accentText: Color(0xFFFF7A59),
    accentFill: Color(0xFFFF7A59),
    accentFillEnd: Color(0xFFF86A4A),
    onAccent: Color(0xFF141416),
    accentContainer: Color(0xFF2A1711),
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
    Color? accent,
    Color? accentText,
    Color? accentFill,
    Color? accentFillEnd,
    Color? onAccent,
    Color? accentContainer,
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
      accent: accent ?? this.accent,
      accentText: accentText ?? this.accentText,
      accentFill: accentFill ?? this.accentFill,
      accentFillEnd: accentFillEnd ?? this.accentFillEnd,
      onAccent: onAccent ?? this.onAccent,
      accentContainer: accentContainer ?? this.accentContainer,
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
      accent: l(accent, other.accent),
      accentText: l(accentText, other.accentText),
      accentFill: l(accentFill, other.accentFill),
      accentFillEnd: l(accentFillEnd, other.accentFillEnd),
      onAccent: l(onAccent, other.onAccent),
      accentContainer: l(accentContainer, other.accentContainer),
    );
  }
}

extension AppColorsContext on BuildContext {
  /// Falls back to the dark (default) palette when no [AppTheme] is
  /// installed.
  AppColors get colors =>
      Theme.of(this).extension<AppColors>() ?? AppColors.dark;
}
