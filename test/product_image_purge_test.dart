// 단계 14 부분 — 라이선스 위험군 사진 폐기 회귀 가드.
//
// V1 출시 전 audit (assets/images/products/_LICENSES.md, 2026-05-09) 결과
// 🔴(203) + 🟡(10) = 213장은 라이선스 위험으로 폐기되었고, 🟢 37장만 잔존.
// 본 테스트는 양방향 락:
//   1. 디스크의 모든 *.jpg 가 잔존 37 productId 안에 포함되어야 함
//      → 폐기된 jpg 가 다시 추가되면 fail
//   2. 잔존 37 productId 의 jpg 가 디스크에 모두 존재해야 함
//      → 안전한 사진이 실수로 삭제되면 fail
//
// 폴백 동작은 lib/core/widgets/product_image.dart 의 Image.asset
// errorBuilder → _CategoryFallback. 폐기된 jpg 는 asset bundle 에서도
// 자동 제외되어 자동 폴백.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// 🟢 audit 분류 — 공식·공공 출처 (제조사 공식 / 약학정보원 / Atomy CDN
/// 등). _LICENSES.md "공식·공공 (사용 가능성 높음)" 섹션과 1:1 일치.
const Set<String> kAllowedProductImageIds = {
  // CJ 웰케어 공식
  'cj_byocore_500',
  'cj_byocore_skin_immune',
  // 그라디움 공식
  'iherb_lcarnitine',
  'msm_general',
  'curcumin_general',
  // 그리팅 공식
  'solgar_d3_1000',
  // 듀오락 공식
  'duolac_kids',
  // RPS 약국 공식
  'cla_general',
  // 애터미 공식 CDN (14)
  'atomy_propolis_gummy',
  'atomy_propolis_gummy_v2',
  'atomy_megavit_c_2000',
  'atomy_b_complex',
  'atomy_rtg_omega3',
  'atomy_saw_palmetto',
  'atomy_inner_collagen',
  'atomy_psyllium',
  'atomy_kids_gummy',
  'atomy_kids_probiotics',
  'atomy_spirulina',
  'atomy_proactamin',
  'atomy_hemohim',
  'atomy_hemohim_v2',
  // 약학정보원 (10)
  'ginexin_f_120',
  'ginexin_f_80',
  'dikamax_1000',
  'dikamax_d',
  'donga_dicamax_d',
  '5htp_general',
  'yuhan_beecom_c',
  'yuhan_vit_cd',
  'aronamin_gold',
  'imp_gold',
  // 임팩타민 공식 (대웅제약)
  'imp_power_a_plus',
  'imp_active',
  // 한미양행 공식 CDN
  'hanmi_mothers_general',
  // 헬스맵 공식
  'melatonin_general',
  // 헬스베네핏 공식
  'jks_hongijanggun_2',
};

void main() {
  // 테스트 실행 위치는 보통 프로젝트 루트. flutter test 가 그렇게 실행함.
  final productsDir = Directory('assets/images/products');

  group('단계 14 — 라이선스 위험군 사진 폐기 회귀 가드', () {
    test('잔존 productId 셋 — 37개 (audit 분류 🟢 카운트 락)', () {
      expect(kAllowedProductImageIds.length, 37,
          reason: '_LICENSES.md 🟢 분류 갯수 변경 시 본 상수 + audit 문서 동시 갱신');
    });

    test('products 디렉토리는 존재', () {
      expect(productsDir.existsSync(), isTrue,
          reason: 'assets/images/products 자체는 폴더는 보존되어야 함 (_LICENSES.md + 잔존 jpg)');
    });

    test('디스크의 모든 *.jpg 는 잔존 37 셋 안에 있어야 함 (폐기 락)', () {
      final actual = productsDir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.toLowerCase().endsWith('.jpg'))
          .map((f) =>
              f.uri.pathSegments.last.replaceAll(RegExp(r'\.jpg$'), ''))
          .toSet();

      final unexpected = actual.difference(kAllowedProductImageIds);
      expect(unexpected, isEmpty,
          reason: 'audit 에서 🔴/🟡 로 분류돼 폐기된 jpg 가 다시 추가됨 — '
              '_LICENSES.md 분류 검토 후 의도된 추가면 본 상수 같이 갱신');
    });

    test('잔존 37 productId 의 jpg 는 모두 디스크에 존재해야 함 (보존 락)', () {
      final missing = <String>[];
      for (final id in kAllowedProductImageIds) {
        final f = File('${productsDir.path}/$id.jpg');
        if (!f.existsSync()) missing.add(id);
      }
      expect(missing, isEmpty,
          reason: '🟢 분류된 잔존 사진이 사라짐 — _LICENSES.md 와 동기화 필요');
    });

    test('잔존 jpg 갯수 = 37 (분류 결과와 1:1 매핑)', () {
      final jpgCount = productsDir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.toLowerCase().endsWith('.jpg'))
          .length;
      expect(jpgCount, kAllowedProductImageIds.length);
    });

    test('_LICENSES.md 자체는 보존 (문서 source of truth)', () {
      expect(File('${productsDir.path}/_LICENSES.md').existsSync(), isTrue);
    });
  });
}
