import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Small status pill (design "Badges & status pills"): 22px, a soft
/// container of [color] with [color] text. Uppercase is reserved for these
/// tiny status codes.
class TagPill extends StatelessWidget {
  final String label;
  final Color color;

  const TagPill(this.label, {super.key, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    height: 22,
    alignment: Alignment.center,
    padding: const EdgeInsets.symmetric(horizontal: 8),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.14),
      borderRadius: BorderRadius.circular(999),
    ),
    child: Text(
      label.toUpperCase(),
      style: AppText.labelUppercase.copyWith(color: color),
    ),
  );
}
