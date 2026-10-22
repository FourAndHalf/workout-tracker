import 'package:flutter/material.dart';

/// The app logo: the same mark bitmap used for the native Android splash
/// (`assets/icon/splash_logo.png`, derived from `assets/icon/app_icon.png`
/// by `assets/icon/generate_icon.py`), on a black tile.
class AppLogo extends StatelessWidget {
  final double size;

  const AppLogo({super.key, required this.size});

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(size * 0.22),
    child: Container(
      width: size,
      height: size,
      color: Colors.black,
      padding: EdgeInsets.all(size * 0.125),
      child: Image.asset('assets/icon/splash_logo.png', fit: BoxFit.contain),
    ),
  );
}
