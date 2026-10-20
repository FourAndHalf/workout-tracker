import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// Pill segmented control: a recessed track with a raised pill that slides
/// between the segments (design "Segmented controls").
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
        widthFactor: 1,
        child: Container(
          height: 44,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(999),
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
                      color: Theme.of(context).brightness == Brightness.dark
                          ? colors.barMuted
                          : colors.raised,
                      borderRadius: BorderRadius.circular(999),
                      boxShadow: AppShadows.raised(
                        Theme.of(context).brightness,
                      ),
                    ),
                  ),
                ),
              ),
              Row(
                children: [
                  for (var i = 0; i < count; i++)
                    Expanded(
                      child: InkWell(
                        borderRadius: BorderRadius.circular(999),
                        onTap: () => onSelected(i),
                        child: Center(
                          child: Text(
                            labels[i],
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: Color.lerp(
                                colors.textSecondary,
                                colors.textPrimary,
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
