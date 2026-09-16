import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/native.dart';
import 'package:fitness_tracker/app.dart';
import 'package:fitness_tracker/main.dart';
import 'package:fitness_tracker/data/database/app_database.dart';

void main() {
  testWidgets('HomeScreen renders welcome banner and navigation cards', (WidgetTester tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(() => db.close());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
        ],
        child: const FitnessTrackerApp(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Verify Title & Banner
    expect(find.text('Fitness Tracker'), findsOneWidget);
    expect(find.text('Fucked From The Start'), findsOneWidget);
    expect(find.text('Start Workout'), findsOneWidget);

    // Verify Quick Action Items
    expect(find.text('Log Food Photo'), findsOneWidget);
    expect(find.text('Browse Workout Program'), findsOneWidget);
  });
}
