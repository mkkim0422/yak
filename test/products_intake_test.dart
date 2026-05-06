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

    test('1회 1정 → "🍴 식후 1정"', () {
      expect(mk().scheduleLabel, '🍴 식후 1정');
    });

    test('1회 2정 / 1일 1회 → 통합 라인', () {
      final p = mk(
        dailyDose: 2,
        dose: 2,
        n: 1,
        timing: IntakeTiming.anyTimeAfterMeal,
      );
      expect(p.scheduleLabel, '🍴 식후 2정');
    });

    test('1+2 분산 → 아침/저녁', () {
      final p = mk(
        dailyDose: 2,
        dose: 1,
        n: 2,
        timing: IntakeTiming.multiple,
      );
      expect(p.scheduleLabel, '🌅 아침 1정 / 🌙 저녁 1정');
    });

    test('1+3 분산 → 아침/점심/저녁', () {
      final p = mk(
        dailyDose: 3,
        dose: 1,
        n: 3,
        timing: IntakeTiming.multiple,
      );
      expect(p.scheduleLabel, '🌅 아침 1정 / 🌞 점심 1정 / 🌙 저녁 1정');
    });

    test('4회 이상 → 라벨 참조', () {
      final p = mk(
        dailyDose: 5,
        dose: 1,
        n: 5,
        timing: IntakeTiming.multiple,
      );
      expect(p.scheduleLabel, '⏰ 1일 5회 (라벨 참조)');
    });

    test('취침 전 1정', () {
      final p = mk(timing: IntakeTiming.beforeSleep);
      expect(p.scheduleLabel, '🌙 취침 전 1정');
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
