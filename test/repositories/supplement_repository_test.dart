import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fitness_tracker/data/repositories/supplement_repository.dart';

void main() {
  test('adds and removes supplements with photos', () async {
    SharedPreferences.setMockInitialValues({});
    final repository = SupplementRepository(
      await SharedPreferences.getInstance(),
    );
    const supplement = SupplementItem(
      id: 'creatine',
      name: 'Creatine',
      photoPath: '/tmp/creatine.jpg',
    );

    await repository.saveSupplement(supplement);
    expect(
      (await repository.getSupplements()).single.photoPath,
      '/tmp/creatine.jpg',
    );

    await repository.deleteSupplement('creatine');
    expect(await repository.getSupplements(), isEmpty);
  });

  test('stores notes per calendar day', () async {
    SharedPreferences.setMockInitialValues({});
    final repository = SupplementRepository(
      await SharedPreferences.getInstance(),
    );
    final date = DateTime(2026, 9, 16);

    await repository.saveNote(date, 'Protein stock ran out');
    expect(await repository.getNote(date), 'Protein stock ran out');
    expect(
      await repository.getNote(date.add(const Duration(days: 1))),
      isEmpty,
    );

    await repository.saveNote(date, '');
    expect(await repository.getNote(date), isEmpty);
  });
}
