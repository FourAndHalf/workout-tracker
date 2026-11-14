import 'package:flutter/material.dart';

import 'app_logo.dart';

/// Startup animation: the logo pops out from the center (a quick overshoot
/// scale-in), holds briefly, then fades away on a black backdrop to reveal
/// [child]. Runs once per cold start, right after the native splash hands
/// off to the Flutter engine.
class SplashReveal extends StatefulWidget {
  final Widget child;

  const SplashReveal({super.key, required this.child});

  @override
  State<SplashReveal> createState() => _SplashRevealState();
}

class _SplashRevealState extends State<SplashReveal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _logoOpacity;
  late final Animation<double> _fadeOut;

  static const _popEnd = 0.45; // pop-out finishes at 45% of the timeline
  static const _holdEnd = 0.65; // brief hold before fading
  // fade-out runs from _holdEnd to 1.0

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _scale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(
          begin: 0.0,
          end: 1.15,
        ).chain(CurveTween(curve: Curves.easeOutBack)),
        weight: _popEnd,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.15,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: _holdEnd - _popEnd,
      ),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 1 - _holdEnd),
    ]).animate(_controller);

    _logoOpacity = CurvedAnimation(
      parent: _controller,
      curve: Interval(0, _popEnd * 0.6, curve: Curves.easeOut),
    );

    _fadeOut = CurvedAnimation(
      parent: _controller,
      curve: Interval(_holdEnd, 1.0, curve: Curves.easeIn),
    );

    _controller.forward();
  }

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
          builder: (context, child) {
            if (_controller.isCompleted) return const SizedBox.shrink();
            return IgnorePointer(
              child: Opacity(
                opacity: 1 - _fadeOut.value,
                child: ColoredBox(
                  color: Colors.black,
                  child: Center(
                    child: Opacity(
                      opacity: _logoOpacity.value,
                      child: Transform.scale(scale: _scale.value, child: child),
                    ),
                  ),
                ),
              ),
            );
          },
          child: const AppLogo(size: 120),
        ),
      ],
    );
  }
}
