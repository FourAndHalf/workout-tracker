import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'explore_style.dart';

/// A front/back anatomy figure with tappable muscle zones, drawn from
/// scratch for this app.
///
/// Everything lives in a 100 x 220 unit box. Each shape is described for the
/// figure's left half as a handful of points and mirrored; a Catmull-Rom
/// spline through the points gives the smooth outlines. Masks carve each
/// muscle into its parts (the upper chest, the long head, ...).
class BodyFigure extends StatelessWidget {
  final String muscleId;
  final String? regionId;

  /// `front` or `back`.
  final String view;
  final ValueChanged<String> onSelectMuscle;

  /// Draws the dashed crosshair through the highlighted part.
  final bool guides;

  const BodyFigure({
    super.key,
    required this.muscleId,
    required this.regionId,
    required this.view,
    required this.onSelectMuscle,
    this.guides = true,
  });

  /// The side of the body a muscle (or one of its parts) is drawn on.
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
    final tokens = ExploreTokens.of(context);
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
            label:
                '${view == 'front' ? 'Front' : 'Back'} view, $muscleId highlighted',
            child: TweenAnimationBuilder<double>(
              key: ValueKey('$view/$muscleId/$regionId'),
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 420),
              curve: Curves.easeOutCubic,
              builder: (context, t, _) => CustomPaint(
                painter: _FigurePainter(
                  view: view,
                  muscleId: muscleId,
                  regionId: regionId,
                  tokens: tokens,
                  guides: guides,
                  reveal: t,
                ),
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

// ------------------------------------------------------------------ geometry

/// A closed Catmull-Rom spline through [xy] (x, y pairs).
Path _smooth(List<double> xy) {
  final pts = [for (var i = 0; i < xy.length; i += 2) Offset(xy[i], xy[i + 1])];
  final n = pts.length;
  final path = Path()..moveTo(pts[0].dx, pts[0].dy);
  for (var i = 0; i < n; i++) {
    final p0 = pts[(i - 1 + n) % n];
    final p1 = pts[i];
    final p2 = pts[(i + 1) % n];
    final p3 = pts[(i + 2) % n];
    final c1 = p1 + (p2 - p0) / 6;
    final c2 = p2 - (p3 - p1) / 6;
    path.cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, p2.dx, p2.dy);
  }
  return path..close();
}

Path _mirror(Path p) => p.transform(
  (Matrix4.identity()
        ..translateByDouble(_w, 0, 0, 1)
        ..scaleByDouble(-1, 1, 1, 1))
      .storage,
);

/// [left] plus its mirror image.
Path _pair(Path left) => Path.combine(PathOperation.union, left, _mirror(left));

Path _sp(List<double> xy) => _pair(_smooth(xy));

Path _rect(double l, double t, double r, double b) =>
    Path()..addRect(Rect.fromLTRB(l, t, r, b));

Path _maskPair(Path left) => _pair(left);

Path _union(List<Path> paths) =>
    paths.reduce((a, b) => Path.combine(PathOperation.union, a, b));

class _Zone {
  final String muscle;
  final Path path;

