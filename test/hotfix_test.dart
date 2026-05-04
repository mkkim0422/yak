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
  bool isPregnant = false,
  bool isBreastfeeding = false,
  List<String> productIds = const [],
}) {
  final now = DateTime(2026, 5, 4);
  return FamilyMember(
    id: 'm1',
    name: '테스트',
    relationship: Relationship.self,
    birthYear: DateTime.now().year - age,
    sex: sex,
    smokingStatus: smoking,
    stressLevel: stress,
    isPregnant: isPregnant,
    isBreastfeeding: isBreastfeeding,
    currentProductIds: productIds,
    createdAt: now,
    updatedAt: now,
  );
}

/// Re-implementation of the family_add `_shouldShow` logic so we can
/// exercise the contract from outside the widget. Mirror this list when
/// editing the production rules.
bool shouldShowStep(int step, {required int age, required Sex sex}) {
  switch (step) {
    case 1:
    case 2:
    case 3:
    case 4:
      return true;
    case 5: // medical disclaimer
      return age < 4;
    case 6: // height/weight
      return true;
    case 7: // pregnancy
    case 8: // breastfeeding
      return sex == Sex.female && age >= 15 && age <= 49;
    case 9: // smoking
    case 10: // drinking
      return age >= 19;
    case 11: // diet
    case 12: // sleep
      return age >= 4;
    case 13: // stress
      return age >= 13;
    case 14: // allergies
      return true;
    case 15: // medications
      return age >= 1;
    case 16:
    case 17:
      return true;
    default:
      return true;
  }
}

