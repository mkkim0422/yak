// Locks the 5-conflict ramp surfaced in the UI:
//   1. nutrient overdose vs UL / 2× RDI
//   2. absorption interference (calcium+iron, etc.) at the same intake time
//   3. timing pile-up (5+ supplements at the same time)
//   4. drug interaction stub (Phase 2 hook — currently emits nothing)
//   5. pregnancy / lactation rules

import 'package:flutter_test/flutter_test.dart';

import 'package:alyak/core/data/models/product_model.dart';
import 'package:alyak/core/services/conflict_checker.dart';
import 'package:alyak/features/family/models/family_member.dart';

FamilyMember _member({
  bool pregnant = false,
  bool lactating = false,
  int age = 35,
  Sex sex = Sex.female,
}) {
  final now = DateTime.now();
  return FamilyMember(
    id: 'm1',
    name: '테스트',
    relationship: Relationship.self,
    birthYear: now.year - age,
    sex: sex,
    isPregnant: pregnant,
    isBreastfeeding: lactating,
    createdAt: now,
    updatedAt: now,
  );
}

Product _product({
  required String id,
  required String name,
  Map<String, double> ingredients = const {},
  IntakeTiming timing = IntakeTiming.anyTimeAfterMeal,
  int dailyDose = 1,
}) {
  return Product(
    id: id,
    name: name,
    brand: '',
    brandType: ProductBrandType.brand,
    category: 'test',
    unit: '정',
    dailyDose: dailyDose,
    packageSize: 30,
    ingredients: ingredients,
    ingredientUnits: const {},
    goodFor: const [],
    alternatives: const [],
    intakeTiming: timing,
  );
}

