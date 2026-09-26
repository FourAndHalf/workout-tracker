import 'package:fitness_tracker/core/widgets/app_logo.dart';
import 'package:fitness_tracker/core/theme/app_theme.dart';
import 'package:fitness_tracker/core/widgets/splash_reveal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows the icon over the child, then removes it', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: const SplashReveal(child: Text('home')),
      ),
    );
    expect(find.byType(AppLogo), findsOneWidget);
    expect(find.text('home'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 1200));
    expect(find.byType(AppLogo), findsNothing);
    expect(find.text('home'), findsOneWidget);
  });
}
