// 2025 한국인 영양소 섭취기준 (KDRIs) — 한국영양학회 / 보건복지부 발표,
// 2025-12-31. https://www.kns.or.kr (자료 167) 및 mohw.go.kr 게시.
//
// 이 파일은 1차 마이그레이션이며, 다음 원칙을 따릅니다:
//   * 권장섭취량(RDA) / 충분섭취량(AI) / 상한섭취량(UL)을 영양소별로 분리.
//   * 연령 13구간 × 성별 2 × 임신/수유 가산치로 정규화.
//   * 2020 → 2025 변경이 미세 조정 위주이고, 콜린(choline_mg)이 신규
//     추가되었습니다. 변경 폭이 큰 영양소(비타민A, 니아신, B6, 칼슘, 인,
//     마그네슘, 아연, 나트륨)는 2025 표를 우선 반영합니다.
//   * 정오표(2026.02-03)에 적힌 미세 수치 갱신을 포함합니다.
//   * 본 앱이 실제로 분석에 사용하는 11종(`_baseRdi` 기존 + 콜린)을
//     우선 채우고, 그 외 영양소(비타민B군 일부)는 충분 정확도로 함께 반영.
//
// 모든 값은 일반인(건강 성인)을 대상으로 하며, 의학적 진단을 대체하지
// 않습니다. UI는 이 값을 추천/충돌 임계로만 사용합니다.

/// 13단계 연령 구간 — KDRIs 표의 행 구조와 1:1 매핑.
enum KAgeBracket {
  infant0to5,    // 0-5개월 (영아 전기)
  infant6to11,   // 6-11개월 (영아 후기)
  child1to2,     // 1-2세
  child3to5,     // 3-5세
  child6to8,     // 6-8세
  child9to11,    // 9-11세
  teen12to14,    // 12-14세
  teen15to18,    // 15-18세
  adult19to29,   // 19-29세
  adult30to49,   // 30-49세
  adult50to64,   // 50-64세
  elderly65to74, // 65-74세
  elderly75plus, // 75세+
}

/// `age` (만 나이, 정수) → 13구간 연령 코드.
///
/// V1 한계: 만 0세는 0-5개월(`infant0to5`)로 단일화합니다. 한국 채팅 흐름이
/// 출생연도만 받고 출생월은 받지 않으므로 6-11개월 구간을 정확히 분기할 수
/// 없습니다. 이로 인해 6-11개월 영아의 권장량(예: 철 6 mg)을 0-5개월 값
/// (철 0.3 mg)으로 비교하게 되며, 영양제 추천에서 일부 보수적 결과가
/// 나올 수 있습니다. V1.1에서 출생월(또는 만 N개월) 입력을 추가하면
/// `infant6to11` 행이 활성화됩니다.
///
/// 참고: 영아 영양제는 채팅 step 5에서 의학 면책을 띄워 소아과 상담을
/// 우선하도록 안내하므로, 본 추천이 단독 의사결정 기준이 되지 않습니다.
KAgeBracket bracketForAge(int age) {
  if (age <= 0) return KAgeBracket.infant0to5;
  if (age <= 2) return KAgeBracket.child1to2;
  if (age <= 5) return KAgeBracket.child3to5;
  if (age <= 8) return KAgeBracket.child6to8;
  if (age <= 11) return KAgeBracket.child9to11;
  if (age <= 14) return KAgeBracket.teen12to14;
  if (age <= 18) return KAgeBracket.teen15to18;
  if (age <= 29) return KAgeBracket.adult19to29;
  if (age <= 49) return KAgeBracket.adult30to49;
  if (age <= 64) return KAgeBracket.adult50to64;
  if (age <= 74) return KAgeBracket.elderly65to74;
  return KAgeBracket.elderly75plus;
}

/// 영양소 1종에 대한 RDA / AI / UL 기준치. RDA가 없으면 AI를 사용하고,
/// 둘 다 비어 있으면 영양소 비교에서 제외됩니다.
class NutrientReference {
  /// 한글 표시명 (UI에 그대로 노출).
  final String name;

  /// 단위 라벨 (`mg`, `mcg`, `IU`, `억CFU`, `g`).
  final String unit;

  /// 연령구간 × 성별 → RDA 또는 AI. `(bracket, isMale) → mg|mcg|IU`.
  /// 임신/수유는 별도 가산치로 표현됩니다.
  final Map<(KAgeBracket, bool), double> matrix;

  /// 임신부 추가량(전체 임기 통합값). null이면 적용 안 함.
  final double? pregnancyAdd;

