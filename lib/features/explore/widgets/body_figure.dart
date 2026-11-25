import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:path_drawing/path_drawing.dart';

import 'anatomy_paths.g.dart';
import 'explore_style.dart';

/// A front/back anatomy figure with tappable muscle groups.
///
/// The body outline and muscle shapes come from react-native-body-highlighter
/// (MIT, © 2022 ELABBASSI Hicham; see `anatomy_paths.g.dart`). This widget
/// maps those shapes onto the app's muscle groups and their parts, and draws
/// the selection: a coral highlight with a soft glow, dashed crosshair guides,
/// a target ring, a scan sweep when a view first shows, and a glide
/// between selections (see [_FigureCanvas]).
class BodyFigure extends StatelessWidget {
  final String muscleId;
  final String? regionId;

  /// `front` or `back`.
  final String view;
  final ValueChanged<String> onSelectMuscle;

  /// Draws the crosshair, ring and scan sweep.
  final bool guides;

  const BodyFigure({
    super.key,
    required this.muscleId,
    required this.regionId,
    required this.view,
    required this.onSelectMuscle,
    this.guides = true,
  });

  /// The side of the body a muscle (or one of its parts) is drawn on. A
  /// muscle that shows on both sides prefers the side it's mostly seen from.
  static String? viewFor(String muscleId, String? regionId) {
    final preferred = _preferBack.contains(muscleId)
        ? const ['back', 'front']
        : const ['front', 'back'];
    for (final side in preferred) {
      for (final zone in _zones(side)) {
        if (zone.muscle != muscleId) continue;
        if (regionId == null || zone.regions.containsKey(regionId)) {
          return side;
        }
      }
    }
    return null;
  }

  /// The muscle group at [point], in the view's own coordinates
  /// (see [viewport]).
  @visibleForTesting
  static String? hitTest(String view, Offset point) {
    for (final zone in _zones(view).reversed) {
      if (zone.path.contains(point)) return zone.muscle;
    }
    return null;
  }

  /// The part of the view's coordinate space the figure shows.
  static Rect viewport(String view) => view == 'back' ? _backBox : _frontBox;

