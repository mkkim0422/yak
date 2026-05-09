import 'package:flutter_test/flutter_test.dart';

import 'package:alyak/core/data/models/product_model.dart';
import 'package:alyak/features/family/models/family_member.dart';
import 'package:alyak/features/family/services/intake_grouping.dart';

Product _product(
  String id, {
  required IntakeTiming timing,
  int dosePerIntake = 1,
  int intakesPerDay = 1,
  String unit = '정',
}) {
  return Product(
    id: id,
    name: id,
    brand: 'b',
    brandType: ProductBrandType.brand,
    category: 'multivitamin',
    unit: unit,
    dailyDose: dosePerIntake * intakesPerDay,
    packageSize: 30,
    ingredients: const {},
    ingredientUnits: const {},
    goodFor: const [],
    alternatives: const [],
    intakeTiming: timing,
    dosePerIntake: dosePerIntake,
    intakesPerDay: intakesPerDay,
  );
}

ManualProductEntry _manual(
  String id, {
  required IntakeTiming timing,
  int dosePerIntake = 1,
  int intakesPerDay = 1,
}) =>
    ManualProductEntry(
      id: id,
      name: id,
      category: 'manual',
      dailyDose: dosePerIntake * intakesPerDay,
      packageSize: 30,
      ingredients: const {},
      startedAt: DateTime(2026, 1, 1),
      intakeTiming: timing,
      dosePerIntake: dosePerIntake,
      intakesPerDay: intakesPerDay,
    );