  /// Muscle part id -> where it sits. Parts without an entry are not drawn on
  /// this side of the body.
  final Map<String, Path> masks;
  const _Zone(this.muscle, this.path, this.masks);
}

Path? _silhouetteCache;

/// The body outline, shared by both views.
Path _silhouette() => _silhouetteCache ??= _union([
  Path()..addOval(
    Rect.fromCenter(center: const Offset(50, 14), width: 16, height: 21),
  ),
  // neck
  _sp([45, 20, 51, 20, 51, 33, 44, 33, 43.5, 27]),
  // torso, with the trapezius slope into the shoulder
  _sp([
    51,
    28,
    45,
    30,
    35,
    33.5,
    26,
    36.5,
    21.5,
    42,
    21,
    50,
    24.5,
    57,
    27.5,
    66,
    29,
    80,
    29.5,
    94,
    30.5,
    106,
    30,
    116,
    33,
    125,
    42,
    129,
    51,
    130,
  ]),
  // upper arm
  _sp([
    22,
    40,
    17.5,
    46,
    14.5,
    58,
    13,
    72,
    13.5,
    86,
    16.5,
    92,
    21,
    90,
    23.5,
    78,
    25.5,
    64,
    27,
    50,
  ]),
  // forearm
  _sp([
    14,
    86,
    11,
    98,
    8.5,
    112,
    8,
    124,
    10.5,
    129,
    13.5,
    127,
    16,
    116,
    19,
    102,
    21,
    90,
  ]),
  // hand
  _sp([
    8.5,
    124,
    6,
    131,
    5.5,
    140,
    7.5,
    147,
    11,
    148.5,
    13.5,
    143,
    14,
    134,
    13.5,
    127,
  ]),
  // thigh
  _sp([
    31,
    106,
    28.5,
    120,
    28.5,
    138,
    31,
    154,
    34.5,
    166,
    41,
    169,
    46,
    164,
    48.5,
    150,
    49.5,
    134,
    50.2,
    124,
    46,
    119,
    39,
    114,
  ]),
  // lower leg
  _sp([
    34.5,
    162,
    32.5,
    174,
    33,
    188,
    36.5,
    203,
    41.5,
    206,
    44.5,
    196,
    46,
    182,
    45.5,
    168,
    43,
    162,
  ]),
  // foot
  _sp([37, 201, 35, 209, 37.5, 215, 44, 215.5, 47, 211, 45.5, 204, 42, 201]),
]);

List<_Zone>? _front;
List<_Zone>? _back;

List<_Zone> _zones(String view) =>
    view == 'back' ? (_back ??= _buildBack()) : (_front ??= _buildFront());

final _deltoid = <double>[
  33,
  34.5,
  26.5,
  36.5,
  21.5,
  42,
  20.5,
  50,
  22.5,
  57,
  26,
  55,
  28.5,
  47,
  31.5,
  39.5,
];
final _upperArm = <double>[
  23.5,
  57,
  19,
  63,
  17,
  73,
  17,
  83,
  19.5,
  88.5,
  23,
  84,
  25.5,
  73,
  26.5,
  62,
];
final _forearm = <double>[
  19,
  90,
  14.5,
  98,
  11.5,
  109,
  10.5,
  121,
  13,
  125,
  15.5,
  115,
  18.5,
  103,
  20.5,
  93,
];

List<_Zone> _buildFront() => [
  _Zone('traps', _sp([45.5, 30, 39, 32.5, 33.5, 35, 40, 36.5, 46, 34]), {
    'upper-traps': _rect(0, 0, 100, 100),
  }),
  _Zone('shoulders', _sp(_deltoid), {
    'front-delts': _maskPair(_rect(24, 28, 40, 60)),
    'side-delts': _maskPair(_rect(10, 28, 24, 60)),
  }),
  _Zone(
    'chest',
    _sp([
      49.5,
      40,
      42,
      37.5,
      33.5,
      39.5,
      29,
      46,
      29.5,
      54,
      34.5,
      60.5,
      42.5,
      62,
      49.5,
      59.5,
    ]),
    {
      'upper-chest': _maskPair(_rect(26, 34, 50, 46.5)),
      'mid-chest': _maskPair(_rect(26, 46.5, 50, 54)),
      'lower-chest': _maskPair(_rect(26, 54, 50, 64)),
    },
  ),
  _Zone('biceps', _sp(_upperArm), {
    'long-head': _maskPair(_rect(14, 55, 21.8, 92)),
    'short-head': _maskPair(_rect(21.8, 55, 30, 92)),
    'brachialis': _maskPair(_rect(14, 77, 30, 92)),
  }),
  _Zone('forearms', _sp(_forearm), {
    'flexors': _maskPair(_rect(6, 86, 24, 130)),
  }),
  _Zone(
    'core',
    _union([
      _sp([50.4, 63, 42, 64, 40.5, 76, 41.2, 90, 43, 102, 50.4, 109]),
      _sp([
        40,
        64.5,
        33.5,
        62.5,
        30.5,
        72,
        31,
        88,
        33.5,
        101,
        40.5,
        104,
        41.5,
        90,
        40,
        77,
      ]),
    ]),
    {
      'abs': _rect(40.8, 58, 59.2, 112),
      'obliques': _maskPair(_rect(28, 58, 40.8, 108)),
      'deep-core': _rect(38, 74, 62, 102),
    },
  ),
  _Zone(
    'hips',
    _union([
      _sp([50.2, 124, 45, 123, 41.5, 131, 43, 145, 47.5, 151, 49.8, 140]),
      _sp([33.5, 107, 30.2, 113, 29.8, 125, 32.5, 124, 35, 114]),
    ]),
    {
      'adductors': _maskPair(_rect(40, 118, 50, 154)),
      'abductors': _maskPair(_rect(26, 104, 37, 128)),
    },
  ),
  _Zone(
    'quads',
    _sp([
      36,
      117,
      31.5,
      129,
      31,
      145,
      34,
      159,
      39,
      165.5,
      44,
      163.5,
      45,
      152,
      43,
      138,
      41,
      128,
      40.5,
      120,
    ]),
    {
      'vasti': _maskPair(_rect(28, 112, 50, 170)),
      'rectus-femoris': _maskPair(
        Path()..addOval(Rect.fromLTRB(34.5, 113, 43, 160)),
      ),
    },
  ),
];

List<_Zone> _buildBack() => [
  _Zone(
    'back',
    _union([
      _sp([
        31,
        50,
        28.5,
        58,
        30,
        72,
        34,
        84,
        42,
        92,
        49.6,
        93,
        49.6,
        83,
        44.5,
        69,
        40,
        58,
        35.5,
        51.5,
      ]),
      _sp([49.6, 39, 41, 40, 34, 44, 33.5, 51.5, 40, 56, 49.6, 58.5]),
    ]),
    {
      'lats': _maskPair(_rect(26, 57, 50, 96)),
      'mid-back': _maskPair(_rect(31, 38, 50, 59)),
    },
  ),
  _Zone(
    'traps',
    _sp([
      50.5,
      25.5,
      45,
      29.5,
      36.5,
      33.5,
      31,
      36.5,
      38,
      39.5,
      44,
      49,
      47.5,
      60,
      50.5,
      65,
    ]),
    {
      'upper-traps': _rect(26, 20, 74, 41),
      'mid-lower-traps': _rect(26, 41, 74, 68),
    },
  ),
  _Zone('shoulders', _sp(_deltoid), {
    'rear-delts': _maskPair(_rect(18, 28, 40, 60)),
    'side-delts': _maskPair(_rect(10, 28, 22, 60)),
  }),
  _Zone(
    'triceps',
    _sp([
      23.5,
      56,
      18.5,
      62,
      16.5,
      74,
      17.5,
      85.5,
      21.5,
      89,
      24.5,
      81,
      26.5,
      69,
      26.5,
      60,
    ]),
    {
      'long-head': _maskPair(_rect(20.8, 54, 30, 92)),
      'lateral-medial': _maskPair(_rect(12, 54, 20.8, 92)),
    },
  ),
  _Zone('forearms', _sp(_forearm), {
    'extensors': _maskPair(_rect(6, 86, 24, 130)),
  }),
  _Zone(
    'lower-back',
    _sp([50.3, 88, 44.5, 90, 42.5, 100, 43.5, 110, 50.3, 112.5]),
    {'erectors': _rect(38, 84, 62, 116)},
  ),
  _Zone(
    'glutes',
    _union([
      _sp([
        50.2,
        110,
        42,
        108.5,
        35,
        112,
        32,
        120,
        34,
        130,
        41,
        134.5,
        48.5,
        132.5,
        50.2,
        125,
      ]),
      _sp([
        36,
        104.5,
        31,
        106.5,
        29.5,
        112.5,
        32.5,
        116.5,
        37.5,
        111,
        41.5,
        108,
      ]),
    ]),
    {
      'glute-max': _maskPair(_rect(31, 107.5, 50, 137)),
      'glute-med': _maskPair(_rect(27, 100, 42, 117)),
    },
  ),
  _Zone(
    'hips',
    _sp([31.2, 116.5, 29.2, 121, 29.8, 128, 32.6, 126, 32.6, 119]),
    {'abductors': _maskPair(_rect(26, 114, 34, 130))},
  ),
  _Zone(
    'hamstrings',
    _sp([
      33.5,
      136,
      31.5,
      148,
      33.5,
      159,
      38.5,
      165.5,
      45,
      163.5,
      47.5,
      152,
      47.5,
      140,
      44,
      134.5,
      38.5,
      134.5,
    ]),
    {
      'hinge': _maskPair(_rect(28, 130, 50, 168)),
      'curl': _maskPair(_rect(28, 130, 50, 168)),
    },
  ),
  _Zone(
    'calves',
    _sp([
      35,
      167.5,
      33,
      177,
      34.5,
      189,
      39,
      196,
      43.5,
      192,
      45.5,
      180,
      44.5,
      170,
      40,
      165.5,
    ]),
    {
      'gastrocnemius': _maskPair(_rect(30, 162, 48, 186)),
      'soleus': _maskPair(_rect(30, 182, 48, 200)),
    },
  ),
];

/// Thin definition lines that read as anatomy without being interactive.
Path _details(String view) {
  final p = Path();
  void line(List<double> xy, {bool mirror = true}) {
    final s = Path()..moveTo(xy[0], xy[1]);
    for (var i = 2; i < xy.length; i += 4) {
      s.quadraticBezierTo(xy[i], xy[i + 1], xy[i + 2], xy[i + 3]);
    }
    p.addPath(s, Offset.zero);
    if (mirror) p.addPath(_mirror(s), Offset.zero);
  }

  if (view == 'front') {
    line([50, 62, 50, 85, 50, 108], mirror: false); // linea alba
    for (final y in [74.0, 85.0, 96.0]) {
      line([41.5, y, 46, y + 1.2, 50, y]);
    }
    line([30, 52, 38, 58, 47, 56]); // under-pec curve
    line([22, 49, 24.5, 51, 27, 48]); // delt split
    line([39, 136, 40, 148, 41, 160]); // quad separation
    line([37, 170, 36, 184, 38.5, 198]); // shin
  } else {
    line([50, 64, 50, 88, 50, 110], mirror: false); // spine
    line([36, 44, 40, 50, 46, 53]); // scapula
    line([41, 141, 41.5, 152, 42, 162]); // hamstring split
    line([39.5, 172, 39.5, 182, 39.5, 192]); // calf split
  }
  return p;
}

// ------------------------------------------------------------------ painting

class _FigurePainter extends CustomPainter {
  final String view;
  final String muscleId;
  final String? regionId;
  final ExploreTokens tokens;
  final bool guides;
  final double reveal;