void main() {
  group('Rule 1 — nutrient overdose', () {
    test('vitamin C >> UL across 2 single-nutrient products → warning', () {
      final m = _member();
      // 1500mg + 1500mg = 3000mg (UL = 2000mg).
      final p1 = _product(
        id: 'a',
        name: '비타민C 1500',
        ingredients: const {'vitamin_c_mg': 1500},
      );
      final p2 = _product(
        id: 'b',
        name: '비타민C B',
        ingredients: const {'vitamin_c_mg': 1500},
      );
      final out = ConflictChecker.check(
        member: m,
        products: [p1, p2],
        manuals: const [],
      );
      final overdose =
          out.where((c) => c.title.contains('비타민C')).toList();
      expect(overdose, isNotEmpty);
      expect(overdose.first.severity, ConflictSeverity.warning);
    });

    test('calcium past UL across 2 products → warning', () {
      // UL = 2500mg. 1500 + 1500 = 3000mg.
      final m = _member();
      final p1 = _product(
        id: 'c1',
        name: '칼슘1500',
        ingredients: const {'calcium_mg': 1500},
      );
      final p2 = _product(
        id: 'c2',
        name: '칼슘1500B',
        ingredients: const {'calcium_mg': 1500},
      );
      final out = ConflictChecker.check(
        member: m,
        products: [p1, p2],
        manuals: const [],
      );
      expect(
        out.any((c) =>
            c.title.contains('칼슘') &&
            c.severity == ConflictSeverity.warning),
        isTrue,
      );
    });

    test('multivitamin alone past RDI → no warning (only fires past UL)', () {
      final m = _member();
      // 8 ingredients → looks like a multivitamin. Vitamin C 1500mg (>RDI
      // 90mg, well within UL 2000mg) → no card.
      final p = _product(
        id: 'mv',
        name: '센트룸 우먼',
        ingredients: const {
          'vitamin_a_mcg': 700,
          'vitamin_c_mg': 1500,
          'vitamin_d_iu': 800,
          'vitamin_e_mg': 30,
          'vitamin_b6_mg': 5,
          'calcium_mg': 200,
          'magnesium_mg': 50,
          'zinc_mg': 11,
        },
      );
      final out = ConflictChecker.check(
        member: m,
        products: [p],
        manuals: const [],
      );
      expect(out.where((c) => c.title.contains('비타민C')), isEmpty);
      expect(out.where((c) => c.title.contains('비타민B6')), isEmpty);
    });

    test('multivitamin + single B6 100mg → warning past UL', () {
      final m = _member();
      final mv = _product(
        id: 'mv',
        name: '센트룸 우먼',
        ingredients: const {
          'vitamin_a_mcg': 700,
          'vitamin_c_mg': 90,
          'vitamin_d_iu': 800,
          'vitamin_e_mg': 30,
          'vitamin_b6_mg': 4.9,
          'calcium_mg': 200,
          'magnesium_mg': 50,
          'zinc_mg': 11,
        },
      );
      final solo = _product(
        id: 'b6',
        name: 'B6 100mg',
        ingredients: const {'vitamin_b6_mg': 100},
      );
      final out = ConflictChecker.check(
        member: m,
        products: [mv, solo],
        manuals: const [],
      );
      // 4.9 + 100 = 104.9 > UL(100)
      final hit = out.where(
        (c) => c.title.contains('비타민B6') &&
            c.severity == ConflictSeverity.warning,
      );
      expect(hit, isNotEmpty);
    });

    test('within RDI single product → no overdose conflict', () {
      final m = _member();
      final p = _product(
        id: 'p',
        name: 'C 90',
        ingredients: const {'vitamin_c_mg': 90},
      );
      final out = ConflictChecker.check(
        member: m,
        products: [p],
        manuals: const [],
      );
      expect(out.where((c) => c.title.contains('비타민C')), isEmpty);
    });
  });

  group('Rule 2 — absorption interference', () {
    test('calcium + iron at same timing → info card', () {
      final m = _member();
      final ca = _product(
        id: 'ca',
        name: '칼슘',
        ingredients: const {'calcium_mg': 500},
        timing: IntakeTiming.morningAfter,
      );
      final fe = _product(
        id: 'fe',
        name: '철분',
        ingredients: const {'iron_mg': 18},
        timing: IntakeTiming.morningAfter,
      );
      final out = ConflictChecker.check(
        member: m,
        products: [ca, fe],
        manuals: const [],
      );
      final hit = out.where((c) => c.title.contains('칼슘 + 철분'));
      expect(hit, isNotEmpty);
      expect(hit.first.severity, ConflictSeverity.info);
    });

    test('different timing → no absorption card', () {
      final m = _member();
      final ca = _product(
        id: 'ca',
        name: '칼슘',
        ingredients: const {'calcium_mg': 500},
        timing: IntakeTiming.morningAfter,
      );
      final fe = _product(
        id: 'fe',
        name: '철분',
        ingredients: const {'iron_mg': 18},
        timing: IntakeTiming.dinnerAfter,
      );
      final out = ConflictChecker.check(
        member: m,
        products: [ca, fe],
        manuals: const [],
      );
      expect(
        out.where((c) => c.title.contains('칼슘 + 철분')),
        isEmpty,
      );
    });
  });

  group('Rule 3 — timing pile-up', () {
    test('5 supplements at same time → info card', () {
      final m = _member();
      final products = [
        for (var i = 0; i < 5; i++)
          _product(
            id: 'p$i',
            name: '영양제 $i',
            timing: IntakeTiming.morningAfter,
          ),
      ];
      final out = ConflictChecker.check(
        member: m,
        products: products,
        manuals: const [],
      );
      final pileup = out.where((c) => c.title.contains('한 번에'));
      expect(pileup, isNotEmpty);
      expect(pileup.first.severity, ConflictSeverity.info);
    });

    test('4 supplements → no pile-up card', () {
      final m = _member();
      final products = [
        for (var i = 0; i < 4; i++)
          _product(
            id: 'p$i',
            name: '영양제 $i',
            timing: IntakeTiming.morningAfter,
          ),
      ];
      final out = ConflictChecker.check(
        member: m,
        products: products,
        manuals: const [],
      );
      expect(out.where((c) => c.title.contains('한 번에')), isEmpty);
    });
  });

  group('Rule 5 — pregnancy / lactation', () {
    test('pregnant + vitamin A 3000mcg → danger', () {
      final m = _member(pregnant: true);
      final p = _product(
        id: 'a1',
        name: '비타민A',
        ingredients: const {'vitamin_a_mcg': 3500},
      );
      final out = ConflictChecker.check(
        member: m,
        products: [p],
        manuals: const [],
      );
      final hit = out.where((c) => c.title.contains('비타민A'));
      expect(hit, isNotEmpty);
      expect(hit.first.severity, ConflictSeverity.danger);
    });

    test('pregnant + vitamin D 4000IU → warning (not danger)', () {
      final m = _member(pregnant: true);
      final p = _product(
        id: 'd1',
        name: '비타민D',
        ingredients: const {'vitamin_d_iu': 5000},
      );
      final out = ConflictChecker.check(
        member: m,
        products: [p],
        manuals: const [],
      );
      final hit = out.where((c) => c.title.contains('비타민D'));
      expect(hit, isNotEmpty);
      expect(hit.first.severity, ConflictSeverity.warning);
    });

    test('breastfeeding + B6 100mg → warning', () {
      final m = _member(lactating: true);
      final p = _product(
        id: 'b6',
        name: 'B6',
        ingredients: const {'vitamin_b6_mg': 120},
      );
      final out = ConflictChecker.check(
        member: m,
        products: [p],
        manuals: const [],
      );
      final hit = out.where((c) => c.title.contains('비타민B6'));
      expect(hit, isNotEmpty);
      expect(hit.first.severity, ConflictSeverity.warning);
    });

    test('non-pregnant + vitamin A high → no pregnancy card', () {
      final m = _member();
      final p = _product(
        id: 'a1',
        name: '비타민A',
        ingredients: const {'vitamin_a_mcg': 3500},
      );
      final out = ConflictChecker.check(
        member: m,
        products: [p],
        manuals: const [],
      );
      expect(
        out.where((c) => c.title.contains('임신 중 비타민A')),
        isEmpty,
      );
    });
  });

  group('diff() — adding a candidate product', () {
    test('returns only the new conflicts that the candidate introduces', () {
      final m = _member();
      final ca = _product(
        id: 'ca',
        name: '칼슘',
        ingredients: const {'calcium_mg': 500},
        timing: IntakeTiming.morningAfter,
      );
      final fe = _product(
        id: 'fe',
        name: '철분',
        ingredients: const {'iron_mg': 18},
        timing: IntakeTiming.morningAfter,
      );
      final added = ConflictChecker.diff(
        member: m,
        products: [ca],
        manuals: const [],
        candidate: fe,
      );
      expect(added, isNotEmpty);
      expect(added.any((c) => c.title.contains('칼슘 + 철분')), isTrue);
    });

    test('candidate without conflicts → empty diff', () {
      final m = _member();
      final ca = _product(
        id: 'ca',
        name: '칼슘',
        ingredients: const {'calcium_mg': 500},
        timing: IntakeTiming.morningAfter,
      );
      final omega = _product(
        id: 'om',
        name: '오메가3',
        ingredients: const {'omega3_total_mg': 1000},
        timing: IntakeTiming.dinnerAfter,
      );
      final added = ConflictChecker.diff(
        member: m,
        products: [ca],
        manuals: const [],
        candidate: omega,
      );
      expect(added, isEmpty);
    });
  });
}