void main() {
  group('buildGroupedSchedule timing → slot mapping', () {
    test('morningAfter → 아침 only', () {
      final s = buildGroupedSchedule(
        curatedProducts: [_product('p', timing: IntakeTiming.morningAfter)],
        manuals: const [],
      );
      expect(s.morning.length, 1);
      expect(s.lunch, isEmpty);
      expect(s.evening, isEmpty);
    });

    test('morningEmpty → 아침 with 식전 hint', () {
      final s = buildGroupedSchedule(
        curatedProducts: [_product('p', timing: IntakeTiming.morningEmpty)],
        manuals: const [],
      );
      expect(s.morning.first.mealRelation, MealRelation.beforeMeal);
    });

    test('lunchAfter → 점심 only', () {
      final s = buildGroupedSchedule(
        curatedProducts: [_product('p', timing: IntakeTiming.lunchAfter)],
        manuals: const [],
      );
      expect(s.lunch.length, 1);
      expect(s.morning, isEmpty);
      expect(s.evening, isEmpty);
    });

    test('dinnerAfter → 저녁 only', () {
      final s = buildGroupedSchedule(
        curatedProducts: [_product('p', timing: IntakeTiming.dinnerAfter)],
        manuals: const [],
      );
      expect(s.evening.length, 1);
    });

    test('beforeSleep → 저녁 with 취침 전 hint', () {
      final s = buildGroupedSchedule(
        curatedProducts: [_product('p', timing: IntakeTiming.beforeSleep)],
        manuals: const [],
      );
      expect(s.evening.length, 1);
      expect(s.evening.first.mealRelation, MealRelation.beforeSleep);
    });

    test('anyTimeAfterMeal default → 아침', () {
      final s = buildGroupedSchedule(
        curatedProducts: [
          _product('p', timing: IntakeTiming.anyTimeAfterMeal),
        ],
        manuals: const [],
      );
      expect(s.morning.length, 1);
      expect(s.morning.first.mealRelation, MealRelation.afterMeal);
    });
  });

  group('buildGroupedSchedule 분복 — 아침 묶음', () {
    test('intakesPerDay=2 morningAfter → 아침 1건, dose=2', () {
      final s = buildGroupedSchedule(
        curatedProducts: [
          _product(
            'duo',
            timing: IntakeTiming.morningAfter,
            dosePerIntake: 1,
            intakesPerDay: 2,
          ),
        ],
        manuals: const [],
      );
      expect(s.morning.length, 1);
      expect(s.lunch, isEmpty);
      expect(s.evening, isEmpty);
      expect(s.morning.first.entryId, 'duo');
      expect(s.morning.first.dose, 2);
    });

    test('intakesPerDay=3 multiple → 아침 1건, dose=3', () {
      final s = buildGroupedSchedule(
        curatedProducts: [
          _product(
            'triple',
            timing: IntakeTiming.multiple,
            dosePerIntake: 1,
            intakesPerDay: 3,
          ),
        ],
        manuals: const [],
      );
      expect(s.total, 1);
      expect(s.morning.length, 1);
      expect(s.morning.first.dose, 3);
    });

    test('intakesPerDay=4 multiple → 아침 1건, dose=4', () {
      final s = buildGroupedSchedule(
        curatedProducts: [
          _product(
            'quad',
            timing: IntakeTiming.multiple,
            dosePerIntake: 1,
            intakesPerDay: 4,
          ),
        ],
        manuals: const [],
      );
      expect(s.total, 1);
      expect(s.morning.length, 1);
      expect(s.morning.first.dose, 4);
    });

    test('lunchAfter는 분복이라도 점심 슬롯 유지', () {
      final s = buildGroupedSchedule(
        curatedProducts: [
          _product(
            'lunch_pair',
            timing: IntakeTiming.lunchAfter,
            dosePerIntake: 1,
            intakesPerDay: 2,
          ),
        ],
        manuals: const [],
      );
      expect(s.lunch.length, 1);
      expect(s.lunch.first.dose, 2);
      expect(s.morning, isEmpty);
      expect(s.evening, isEmpty);
    });

    test('dosePerIntake=2 × intakesPerDay=3 → 아침 1건, dose=6', () {
      final s = buildGroupedSchedule(
        curatedProducts: [
          _product(
            'big',
            timing: IntakeTiming.multiple,
            dosePerIntake: 2,
            intakesPerDay: 3,
          ),
        ],
        manuals: const [],
      );
      expect(s.morning.length, 1);
      expect(s.morning.first.dose, 6);
    });
  });

  group('IntakeOccurrence.timing 노출 (badge용)', () {
    test('curated product timing이 그대로 occurrence에 전달됨', () {
      final s = buildGroupedSchedule(
        curatedProducts: [
          _product('p', timing: IntakeTiming.beforeSleep),
        ],
        manuals: const [],
      );
      expect(s.evening.first.timing, IntakeTiming.beforeSleep);
    });

    test('manual entry timing도 occurrence에 전달됨', () {
      final s = buildGroupedSchedule(
        curatedProducts: const [],
        manuals: [_manual('m', timing: IntakeTiming.morningEmpty)],
      );
      expect(s.morning.first.timing, IntakeTiming.morningEmpty);
    });
  });

  group('buildGroupedSchedule manuals + occurrence content', () {
    test('manual entry preserves dose and meal hint', () {
      final s = buildGroupedSchedule(
        curatedProducts: const [],
        manuals: [
          _manual(
            'm1',
            timing: IntakeTiming.dinnerAfter,
            dosePerIntake: 2,
            intakesPerDay: 1,
          ),
        ],
      );
      expect(s.evening.length, 1);
      final occ = s.evening.first;
      expect(occ.isCurated, false);
      expect(occ.dose, 2);
      expect(occ.mealRelation, MealRelation.afterMeal);
      expect(occ.manual?.id, 'm1');
    });

    test('curated and manual mixed across slots', () {
      final s = buildGroupedSchedule(
        curatedProducts: [
          _product('p1', timing: IntakeTiming.morningAfter),
        ],
        manuals: [
          _manual('m1', timing: IntakeTiming.dinnerAfter),
        ],
      );
      expect(s.morning.length, 1);
      expect(s.morning.first.isCurated, true);
      expect(s.evening.length, 1);
      expect(s.evening.first.isCurated, false);
    });
  });

  group('IntakeSlot labels', () {
    test('emoji + label', () {
      expect(IntakeSlot.morning.emoji, '🌅');
      expect(IntakeSlot.morning.label, '아침');
      expect(IntakeSlot.lunch.emoji, '🌞');
      expect(IntakeSlot.lunch.label, '점심');
      expect(IntakeSlot.evening.emoji, '🌙');
      expect(IntakeSlot.evening.label, '저녁');
    });
  });
}