  _FigurePainter({
    required this.view,
    required this.muscleId,
    required this.regionId,
    required this.tokens,
    required this.guides,
    required this.reveal,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / _w;
    canvas.save();
    canvas.scale(scale, size.height / _h);

    final hair = 0.9 / scale; // ~0.9 logical px whatever the size
    final outline = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = hair * 1.1
      ..color = tokens.line;
    final thin = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = hair * 0.8
      ..color = tokens.line.withValues(alpha: 0.55);

    final body = _silhouette();
    canvas.drawPath(body, Paint()..color = tokens.body);

    Path? focus;
    for (final z in _zones(view)) {
      final selected = z.muscle == muscleId;
      canvas.drawPath(z.path, Paint()..color = tokens.muscle);
      if (selected) {
        final mask = regionId == null ? null : z.masks[regionId];
        final part = mask == null
            ? z.path
            : Path.combine(PathOperation.intersect, z.path, mask);
        // The rest of the muscle in a quiet tint.
        if (mask != null) {
          canvas.drawPath(
            z.path,
            Paint()..color = tokens.accent.withValues(alpha: 0.16),
          );
        }
        focus = focus == null
            ? part
            : Path.combine(PathOperation.union, focus, part);
      }
      canvas.drawPath(z.path, thin);
    }
    canvas.drawPath(_details(view), thin);
    canvas.drawPath(body, outline);

    if (focus != null) {
      final bounds = focus.getBounds();
      final a = reveal;
      // Soft glow, then a lit gradient fill.
      canvas.drawPath(
        focus,
        Paint()
          ..color = tokens.accent.withValues(alpha: 0.55 * a)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 4 / scale),
      );
      canvas.drawPath(
        focus,
        Paint()
          ..shader = ui.Gradient.radial(
            bounds.center,
            math.max(bounds.width, bounds.height) * 0.75,
            [
              Color.lerp(
                tokens.accent,
                Colors.white,
                0.25,
              )!.withValues(alpha: a),
              tokens.accentDeep.withValues(alpha: a),
            ],
          ),
      );
      canvas.drawPath(
        focus,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = hair
          ..color = Colors.white.withValues(alpha: 0.35 * a),
      );
      canvas.restore();
      // Aim at the figure's left-hand part when the highlight is a pair.
      final left = Path.combine(
        PathOperation.intersect,
        focus,
        _rect(0, 0, 50.5, _h),
      ).getBounds();
      final aim = left.isEmpty || left.right >= 49.5 ? bounds : left;
      if (guides) _crosshair(canvas, size, aim, scale, size.height / _h, a);
      return;
    }
    canvas.restore();
  }

