import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// A module: a rounded tile on the canvas with a hairline border and, in
/// light mode, one wide, faint shadow.
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final Color? borderColor;
  final double borderWidth;
  final double radius;
  final Gradient? gradient;
  final VoidCallback? onTap;

  /// Inner panels (a module inside a module) sit flat, without a shadow.
  final bool flat;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.color,
    this.borderColor,
    this.borderWidth = 1,
    this.radius = AppRadius.lg,
    this.gradient,
    this.onTap,
    this.flat = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final brightness = Theme.of(context).brightness;
    final highlight = colors.border;
    final borderRadius = BorderRadius.circular(radius);
    final card = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: gradient == null ? (color ?? colors.card) : null,
        gradient: gradient,
        borderRadius: borderRadius,
        border: Border.all(
          color: borderColor ?? (flat ? Colors.transparent : highlight),
          width: borderWidth,
        ),
        boxShadow: flat ? null : AppShadows.module(brightness),
      ),
      child: child,
    );

    if (onTap == null) return card;
    return Material(
      type: MaterialType.transparency,
      child: InkWell(onTap: onTap, borderRadius: borderRadius, child: card),
    );
  }
}
