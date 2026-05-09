// Locks the supplement-search match quality after the V1 cleanup:
//   * 영문명(english_name)도 검색 대상 — 약통의 영문 라벨을 그대로 입력해도
//     매칭되어야 함
//   * 대소문자 무시
//   * 공백 변형 허용 — "센트룸맨" / "센트룸  맨" / "센트룸 맨" 모두 같음
//   * 토큰 분리된 부분 매칭 — "센트룸 50+" 같이 공백을 사이에 두고 떨어진
//     키워드도 모두 포함되면 매칭
//
// 확장 작업이 아닌 회귀 가드 — 카테고리 한글 라벨 / 영양소 한글 → 영문
// 매핑 / 동의어 사전은 의도적으로 추가하지 않음 (V1 결정).

import 'package:flutter_test/flutter_test.dart';

import 'package:alyak/core/data/models/product_model.dart';
import 'package:alyak/core/data/product_repository.dart';

Product _p({
  required String id,
  required String name,
  String englishName = '',
  String brand = '',
  String category = 'multivitamin',
}) =>
    Product(
      id: id,
      name: name,
      englishName: englishName,
      brand: brand,
      brandType: ProductBrandType.brand,
      category: category,
      unit: '정',
      dailyDose: 1,
      packageSize: 60,
      ingredients: const {},
      ingredientUnits: const {},
      goodFor: const [],
      alternatives: const [],
    );

ProductRepository _repo() => ProductRepository.withProducts([
      _p(
        id: 'centrum_woman',
        name: '센트룸 우먼',
        englishName: 'Centrum For Women',
        brand: '센트룸',
      ),
      _p(
        id: 'centrum_man',
        name: '센트룸 맨',
        englishName: 'Centrum For Men',
        brand: '센트룸',
      ),
      _p(
        id: 'centrum_silver_man',
        name: '센트룸 실버 맨 50+',
        englishName: 'Centrum Silver Men 50+',
        brand: '센트룸',
      ),
      _p(
        id: 'solgar_d3',
        name: '솔가 비타민D3 1000IU',
        englishName: 'Solgar Vitamin D3 1000 IU',
        brand: '솔가',
        category: 'vitamin_d',
      ),
      _p(
        id: 'solgar_woman_multi',
        name: '솔가 여성용 멀티비타민&미네랄',
        englishName: 'Solgar Female Multiple',
        brand: '솔가',
      ),
    ]);

List<String> _ids(ProductRepository r, String q) =>
    r.search(q).map((p) => p.id).toList();

void main() {
  group('ProductRepository.search — 회귀 가드', () {
    test('한글명 정확 키워드 → 단일 매칭', () {
      expect(_ids(_repo(), '센트룸 맨'),
          containsAll(<String>['centrum_man', 'centrum_silver_man']));
    });

    test('영문명 매칭 — Centrum Men', () {
      // 약통 영문 라벨을 그대로 입력 → english_name 필드 기반 매칭.
      final hits = _ids(_repo(), 'Centrum Men');
      expect(hits, contains('centrum_man'));
      expect(hits, contains('centrum_silver_man'));
    });

    test('영문명 — 소문자 입력도 매칭', () {
      expect(_ids(_repo(), 'centrum'), contains('centrum_man'));
      expect(_ids(_repo(), 'centrum'), contains('centrum_woman'));
    });

    test('영문명 — 대문자 입력도 매칭', () {
      expect(_ids(_repo(), 'CENTRUM'), contains('centrum_man'));
    });

    test('공백 제거 입력 — "센트룸맨" → "센트룸 맨"', () {
      expect(_ids(_repo(), '센트룸맨'), contains('centrum_man'));
    });

    test('다중 공백 입력 — "센트룸  맨"', () {
      expect(_ids(_repo(), '센트룸  맨'), contains('centrum_man'));
    });

    test('토큰 분리된 부분 매칭 — "센트룸 50+"', () {
      // 50+가 name 끝에 떨어져 있어도 토큰 AND 매칭으로 포함.
      expect(_ids(_repo(), '센트룸 50+'), ['centrum_silver_man']);
    });

    test('브랜드 검색 — "솔가" → 솔가 브랜드 모든 제품', () {
      // brand 필드가 name에 포함되어 있어 사실상 브랜드 검색됨.
      final hits = _ids(_repo(), '솔가');
      expect(hits, containsAll(<String>['solgar_d3', 'solgar_woman_multi']));
      expect(hits, isNot(contains('centrum_man')));
    });

    test('"솔가 비타민" → 솔가 비타민 계열', () {
      expect(_ids(_repo(), '솔가 비타민'), contains('solgar_d3'));
    });

    test('빈 쿼리 / 공백만 → 전체 반환', () {
      expect(_ids(_repo(), '').length, 5);
      expect(_ids(_repo(), '   ').length, 5);
    });

    test('매칭 없는 키워드 → 빈 리스트', () {
      expect(_ids(_repo(), '존재하지않는브랜드xyz'), isEmpty);
    });
  });
}
