import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// Shared Pearl Ledger building blocks (design/DESIGN.md "Components" and
/// "Data visualization"). They take their colors from `context.colors`, so
/// they follow the light/dark theme.

/// A module title in `headline-md` with an optional muted subtitle and a
/// trailing slot (a "View all" pill or an icon button).
class ModuleHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;

  const ModuleHeader(this.title, {super.key, this.subtitle, this.trailing});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: textTheme.titleMedium),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  style: textTheme.bodySmall?.copyWith(
                    color: context.colors.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),
        ?trailing,
      ],
    );
  }
}

/// `▲ 6%` / `▼ 4%`: semantic color always paired with a glyph.
class DeltaPill extends StatelessWidget {
  final int percent;

  /// Renders the change as a unit suffix instead of a percentage,
  /// e.g. `▲ 2.5 kg`.
  final String? label;

  const DeltaPill(this.percent, {super.key, this.label});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final up = percent >= 0;
    return StatusBadge(
      '${up ? '▲' : '▼'} ${label ?? '${percent.abs()}%'}',
      foreground: up ? colors.success : colors.error,
      background: up ? colors.successContainer : colors.errorContainer,
    );
  }
}

/// A 22px semantic badge: container color plus text color.
class StatusBadge extends StatelessWidget {
  final String label;
  final Color foreground;
  final Color background;
  final IconData? icon;

  const StatusBadge(
    this.label, {
    super.key,
    required this.foreground,
    required this.background,
    this.icon,
  });

  @override
  Widget build(BuildContext context) => Container(
    height: 22,
    padding: const EdgeInsets.symmetric(horizontal: 8),
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(999),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 12, color: foreground),
          const SizedBox(width: 4),
        ],
        Text(label, style: AppText.metricDelta.copyWith(color: foreground)),
      ],
    ),
  );
}

/// The dark callout pill that marks a chart highlight (`+12%`, `84%`).
class CalloutPill extends StatelessWidget {
  final String label;

  const CalloutPill(this.label, {super.key});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: context.colors.primary,
      borderRadius: BorderRadius.circular(999),
    ),
    child: Text(
      label,
      style: AppText.metricDelta.copyWith(color: context.colors.onPrimary),
    ),
  );
}

/// A 44px raised circle with a 20px outline icon.
class RoundIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final double size;

  /// Charcoal fill with a light icon, for the primary action in a group.
  final bool filled;

  const RoundIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.size = 44,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: filled ? colors.primary : colors.raised,
        shape: CircleBorder(
          side: filled ? BorderSide.none : BorderSide(color: colors.border),
        ),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: SizedBox(
            width: size,
            height: size,
            child: Icon(
              icon,
              size: 20,
              color: filled ? colors.onPrimary : colors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

/// A 1.25px charcoal line, no fill, no axes.
class Sparkline extends StatelessWidget {
  final List<double> values;
  final double width;
  final double height;

  const Sparkline(this.values, {super.key, this.width = 56, this.height = 20});

  @override
  Widget build(BuildContext context) => CustomPaint(
    size: Size(width, height),
    painter: _SparklinePainter(values, context.colors.primary),
  );
}

class _SparklinePainter extends CustomPainter {
  final List<double> values;
  final Color color;

  _SparklinePainter(this.values, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;
    final maxV = values.reduce(math.max);
    final minV = values.reduce(math.min);
    final span = maxV - minV == 0 ? 1 : maxV - minV;
    final path = Path();
    for (var i = 0; i < values.length; i++) {
      final x = size.width * i / (values.length - 1);
      final y = size.height - (values[i] - minV) / span * size.height;
      i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.25
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_SparklinePainter old) =>
      old.color != color || old.values != values;
}

/// A 270° arc gauge: track in hairline gray, fill in charcoal, [child]
/// centered.
class GaugeArc extends StatelessWidget {
  final double value;
  final double size;
  final double stroke;
  final Widget child;

  /// Fill color override, e.g. positive when a goal is met.
  final Color? color;

  const GaugeArc({
    super.key,
    required this.value,
    required this.child,
    this.size = 96,
    this.stroke = 8,
    this.color,
  });

  @override
  Widget build(BuildContext context) => SizedBox(
    width: size,
    height: size,
    child: CustomPaint(
      painter: _GaugePainter(
        value: value.clamp(0.0, 1.0),
        stroke: stroke,
        track: context.colors.border,
        fill: color ?? context.colors.primary,
      ),
      child: Center(child: child),
    ),
  );
}

class _GaugePainter extends CustomPainter {
  final double value;
  final double stroke;
  final Color track;
  final Color fill;

  _GaugePainter({
    required this.value,
    required this.stroke,
    required this.track,
    required this.fill,
  });

  static const _start = math.pi * 0.75; // 7:30 o'clock
  static const _sweep = math.pi * 1.5; // 270°

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(
      stroke / 2,
      stroke / 2,
      size.width - stroke,
      size.height - stroke,
    );
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, _start, _sweep, false, paint..color = track);
    if (value > 0) {
      canvas.drawArc(rect, _start, _sweep * value, false, paint..color = fill);
    }
  }

  @override
  bool shouldRepaint(_GaugePainter old) =>
      old.value != value || old.fill != fill || old.track != track;
}

/// Stacked dots for usage or progress-to-limit. [columns] lists each
/// column's dots top to bottom; `true` dots are charcoal.
class DotMatrix extends StatelessWidget {
  final List<List<bool>> columns;
  final double dot;
  final double gap;

  /// Optional per-column highlight (e.g. the current week).
  final int? highlightColumn;

  const DotMatrix({
    super.key,
    required this.columns,
    this.dot = 8,
    this.gap = 4,
    this.highlightColumn,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        for (var c = 0; c < columns.length; c++)
          Column(
            children: [
              for (final on in columns[c])
                Container(
                  width: dot,
                  height: dot,
                  margin: EdgeInsets.only(bottom: gap),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: on
                        ? colors.primary
                        : c == highlightColumn
                        ? colors.barMuted
                        : colors.track,
                  ),
                ),
            ],
          ),
      ],
    );
  }
}

