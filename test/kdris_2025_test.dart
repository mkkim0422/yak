// 2025 KDRIs 매트릭스 회귀 테스트.
//
// 본 앱이 분석/충돌에 직접 사용하는 영양소 셀이 페르소나별로 의도한
// 값을 돌려주는지, 임신/수유 가산치가 더해지는지, UL 룩업이 동작하는지를
// 검증합니다. 시안 시점의 임의 페르소나(35세 여 / 임산부 / 수유부 /
// 70세 여 / 10세 어린이) 5케이스를 핀처럼 박아 둡니다.

import 'package:flutter_test/flutter_test.dart';

import 'package:alyak/core/data/kdris_2025.dart';

void main() {
  group('bracketForAge — 13구간 매핑', () {
    test('성인 19/29/30/49/50/64', () {
      expect(bracketForAge(19), KAgeBracket.adult19to29);
      expect(bracketForAge(29), KAgeBracket.adult19to29);
      expect(bracketForAge(30), KAgeBracket.adult30to49);
      expect(bracketForAge(49), KAgeBracket.adult30to49);
      expect(bracketForAge(50), KAgeBracket.adult50to64);
      expect(bracketForAge(64), KAgeBracket.adult50to64);
    });
    test('노인 65-74 / 75+', () {
      expect(bracketForAge(65), KAgeBracket.elderly65to74);
      expect(bracketForAge(74), KAgeBracket.elderly65to74);
      expect(bracketForAge(75), KAgeBracket.elderly75plus);
      expect(bracketForAge(99), KAgeBracket.elderly75plus);
    });
    test('아동/청소년 경계', () {
      expect(bracketForAge(1), KAgeBracket.child1to2);
      expect(bracketForAge(5), KAgeBracket.child3to5);
      expect(bracketForAge(8), KAgeBracket.child6to8);
      expect(bracketForAge(11), KAgeBracket.child9to11);
      expect(bracketForAge(14), KAgeBracket.teen12to14);
      expect(bracketForAge(18), KAgeBracket.teen15to18);
    });
  });

  group('recommendedKDRIs2025 — 35세 여성 (기본)', () {
    test('비타민C 100 mg', () {
      expect(
        recommendedKDRIs2025(
            nutrient: 'vitamin_c_mg', age: 35, isMale: false),
        100,
      );
    });
    test('철분 14 mg (생리 손실 가산)', () {
      expect(
        recommendedKDRIs2025(
            nutrient: 'iron_mg', age: 35, isMale: false),
        14,
      );
    });
    test('칼슘 700 mg', () {
      expect(
        recommendedKDRIs2025(
            nutrient: 'calcium_mg', age: 35, isMale: false),
        700,
      );
    });
    test('엽산 400 μg DFE', () {
      expect(
        recommendedKDRIs2025(
            nutrient: 'vitamin_b9_mcg', age: 35, isMale: false),
        400,
      );
    });
    test('콜린 425 mg (2025 신규)', () {
      expect(
        recommendedKDRIs2025(
            nutrient: 'choline_mg', age: 35, isMale: false),
        425,
      );
    });
  });

  group('recommendedKDRIs2025 — 임신부 가산치', () {
    test('비타민C 100 + 10 = 110 mg', () {
      expect(
        recommendedKDRIs2025(
          nutrient: 'vitamin_c_mg',
          age: 30,
          isMale: false,
          isPregnant: true,
        ),
        110,
      );
    });
    test('엽산 400 + 220 = 620 μg DFE', () {
      expect(
        recommendedKDRIs2025(
          nutrient: 'vitamin_b9_mcg',
          age: 30,
          isMale: false,
          isPregnant: true,
        ),
        620,
      );
    });
    test('철분 14 + 10 = 24 mg', () {
      expect(
        recommendedKDRIs2025(
          nutrient: 'iron_mg',
          age: 30,
          isMale: false,
          isPregnant: true,
        ),
        24,
      );
    });
    test('비타민A 650 + 70 = 720 μg RAE', () {
      expect(
        recommendedKDRIs2025(
          nutrient: 'vitamin_a_mcg',
          age: 35,
          isMale: false,
          isPregnant: true,
        ),
        720,
      );
    });
    test('콜린 425 + 25 = 450 mg', () {
      expect(
        recommendedKDRIs2025(
          nutrient: 'choline_mg',
          age: 30,
          isMale: false,
          isPregnant: true,
        ),
        450,
      );
    });
  });

  group('recommendedKDRIs2025 — 수유부 가산치', () {
    test('비타민C 100 + 35 = 135 mg', () {
      expect(
        recommendedKDRIs2025(
          nutrient: 'vitamin_c_mg',
          age: 30,
          isMale: false,
          isLactating: true,
        ),
        135,
      );
    });
    test('비타민A 650 + 490 = 1140 μg RAE', () {
      expect(
        recommendedKDRIs2025(
          nutrient: 'vitamin_a_mcg',
          age: 30,
          isMale: false,
          isLactating: true,
        ),
        1140,
      );
    });
    test('콜린 425 + 125 = 550 mg', () {
      expect(
        recommendedKDRIs2025(
          nutrient: 'choline_mg',
          age: 30,
          isMale: false,
          isLactating: true,
        ),
        550,
      );
    });
  });

  group('recommendedKDRIs2025 — 노인 / 어린이 / 영아', () {
    test('70세 여성 칼슘 800 mg (50+ 여성 800)', () {
      expect(
        recommendedKDRIs2025(
            nutrient: 'calcium_mg', age: 70, isMale: false),
        800,
      );
    });
    test('70세 남성 칼슘 700 mg', () {
      expect(
        recommendedKDRIs2025(
            nutrient: 'calcium_mg', age: 70, isMale: true),
        700,
      );
    });
    test('10세 어린이 비타민D 400 IU', () {
      expect(
        recommendedKDRIs2025(
            nutrient: 'vitamin_d_iu', age: 10, isMale: false),
        400,
      );
    });
    test('5세 어린이 칼슘 600 mg', () {
      expect(
        recommendedKDRIs2025(
            nutrient: 'calcium_mg', age: 5, isMale: true),
        600,
      );
    });
  });

  group('upperLimitKDRIs2025 — UL 룩업', () {
    test('칼슘 UL 2500', () {
      expect(upperLimitKDRIs2025('calcium_mg'), 2500);
    });
    test('비타민C UL 2000', () {
      expect(upperLimitKDRIs2025('vitamin_c_mg'), 2000);
    });
    test('비타민D UL 4000 IU', () {
      expect(upperLimitKDRIs2025('vitamin_d_iu'), 4000);
    });
    test('비타민A UL 3000 μg RAE', () {
      expect(upperLimitKDRIs2025('vitamin_a_mcg'), 3000);
    });
    test('콜린 UL 3500 mg (2025 신규)', () {
      expect(upperLimitKDRIs2025('choline_mg'), 3500);
    });
    test('수용성 비타민(B12) → UL 없음 (null)', () {
      expect(upperLimitKDRIs2025('vitamin_b12_mcg'), isNull);
    });
    test('표에 없는 영양소 → null', () {
      expect(upperLimitKDRIs2025('unknown_xyz'), isNull);
    });
  });

  group('nameKDRIs2025 — 한글 표시명', () {
    test('알려진 영양소 한글 매핑', () {
      expect(nameKDRIs2025('vitamin_d_iu'), '비타민D');
      expect(nameKDRIs2025('iron_mg'), '철분');
      expect(nameKDRIs2025('choline_mg'), '콜린');
      expect(nameKDRIs2025('vitamin_b9_mcg'), '엽산');
    });
    test('표에 없는 키 → null (호출자 폴백)', () {
      expect(nameKDRIs2025('phantom_mg'), isNull);
    });
  });
}
