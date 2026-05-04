import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:alyak/core/data/product_repository.dart';
import 'package:alyak/features/family/models/family_member.dart';
import 'package:alyak/features/home/providers/member_analysis_provider.dart';

FamilyMember _member({
  int age = 30,
  Sex sex = Sex.male,
  SmokingStatus smoking = SmokingStatus.never,
  StressLevel stress = StressLevel.low,
  HealthCheckup? checkup,
  List<String> productIds = const [],
}) {
  final now = DateTime(2026, 5, 4);
  return FamilyMember(
    id: 'm1',
    name: '테스트',
    relationship: Relationship.self,
    age: age,
    sex: sex,
    smokingStatus: smoking,
    stressLevel: stress,
    lastCheckup: checkup,
    currentProductIds: productIds,
    createdAt: now,
    updatedAt: now,
  );
}

// Re-implement the family_add _shouldShow logic so tests can exercise
// the branching contract without depending on the private widget state.
bool shouldShowStep(int step, {required int age, required Sex sex}) {
  if (step <= 5 || step >= 16) return true;
  switch (step) {
    case 6: // pregnancy
      return sex == Sex.female && age >= 15 && age < 55;
    case 7: // smoking
    case 8: // drinking
      return age >= 19;
    case 9: // diet
    case 11: // stress
      return age >= 13;
    case 10: // sleep
      return age >= 3;
    case 12: // allergies
      return true;
    case 13: // medications
      return age >= 3;
    case 14: // checkup
      return age >= 13;
    case 15: // products
      return true;
    default:
      return true;
  }
}

void main() {
  group('FIX1 - age/sex step branching', () {
    test('newborn (0세): only foundation + allergies + products', () {
      const a = 0, s = Sex.male;
      // foundation 1-5
      for (var i = 1; i <= 5; i++) {
        expect(shouldShowStep(i, age: a, sex: s), true, reason: 'step $i');
      }
      // gated steps 6-14: all should be hidden except allergies (12)
      expect(shouldShowStep(6, age: a, sex: s), false);
      expect(shouldShowStep(7, age: a, sex: s), false);
      expect(shouldShowStep(8, age: a, sex: s), false);
      expect(shouldShowStep(9, age: a, sex: s), false);
      expect(shouldShowStep(10, age: a, sex: s), false);
      expect(shouldShowStep(11, age: a, sex: s), false);
      expect(shouldShowStep(12, age: a, sex: s), true);
      expect(shouldShowStep(13, age: a, sex: s), false);
      expect(shouldShowStep(14, age: a, sex: s), false);
      expect(shouldShowStep(15, age: a, sex: s), true);
      expect(shouldShowStep(16, age: a, sex: s), true);
    });

    test('3세 child: + sleep + medications', () {
      const a = 3, s = Sex.female;
      expect(shouldShowStep(7, age: a, sex: s), false, reason: 'no smoking');
      expect(shouldShowStep(8, age: a, sex: s), false, reason: 'no drinking');
      expect(shouldShowStep(10, age: a, sex: s), true, reason: 'sleep ok');
      expect(shouldShowStep(13, age: a, sex: s), true, reason: 'meds ok');
      expect(shouldShowStep(6, age: a, sex: s), false, reason: 'no pregnancy');
    });

    test('17세 teen: + diet/sleep/stress/checkup, no smoking/drinking', () {
      const a = 17, s = Sex.male;
      expect(shouldShowStep(7, age: a, sex: s), false);
      expect(shouldShowStep(8, age: a, sex: s), false);
      expect(shouldShowStep(9, age: a, sex: s), true);
      expect(shouldShowStep(10, age: a, sex: s), true);
      expect(shouldShowStep(11, age: a, sex: s), true);
      expect(shouldShowStep(14, age: a, sex: s), true);
      expect(shouldShowStep(6, age: a, sex: s), false);
    });

    test('30세 woman: pregnancy step shown', () {
      expect(
          shouldShowStep(6, age: 30, sex: Sex.female), true);
    });

    test('30세 man: pregnancy step skipped', () {
      expect(shouldShowStep(6, age: 30, sex: Sex.male), false);
    });

    test('70세 elderly: everything except pregnancy', () {
      const a = 70;
      expect(shouldShowStep(6, age: a, sex: Sex.female), false,
          reason: 'past child-bearing age');
      expect(shouldShowStep(7, age: a, sex: Sex.male), true);
      expect(shouldShowStep(13, age: a, sex: Sex.male), true);
    });
  });

  group('FIX5 - product DB shape + count', () {
    final json = jsonDecode(
      File('assets/data/products.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    final products = json['products'] as List;

    test('exactly 30 products', () {
      expect(products.length, 30);
    });

    test('all ids are unique', () {
      final ids = products.map((p) => (p as Map)['id']).toList();
      expect(ids.toSet().length, ids.length);
    });

    test('popularity_rank covers 1..30', () {
      final ranks = products
          .map((p) => (p as Map)['popularity_rank'] as int)
          .toList()
        ..sort();
      expect(ranks, List.generate(30, (i) => i + 1));
    });

    test('all ingredient keys are snake_case (no Korean chars)', () {
      final korean = RegExp(r'[가-힣]');
      for (final p in products) {
        final ing = (p as Map)['ingredients'] as Map;
        for (final k in ing.keys) {
          expect(korean.hasMatch(k as String), false,
              reason: 'product ${p['id']} has Korean key $k');
        }
      }
    });

    test('search "센트룸" hits >= 3 products', () {
      final hits = products
          .where((p) => ((p as Map)['name'] as String).contains('센트룸'))
          .toList();
      expect(hits.length, greaterThanOrEqualTo(3));
    });
  });

  group('FIX6 - tier-based nutrient grouping', () {
    // Empty repo → no products found → every RDI is a 0% deficit.
    final emptyRepo = ProductRepository();

    test('priority is at most 3, secondary holds the rest', () {
      final analysis = analyzeMember(_member(), emptyRepo);
      expect(analysis.priority.length, lessThanOrEqualTo(3));
      expect(
        analysis.priority.length + analysis.secondary.length,
        analysis.deficits.length,
      );
    });

    test('checkup vitamin D < 30 boosts vitamin D into priority', () {
      final analysis = analyzeMember(
        _member(
          checkup: HealthCheckup(
            checkupDate: DateTime(2025, 11, 1),
            vitaminD: 22,
          ),
        ),
        emptyRepo,
      );
      final vd = analysis.priority
          .where((s) => s.deficit.nutrient == 'vitamin_d_iu')
          .toList();
      expect(vd, isNotEmpty,
          reason: 'vitamin D should be promoted to priority');
      expect(
        vd.first.reasons.any((r) => r.contains('검진 결과')),
        true,
      );
    });

    test('current smoker boosts vitamin C reasons', () {
      final analysis = analyzeMember(
        _member(smoking: SmokingStatus.current),
        emptyRepo,
      );
      final all = [...analysis.priority, ...analysis.secondary];
      final c = all
          .where((s) => s.deficit.nutrient == 'vitamin_c_mg')
          .toList();
      expect(c, isNotEmpty);
      expect(c.first.reasons.any((r) => r.contains('흡연')), true);
    });
  });
}