  /// Dashed guides through the highlighted part and a small target ring.
  void _crosshair(
    Canvas canvas,
    Size size,
    Rect unitBounds,
    double sx,
    double sy,
    double a,
  ) {
    final target = Offset(unitBounds.center.dx * sx, unitBounds.center.dy * sy);
    final dash = Paint()
      ..color = tokens.line.withValues(alpha: 0.8 * a)
      ..strokeWidth = 1;
    void dashed(Offset from, Offset to) {
      final d = to - from;
      final len = d.distance;
      final dir = d / len;
      for (double s = 0; s < len; s += 7) {
        canvas.drawLine(
          from + dir * s,
          from + dir * math.min(s + 3.5, len),
          dash,
        );
      }
    }

    dashed(Offset(0, target.dy), Offset(size.width, target.dy));
    dashed(Offset(target.dx, 0), Offset(target.dx, size.height));
    canvas.drawCircle(
      target,
      6,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..color = Colors.white.withValues(alpha: 0.9 * a),
    );
    canvas.drawCircle(
      target,
      2,
      Paint()..color = Colors.white.withValues(alpha: a),
    );
  }

  @override
  bool shouldRepaint(_FigurePainter old) =>
      old.view != view ||
      old.muscleId != muscleId ||
      old.regionId != regionId ||
      old.reveal != reveal ||
      old.tokens.accent != tokens.accent ||
      old.tokens.body != tokens.body;
}
