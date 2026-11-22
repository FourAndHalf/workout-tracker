import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';

/// The one accent the Explore tab adds to the neutral app palette: a warm
/// coral that marks the selected muscle, the top pick and other active
/// states. Everything else reuses the app tokens.
class ExploreTokens {
  final Color accent;
  final Color accentDeep;
  final Color accentContainer;
  final Color onAccent;

  /// Figure fills and outlines.
  final Color body;
  final Color muscle;
  final Color line;

  const ExploreTokens({
    required this.accent,
    required this.accentDeep,
    required this.accentContainer,
    required this.onAccent,
    required this.body,
    required this.muscle,
    required this.line,
  });

  static ExploreTokens of(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final colors = context.colors;
    return dark
        ? ExploreTokens(
            accent: const Color(0xFFFF7A59),
            accentDeep: const Color(0xFFF0533A),
            accentContainer: const Color(0xFF2A1812),
            onAccent: Colors.white,
            body: const Color(0xFF151A21),
            muscle: const Color(0xFF1C222B),
            line: colors.textMuted.withValues(alpha: 0.55),
          )
        : ExploreTokens(
            accent: const Color(0xFFE4572E),
            accentDeep: const Color(0xFFC9431F),
            accentContainer: const Color(0xFFFCE7DF),
            onAccent: Colors.white,
            body: const Color(0xFFDDDEE2),
            muscle: const Color(0xFFE9EAED),
            line: colors.textMuted.withValues(alpha: 0.6),
          );
  }

  LinearGradient get gradient => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accent, accentDeep],
  );
}

/// Spaced uppercase micro-label, e.g. `02 / 14 · DELTOID`.
class MicroLabel extends StatelessWidget {
  final String text;
  final Color? color;
  final double size;
  const MicroLabel(this.text, {super.key, this.color, this.size = 11});

  @override
  Widget build(BuildContext context) => Text(
    text.toUpperCase(),
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
    style: AppText.labelUppercase.copyWith(
      fontSize: size,
      letterSpacing: size * 0.22,
      color: color ?? context.colors.textMuted,
    ),
  );
}

/// A pill chip: coral gradient with a soft glow when selected, a hairline
/// outline otherwise.
class AccentChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool dense;

  const AccentChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.dense = false,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = ExploreTokens.of(context);
    final colors = context.colors;
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          padding: EdgeInsets.symmetric(
            horizontal: dense ? 14 : 18,
            vertical: dense ? 7 : 9,
          ),
          decoration: BoxDecoration(
            gradient: selected ? tokens.gradient : null,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected ? Colors.transparent : colors.border,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: tokens.accent.withValues(alpha: 0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontSize: dense ? 13 : 14,
              color: selected ? tokens.onAccent : colors.textSecondary,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }
}

/// A small two-way switch, e.g. GYM | HOME.
class CompactToggle extends StatelessWidget {
  final List<String> labels;
  final int index;
  final ValueChanged<int> onChanged;

  const CompactToggle({
    super.key,
    required this.labels,
    required this.index,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < labels.length; i++)
            Semantics(
              button: true,
              selected: i == index,
              child: GestureDetector(
                onTap: () => onChanged(i),
                child: AnimatedContainer(
                  key: ValueKey('toggle-${labels[i].toLowerCase()}'),
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: i == index ? colors.raised : Colors.transparent,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: MicroLabel(
                    labels[i],
                    size: 12,
                    color: i == index ? colors.textPrimary : colors.textMuted,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
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

/// Outlined accent pill such as TOP PICK.
class OutlinePill extends StatelessWidget {
  final String label;
  const OutlinePill(this.label, {super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = ExploreTokens.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: tokens.accent.withValues(alpha: 0.75)),
      ),
      child: MicroLabel(label, size: 10, color: tokens.accent),
    );
  }
}