/// A row of [total] pill segments with the first [filled] in charcoal, used
/// for set and goal progress.
class SegmentProgress extends StatelessWidget {
  final int total;
  final int filled;
  final double height;
  final Color? color;

  const SegmentProgress({
    super.key,
    required this.total,
    required this.filled,
    this.height = 6,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      children: [
        for (var i = 0; i < total; i++) ...[
          if (i > 0) const SizedBox(width: 4),
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              height: height,
              decoration: BoxDecoration(
                color: i < filled ? (color ?? colors.primary) : colors.track,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Thin vertical bars in muted gray with the [highlightIndex] bar in
/// charcoal and an optional dark callout pill floating above it. No
/// gridlines, just a muted axis row.
class ThinBarChart extends StatelessWidget {
  final List<double> values;
  final List<String> labels;
  final int highlightIndex;
  final String? callout;
  final double height;
  final double barWidth;

  const ThinBarChart({
    super.key,
    required this.values,
    this.labels = const [],
    required this.highlightIndex,
    this.callout,
    this.height = 128,
    this.barWidth = 6,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final maxV = values.isEmpty ? 0.0 : values.reduce(math.max);
    final labelStyle = Theme.of(context).textTheme.bodySmall
        ?.copyWith(color: colors.textSecondary, fontSize: 10);
    return Column(
      children: [
        SizedBox(
          height: height,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (var i = 0; i < values.length; i++)
                Expanded(
                  child: Column(
                    children: [
                      // Every column reserves the callout's row so all bars
                      // share one scale.
                      SizedBox(
                        height: 26,
                        child: i == highlightIndex && callout != null
                            ? Align(
                                alignment: Alignment.topCenter,
                                child: OverflowBox(
                                  maxWidth: 120,
                                  child: CalloutPill(callout!),
                                ),
                              )
                            : null,
                      ),
                      Expanded(
                        child: FractionallySizedBox(
                          alignment: Alignment.bottomCenter,
                          heightFactor: maxV <= 0
                              ? 0.04
                              : math.max(0.04, values[i] / maxV),
                          child: Container(
                            width: barWidth,
                            decoration: BoxDecoration(
                              color: i == highlightIndex
                                  ? colors.primary
                                  : colors.barMuted,
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        if (labels.isNotEmpty) const SizedBox(height: 8),
        Row(
          children: [
            for (var i = 0; i < labels.length; i++)
              Expanded(
                child: Text(
                  labels[i],
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.clip,
                  style: labelStyle?.copyWith(
                    color: i == highlightIndex
                        ? colors.textPrimary
                        : colors.textSecondary,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

/// A 36px circular icon chip: raised fill, hairline border.
class IconChip extends StatelessWidget {
  final IconData icon;
  final double size;
  final Color? color;

  const IconChip(this.icon, {super.key, this.size = 36, this.color});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: colors.raised,
        shape: BoxShape.circle,
        border: Border.all(color: colors.border),
      ),
      child: Icon(icon, size: size * 0.5, color: color ?? colors.textPrimary),
    );
  }
}
