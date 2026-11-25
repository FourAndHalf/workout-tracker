import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// Shared building blocks for the coral accent (design/DESIGN.md › Colors ›
/// Coral accent and › Components). Any screen can use them; they read the
/// global [AppColors] tokens, so both themes and contrast rules come for free.

/// The fill for the one main action on a screen and for selected chips.
LinearGradient accentGradient(AppColors colors) => LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [colors.accentFill, colors.accentFillEnd],
);

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
            gradient: selected ? accentGradient(colors) : null,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected ? Colors.transparent : colors.border,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: colors.accent.withValues(alpha: 0.35),
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
              color: selected ? colors.onAccent : colors.textSecondary,
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

/// Outlined accent pill such as TOP PICK.
class OutlinePill extends StatelessWidget {
  final String label;
  const OutlinePill(this.label, {super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: colors.accent.withValues(alpha: 0.75)),
      ),
      child: MicroLabel(label, size: 10, color: colors.accentText),
    );
  }
}

/// The one main action on a screen (design/DESIGN.md › Buttons › Main
/// action): a coral gradient pill with a soft glow and an [AppColors.onAccent]
/// label. With [onPressed] null it becomes a quiet outline pill, e.g.
/// "Current split".
///
/// Use at most one per screen. Actions that repeat down a list (Log set)
/// keep the neutral primary button.
class AccentButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;

  /// 52 px main action, or a 40 px pill for a list row (`compact`).
  final bool compact;

  /// Fill the available width.
  final bool expand;

  const AccentButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.compact = false,
    this.expand = true,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final enabled = onPressed != null;
    final fg = enabled ? colors.onAccent : colors.textSecondary;
    final radius = BorderRadius.circular(999);
    final content = Row(
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 18, color: fg),
          const SizedBox(width: 8),
        ],
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleSmall
                ?.copyWith(color: fg, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );

    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      excludeSemantics: true,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: compact ? 40 : 52,
        decoration: BoxDecoration(
          gradient: enabled ? accentGradient(colors) : null,
          borderRadius: radius,
          border: enabled ? null : Border.all(color: colors.border),
          boxShadow: enabled
              ? [
                  BoxShadow(
                    color: colors.accent.withValues(alpha: 0.35),
                    blurRadius: compact ? 12 : 18,
                    offset: Offset(0, compact ? 4 : 6),
                  ),
                ]
              : null,
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onPressed,
            borderRadius: radius,
            splashColor: colors.onAccent.withValues(alpha: 0.14),
            highlightColor: colors.onAccent.withValues(alpha: 0.06),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: compact ? 14 : 20),
              child: content,
            ),
          ),
        ),
      ),
    );
  }
}
