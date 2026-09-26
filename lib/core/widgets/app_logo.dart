import 'package:flutter/material.dart';

/// The app logo, drawn from the same 128x128 vector as the launcher icon
/// (`ic_launcher_brand.xml`): a light dumbbell mark on a black tile.
class AppLogo extends StatelessWidget {
  final double size;

  const AppLogo({super.key, required this.size});

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(size * 0.22),
    child: CustomPaint(size: Size.square(size), painter: _LogoPainter()),
  );
}

class _LogoPainter extends CustomPainter {
  static const _points = [
    Offset(18, 52),
    Offset(32, 52),
    Offset(32, 38),
    Offset(44, 38),
    Offset(44, 52),
    Offset(56, 52),
    Offset(56, 38),
    Offset(68, 38),
    Offset(68, 52),
    Offset(80, 52),
    Offset(80, 38),
    Offset(92, 38),
    Offset(92, 52),
    Offset(106, 52),
    Offset(106, 76),
    Offset(92, 76),
    Offset(92, 90),
    Offset(80, 90),
    Offset(80, 76),
    Offset(68, 76),
    Offset(68, 90),
    Offset(56, 90),
    Offset(56, 76),
    Offset(44, 76),
    Offset(44, 90),
    Offset(32, 90),
    Offset(32, 76),
    Offset(18, 76),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = Colors.black);
    canvas.scale(size.width / 128, size.height / 128);
    canvas.drawPath(
      Path()..addPolygon(_points, true),
      Paint()..color = const Color(0xFFEDEDED),
    );
  }

  @override
  bool shouldRepaint(_LogoPainter oldDelegate) => false;
}
