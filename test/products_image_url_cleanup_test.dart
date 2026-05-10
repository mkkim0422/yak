// 단계 14 후속 (B6) — products.json image_url 정리 회귀 가드.
//
// 단계 14 부분 작업으로 라이선스 위험군 213장 jpg 폐기 후, 본 작업에서
// products.json 의 image_url 외부 URL 메타데이터도 정리. V1 출시 빌드는
// 잔존 37개 (🟢 audit 분류, 제조사 공식 / 약학정보원 / Atomy CDN 등) 의
// image_url 만 보유.
//
// 정책: 폐기된 213개는 image_url = "" (빈 문자열로 명시 마킹).
//   - 빈 문자열 = "image_url 있었지만 폐기됨" (의도 명시)
//   - 필드 제거 = 사용 안 함 (모델은 nullable 이지만 audit 재실행 시 누락
//     vs 폐기 구분이 사라져 오해 가능)
//
// 본 테스트는 양방향 락:
//   1. 잔존 37 셋의 image_url 은 비어있지 않아야 함 (실수 정리 fail)
//   2. 잔존 셋 외 productId의 image_url 은 빈 문자열이어야 함 (재추가 fail)
//   3. data_source 는 모두 보존되어야 함 (라벨 검증 출처 — 본 작업 범위 외,
//      함께 정리되지 않았음 검증)

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'product_image_purge_test.dart' show kAllowedProductImageIds;

void main() {
  late List<Map<String, dynamic>> products;

  setUpAll(() {
    final raw = File('assets/data/products.json').readAsStringSync();
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    products = (decoded['products'] as List)
        .cast<Map<String, dynamic>>();
  });

  group('단계 14 B6 — products.json image_url 정리', () {
    test('products.json 은 250개 (audit 대상 카운트 락)', () {
      expect(products.length, 250);
    });

    test('잔존 37 productId 의 image_url 은 비어있지 않음 (보존 락)', () {
      final missing = <String>[];
      for (final p in products) {
        final id = p['id'] as String;
        if (kAllowedProductImageIds.contains(id)) {
          final url = (p['image_url'] as String?) ?? '';
          if (url.isEmpty) missing.add(id);
        }
      }
      expect(missing, isEmpty,
          reason: '🟢 audit 분류 productId 의 image_url 메타가 사라짐 — '
              '잔존 사진 출처 추적이 깨짐');
    });

    test('잔존 셋 외 productId 의 image_url 은 빈 문자열 (폐기 락)', () {
      final unexpected = <String>[];
      for (final p in products) {
        final id = p['id'] as String;
        if (!kAllowedProductImageIds.contains(id)) {
          final url = (p['image_url'] as String?) ?? '';
          if (url.isNotEmpty) unexpected.add('$id → $url');
        }
      }
      expect(unexpected, isEmpty,
          reason: '폐기된 productId 에 image_url 이 다시 채워짐 — '
              '본 작업의 정리가 무효화됨. 의도된 재추가면 본 productId 를 '
              'kAllowedProductImageIds 에 같이 등록');
    });

    test('빈 image_url 갯수 = 250 - 잔존 셋 카운트', () {
      final emptyCount = products
          .where((p) => ((p['image_url'] as String?) ?? '').isEmpty)
          .length;
      expect(emptyCount, 250 - kAllowedProductImageIds.length,
          reason: '잔존/폐기 합 250 정합성');
    });

    test('data_source 는 모두 보존 (B6 명시 범위 외 변경 0 검증)', () {
      // data_source 는 라벨 검증 출처라 다나와여도 합법 인용 — 본 작업
      // 명시 범위 외. 같이 정리되지 않았음을 락.
      final emptyDataSource = <String>[];
      for (final p in products) {
        final id = p['id'] as String;
        final ds = (p['data_source'] as String?) ?? '';
        if (ds.isEmpty) emptyDataSource.add(id);
      }
      expect(emptyDataSource, isEmpty,
          reason: 'data_source 가 비었음 — 본 작업이 image_url 외 필드를 '
              '건드림 (룰 위반). 또는 원본 데이터 누락');
    });

    test('잔존 image_url 은 외부 URL 형식 (http/https)', () {
      for (final p in products) {
        final id = p['id'] as String;
        if (kAllowedProductImageIds.contains(id)) {
          final url = (p['image_url'] as String?) ?? '';
          expect(url.startsWith('http'), isTrue,
              reason: 'productId=$id 의 image_url 이 외부 URL 형식이 아님: $url');
        }
      }
    });
  });
}
