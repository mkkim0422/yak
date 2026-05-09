// Verifies that every product in assets/data/products.json carries the new
// intake-timing fields and that the dose_per_intake × intakes_per_day
// invariant holds against daily_dose. Acts as a guard against regressions
// when products are added or edited.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:alyak/core/data/models/product_model.dart';

const _path = 'assets/data/products.json';

List<Map<String, dynamic>> _loadRaw() {
  final raw = File(_path).readAsStringSync();
  final json = jsonDecode(raw) as Map<String, dynamic>;
  final list = json['products'] as List<dynamic>;
  return list.cast<Map<String, dynamic>>();
}

void main() {
  group('products.json intake fields', () {
    final raw = _loadRaw();

    test('there are 250 products', () {
      expect(raw, hasLength(250));
    });

    test('every product has intake_timing / dose_per_intake / intakes_per_day',
        () {
      final missing = <String>[];
      for (final p in raw) {
        final id = p['id'] as String? ?? '<unknown>';
        if (p['intake_timing'] is! String) missing.add('$id(intake_timing)');
        if (p['dose_per_intake'] is! int) missing.add('$id(dose_per_intake)');
        if (p['intakes_per_day'] is! int) missing.add('$id(intakes_per_day)');
      }
      expect(missing, isEmpty, reason: 'Missing fields:\n${missing.join('\n')}');
    });

    test('dose_per_intake × intakes_per_day == daily_dose', () {
      final mismatches = <String>[];
      for (final p in raw) {
        final id = p['id'] as String? ?? '';
        final daily = (p['daily_dose'] as num).toInt();
        final dose = (p['dose_per_intake'] as num).toInt();
        final n = (p['intakes_per_day'] as num).toInt();
        if (dose * n != daily) {
          mismatches.add('$id: $dose × $n != $daily');
        }
      }
      expect(mismatches, isEmpty,
          reason: 'Mismatches:\n${mismatches.join('\n')}');
    });

    test('dose_per_intake >= 1 and intakes_per_day >= 1 for every product',
        () {
      for (final p in raw) {
        final dose = (p['dose_per_intake'] as num).toInt();
        final n = (p['intakes_per_day'] as num).toInt();
        expect(dose, greaterThanOrEqualTo(1));
        expect(n, greaterThanOrEqualTo(1));
      }
    });

    test('intake_timing parses to a known IntakeTiming enum', () {
      final allowed = IntakeTiming.values.map((e) => e.name).toSet();
      final unknown = <String>[];
      for (final p in raw) {
        final t = p['intake_timing'] as String;
        if (!allowed.contains(t)) {
          unknown.add('${p['id']}: $t');
        }
      }
      expect(unknown, isEmpty,
          reason: 'Unknown intake_timing values:\n${unknown.join('\n')}');
    });

    test('multiple timing implies intakes_per_day >= 2', () {
      final violations = <String>[];
      for (final p in raw) {
        final t = p['intake_timing'] as String;
        final n = (p['intakes_per_day'] as num).toInt();
        if (t == 'multiple' && n < 2) {
          violations.add('${p['id']}: timing=multiple but intakes=$n');
        }
      }
      expect(violations, isEmpty,
          reason: 'multiple-timing violations:\n${violations.join('\n')}');
    });
  });

  group('Product.scheduleLabel', () {
    Product mk({
      int dailyDose = 1,
      int dose = 1,
      int n = 1,
      IntakeTiming timing = IntakeTiming.anyTimeAfterMeal,
      String unit = '정',
    }) {
      return Product(
        id: 'x',
        name: 'x',
        brand: '',
        brandType: ProductBrandType.brand,
        category: '',
        unit: unit,
        dailyDose: dailyDose,
        packageSize: 0,
        ingredients: const {},
        ingredientUnits: const {},
        goodFor: const [],
        alternatives: const [],
        intakeTiming: timing,
        dosePerIntake: dose,
        intakesPerDay: n,
      );
    }

    // V1+ 사용자 행동 정렬 — 분산 표시 대신 "하루 N{unit}" 단순 형태.
    // 시점은 IntakeTimingBadge로 분리 노출.
    test('1회 1정 → "하루 1정"', () {
      expect(mk().scheduleLabel, '하루 1정');
    });

    test('1회 2정 / 1일 1회 → "하루 2정"', () {
      final p = mk(
        dailyDose: 2,
        dose: 2,
        n: 1,
        timing: IntakeTiming.anyTimeAfterMeal,
      );
      expect(p.scheduleLabel, '하루 2정');
    });

    test('1+2 분복 → "하루 2정" (묶음)', () {
      final p = mk(
        dailyDose: 2,
        dose: 1,
        n: 2,
        timing: IntakeTiming.multiple,
      );
      expect(p.scheduleLabel, '하루 2정');
    });

    test('1+3 분복 → "하루 3정"', () {
      final p = mk(
        dailyDose: 3,
        dose: 1,
        n: 3,
        timing: IntakeTiming.multiple,
      );
      expect(p.scheduleLabel, '하루 3정');
    });

    test('5회 분복 → "하루 5정"', () {
      final p = mk(
        dailyDose: 5,
        dose: 1,
        n: 5,
        timing: IntakeTiming.multiple,
      );
      expect(p.scheduleLabel, '하루 5정');
    });

    test('취침 전 1정 → "하루 1정"', () {
      final p = mk(timing: IntakeTiming.beforeSleep);
      expect(p.scheduleLabel, '하루 1정');
    });

    test('unit이 캡슐이면 "하루 1캡슐"', () {
      final p = mk(unit: '캡슐');
      expect(p.scheduleLabel, '하루 1캡슐');
    });
  });

  group('IntakeTimingX.badgeText — 8 분기', () {
    test('anyTimeAfterMeal → 식후 아무 때나', () {
      expect(IntakeTiming.anyTimeAfterMeal.badgeText, '식후 아무 때나');
    });
    test('multiple → 묶어 드셔도 OK', () {
      expect(IntakeTiming.multiple.badgeText, '묶어 드셔도 OK');
    });
    test('morningEmpty → 공복 권장', () {
      expect(IntakeTiming.morningEmpty.badgeText, '공복 권장');
    });
    test('morningAfter → 아침 식후', () {
      expect(IntakeTiming.morningAfter.badgeText, '아침 식후');
    });
    test('lunchAfter → 점심 식후', () {
      expect(IntakeTiming.lunchAfter.badgeText, '점심 식후');
    });
    test('dinnerAfter → 저녁 식후', () {
      expect(IntakeTiming.dinnerAfter.badgeText, '저녁 식후');
    });
    test('beforeSleep → 잠들기 전', () {
      expect(IntakeTiming.beforeSleep.badgeText, '잠들기 전');
    });
    test('withMeal → 식사 중', () {
      expect(IntakeTiming.withMeal.badgeText, '식사 중');
    });
  });

  group('Product.fromJson backwards compat', () {
    test('product without new fields defaults to anyTimeAfterMeal + 1+1', () {
      final p = Product.fromJson({
        'id': 'legacy',
        'name': 'legacy',
        'category': 'multivitamin',
        'unit': '정',
        'daily_dose': 1,
      });
      expect(p.intakeTiming, IntakeTiming.anyTimeAfterMeal);
      expect(p.dosePerIntake, 1);
      expect(p.intakesPerDay, 1);
    });
  });
}
