import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/accent.dart';

export '../../../core/widgets/accent.dart';

/// Explore's view of the theme: the global coral accent plus the three tones
/// the body figure is drawn with.
class ExploreTokens {
  /// Graphics: the figure highlight, meters, borders.
  final Color accent;

  /// Darker end of the figure highlight's gradient.
  final Color accentDeep;

  /// Coral text and small icons.
  final Color accentText;
  final Color accentContainer;
  final Color onAccent;
  final AppColors colors;

  /// Figure fills and outlines.
  final Color body;
  final Color muscle;
  final Color line;

  const ExploreTokens({
    required this.accent,
    required this.accentDeep,
    required this.accentText,
    required this.accentContainer,
    required this.onAccent,
    required this.colors,
    required this.body,
    required this.muscle,
    required this.line,
  });

  static ExploreTokens of(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final colors = context.colors;
    return ExploreTokens(
      accent: colors.accent,
      accentDeep: colors.accentFillEnd,
      accentText: colors.accentText,
      accentContainer: colors.accentContainer,
      onAccent: colors.onAccent,
      colors: colors,
      body: dark ? const Color(0xFF151A21) : const Color(0xFFDDDEE2),
      muscle: dark ? const Color(0xFF1C222B) : const Color(0xFFE9EAED),
      line: colors.textMuted.withValues(alpha: dark ? 0.55 : 0.6),
    );
  }

  /// The filled main-action gradient.
  LinearGradient get gradient => accentGradient(colors);
}

/// Three short bars filled to show how directly an exercise trains the
/// muscle, with a label: PRIMARY (3) or ASSISTS (2).
class FocusMeter extends StatelessWidget {
  final bool primary;
  const FocusMeter({super.key, required this.primary});

  @override
  Widget build(BuildContext context) {
    final tokens = ExploreTokens.of(context);
    final filled = primary ? 3 : 2;
    return Semantics(
      label: primary ? 'Primary driver' : 'Assists',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < 3; i++)
            Container(
              width: 16,
              height: 4,
              margin: const EdgeInsets.only(right: 3),
              decoration: BoxDecoration(
                color: i < filled ? tokens.accent : context.colors.border,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          const SizedBox(width: 6),
          MicroLabel(primary ? 'Primary' : 'Assists', size: 10),
        ],
      ),
    );
  }
}

/// Cross-fades [child] with a short rise whenever [swapKey] changes, and
/// eases the height between the old and new content, so switching muscles,
/// parts or GYM/HOME never jumps.
class SmoothSwap extends StatelessWidget {
  final Object swapKey;
  final Widget child;
  const SmoothSwap({super.key, required this.swapKey, required this.child});

  static const duration = Duration(milliseconds: 280);

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: duration,
      curve: Curves.easeOutCubic,
      alignment: Alignment.topCenter,
      child: AnimatedSwitcher(
        duration: duration,
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        layoutBuilder: (current, previous) => Stack(
          alignment: Alignment.topLeft,
          children: [
            // The outgoing content fades in place without taking space or
            // taps.
            for (final p in previous)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: IgnorePointer(child: p),
              ),
            ?current,
          ],
        ),
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween(
              begin: const Offset(0, 0.015),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        ),
        child: KeyedSubtree(key: ValueKey(swapKey), child: child),
      ),
    );
  }
}