  /// 수유부 추가량. null이면 적용 안 함.
  final double? lactationAdd;

  /// 상한섭취량 (UL). null이면 임계 없음(수용성 비타민 등).
  final double? upperLimit;

  /// 만성질환위험감소섭취량 (CDRR) — 현재 KDRIs에서는 나트륨에만 사용.
  final double? cdrr;

  /// 표 출처 노트 (2020 / 2025 신규 / 정오표 등).
  final String? note;

  const NutrientReference({
    required this.name,
    required this.unit,
    required this.matrix,
    this.pregnancyAdd,
    this.lactationAdd,
    this.upperLimit,
    this.cdrr,
    this.note,
  });

  /// 페르소나 → 권장량. 매트릭스 누락 시 같은 성별의 인접 구간에서
  /// 폴백합니다 (영아·소아의 경우 어른값을 그대로 두면 위험하므로
  /// 폴백은 같은 연령대 내에서만 이루어집니다).
  double recommendedFor({
    required int age,
    required bool isMale,
    bool isPregnant = false,
    bool isLactating = false,
  }) {
    final bracket = bracketForAge(age);
    final base = matrix[(bracket, isMale)] ??
        _fallbackBase(bracket, isMale) ??
        0;
    var total = base;
    if (isPregnant && pregnancyAdd != null) total += pregnancyAdd!;
    if (isLactating && lactationAdd != null) total += lactationAdd!;
    return total;
  }

  /// 결측 셀 폴백 — 동일 성별의 가장 가까운 인접 연령구간을 사용.
  double? _fallbackBase(KAgeBracket bracket, bool isMale) {
    final brackets = KAgeBracket.values;
    final idx = brackets.indexOf(bracket);
    for (var d = 1; d < brackets.length; d++) {
      for (final delta in [-d, d]) {
        final j = idx + delta;
        if (j < 0 || j >= brackets.length) continue;
        final v = matrix[(brackets[j], isMale)];
        if (v != null) return v;
      }
    }
    return null;
  }
}

/// 세 자리 적힌 RDA / AI 매트릭스를 짧게 빌드. (M, F) 두 값을 한 번에
/// 묶어주는 헬퍼 — 코드 길이를 절반으로 줄입니다.
Map<(KAgeBracket, bool), double> _matrix(
    Map<KAgeBracket, (double male, double female)> rows) {
  final out = <(KAgeBracket, bool), double>{};
  rows.forEach((b, mf) {
    out[(b, true)] = mf.$1;
    out[(b, false)] = mf.$2;
  });
  return out;
}

