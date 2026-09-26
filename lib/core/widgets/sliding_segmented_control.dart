import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Rectangular side-by-side tabs with a highlight that slides between them.
///
/// [position] is the (possibly fractional) index of the highlighted tab, so
/// callers can feed it an animation value and the highlight glides smoothly.
class SlidingSegmentedControl extends StatelessWidget {
  final List<String> labels;
  final double position;
  final ValueChanged<int> onSelected;

  const SlidingSegmentedControl({
    super.key,
    required this.labels,
    required this.position,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final count = labels.length;

    return Center(
      child: FractionallySizedBox(
        widthFactor: 0.9,
        child: Container(
          height: 44,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: colors.card,
            border: Border.all(color: colors.border),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Stack(
            children: [
              Align(
                alignment: Alignment(
                  count > 1 ? -1 + 2 * position / (count - 1) : 0,
                  0,
                ),
                child: FractionallySizedBox(
                  widthFactor: 1 / count,
                  heightFactor: 1,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: colors.primary,
                      borderRadius: BorderRadius.circular(9),
                    ),
                  ),
                ),
              ),
              Row(
                children: [
                  for (var i = 0; i < count; i++)
                    Expanded(
                      child: InkWell(
                        borderRadius: BorderRadius.circular(9),
                        onTap: () => onSelected(i),
                        child: Center(
                          child: Text(
                            labels[i],
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Color.lerp(
                                colors.textSecondary,
                                Colors.white,
                                (1 - (position - i).abs()).clamp(0.0, 1.0),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
