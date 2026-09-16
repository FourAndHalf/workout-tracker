import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fitness_tracker/data/repositories/progress_repository.dart';

void main() {
  test(
    'stores one check-in per calendar week and returns newest first',
    () async {
      SharedPreferences.setMockInitialValues({});
      final repository = ProgressRepository(
        await SharedPreferences.getInstance(),
      );

      await repository.saveCheckIn(
        ProgressCheckIn(
          date: DateTime(2026, 9, 14),
          weightKg: 80,
          fatPercent: 18,
        ),
      );
      await repository.saveCheckIn(
        ProgressCheckIn(
          date: DateTime(2026, 9, 16),
          weightKg: 79.5,
          fatPercent: 17.5,
          photoPath: '/tmp/check-in.jpg',
        ),
      );
      await repository.saveCheckIn(
        ProgressCheckIn(
          date: DateTime(2026, 9, 21),
          weightKg: 79,
          fatPercent: 17,
        ),
      );

      final entries = await repository.getCheckIns();
      expect(entries, hasLength(2));
      expect(entries.first.weightKg, 79);
      expect(entries.last.weightKg, 79.5);
      expect(entries.last.photoPath, '/tmp/check-in.jpg');
    },
  );
}