/// 주요 11종 + 콜린(2025 신규) 매트릭스. 본 앱 분석 엔진이 직접 비교에
/// 사용하는 영양소만 채워 두었고, 그 외는 향후 추가될 수 있습니다.
final Map<String, NutrientReference> kKDRIs2025 = {
  // ── 비타민D (μg → IU 환산은 호출 측에서 처리) ────────────────
  // 2020 AI = 10μg (성인) / 15μg (65+). 2025 동일.
  'vitamin_d_iu': NutrientReference(
    name: '비타민D',
    unit: 'IU',
    matrix: _matrix({
      KAgeBracket.infant0to5: (200, 200),
      KAgeBracket.infant6to11: (200, 200),
      KAgeBracket.child1to2: (200, 200),
      KAgeBracket.child3to5: (200, 200),
      KAgeBracket.child6to8: (200, 200),
      KAgeBracket.child9to11: (400, 400),
      KAgeBracket.teen12to14: (400, 400),
      KAgeBracket.teen15to18: (400, 400),
      KAgeBracket.adult19to29: (400, 400),
      KAgeBracket.adult30to49: (400, 400),
      KAgeBracket.adult50to64: (400, 400),
      KAgeBracket.elderly65to74: (600, 600),
      KAgeBracket.elderly75plus: (600, 600),
    }),
    upperLimit: 4000, // UL = 100μg
    note: '2025 KDRIs AI: 성인 10μg/일 (=400 IU), 65세+ 15μg/일.',
  ),

  // ── 비타민C ───────────────────────────────────────────────
  'vitamin_c_mg': NutrientReference(
    name: '비타민C',
    unit: 'mg',
    matrix: _matrix({
      KAgeBracket.infant0to5: (40, 40),
      KAgeBracket.infant6to11: (45, 45),
      KAgeBracket.child1to2: (35, 35),
      KAgeBracket.child3to5: (40, 40),
      KAgeBracket.child6to8: (50, 50),
      KAgeBracket.child9to11: (70, 70),
      KAgeBracket.teen12to14: (90, 90),
      KAgeBracket.teen15to18: (100, 100),
      KAgeBracket.adult19to29: (100, 100),
      KAgeBracket.adult30to49: (100, 100),
      KAgeBracket.adult50to64: (100, 100),
      KAgeBracket.elderly65to74: (100, 100),
      KAgeBracket.elderly75plus: (100, 100),
    }),
    pregnancyAdd: 10,
    lactationAdd: 35,
    upperLimit: 2000,
  ),

  // ── 엽산 (Vitamin B9, μg DFE) ────────────────────────────
  'vitamin_b9_mcg': NutrientReference(
    name: '엽산',
    unit: 'mcg',
    matrix: _matrix({
      KAgeBracket.infant0to5: (65, 65),
      KAgeBracket.infant6to11: (90, 90),
      KAgeBracket.child1to2: (150, 150),
      KAgeBracket.child3to5: (180, 180),
      KAgeBracket.child6to8: (220, 220),
      KAgeBracket.child9to11: (300, 300),
      KAgeBracket.teen12to14: (360, 360),
      KAgeBracket.teen15to18: (400, 400),
      KAgeBracket.adult19to29: (400, 400),
      KAgeBracket.adult30to49: (400, 400),
      KAgeBracket.adult50to64: (400, 400),
      KAgeBracket.elderly65to74: (400, 400),
      KAgeBracket.elderly75plus: (400, 400),
    }),
    pregnancyAdd: 220,
    lactationAdd: 150,
    upperLimit: 1000,
    note: 'μg DFE 기준. 임신부 +220 (2025 표).',
  ),

  // ── 비타민B12 ─────────────────────────────────────────────
  'vitamin_b12_mcg': NutrientReference(
    name: '비타민B12',
    unit: 'mcg',
    matrix: _matrix({
      KAgeBracket.infant0to5: (0.3, 0.3),
      KAgeBracket.infant6to11: (0.5, 0.5),
      KAgeBracket.child1to2: (0.9, 0.9),
      KAgeBracket.child3to5: (1.1, 1.1),
      KAgeBracket.child6to8: (1.3, 1.3),
      KAgeBracket.child9to11: (1.7, 1.7),
      KAgeBracket.teen12to14: (2.3, 2.3),
      KAgeBracket.teen15to18: (2.4, 2.4),
      KAgeBracket.adult19to29: (2.4, 2.4),
      KAgeBracket.adult30to49: (2.4, 2.4),
      KAgeBracket.adult50to64: (2.4, 2.4),
      KAgeBracket.elderly65to74: (2.4, 2.4),
      KAgeBracket.elderly75plus: (2.4, 2.4),
    }),
    pregnancyAdd: 0.2,
    lactationAdd: 0.4,
    // UL 미설정 (수용성).
  ),

  // ── 칼슘 ──────────────────────────────────────────────────
  'calcium_mg': NutrientReference(
    name: '칼슘',
    unit: 'mg',
    matrix: _matrix({
      KAgeBracket.infant0to5: (250, 250),
      KAgeBracket.infant6to11: (300, 300),
      KAgeBracket.child1to2: (500, 500),
      KAgeBracket.child3to5: (600, 600),
      KAgeBracket.child6to8: (700, 700),
      KAgeBracket.child9to11: (800, 800),
      KAgeBracket.teen12to14: (1000, 900),
      KAgeBracket.teen15to18: (900, 800),
      KAgeBracket.adult19to29: (800, 700),
      KAgeBracket.adult30to49: (800, 700),
      KAgeBracket.adult50to64: (750, 800),
      KAgeBracket.elderly65to74: (700, 800),
      KAgeBracket.elderly75plus: (700, 800),
    }),
    pregnancyAdd: 0,
    lactationAdd: 0,
    upperLimit: 2500,
  ),

  // ── 철분 ──────────────────────────────────────────────────
  'iron_mg': NutrientReference(
    name: '철분',
    unit: 'mg',
    matrix: _matrix({
      KAgeBracket.infant0to5: (0.3, 0.3),
      KAgeBracket.infant6to11: (6, 6),
      KAgeBracket.child1to2: (6, 6),
      KAgeBracket.child3to5: (7, 7),
      KAgeBracket.child6to8: (9, 9),
      KAgeBracket.child9to11: (11, 10),
      KAgeBracket.teen12to14: (14, 16),
      KAgeBracket.teen15to18: (14, 14),
      KAgeBracket.adult19to29: (10, 14),
      KAgeBracket.adult30to49: (10, 14),
      KAgeBracket.adult50to64: (10, 8),
      KAgeBracket.elderly65to74: (9, 8),
      KAgeBracket.elderly75plus: (9, 7),
    }),
    pregnancyAdd: 10,
    lactationAdd: 0,
    upperLimit: 45,
    note: '여성 19-49세는 생리로 인한 손실로 +4mg. 임신부 +10mg.',
  ),

  // ── 마그네슘 ───────────────────────────────────────────────
  'magnesium_mg': NutrientReference(
    name: '마그네슘',
    unit: 'mg',
    matrix: _matrix({
      KAgeBracket.infant0to5: (25, 25),
      KAgeBracket.infant6to11: (55, 55),
      KAgeBracket.child1to2: (80, 80),
      KAgeBracket.child3to5: (110, 110),
      KAgeBracket.child6to8: (150, 150),
      KAgeBracket.child9to11: (220, 220),
      KAgeBracket.teen12to14: (320, 290),
      KAgeBracket.teen15to18: (410, 340),
      KAgeBracket.adult19to29: (360, 280),
      KAgeBracket.adult30to49: (370, 280),
      KAgeBracket.adult50to64: (370, 280),
      KAgeBracket.elderly65to74: (350, 270),
      KAgeBracket.elderly75plus: (350, 270),
    }),
    pregnancyAdd: 40,
    lactationAdd: 0,
    upperLimit: 350, // 보충제 기준 (식이 무관)
    note: 'UL은 보충제(추가 섭취) 기준. 식품 섭취는 무관.',
  ),

  // ── 아연 ──────────────────────────────────────────────────
  'zinc_mg': NutrientReference(
    name: '아연',
    unit: 'mg',
    matrix: _matrix({
      KAgeBracket.infant0to5: (2, 2),
      KAgeBracket.infant6to11: (3, 3),
      KAgeBracket.child1to2: (3, 3),
      KAgeBracket.child3to5: (4, 4),
      KAgeBracket.child6to8: (5, 5),
      KAgeBracket.child9to11: (8, 7),
      KAgeBracket.teen12to14: (8, 8),
      KAgeBracket.teen15to18: (10, 9),
      KAgeBracket.adult19to29: (10, 8),
      KAgeBracket.adult30to49: (10, 8),
      KAgeBracket.adult50to64: (9, 7),
      KAgeBracket.elderly65to74: (9, 7),
      KAgeBracket.elderly75plus: (9, 7),
    }),
    pregnancyAdd: 2.5,
    lactationAdd: 5,
    upperLimit: 35,
  ),

  // ── 오메가-3 (총량) ───────────────────────────────────────
  // KDRIs 2020 AI: ALA 0.8% 에너지(약 1.6g/일), EPA+DHA 권장 없음.
  // 본 앱 분석 임계는 EPA+DHA+ALA 합산 1g/일로 단순화.
  'omega3_total_mg': NutrientReference(
    name: '오메가3',
    unit: 'mg',
    matrix: _matrix({
      KAgeBracket.infant0to5: (200, 200),
      KAgeBracket.infant6to11: (300, 300),
      KAgeBracket.child1to2: (400, 400),
      KAgeBracket.child3to5: (500, 500),
      KAgeBracket.child6to8: (700, 700),
      KAgeBracket.child9to11: (900, 900),
      KAgeBracket.teen12to14: (1000, 1000),
      KAgeBracket.teen15to18: (1000, 1000),
      KAgeBracket.adult19to29: (1000, 1000),
      KAgeBracket.adult30to49: (1000, 1000),
      KAgeBracket.adult50to64: (1000, 1000),
      KAgeBracket.elderly65to74: (1000, 1000),
      KAgeBracket.elderly75plus: (1000, 1000),
    }),
    pregnancyAdd: 200,
    lactationAdd: 200,
    note: '본 앱 분석 임계 — KDRIs는 ALA만 AI를 정의. 추천 시뮬레이션용.',
  ),

  // ── 유산균 (보충제 가이드) ────────────────────────────────
  'probiotics_billion_cfu': NutrientReference(
    name: '유산균',
    unit: '억CFU',
    matrix: _matrix({
      KAgeBracket.infant0to5: (1, 1),
      KAgeBracket.infant6to11: (1, 1),
      KAgeBracket.child1to2: (5, 5),
      KAgeBracket.child3to5: (5, 5),
      KAgeBracket.child6to8: (10, 10),
      KAgeBracket.child9to11: (10, 10),
      KAgeBracket.teen12to14: (10, 10),
      KAgeBracket.teen15to18: (10, 10),
      KAgeBracket.adult19to29: (10, 10),
      KAgeBracket.adult30to49: (10, 10),
      KAgeBracket.adult50to64: (10, 10),
      KAgeBracket.elderly65to74: (10, 10),
      KAgeBracket.elderly75plus: (10, 10),
    }),
    note: 'KDRIs 영양소 아님 — 보충제 일반 권고치(억CFU/일).',
  ),

  // ── 코엔자임Q10 (보충제 가이드) ────────────────────────────
  'coenzyme_q10_mg': NutrientReference(
    name: '코엔자임Q10',
    unit: 'mg',
    matrix: _matrix({
      KAgeBracket.adult19to29: (100, 100),
      KAgeBracket.adult30to49: (100, 100),
      KAgeBracket.adult50to64: (100, 100),
      KAgeBracket.elderly65to74: (100, 100),
      KAgeBracket.elderly75plus: (100, 100),
    }),
    note: 'KDRIs 영양소 아님 — 보충제 일반 권고치.',
  ),

  // ── 콜린 (Choline, 2025 신규) ─────────────────────────────
  'choline_mg': NutrientReference(
    name: '콜린',
    unit: 'mg',
    matrix: _matrix({
      KAgeBracket.infant0to5: (125, 125),
      KAgeBracket.infant6to11: (150, 150),
      KAgeBracket.child1to2: (200, 200),
      KAgeBracket.child3to5: (250, 250),
      KAgeBracket.child6to8: (300, 300),
      KAgeBracket.child9to11: (375, 375),
      KAgeBracket.teen12to14: (450, 425),
      KAgeBracket.teen15to18: (550, 425),
      KAgeBracket.adult19to29: (550, 425),
      KAgeBracket.adult30to49: (550, 425),
      KAgeBracket.adult50to64: (550, 425),
      KAgeBracket.elderly65to74: (550, 425),
      KAgeBracket.elderly75plus: (550, 425),
    }),
    pregnancyAdd: 25,
    lactationAdd: 125,
    upperLimit: 3500,
    note: '2025 KDRIs 신규 영양소 — 충분섭취량(AI) + UL 동시 설정.',
  ),

  // ── UL만 사용되는 영양소 (RDA 매트릭스 비어 있음) ──────────
  // 분석 엔진은 이 키들에 대해 매트릭스 폴백 → 0 이지만, conflict
  // checker는 upperLimit만 읽으므로 영향 없습니다.
  'vitamin_a_mcg': NutrientReference(
    name: '비타민A',
    unit: 'mcg',
    matrix: _matrix({
      KAgeBracket.adult19to29: (800, 650),
      KAgeBracket.adult30to49: (800, 650),
      KAgeBracket.adult50to64: (750, 600),
      KAgeBracket.elderly65to74: (700, 600),
      KAgeBracket.elderly75plus: (700, 600),
      KAgeBracket.teen15to18: (850, 650),
      KAgeBracket.teen12to14: (750, 650),
      KAgeBracket.child9to11: (600, 550),
      KAgeBracket.child6to8: (450, 400),
      KAgeBracket.child3to5: (350, 350),
      KAgeBracket.child1to2: (250, 250),
      KAgeBracket.infant6to11: (350, 350),
      KAgeBracket.infant0to5: (350, 350),
    }),
    pregnancyAdd: 70,
    lactationAdd: 490,
    upperLimit: 3000,
    note: 'μg RAE 기준. 임신부 +70, 수유부 +490 (2025 표).',
  ),
  'vitamin_e_mg': NutrientReference(
    name: '비타민E',
    unit: 'mg',
    matrix: _matrix({
      KAgeBracket.infant0to5: (3, 3),
      KAgeBracket.infant6to11: (4, 4),
      KAgeBracket.child1to2: (5, 5),
      KAgeBracket.child3to5: (6, 6),
      KAgeBracket.child6to8: (7, 7),
      KAgeBracket.child9to11: (9, 9),
      KAgeBracket.teen12to14: (11, 11),
      KAgeBracket.teen15to18: (12, 12),
      KAgeBracket.adult19to29: (12, 12),
      KAgeBracket.adult30to49: (12, 12),
      KAgeBracket.adult50to64: (12, 12),
      KAgeBracket.elderly65to74: (12, 12),
      KAgeBracket.elderly75plus: (12, 12),
    }),
    pregnancyAdd: 0,
    lactationAdd: 3,
    upperLimit: 540,
    note: 'mg α-TE 기준. 충분섭취량(AI).',
  ),
  'vitamin_b6_mg': NutrientReference(
    name: '비타민B6',
    unit: 'mg',
    matrix: _matrix({
      KAgeBracket.infant0to5: (0.1, 0.1),
      KAgeBracket.infant6to11: (0.3, 0.3),
      KAgeBracket.child1to2: (0.6, 0.6),
      KAgeBracket.child3to5: (0.7, 0.7),
      KAgeBracket.child6to8: (0.9, 0.9),
      KAgeBracket.child9to11: (1.1, 1.1),
      KAgeBracket.teen12to14: (1.5, 1.4),
      KAgeBracket.teen15to18: (1.5, 1.4),
      KAgeBracket.adult19to29: (1.5, 1.4),
      KAgeBracket.adult30to49: (1.5, 1.4),
      KAgeBracket.adult50to64: (1.5, 1.4),
      KAgeBracket.elderly65to74: (1.5, 1.4),
      KAgeBracket.elderly75plus: (1.5, 1.4),
    }),
    pregnancyAdd: 0.8,
    lactationAdd: 0.8,
    upperLimit: 100,
  ),
  // 'niacin_mg' 기존 키는 conflict_checker UL alias로만 사용. 본 매트릭스
  // 키는 products.json과 정합한 'vitamin_b3_mg'로 통일 (둘 다 등록 X).
  'vitamin_b3_mg': NutrientReference(
    name: '나이아신',
    unit: 'mg',
    matrix: _matrix({
      KAgeBracket.infant0to5: (2, 2),
      KAgeBracket.infant6to11: (3, 3),
      KAgeBracket.child1to2: (6, 6),
      KAgeBracket.child3to5: (7, 7),
      KAgeBracket.child6to8: (9, 9),
      KAgeBracket.child9to11: (11, 11),
      KAgeBracket.teen12to14: (15, 15),
      KAgeBracket.teen15to18: (17, 14),
      KAgeBracket.adult19to29: (16, 14),
      KAgeBracket.adult30to49: (16, 14),
      KAgeBracket.adult50to64: (16, 14),
      KAgeBracket.elderly65to74: (14, 13),
      KAgeBracket.elderly75plus: (13, 12),
    }),
    pregnancyAdd: 4,
    lactationAdd: 3,
    upperLimit: 35,
    note: 'mg NE 기준. UL: 니코틴아미드(=일반 보충제).',
  ),
  // ── 비타민B1 (티아민) ─────────────────────────────────────
  'vitamin_b1_mg': NutrientReference(
    name: '비타민B1',
    unit: 'mg',
    matrix: _matrix({
      KAgeBracket.infant0to5: (0.2, 0.2),
      KAgeBracket.infant6to11: (0.3, 0.3),
      KAgeBracket.child1to2: (0.5, 0.5),
      KAgeBracket.child3to5: (0.5, 0.5),
      KAgeBracket.child6to8: (0.7, 0.7),
      KAgeBracket.child9to11: (0.9, 0.9),
      KAgeBracket.teen12to14: (1.1, 1.0),
      KAgeBracket.teen15to18: (1.3, 1.1),
      KAgeBracket.adult19to29: (1.2, 1.1),
      KAgeBracket.adult30to49: (1.2, 1.1),
      KAgeBracket.adult50to64: (1.2, 1.1),
      KAgeBracket.elderly65to74: (1.1, 1.0),
      KAgeBracket.elderly75plus: (1.1, 1.0),
    }),
    pregnancyAdd: 0.4,
    lactationAdd: 0.4,
    // UL 미설정 (수용성 비타민, 과다 섭취 부작용 보고 적음).
  ),
  // ── 비타민B2 (리보플라빈) ────────────────────────────────
  'vitamin_b2_mg': NutrientReference(
    name: '비타민B2',
    unit: 'mg',
    matrix: _matrix({
      KAgeBracket.infant0to5: (0.3, 0.3),
      KAgeBracket.infant6to11: (0.4, 0.4),
      KAgeBracket.child1to2: (0.5, 0.5),
      KAgeBracket.child3to5: (0.6, 0.6),
      KAgeBracket.child6to8: (0.9, 0.8),
      KAgeBracket.child9to11: (1.1, 1.0),
      KAgeBracket.teen12to14: (1.4, 1.2),
      KAgeBracket.teen15to18: (1.7, 1.2),
      KAgeBracket.adult19to29: (1.5, 1.2),
      KAgeBracket.adult30to49: (1.5, 1.2),
      KAgeBracket.adult50to64: (1.5, 1.2),
      KAgeBracket.elderly65to74: (1.4, 1.1),
      KAgeBracket.elderly75plus: (1.3, 1.1),
    }),
    pregnancyAdd: 0.4,
    lactationAdd: 0.5,
  ),
  // ── 판토텐산 (충분섭취량 AI) ────────────────────────────
  'vitamin_b5_mg': NutrientReference(
    name: '판토텐산',
    unit: 'mg',
    matrix: _matrix({
      KAgeBracket.infant0to5: (1.7, 1.7),
      KAgeBracket.infant6to11: (1.9, 1.9),
      KAgeBracket.child1to2: (2, 2),
      KAgeBracket.child3to5: (3, 3),
      KAgeBracket.child6to8: (4, 4),
      KAgeBracket.child9to11: (5, 5),
      KAgeBracket.teen12to14: (5, 5),
      KAgeBracket.teen15to18: (5, 5),
      KAgeBracket.adult19to29: (5, 5),
      KAgeBracket.adult30to49: (5, 5),
      KAgeBracket.adult50to64: (5, 5),
      KAgeBracket.elderly65to74: (5, 5),
      KAgeBracket.elderly75plus: (5, 5),
    }),
    pregnancyAdd: 1,
    lactationAdd: 2,
    note: '충분섭취량(AI). UL 미설정.',
  ),
  // ── 비오틴 (AI) ─────────────────────────────────────────
  'biotin_mcg': NutrientReference(
    name: '비오틴',
    unit: 'mcg',
    matrix: _matrix({
      KAgeBracket.infant0to5: (5, 5),
      KAgeBracket.infant6to11: (7, 7),
      KAgeBracket.child1to2: (9, 9),
      KAgeBracket.child3to5: (12, 12),
      KAgeBracket.child6to8: (15, 15),
      KAgeBracket.child9to11: (20, 20),
      KAgeBracket.teen12to14: (25, 25),
      KAgeBracket.teen15to18: (30, 30),
      KAgeBracket.adult19to29: (30, 30),
      KAgeBracket.adult30to49: (30, 30),
      KAgeBracket.adult50to64: (30, 30),
      KAgeBracket.elderly65to74: (30, 30),
      KAgeBracket.elderly75plus: (30, 30),
    }),
    pregnancyAdd: 0,
    lactationAdd: 5,
    note: '충분섭취량(AI). UL 미설정.',
  ),
  // ── 비타민K (AI) ────────────────────────────────────────
  'vitamin_k_mcg': NutrientReference(
    name: '비타민K',
    unit: 'mcg',
    matrix: _matrix({
      KAgeBracket.infant0to5: (4, 4),
      KAgeBracket.infant6to11: (7, 7),
      KAgeBracket.child1to2: (25, 25),
      KAgeBracket.child3to5: (30, 30),
      KAgeBracket.child6to8: (40, 40),
      KAgeBracket.child9to11: (55, 55),
      KAgeBracket.teen12to14: (70, 65),
      KAgeBracket.teen15to18: (80, 65),
      KAgeBracket.adult19to29: (75, 65),
      KAgeBracket.adult30to49: (75, 65),
      KAgeBracket.adult50to64: (75, 65),
      KAgeBracket.elderly65to74: (75, 65),
      KAgeBracket.elderly75plus: (75, 65),
    }),
    note: '충분섭취량(AI). UL 미설정.',
  ),
  'selenium_mcg': NutrientReference(
    name: '셀레늄',
    unit: 'mcg',
    matrix: _matrix({
      KAgeBracket.infant0to5: (9, 9),
      KAgeBracket.infant6to11: (12, 12),
      KAgeBracket.child1to2: (20, 20),
      KAgeBracket.child3to5: (25, 25),
      KAgeBracket.child6to8: (35, 35),
      KAgeBracket.child9to11: (45, 45),
      KAgeBracket.teen12to14: (60, 60),
      KAgeBracket.teen15to18: (60, 60),
      KAgeBracket.adult19to29: (60, 60),
      KAgeBracket.adult30to49: (60, 60),
      KAgeBracket.adult50to64: (60, 60),
      KAgeBracket.elderly65to74: (60, 60),
      KAgeBracket.elderly75plus: (60, 60),
    }),
    pregnancyAdd: 4,
    lactationAdd: 10,
    upperLimit: 400,
  ),
  'iodine_mcg': NutrientReference(
    name: '요오드',
    unit: 'mcg',
    matrix: _matrix({
      KAgeBracket.infant0to5: (130, 130),
      KAgeBracket.infant6to11: (180, 180),
      KAgeBracket.child1to2: (80, 80),
      KAgeBracket.child3to5: (90, 90),
      KAgeBracket.child6to8: (100, 100),
      KAgeBracket.child9to11: (110, 110),
      KAgeBracket.teen12to14: (130, 130),
      KAgeBracket.teen15to18: (130, 130),
      KAgeBracket.adult19to29: (150, 150),
      KAgeBracket.adult30to49: (150, 150),
      KAgeBracket.adult50to64: (150, 150),
      KAgeBracket.elderly65to74: (150, 150),
      KAgeBracket.elderly75plus: (150, 150),
    }),
    pregnancyAdd: 90,
    lactationAdd: 190,
    upperLimit: 2400,
  ),
  // ── 구리 (mg 단위, products.json 정합) ───────────────────
  'copper_mg': NutrientReference(
    name: '구리',
    unit: 'mg',
    matrix: _matrix({
      KAgeBracket.infant0to5: (0.24, 0.24),
      KAgeBracket.infant6to11: (0.33, 0.33),
      KAgeBracket.child1to2: (0.29, 0.29),
      KAgeBracket.child3to5: (0.36, 0.36),
      KAgeBracket.child6to8: (0.46, 0.46),
      KAgeBracket.child9to11: (0.59, 0.59),
      KAgeBracket.teen12to14: (0.71, 0.71),
      KAgeBracket.teen15to18: (0.85, 0.85),
      KAgeBracket.adult19to29: (0.85, 0.80),
      KAgeBracket.adult30to49: (0.85, 0.80),
      KAgeBracket.adult50to64: (0.85, 0.80),
      KAgeBracket.elderly65to74: (0.85, 0.80),
      KAgeBracket.elderly75plus: (0.85, 0.80),
    }),
    pregnancyAdd: 0.13,
    lactationAdd: 0.48,
    upperLimit: 10,
    note: 'mg 단위. 1 mg = 1000 mcg. UL=10mg=10000mcg와 동일.',
  ),
  // ── 망간 (mg, AI) ───────────────────────────────────────
  'manganese_mg': NutrientReference(
    name: '망간',
    unit: 'mg',
    matrix: _matrix({
      KAgeBracket.infant0to5: (0.01, 0.01),
      KAgeBracket.infant6to11: (0.6, 0.6),
      KAgeBracket.child1to2: (1.5, 1.5),
      KAgeBracket.child3to5: (2.0, 2.0),
      KAgeBracket.child6to8: (2.5, 2.5),
      KAgeBracket.child9to11: (3.0, 3.0),
      KAgeBracket.teen12to14: (3.5, 3.5),
      KAgeBracket.teen15to18: (4.0, 3.5),
      KAgeBracket.adult19to29: (4.0, 3.5),
      KAgeBracket.adult30to49: (4.0, 3.5),
      KAgeBracket.adult50to64: (4.0, 3.5),
      KAgeBracket.elderly65to74: (4.0, 3.5),
      KAgeBracket.elderly75plus: (4.0, 3.5),
    }),
    pregnancyAdd: 0,
    lactationAdd: 0,
    upperLimit: 11,
    note: '충분섭취량(AI). 보충제 + 식품 합산 UL.',
  ),
};

/// 단일 진입점 — 페르소나 + 영양소 키 → 권장량.
/// 영양소가 표에 없으면 `null`을 반환하므로 호출자가 폴백하면 됩니다.
double? recommendedKDRIs2025({
  required String nutrient,
  required int age,
  required bool isMale,
  bool isPregnant = false,
  bool isLactating = false,
}) {
  final ref = kKDRIs2025[nutrient];
  if (ref == null) return null;
  final v = ref.recommendedFor(
    age: age,
    isMale: isMale,
    isPregnant: isPregnant,
    isLactating: isLactating,
  );
  if (v <= 0) return null;
  return v;
}

/// 영양소의 상한섭취량 (UL). 없으면 `null`.
double? upperLimitKDRIs2025(String nutrient) =>
    kKDRIs2025[nutrient]?.upperLimit;

/// 영양소의 한글 표시명. 매트릭스에 없으면 `null` (호출자가 폴백 가능).
String? nameKDRIs2025(String nutrient) => kKDRIs2025[nutrient]?.name;