void main() {
  group('H3 - precise step branching', () {
    test('1세 영아: medical disclaimer + minimal steps only', () {
      const a = 1, s = Sex.male;
      expect(shouldShowStep(5, age: a, sex: s), true,
          reason: 'medical disclaimer for under 4');
      expect(shouldShowStep(11, age: a, sex: s), false, reason: 'no diet');
      expect(shouldShowStep(12, age: a, sex: s), false, reason: 'no sleep');
      expect(shouldShowStep(13, age: a, sex: s), false, reason: 'no stress');
      expect(shouldShowStep(9, age: a, sex: s), false, reason: 'no smoking');
      expect(shouldShowStep(10, age: a, sex: s), false, reason: 'no drinking');
      expect(shouldShowStep(7, age: a, sex: s), false, reason: 'no pregnancy');
      expect(shouldShowStep(15, age: a, sex: s), true, reason: 'meds ok at >=1');
    });

    test('7세 child: skips smoking/drinking/pregnancy/stress', () {
      const a = 7, s = Sex.male;
      expect(shouldShowStep(5, age: a, sex: s), false,
          reason: 'no medical disclaimer');
      expect(shouldShowStep(9, age: a, sex: s), false);
      expect(shouldShowStep(10, age: a, sex: s), false);
      expect(shouldShowStep(13, age: a, sex: s), false);
      expect(shouldShowStep(7, age: a, sex: s), false);
      expect(shouldShowStep(11, age: a, sex: s), true, reason: 'diet ok at >=4');
      expect(shouldShowStep(12, age: a, sex: s), true,
          reason: 'sleep ok at >=4');
    });

    test('17세 teen female: no smoking/drinking, has stress/diet/pregnancy', () {
      const a = 17, s = Sex.female;
      expect(shouldShowStep(7, age: a, sex: s), true, reason: 'pregnancy 15+');
      expect(shouldShowStep(9, age: a, sex: s), false);
      expect(shouldShowStep(10, age: a, sex: s), false);
      expect(shouldShowStep(13, age: a, sex: s), true);
    });

    test('35세 male: pregnancy/breastfeeding skipped', () {
      const a = 35;
      expect(shouldShowStep(7, age: a, sex: Sex.male), false);
      expect(shouldShowStep(8, age: a, sex: Sex.male), false);
      expect(shouldShowStep(9, age: a, sex: Sex.male), true);
    });

    test('35세 female: pregnancy AND breastfeeding both shown', () {
      const a = 35;
      expect(shouldShowStep(7, age: a, sex: Sex.female), true);
      expect(shouldShowStep(8, age: a, sex: Sex.female), true);
    });

    test('70세 elderly: no pregnancy, everything else applies', () {
      const a = 70;
      expect(shouldShowStep(7, age: a, sex: Sex.female), false,
          reason: 'past child-bearing age');
      expect(shouldShowStep(9, age: a, sex: Sex.male), true);
      expect(shouldShowStep(13, age: a, sex: Sex.male), true);
    });
  });

  group('H8 - product DB shape (web-verified entries only)', () {
    final json = jsonDecode(
      File('assets/data/products.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    final products = json['products'] as List;

    test('at least 15 verified products', () {
      // Spec asked for 100, but per "추정 금지, 검색 결과 기반만"
      // we ship only entries we could web-verify.
      expect(products.length, greaterThanOrEqualTo(15));
    });

    test('all ids are unique', () {
      final ids = products.map((p) => (p as Map)['id']).toList();
      expect(ids.toSet().length, ids.length);
    });

    test('every entry has data_source URL + verified_date', () {
      for (final p in products) {
        final m = p as Map;
        expect((m['data_source'] as String?)?.isNotEmpty, true,
            reason: '${m['id']} missing data_source');
        expect((m['verified_date'] as String?)?.isNotEmpty, true,
            reason: '${m['id']} missing verified_date');
      }
    });

    test('every entry has the ingredients field (may be empty)', () {
      // Per spec, products that exist publicly but with undisclosed
      // amounts are still indexed so users can find/request them.
      // The analysis engine skips empty maps automatically.
      for (final p in products) {
        expect((p as Map).containsKey('ingredients'), true,
            reason: '${p['id']} missing ingredients key');
      }
    });

    test('at least 50% of entries have non-empty ingredients', () {
      final total = products.length;
      final filled = products
          .where((p) => ((p as Map)['ingredients'] as Map).isNotEmpty)
          .length;
      expect(filled / total, greaterThanOrEqualTo(0.5),
          reason: 'too many empty-ingredient entries; verify amounts');
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

    test('no entry contains a price field', () {
      for (final p in products) {
        final m = p as Map;
        expect(m.containsKey('package_price_krw'), false,
            reason: '${m['id']} still has package_price_krw');
        expect(m.containsKey('price_per_unit_krw'), false,
            reason: '${m['id']} still has price_per_unit_krw');
      }
    });

    test('search "센트룸" returns multiple variants', () {
      final hits = products
          .where((p) => ((p as Map)['name'] as String).contains('센트룸'))
          .toList();
      expect(hits.length, greaterThanOrEqualTo(2));
    });
  });

  group('H9 - tier-based nutrient grouping (no checkup)', () {
    final emptyRepo = ProductRepository();

    test('priority capped at 3, secondary holds the rest', () {
      final analysis = analyzeMember(_member(), emptyRepo);
      expect(analysis.priority.length, lessThanOrEqualTo(3));
      expect(
        analysis.priority.length + analysis.secondary.length,
        analysis.deficits.length,
      );
    });

    test('current smoker → vitamin C / E reasons mention 흡연', () {
      final analysis = analyzeMember(
        _member(smoking: SmokingStatus.current),
        emptyRepo,
      );
      final all = [...analysis.priority, ...analysis.secondary];
      final c = all
          .where((s) =>
              s.deficit.nutrient == 'vitamin_c_mg' ||
              s.deficit.nutrient == 'vitamin_e_mg')
          .toList();
      expect(c, isNotEmpty);
      expect(c.first.reasons.any((r) => r.contains('흡연')), true);
    });

    test('pregnant member → folate boosted into priority', () {
      final analysis = analyzeMember(
        _member(sex: Sex.female, isPregnant: true),
        emptyRepo,
      );
      final hits = analysis.priority
          .where((s) => s.deficit.nutrient == 'vitamin_b9_mcg')
          .toList();
      expect(hits, isNotEmpty,
          reason: 'folate should be top-3 for pregnant members');
      expect(hits.first.reasons.any((r) => r.contains('임신')), true);
    });
  });

  group('H1 - birthYear → age computed', () {
    test('age = currentYear - birthYear', () {
      final m = _member(age: 25);
      expect(m.age, 25);
      expect(m.birthYear, DateTime.now().year - 25);
    });

    test('ageLabel formatted as 만 X세', () {
      final m = _member(age: 42);
      expect(m.ageLabel, '만 42세');
    });
  });

  group('H2 - HealthCheckup is gone', () {
    test('no source file references HealthCheckup or lastCheckup', () {
      final libRoot = Directory('lib');
      final offenders = <String>[];
      for (final f in libRoot
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))) {
        final text = f.readAsStringSync();
        if (text.contains('HealthCheckup') ||
            text.contains('lastCheckup') ||
            text.contains('health_checkup_input_screen')) {
          offenders.add(f.path);
        }
      }
      expect(offenders, isEmpty,
          reason: 'still references HealthCheckup: $offenders');
    });
  });
}
