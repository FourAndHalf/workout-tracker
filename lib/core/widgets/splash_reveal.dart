import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Shows the app icon centered on the canvas, then enlarges and fades it away
/// to reveal [child].
class SplashReveal extends StatefulWidget {
  final Widget child;

  const SplashReveal({super.key, required this.child});

  @override
  State<SplashReveal> createState() => _SplashRevealState();
}

class _SplashRevealState extends State<SplashReveal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..forward();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            if (_controller.isCompleted) return const SizedBox.shrink();
            final t = Curves.easeIn.transform(_controller.value);
            return IgnorePointer(
              child: Opacity(
                opacity: 1 - t,
                child: ColoredBox(
                  color: context.colors.background,
                  child: Center(
                    child: Transform.scale(
                      scale: 1 + 3 * t,
                      child: const AppLogo(size: 120),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

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