  @override
  Widget build(BuildContext context) {
    final tokens = ExploreTokens.of(context);
    final box = viewport(view);
    return AspectRatio(
      aspectRatio: box.width / box.height,
      child: LayoutBuilder(
        builder: (context, constraints) => GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapUp: (details) {
            final point = Offset(
              box.left +
                  details.localPosition.dx / constraints.maxWidth * box.width,
              box.top +
                  details.localPosition.dy / constraints.maxHeight * box.height,
            );
            final hit = hitTest(view, point);
            if (hit != null) onSelectMuscle(hit);
          },
          child: Semantics(
            label:
                '${view == 'front' ? 'Front' : 'Back'} view, $muscleId highlighted',
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 320),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              layoutBuilder: (current, previous) => Stack(
                fit: StackFit.expand,
                children: [...previous, ?current],
              ),
              child: _FigureCanvas(
                key: ValueKey(view),
                view: view,
                muscleId: muscleId,
                regionId: regionId,
                tokens: tokens,
                guides: guides,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Paints one view and animates between selections on it: the first
/// selection lands with a scan sweep; later ones glide, the old highlight
/// fading out while the target slides to the new part.
class _FigureCanvas extends StatefulWidget {
  final String view;
  final String muscleId;
  final String? regionId;
  final ExploreTokens tokens;
  final bool guides;

  const _FigureCanvas({
    super.key,
    required this.view,
    required this.muscleId,
    required this.regionId,
    required this.tokens,
    required this.guides,
  });

  @override
  State<_FigureCanvas> createState() => _FigureCanvasState();
}

class _FigureCanvasState extends State<_FigureCanvas>
    with SingleTickerProviderStateMixin {
  static const _enter = Duration(milliseconds: 900);
  static const _glide = Duration(milliseconds: 480);

  late final _ctrl = AnimationController(vsync: this, duration: _enter)
    ..forward();
  bool _entering = true;
  String? _fromMuscle;
  String? _fromRegion;
  Offset? _fromAim;

  @override
  void didUpdateWidget(_FigureCanvas old) {
    super.didUpdateWidget(old);
    if (old.muscleId == widget.muscleId && old.regionId == widget.regionId) {
      return;
    }
    // Start the glide from wherever the target is right now, so a change
    // made mid-animation never jumps.
    final e = _eased;
    final aimFrom = _entering ? null : _fromAim;
    final aimTo = _aimFor(widget.view, old.muscleId, old.regionId);
    _fromAim = aimFrom != null && aimTo != null
        ? Offset.lerp(aimFrom, aimTo, e)
        : aimTo;
    _fromMuscle = old.muscleId;
    _fromRegion = old.regionId;
    _entering = false;
    _ctrl
      ..duration = _glide
      ..forward(from: 0);
  }

  double get _eased =>
      _entering ? _ctrl.value : Curves.easeInOutCubic.transform(_ctrl.value);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _ctrl,
    builder: (context, _) => CustomPaint(
      painter: _FigurePainter(
        view: widget.view,
        muscleId: widget.muscleId,
        regionId: widget.regionId,
        fromMuscle: _entering ? null : _fromMuscle,
        fromRegion: _fromRegion,
        fromAim: _entering ? null : _fromAim,
        entering: _entering,
        tokens: widget.tokens,
        guides: widget.guides,
        t: _eased,
      ),
    ),
  );
}

/// Where the target sits for a selection: the selected part, or the
/// figure's left-hand one when the part is a pair.
Offset? _aimFor(String view, String muscleId, String? regionId) {
  final focus = _focusFor(view, muscleId, regionId);
  if (focus == null) return null;
  return _aimCache.putIfAbsent('$view/$muscleId/$regionId', () {
    final box = BodyFigure.viewport(view);
    final bounds = focus.getBounds();
    final left = Path.combine(
      PathOperation.intersect,
      focus,
      Path()..addRect(
        Rect.fromLTRB(box.left, box.top, box.center.dx + 4, box.bottom),
      ),
    ).getBounds();
    return (left.isEmpty || left.right >= box.center.dx - 4)
        ? bounds.center
        : left.center;
  });
}

final _aimCache = <String, Offset>{};

/// The zone of [muscleId] on [view] and the path of the selected part.
({Path zone, Path focus})? _selection(
  String view,
  String muscleId,
  String? regionId,
) {
  final zone = _zones(view).where((z) => z.muscle == muscleId).firstOrNull;
  if (zone == null) return null;
  return (
    zone: zone.path,
    focus: (regionId == null ? null : zone.regions[regionId]) ?? zone.path,
  );
}

Path? _focusFor(String view, String muscleId, String? regionId) =>
    _selection(view, muscleId, regionId)?.focus;

// ------------------------------------------------------------------ geometry

/// What the figure shows of each 724 x 1448 view, with a little margin.
const _frontBox = Rect.fromLTRB(20, 84, 704, 1372);
const _backBox = Rect.fromLTRB(744, 84, 1428, 1372);

/// Muscles drawn on both sides that are mostly seen from behind.
const _preferBack = {
  'triceps',
  'calves',
  'hamstrings',
  'glutes',
  'back',
  'traps',
  'lower-back',
};

/// Shapes that are body, not trainable muscle: drawn, never tappable.
const _bodyOnly = {
  'neck',
  'knees',
  'hands',
  'ankles',
  'feet',
  'head',
  'hair',
  'tibialis',
};

final _shapeCache = <String, Map<String, Path>>{};

/// Parsed SVG paths for every slug of a view.
Map<String, Path> _shapes(String view) => _shapeCache.putIfAbsent(view, () {
  final out = <String, Path>{};
  anatomyMuscles[view]!.forEach((slug, paths) {
    final path = Path();
    for (final d in paths) {
      path.addPath(parseSvgPathData(d), Offset.zero);
    }
    out[slug] = path;
  });
  return out;
});

final _outlineCache = <String, Path>{};
Path _outline(String view) => _outlineCache.putIfAbsent(
  view,
  () => parseSvgPathData(anatomyOutline[view]!),
);

Path _rects(List<Rect> rects, {bool oval = false}) {
  final p = Path();
  for (final r in rects) {
    oval ? p.addOval(r) : p.addRect(r);
  }
  return p;
}

Path _union(Iterable<Path> paths) {
  Path? out;
  for (final p in paths) {
    out = out == null ? p : Path.combine(PathOperation.union, out, p);
  }
  return out ?? Path();
}

/// One part of a muscle: some of its shapes, optionally cut to some areas.
class _Part {
  /// Shapes the part covers; empty means all of the zone's shapes.
  final Set<String> slugs;
  final List<Rect>? within;

  /// Treat [within] as ovals, for a soft-edged cut down a muscle.
  final bool oval;
  const _Part({this.slugs = const {}, this.within, this.oval = false});
}

/// A muscle group on one view: the shapes it owns and where its parts are.
class _ZoneSpec {
  final String muscle;
  final List<String> slugs;

  /// Keep only these areas of the shapes (the outer hip of the gluteal).
  final List<Rect>? within;
  final Map<String, _Part> regions;
  const _ZoneSpec(this.muscle, this.slugs, this.regions, {this.within});
}

class _Zone {
  final String muscle;
  final Path path;
  final Map<String, Path> regions;
  const _Zone(this.muscle, this.path, this.regions);
}

const _all = _Part();
const double _w = 724;

// Rects are in each view's own coordinates. Front: x 0-724. Back: x 724-1448.
const _frontSpecs = [
  _ZoneSpec('traps', ['trapezius'], {'upper-traps': _all}),
  _ZoneSpec(
    'shoulders',
    ['deltoids'],
    {
      'front-delts': _Part(within: [Rect.fromLTRB(222, 280, 514, 410)]),
      'side-delts': _Part(
        within: [
          Rect.fromLTRB(0, 280, 222, 410),
          Rect.fromLTRB(514, 280, _w, 410),
        ],
      ),
    },
  ),
  _ZoneSpec(
    'chest',
    ['chest'],
    {
      'upper-chest': _Part(within: [Rect.fromLTRB(0, 300, _w, 360)]),
      'mid-chest': _Part(within: [Rect.fromLTRB(0, 360, _w, 400)]),
      'lower-chest': _Part(within: [Rect.fromLTRB(0, 400, _w, 450)]),
    },
  ),
  _ZoneSpec(
    'biceps',
    ['biceps'],
    {
      'long-head': _Part(
        within: [
          Rect.fromLTRB(0, 380, 202, 520),
          Rect.fromLTRB(526, 380, _w, 520),
        ],
      ),
      'short-head': _Part(within: [Rect.fromLTRB(202, 380, 526, 520)]),
      'brachialis': _Part(within: [Rect.fromLTRB(0, 462, _w, 520)]),
    },
  ),
  _ZoneSpec('triceps', ['triceps'], {'lateral-medial': _all}),
  _ZoneSpec('forearms', ['forearm'], {'flexors': _all}),
  _ZoneSpec(
    'core',
    ['abs', 'obliques'],
    {
      'abs': _Part(slugs: {'abs'}),
      'obliques': _Part(slugs: {'obliques'}),
      'deep-core': _Part(
        slugs: {'abs'},
        within: [Rect.fromLTRB(0, 520, _w, 720)],
      ),
    },
  ),
  _ZoneSpec('hips', ['adductors'], {'adductors': _all}),
  _ZoneSpec(
    'quads',
    ['quadriceps'],
    {
      'vasti': _all,
      'rectus-femoris': _Part(
        oval: true,
        within: [
          Rect.fromLTRB(262, 680, 308, 950),
          Rect.fromLTRB(420, 680, 466, 950),
        ],
      ),
    },
  ),
  _ZoneSpec(
    'calves',
    ['calves'],
    {
      'gastrocnemius': _Part(within: [Rect.fromLTRB(0, 1000, _w, 1125)]),
      'soleus': _Part(within: [Rect.fromLTRB(0, 1110, _w, 1240)]),
    },
  ),
];

const _backSpecs = [
  // The outer hip (glute medius / TFL) is the top-outer corner of the
  // gluteal shape. Listed before glutes so a tap there still picks glutes.
  _ZoneSpec(
    'hips',
    ['gluteal', 'adductors'],
    {
      'abductors': _Part(slugs: {'gluteal'}),
      'adductors': _Part(slugs: {'adductors'}),
    },
    within: [
      Rect.fromLTRB(960, 600, 1012, 720),
      Rect.fromLTRB(1162, 600, 1210, 720),
      Rect.fromLTRB(1030, 775, 1140, 870),
    ],
  ),
  _ZoneSpec(
    'glutes',
    ['gluteal'],
    {
      'glute-max': _Part(within: [Rect.fromLTRB(724, 662, 1448, 790)]),
      'glute-med': _Part(within: [Rect.fromLTRB(724, 600, 1448, 676)]),
    },
  ),
  _ZoneSpec(
    'back',
    ['upper-back'],
    {
      'lats': _Part(within: [Rect.fromLTRB(724, 430, 1448, 600)]),
      'mid-back': _Part(within: [Rect.fromLTRB(724, 315, 1448, 446)]),
    },
  ),
  _ZoneSpec(
    'traps',
    ['trapezius'],
    {
      'upper-traps': _Part(within: [Rect.fromLTRB(724, 280, 1448, 362)]),
      'mid-lower-traps': _Part(within: [Rect.fromLTRB(724, 362, 1448, 480)]),
    },
  ),
  _ZoneSpec(
    'shoulders',
    ['deltoids'],
    {
      'rear-delts': _all,
      'side-delts': _Part(
        within: [
          Rect.fromLTRB(724, 300, 934, 410),
          Rect.fromLTRB(1233, 300, 1448, 410),
        ],
      ),
    },
  ),
  _ZoneSpec(
    'triceps',
    ['triceps'],
    {
      'long-head': _Part(within: [Rect.fromLTRB(930, 370, 1237, 545)]),
      'lateral-medial': _Part(
        within: [
          Rect.fromLTRB(724, 370, 930, 545),
          Rect.fromLTRB(1237, 370, 1448, 545),
        ],
      ),
    },
  ),
  _ZoneSpec('forearms', ['forearm'], {'extensors': _all}),
  _ZoneSpec('lower-back', ['lower-back'], {'erectors': _all}),
  _ZoneSpec('hamstrings', ['hamstring'], {'hinge': _all, 'curl': _all}),
  _ZoneSpec(
    'calves',
    ['calves'],
    {
      'gastrocnemius': _Part(within: [Rect.fromLTRB(724, 960, 1448, 1125)]),
      'soleus': _Part(within: [Rect.fromLTRB(724, 1110, 1448, 1300)]),
    },
  ),
];

final _zoneCache = <String, List<_Zone>>{};

List<_Zone> _zones(String view) => _zoneCache.putIfAbsent(view, () {
  final shapes = _shapes(view);
  final specs = view == 'back' ? _backSpecs : _frontSpecs;
  return [
    for (final spec in specs)
      () {
        Path shapeOf(Iterable<String> slugs) {
          final p = _union(slugs.map((s) => shapes[s]!));
          return spec.within == null
              ? p
              : Path.combine(PathOperation.intersect, p, _rects(spec.within!));
        }

        final whole = shapeOf(spec.slugs);
        return _Zone(spec.muscle, whole, {
          for (final entry in spec.regions.entries)
            entry.key: () {
              final part = entry.value;
              var p = part.slugs.isEmpty ? whole : shapeOf(part.slugs);
              if (part.within != null) {
                p = Path.combine(
                  PathOperation.intersect,
                  p,
                  _rects(part.within!, oval: part.oval),
                );
              }
              return p;
            }(),
        });
      }(),
  ];
});

// ------------------------------------------------------------------ painting

class _FigurePainter extends CustomPainter {
  final String view;
  final String muscleId;
  final String? regionId;

  /// The previous selection while gliding to this one; null on entry.
  final String? fromMuscle;
  final String? fromRegion;
  final Offset? fromAim;

  /// True for the first selection on this view (scan sweep and ring settle).
  final bool entering;
  final ExploreTokens tokens;
  final bool guides;

  /// 0 → 1: the reveal on entry, or the eased glide between selections.
  final double t;

  _FigurePainter({
    required this.view,
    required this.muscleId,
    required this.regionId,
    required this.fromMuscle,
    required this.fromRegion,
    required this.fromAim,
    required this.entering,
    required this.tokens,
    required this.guides,
    required this.t,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final box = BodyFigure.viewport(view);
    final scale = size.width / box.width;
    canvas.save();
    // Nothing (glow, guides, scan) may spill outside the figure's box.
    canvas.clipRect(Offset.zero & size);
    canvas.scale(scale, size.height / box.height);
    canvas.translate(-box.left, -box.top);

    final px = 1 / scale; // one logical pixel in view units
    final shapes = _shapes(view);
    final outline = _outline(view);

    // Body and muscles: dark slate shapes whose gaps read as anatomy lines.
    canvas.drawPath(outline, Paint()..color = tokens.body);
    final musclePaint = Paint()..color = tokens.muscle;
    final seam = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.7 * px
      ..color = tokens.line.withValues(alpha: 0.45);
    shapes.forEach((slug, path) {
      canvas.drawPath(
        path,
        _bodyOnly.contains(slug)
            ? (Paint()..color = Color.lerp(tokens.body, tokens.muscle, 0.5)!)
            : musclePaint,
      );
      canvas.drawPath(path, seam);
    });
    canvas.drawPath(
      outline,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.1 * px
        ..color = tokens.line,
    );

    // The selection: on entry it fades in; between selections the old
    // highlight fades out as the new one fades in.
    final to = _selection(view, muscleId, regionId);
    final from = fromMuscle == null
        ? null
        : _selection(view, fromMuscle!, fromRegion);
    final fade = entering
        ? Curves.easeOutCubic.transform((t * 2.2).clamp(0.0, 1.0))
        : t;
    if (from != null) {
      // A shared muscle tint stays put while only the part changes.
      final sameZone = identical(from.zone, to?.zone);
      _highlight(canvas, from, px, 1 - fade, tint: sameZone ? 0 : 1 - fade);
    }
    if (to != null) {
      final sameZone = from != null && identical(from.zone, to.zone);
      _highlight(canvas, to, px, fade, tint: sameZone ? 1 : fade);
    }

    if (guides && to != null) {
      final target = _aimFor(view, muscleId, regionId)!;
      final aim = fromAim == null ? target : Offset.lerp(fromAim, target, t)!;
      _guides(canvas, box, aim, px);
      if (entering) _scan(canvas, box, px);
    }
    canvas.restore();
  }

  void _highlight(
    Canvas canvas,
    ({Path zone, Path focus}) sel,
    double px,
    double alpha, {
    required double tint,
  }) {
    final focus = sel.focus;
    if (!identical(focus, sel.zone) && tint > 0) {
      canvas.drawPath(
        sel.zone,
        Paint()..color = tokens.accent.withValues(alpha: 0.18 * tint),
      );
    }
    if (alpha <= 0) return;
    final bounds = focus.getBounds();
    canvas.drawPath(
      focus,
      Paint()
        ..color = tokens.accent.withValues(alpha: 0.6 * alpha)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 6 * px),
    );
    canvas.drawPath(
      focus,
      Paint()
        ..shader = ui.Gradient.radial(
          bounds.center,
          math.max(bounds.width, bounds.height) * 0.7,
          [
            Color.lerp(
              tokens.accent,
              Colors.white,
              0.28,
            )!.withValues(alpha: alpha),
            tokens.accentDeep.withValues(alpha: alpha),
          ],
        ),
    );
    canvas.drawPath(
      focus,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8 * px
        ..color = Colors.white.withValues(alpha: 0.3 * alpha),
    );
  }

  void _guides(Canvas canvas, Rect box, Offset aim, double px) {
    final a = entering
        ? Curves.easeOut.transform((t * 1.6).clamp(0.0, 1.0))
        : 1.0;
    // Soft hot spot behind the target.
    const hot = 90.0; // view units, about a muscle's width
    canvas.drawCircle(
      aim,
      hot,
      Paint()
        ..shader = ui.Gradient.radial(aim, hot, [
          tokens.accent.withValues(alpha: 0.22 * a),
          tokens.accent.withValues(alpha: 0),
        ]),
    );
    // Dashed crosshair across the whole figure.
    final dash = Paint()
      ..color = tokens.line.withValues(alpha: 0.85 * a)
      ..strokeWidth = px;
    void dashed(Offset from, Offset to) {
      final d = to - from;
      final len = d.distance;
      final dir = d / len;
      for (double s = 0; s < len; s += 8 * px) {
        canvas.drawLine(
          from + dir * s,
          from + dir * math.min(s + 4 * px, len),
          dash,
        );
      }
    }

    dashed(Offset(box.left, aim.dy), Offset(box.right, aim.dy));
    dashed(Offset(aim.dx, box.top), Offset(aim.dx, box.bottom));

    // Target: an outer ring that settles in, a rotating dashed inner ring and
    // a dot.
    // While gliding the ring pulses once, tightening as it lands.
    final settle = entering
        ? Curves.easeOutBack.transform(a)
        : 1 - 0.5 * math.sin(t * math.pi);
    canvas.drawCircle(
      aim,
      (12 - 4 * settle) * px * 1.6,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2 * px
        ..color = Colors.white.withValues(alpha: 0.9 * a),
    );
    final inner = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4 * px
      ..strokeCap = StrokeCap.round
      ..color = Colors.white.withValues(alpha: a);
    final r = 7 * px * 1.6;
    final spin = t * math.pi * 1.5;
    for (var i = 0; i < 3; i++) {
      canvas.drawArc(
        Rect.fromCircle(center: aim, radius: r),
        spin + i * (2 * math.pi / 3),
        math.pi / 3,
        false,
        inner,
      );
    }
    canvas.drawCircle(
      aim,
      2.2 * px * 1.6,
      Paint()..color = Colors.white.withValues(alpha: a),
    );
  }

  /// One sweep from top to bottom as the selection lands.
  void _scan(Canvas canvas, Rect box, double px) {
    if (t <= 0 || t >= 1) return;
    final y = box.top + box.height * Curves.easeInOutCubic.transform(t);
    final alpha = math.sin(t * math.pi);
    final band = 90 * px * 2;
    canvas.save();
    canvas.clipPath(_outline(view));
    canvas.drawRect(
      Rect.fromLTRB(box.left, y - band, box.right, y),
      Paint()
        ..shader = ui.Gradient.linear(Offset(0, y - band), Offset(0, y), [
          tokens.accent.withValues(alpha: 0),
          tokens.accent.withValues(alpha: 0.28 * alpha),
        ]),
    );
    canvas.drawRect(
      Rect.fromLTRB(box.left, y - 1.5 * px, box.right, y + 1.5 * px),
      Paint()
        ..color = Color.lerp(
          tokens.accent,
          Colors.white,
          0.55,
        )!.withValues(alpha: 0.9 * alpha),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_FigurePainter old) =>
      old.view != view ||
      old.fromMuscle != fromMuscle ||
      old.fromRegion != fromRegion ||
      old.fromAim != fromAim ||
      old.entering != entering ||
      old.muscleId != muscleId ||
      old.regionId != regionId ||
      old.t != t ||
      old.guides != guides ||
      old.tokens.accent != tokens.accent ||
      old.tokens.body != tokens.body;
}
