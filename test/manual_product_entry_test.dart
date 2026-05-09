// ManualProductEntry now carries intakeTiming / dosePerIntake /
// intakesPerDay / intakeNote. Verifies serialization, migration of legacy
// JSON without the new fields, and scheduleLabel composition.

import 'package:flutter_test/flutter_test.dart';

import 'package:alyak/core/data/models/product_model.dart';
import 'package:alyak/features/family/models/family_member.dart';

ManualProductEntry _entry({
  IntakeTiming timing = IntakeTiming.anyTimeAfterMeal,
  int dose = 1,
  int n = 1,
  String? note,
}) {
  return ManualProductEntry(
    id: 'm1',
    name: 'Sample',
    brand: 'BrandX',
    category: '기타',
    dailyDose: dose * n,
    packageSize: 60,
    ingredients: const {},
    startedAt: DateTime(2026, 5, 6),
    intakeTiming: timing,
    dosePerIntake: dose,
    intakesPerDay: n,
    intakeNote: note,
  );
}

void main() {
  group('ManualProductEntry serialization', () {
    test('round-trips intake fields', () {
      final original = _entry(
        timing: IntakeTiming.beforeSleep,
        dose: 2,
        n: 1,
        note: '취침 30분 전',
      );
      final json = original.toJson();
      final restored = ManualProductEntry.fromJson(json);
      expect(restored.intakeTiming, IntakeTiming.beforeSleep);
      expect(restored.dosePerIntake, 2);
      expect(restored.intakesPerDay, 1);
      expect(restored.intakeNote, '취침 30분 전');
      expect(restored.dailyDose, 2);
    });

    test('legacy JSON without new fields gets sensible defaults', () {
      final legacy = {
        'id': 'm_legacy',
        'name': 'Old supplement',
        'brand': null,
        'category': '종합비타민',
        'daily_dose': 2,
        'package_size': 60,
        'price_krw': null,
        'image_path': null,
        'ingredients': const <String, dynamic>{},
        'started_at': '2025-12-01T00:00:00.000',
      };
      final entry = ManualProductEntry.fromJson(legacy);
      expect(entry.intakeTiming, IntakeTiming.anyTimeAfterMeal);
      // dose defaults to dailyDose, intakes to 1 — preserves dose × n == dailyDose
      expect(entry.dosePerIntake, 2);
      expect(entry.intakesPerDay, 1);
      expect(entry.intakeNote, isNull);
    });

    test('rejects invalid (<1) dose/intakes by clamping to 1', () {
      final json = {
        'id': 'x',
        'name': 'X',
        'brand': null,
        'category': '기타',
        'daily_dose': 1,
        'package_size': 30,
        'ingredients': const <String, dynamic>{},
        'started_at': '2026-01-01T00:00:00.000',
        'intake_timing': 'morningAfter',
        'dose_per_intake': 0,
        'intakes_per_day': -1,
      };
      final entry = ManualProductEntry.fromJson(json);
      expect(entry.dosePerIntake, 1);
      expect(entry.intakesPerDay, 1);
    });
  });

  group('ManualProductEntry.scheduleLabel — V1+ 단순 묶음', () {
    test('1+1 → "하루 1정"', () {
      final e = _entry(timing: IntakeTiming.anyTimeAfterMeal, dose: 1, n: 1);
      expect(e.scheduleLabel, '하루 1정');
    });

    test('1+2 분복 → "하루 2정"', () {
      final e = _entry(timing: IntakeTiming.multiple, dose: 1, n: 2);
      expect(e.scheduleLabel, '하루 2정');
    });

    test('1+3 분복 → "하루 3정"', () {
      final e = _entry(timing: IntakeTiming.multiple, dose: 1, n: 3);
      expect(e.scheduleLabel, '하루 3정');
    });

    test('2+1 → "하루 2정"', () {
      final e = _entry(timing: IntakeTiming.morningAfter, dose: 2, n: 1);
      expect(e.scheduleLabel, '하루 2정');
    });

    test('1+5 → "하루 5정"', () {
      final e = _entry(timing: IntakeTiming.multiple, dose: 1, n: 5);
      expect(e.scheduleLabel, '하루 5정');
    });

    test('취침 전 1정 → "하루 1정"', () {
      final e = _entry(timing: IntakeTiming.beforeSleep, dose: 1, n: 1);
      expect(e.scheduleLabel, '하루 1정');
    });
  });

  group('ManualProductEntry.copyWith', () {
    test('preserves id/startedAt and overrides intake fields', () {
      final base = _entry();
      final updated = base.copyWith(
        intakeTiming: IntakeTiming.dinnerAfter,
        dosePerIntake: 2,
        intakesPerDay: 1,
        dailyDose: 2,
        intakeNote: '저녁 식후',
      );
      expect(updated.id, base.id);
      expect(updated.startedAt, base.startedAt);
      expect(updated.intakeTiming, IntakeTiming.dinnerAfter);
      expect(updated.dosePerIntake, 2);
      expect(updated.intakesPerDay, 1);
      expect(updated.dailyDose, 2);
      expect(updated.intakeNote, '저녁 식후');
    });
  });
}
