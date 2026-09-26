import 'package:flutter/material.dart';

/// Small uppercase status/modality pill (design `badge-tag`): tinted fill,
/// tinted outline, [color] text.
class TagPill extends StatelessWidget {
  final String label;
  final Color color;

  const TagPill(this.label, {super.key, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(999),
      border: Border.all(color: color.withValues(alpha: 0.4)),
    ),
    child: Text(
      label.toUpperCase(),
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
        color: color,
      ),
    ),
  );
}
