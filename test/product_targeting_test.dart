// Locks the persona ↔ product targeting heuristics that drive the
// recommendation screen — specifically that a 35세 wife never receives
// "센트룸 맨" suggestions and a 60세 mother prefers senior-female
// products.

import 'package:flutter_test/flutter_test.dart';

import 'package:alyak/core/data/models/product_model.dart';
import 'package:alyak/core/services/product_targeting.dart';
import 'package:alyak/features/family/models/family_member.dart';

Product _product({
  required String id,
  required String name,
  String category = 'multivitamin',
}) =>
    Product(
      id: id,
      name: name,
      brand: '',
      brandType: ProductBrandType.brand,
      category: category,
      unit: '정',
      dailyDose: 1,
      packageSize: 30,
      ingredients: const {},
      ingredientUnits: const {},
      goodFor: const [],
      alternatives: const [],
    );

FamilyMember _member({
  Sex sex = Sex.female,
  int age = 35,
  Relationship rel = Relationship.self,
  bool pregnant = false,
}) {
  final now = DateTime.now();
  return FamilyMember(
    id: 'm1',
    name: '테스트',
    relationship: rel,
    birthYear: now.year - age,
    sex: sex,
    isPregnant: pregnant,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  group('inferProductTargets', () {
    test('우먼/Women products → adultFemale', () {
      final p = _product(id: 'p', name: '센트룸 우먼');
      final t = inferProductTargets(p);
      expect(t.contains(TargetGroup.adultFemale), isTrue);
      expect(t.contains(TargetGroup.adultMale), isFalse);
    });

    test('맨/Men products → adultMale', () {
      final p = _product(id: 'p', name: '센트룸 맨');
      final t = inferProductTargets(p);
      expect(t.contains(TargetGroup.adultMale), isTrue);
      expect(t.contains(TargetGroup.adultFemale), isFalse);
    });

    test('실버 우먼 → seniorFemale', () {
      final p = _product(id: 'p', name: '센트룸 실버 우먼');
      final t = inferProductTargets(p);
      expect(t.contains(TargetGroup.seniorFemale), isTrue);
    });

    test('키즈 → kids only', () {
      final p = _product(id: 'p', name: '키즈 멀티비타민', category: 'kids_multivitamin');
      final t = inferProductTargets(p);
      expect(t.contains(TargetGroup.kids), isTrue);
      expect(t.contains(TargetGroup.adultFemale), isFalse);
    });

    test('prenatal category → pregnant', () {
      final p = _product(id: 'p', name: '엘레비트', category: 'prenatal');
      final t = inferProductTargets(p);
      expect(t.contains(TargetGroup.pregnant), isTrue);
    });

    test('generic name → empty (universally recommendable)', () {
      final p = _product(id: 'p', name: '비타민D 1000IU', category: 'vitamin_d');
      final t = inferProductTargets(p);
      expect(t, isEmpty);
    });
  });

  group('targetMatchScore — exclusions', () {
    test('35세 여자 → 센트룸 맨 hard-excluded', () {
      final wife = _member(sex: Sex.female, age: 35);
      final menProduct = _product(id: 'p', name: '센트룸 맨');
      final score = targetMatchScore(product: menProduct, member: wife);
      expect(score, lessThan(0));
    });

    test('35세 여자 → 센트룸 우먼 high score', () {
      final wife = _member(sex: Sex.female, age: 35);
      final womanProduct = _product(id: 'p', name: '센트룸 우먼');
      expect(
        targetMatchScore(product: womanProduct, member: wife),
        greaterThanOrEqualTo(50),
      );
    });

    test('35세 남자 → 센트룸 우먼 hard-excluded', () {
      final husband = _member(sex: Sex.male, age: 35);
      final wp = _product(id: 'p', name: '센트룸 우먼');
      expect(
        targetMatchScore(product: wp, member: husband),
        lessThan(0),
      );
    });

    test('60세 여자 → 실버 우먼 / 시니어 high score', () {
      final mother = _member(sex: Sex.female, age: 60);
      final silverWoman = _product(id: 'p', name: '센트룸 실버 우먼');
      expect(
        targetMatchScore(product: silverWoman, member: mother),
        greaterThan(0),
      );
    });

    test('5세 어린이 → 어른 제품 hard-excluded', () {
      final kid = _member(sex: Sex.male, age: 5);
      final adultProduct = _product(id: 'p', name: '센트룸 맨');
      expect(
        targetMatchScore(product: adultProduct, member: kid),
        lessThan(0),
      );
    });

    test('generic 비타민D → 모든 어른에게 universal', () {
      final wife = _member(sex: Sex.female, age: 35);
      final husband = _member(sex: Sex.male, age: 35);
      final generic =
          _product(id: 'p', name: '솔가 비타민D3 1000IU', category: 'vitamin_d');
      expect(targetMatchScore(product: generic, member: wife), 10);
      expect(targetMatchScore(product: generic, member: husband), 10);
    });

    test('임산부 → 남성용 제품 hard-excluded', () {
      final pregnant = _member(pregnant: true);
      final mp = _product(id: 'p', name: '센트룸 맨');
      expect(
        targetMatchScore(product: mp, member: pregnant),
        lessThan(0),
      );
    });
  });

  group('personaTargets', () {
    test('pregnant trumps everything', () {
      final preg = _member(pregnant: true);
      final t = personaTargets(preg);
      expect(t.first, TargetGroup.pregnant);
    });

    test('60세 female → menopauseFemale before adultFemale', () {
      final m = _member(sex: Sex.female, age: 60);
      final t = personaTargets(m);
      expect(t.first, TargetGroup.menopauseFemale);
    });

    test('5세 → kids only', () {
      final m = _member(age: 5);
      expect(personaTargets(m), [TargetGroup.kids]);
    });
  });
}
