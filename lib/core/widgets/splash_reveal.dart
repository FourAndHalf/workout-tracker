import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'app_logo.dart';

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
