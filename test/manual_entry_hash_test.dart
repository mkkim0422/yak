import 'package:flutter_test/flutter_test.dart';

import 'package:alyak/core/data/models/product_model.dart';
import 'package:alyak/core/services/manual_entry_hash.dart';
import 'package:alyak/features/family/models/family_member.dart';

ManualProductEntry _e({
  String name = 'Now D3 5000IU',
  String? brand = 'Now Foods',
  String category = 'vitamin_d',
  IntakeTiming timing = IntakeTiming.morningAfter,
  int dosePerIntake = 1,
  int intakesPerDay = 1,
  int packageSize = 60,
}) =>
    ManualProductEntry(
      id: 'm_${DateTime.now().microsecondsSinceEpoch}',
      name: name,
      brand: brand,
      category: category,
      dailyDose: dosePerIntake * intakesPerDay,
      packageSize: packageSize,
      ingredients: const {},
      startedAt: DateTime(2026, 5, 6),
      intakeTiming: timing,
      dosePerIntake: dosePerIntake,
      intakesPerDay: intakesPerDay,
    );

void main() {
  group('manualEntryHash — identity join key for Phase 4 backend', () {
    test('same product fields → same hash', () {
      final a = _e();
      final b = _e();
      expect(manualEntryHash(a), manualEntryHash(b));
    });

    test('whitespace and case differences in name still collapse', () {
      final a = _e(name: 'Now D3 5000IU');
      final b = _e(name: '  now  d3 5000iu  ');
      expect(manualEntryHash(a), manualEntryHash(b));
    });

    test('different dose → different hash', () {
      final a = _e(dosePerIntake: 1);
      final b = _e(dosePerIntake: 2);
      expect(manualEntryHash(a), isNot(manualEntryHash(b)));
    });

    test('different intake timing → different hash', () {
      final a = _e(timing: IntakeTiming.morningAfter);
      final b = _e(timing: IntakeTiming.dinnerAfter);
      expect(manualEntryHash(a), isNot(manualEntryHash(b)));
    });

    test('different package size → different hash', () {
      final a = _e(packageSize: 60);
      final b = _e(packageSize: 90);
      expect(manualEntryHash(a), isNot(manualEntryHash(b)));
    });

    test('same product even when brand is null vs empty', () {
      final a = _e(brand: '');
      final b = _e(brand: null);
      expect(manualEntryHash(a), manualEntryHash(b));
    });
  });
}
