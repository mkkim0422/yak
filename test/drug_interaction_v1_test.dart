// V1 약물-영양제 임상 충돌 룰 5건 회귀 테스트.
// 추가로 임계값 경계 케이스 1건 + 약물 미입력 케이스 1건을 포함해 총 7케이스.

import 'package:flutter_test/flutter_test.dart';

import 'package:alyak/core/data/models/product_model.dart';
import 'package:alyak/core/services/conflict_checker.dart';
import 'package:alyak/features/family/models/family_member.dart';

FamilyMember _member({List<String> medications = const []}) {
  final now = DateTime.now();
  return FamilyMember(
    id: 'm1',
    name: '테스트',
    relationship: Relationship.self,
    birthYear: now.year - 40,
    sex: Sex.female,
    medications: medications,
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

bool _hasTitle(List<ConflictItem> items, String keyword) =>
    items.any((c) => c.title.contains(keyword));

void main() {
  group('V1 약물-영양제 임상 충돌 룰', () {
    test('항응고제 + 오메가3 2000mg 이상 → danger', () {
      final m = _member(medications: const ['항응고제']);
      final p = _product(
        id: 'o3',
        name: '오메가3 2000',
        ingredients: const {'omega3_total_mg': 2000},
      );
      final out = ConflictChecker.check(
        member: m,
        products: [p],
        manuals: const [],
      );
      final hit = out.where((c) => c.title.contains('오메가3')).toList();
      expect(hit, isNotEmpty);
      expect(hit.first.severity, ConflictSeverity.danger);
    });

    test('항응고제 + 오메가3 1999mg → 경고 안함 (임계값 경계)', () {
      final m = _member(medications: const ['항응고제']);
      final p = _product(
        id: 'o3',
        name: '오메가3 1999',
        ingredients: const {'omega3_total_mg': 1999},
      );
      final out = ConflictChecker.check(
        member: m,
        products: [p],
        manuals: const [],
      );
      expect(_hasTitle(out, '오메가3'), isFalse);
    });

    test('항응고제 + 은행잎 함유 시 함량 무관 → danger', () {
      final m = _member(medications: const ['항응고제']);
      final p = _product(
        id: 'gk',
        name: '은행잎 40',
        ingredients: const {'ginkgo_extract_mg': 40},
      );
      final out = ConflictChecker.check(
        member: m,
        products: [p],
        manuals: const [],
      );
      final hit = out.where((c) => c.title.contains('은행잎')).toList();
      expect(hit, isNotEmpty);
      expect(hit.first.severity, ConflictSeverity.danger);
    });

    test('항응고제 + 비타민E 200mg 이상 → warning', () {
      final m = _member(medications: const ['항응고제']);
      final p = _product(
        id: 've',
        name: '비타민E 200',
        ingredients: const {'vitamin_e_mg': 200},
      );
      final out = ConflictChecker.check(
        member: m,
        products: [p],
        manuals: const [],
      );
      final hit = out.where((c) => c.title.contains('비타민E')).toList();
      expect(hit, isNotEmpty);
      expect(hit.first.severity, ConflictSeverity.warning);
    });

    test('갑상선약 + 칼슘 함유 → warning', () {
      final m = _member(medications: const ['갑상선약']);
      final p = _product(
        id: 'ca',
        name: '칼슘 500',
        ingredients: const {'calcium_mg': 500},
      );
      final out = ConflictChecker.check(
        member: m,
        products: [p],
        manuals: const [],
      );
      final hit = out.where((c) => c.title.contains('갑상선약과 칼슘')).toList();
      expect(hit, isNotEmpty);
      expect(hit.first.severity, ConflictSeverity.warning);
    });

    test('갑상선약 + 철분 함유 → warning', () {
      final m = _member(medications: const ['갑상선약']);
      final p = _product(
        id: 'fe',
        name: '철분 18',
        ingredients: const {'iron_mg': 18},
      );
      final out = ConflictChecker.check(
        member: m,
        products: [p],
        manuals: const [],
      );
      final hit = out.where((c) => c.title.contains('갑상선약과 철분')).toList();
      expect(hit, isNotEmpty);
      expect(hit.first.severity, ConflictSeverity.warning);
    });

    test('약물 미입력 멤버는 V1 룰 발동 안함', () {
      final m = _member();
      final p = _product(
        id: 'gk',
        name: '은행잎 120',
        ingredients: const {'ginkgo_extract_mg': 120},
      );
      final out = ConflictChecker.check(
        member: m,
        products: [p],
        manuals: const [],
      );
      expect(_hasTitle(out, '은행잎'), isFalse);
      expect(_hasTitle(out, '갑상선약'), isFalse);
    });
  });
}
