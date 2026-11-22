import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// A simple front/back body figure with tappable muscle zones.
///
/// Everything is drawn in a 100 x 220 unit box. Each zone is described for
/// the figure's left half and mirrored to the right, so a zone is one path
/// plus, optionally, one mask per muscle part that carves out where that
/// part sits (the upper chest, the long head, and so on).
class BodyFigure extends StatelessWidget {
  /// The muscle group to emphasise.
  final String muscleId;

  /// The part of that muscle to emphasise with the strongest tint, if any.
  final String? regionId;

  /// `front` or `back`.
  final String view;
  final ValueChanged<String> onSelectMuscle;

  const BodyFigure({
    super.key,
    required this.muscleId,
    required this.regionId,
    required this.view,
    required this.onSelectMuscle,
  });

  /// The side of the body a region is visible from, or null when it is not
  /// drawn on either side.
  static String? viewFor(String muscleId, String? regionId) {
    for (final side in const ['front', 'back']) {
      for (final zone in _zones(side)) {
        if (zone.muscle != muscleId) continue;
        if (regionId == null || zone.masks.containsKey(regionId)) return side;
      }
    }
    return null;
  }

  /// The muscle group at [unit] (figure coordinates), if any.
  @visibleForTesting
  static String? hitTest(String view, Offset unit) {
    for (final zone in _zones(view).reversed) {
      if (zone.path.contains(unit)) return zone.muscle;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return AspectRatio(
      aspectRatio: _w / _h,
      child: LayoutBuilder(
        builder: (context, box) => GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapUp: (details) {
            final unit = Offset(
              details.localPosition.dx / box.maxWidth * _w,
              details.localPosition.dy / box.maxHeight * _h,
            );
            final hit = hitTest(view, unit);
            if (hit != null) onSelectMuscle(hit);
          },
          child: Semantics(
            label: '${view == 'front' ? 'Front' : 'Back'} body figure',
            child: CustomPaint(
              painter: _FigurePainter(
                view: view,
                muscleId: muscleId,
                regionId: regionId,
                base: colors.surface,
                zone: colors.raised,
                outline: colors.border,
                tint: colors.primary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

const double _w = 100;
const double _h = 220;

class _Zone {
  final String muscle;
  final Path path;

  /// Muscle part id -> where it sits. A part without an entry is not drawn
  /// on this side of the body.
  final Map<String, Path> masks;

  const _Zone(this.muscle, this.path, this.masks);
}

Path _mirror(Path p) => p.transform(
  (Matrix4.identity()
        ..translateByDouble(_w, 0, 0, 1)
        ..scaleByDouble(-1, 1, 1, 1))
      .storage,
);

/// [left] plus its mirror image.
Path _pair(Path left) => Path.combine(PathOperation.union, left, _mirror(left));

Path _oval(double cx, double cy, double rx, double ry) => Path()
  ..addOval(
    Rect.fromCenter(center: Offset(cx, cy), width: rx * 2, height: ry * 2),
  );

Path _box(double l, double t, double r, double b, [double radius = 4]) =>
    Path()..addRRect(RRect.fromLTRBR(l, t, r, b, Radius.circular(radius)));

Path _poly(List<double> xy) {
  final path = Path()..moveTo(xy[0], xy[1]);
  for (var i = 2; i < xy.length; i += 2) {
    path.lineTo(xy[i], xy[i + 1]);
  }
  return path..close();
}

Path _rect(double l, double t, double r, double b) =>
    Path()..addRect(Rect.fromLTRB(l, t, r, b));

/// A mask is drawn on the left and mirrored to the right.
Path _maskPair(Path left) => _pair(left);

List<_Zone>? _front;
List<_Zone>? _back;

List<_Zone> _zones(String view) =>
    view == 'back' ? (_back ??= _buildBack()) : (_front ??= _buildFront());

List<_Zone> _buildFront() => [
  _Zone('traps', _pair(_poly([45, 24, 36, 33, 42, 37, 48, 29])), {
    'upper-traps': _rect(0, 0, 100, 100),
  }),
  _Zone('shoulders', _pair(_oval(26.5, 41, 8, 9)), {
    'front-delts': _maskPair(_rect(23, 28, 40, 54)),
    'side-delts': _maskPair(_rect(10, 28, 23, 54)),
  }),
  _Zone('chest', _pair(_box(31, 39, 49.5, 58, 7)), {
    'upper-chest': _maskPair(_rect(28, 36, 50, 45)),
    'mid-chest': _maskPair(_rect(28, 45, 50, 52)),
    'lower-chest': _maskPair(_rect(28, 52, 50, 60)),
  }),
  _Zone('biceps', _pair(_box(17.5, 50, 26.5, 76, 4.5)), {
    'long-head': _maskPair(_rect(16, 48, 22, 78)),
    'short-head': _maskPair(_rect(22, 48, 28, 78)),
    'brachialis': _maskPair(_rect(16, 64, 28, 78)),
  }),
  _Zone('forearms', _pair(_box(12.5, 78, 22, 107, 4)), {
    'flexors': _maskPair(_rect(10, 76, 24, 110)),
  }),
  _Zone(
    'core',
    Path.combine(
      PathOperation.union,
      _box(39, 61, 61, 101, 5),
      _pair(_box(32, 62, 38, 98, 3)),
    ),
    {
      'abs': _rect(38.5, 58, 61.5, 104),
      'obliques': _maskPair(_rect(30, 58, 38.5, 104)),
      'deep-core': _rect(36, 70, 64, 96),
    },
  ),
  _Zone(
    'hips',
    Path.combine(
      PathOperation.union,
      _pair(_box(43.5, 110, 49.5, 142, 3)),
      _pair(_oval(28, 107, 3.6, 8)),
    ),
    {
      'adductors': _maskPair(_rect(40, 105, 50, 145)),
      'abductors': _maskPair(_rect(22, 96, 34, 124)),
    },
  ),
  _Zone('quads', _pair(_box(31, 108, 48, 163, 7.5)), {
    'vasti': _maskPair(_rect(28, 108, 50, 166)),
    'rectus-femoris': _maskPair(_rect(35, 108, 44, 152)),
  }),
];

List<_Zone> _buildBack() => [
  _Zone(
    'traps',
    Path()..addPath(
      _poly([50, 23, 41, 28, 33, 37, 50, 65, 67, 37, 59, 28]),
      Offset.zero,
    ),
    {
      'upper-traps': _rect(28, 20, 72, 42),
      'mid-lower-traps': _rect(28, 42, 72, 68),
    },
  ),
  _Zone('shoulders', _pair(_oval(26.5, 41, 8, 9)), {
    'rear-delts': _maskPair(_rect(14, 28, 40, 54)),
    'side-delts': _maskPair(_rect(10, 28, 18, 54)),
  }),
  _Zone(
    'back',
    Path.combine(
      PathOperation.union,
      _pair(_poly([33, 47, 48, 62, 48, 90, 38, 86, 33, 64])),
      _pair(_box(40, 44, 49, 62, 3)),
    ),
    {
      'lats': _maskPair(_rect(28, 58, 50, 94)),
      'mid-back': _maskPair(_rect(34, 42, 50, 62)),
    },
  ),
  _Zone('triceps', _pair(_box(17.5, 50, 26.5, 76, 4.5)), {
    'long-head': _maskPair(_rect(16, 48, 28, 63)),
    'lateral-medial': _maskPair(_rect(16, 58, 28, 78)),
  }),
  _Zone('forearms', _pair(_box(12.5, 78, 22, 107, 4)), {
    'extensors': _maskPair(_rect(10, 76, 24, 110)),
  }),
  _Zone('lower-back', _box(40, 90, 60, 106, 4), {
    'erectors': _rect(36, 86, 64, 110),
  }),
  _Zone('glutes', _pair(_oval(41, 116, 9.5, 11)), {
    'glute-max': _maskPair(_rect(30, 106, 50, 130)),
    'glute-med': _maskPair(_rect(28, 98, 38, 114)),
  }),
  _Zone('hips', _pair(_oval(27.5, 107, 3.6, 8)), {
    'abductors': _maskPair(_rect(20, 96, 34, 120)),
  }),
  _Zone('hamstrings', _pair(_box(31, 130, 48, 170, 7.5)), {
    'hinge': _maskPair(_rect(28, 128, 50, 172)),
    'curl': _maskPair(_rect(28, 128, 50, 172)),
  }),
  _Zone('calves', _pair(_box(32, 174, 45, 209, 6.5)), {
    'gastrocnemius': _maskPair(_rect(30, 172, 47, 196)),
    'soleus': _maskPair(_rect(30, 192, 47, 212)),
  }),
];

class _FigurePainter extends CustomPainter {
  final String view;
  final String muscleId;
  final String? regionId;
  final Color base;
  final Color zone;
  final Color outline;
  final Color tint;

  _FigurePainter({
    required this.view,
    required this.muscleId,
    required this.regionId,
    required this.base,
    required this.zone,
    required this.outline,
    required this.tint,
  });

  Path _silhouette() {
    final body = Path()
      ..addOval(Rect.fromCircle(center: const Offset(50, 12), radius: 8.5))
      ..addPath(_box(45, 19, 55, 28, 3), Offset.zero)
      ..addPath(_poly([32, 32, 68, 32, 66, 104, 34, 104]), Offset.zero)
      ..addPath(_pair(_box(14, 46, 27, 80, 5)), Offset.zero)
      ..addPath(_pair(_box(11, 77, 23, 112, 5)), Offset.zero)
      ..addPath(_pair(_box(30, 102, 49, 166, 8)), Offset.zero)
      ..addPath(_pair(_box(31, 164, 46, 212, 7)), Offset.zero);
    return body;
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / _w, size.height / _h);

    final fill = Paint()..color = base;
    canvas.drawPath(_silhouette(), fill);

    final edge = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5
      ..color = outline;
    final zonePaint = Paint()..color = zone;
    final groupPaint = Paint()..color = tint.withValues(alpha: 0.32);
    final partPaint = Paint()..color = tint;

    for (final z in _zones(view)) {
      final selected = z.muscle == muscleId;
      canvas.drawPath(z.path, selected ? groupPaint : zonePaint);
      canvas.drawPath(z.path, edge);
      if (selected && regionId != null) {
        final mask = z.masks[regionId];
        if (mask != null) {
          canvas.drawPath(
            Path.combine(PathOperation.intersect, z.path, mask),
            partPaint,
          );
        }
      } else if (selected) {
        canvas.drawPath(z.path, partPaint..color = tint.withValues(alpha: 0.7));
        partPaint.color = tint;
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_FigurePainter old) =>
      old.view != view ||
      old.muscleId != muscleId ||
      old.regionId != regionId ||
      old.base != base ||
      old.zone != zone ||
      old.tint != tint;
}
