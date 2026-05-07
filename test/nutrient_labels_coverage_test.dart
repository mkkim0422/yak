// 250 DB의 모든 ingredient 키가 nutrient_labels의 한글 매핑을 가지는지
// 보장합니다. 매핑 누락 시 사용자가 영양제 상세에서 영문 키를 보게 되어
// "신뢰성 X" 인식. V1 출시 마무리에서 33개 누락을 일괄 추가했고, 이후
// DB가 늘어나면서 누락 영양소가 다시 생기는 회귀를 본 테스트가 가드.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:alyak/core/data/nutrient_labels.dart';

void main() {
  test('250 DB의 모든 ingredient 키가 nutrientLabel에서 한글로 매핑됨', () {
    final json = jsonDecode(
      File('assets/data/products.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    final products = (json['products'] as List).cast<Map<String, dynamic>>();
    final allKeys = <String>{};
    for (final p in products) {
      final ing = p['ingredients'] as Map<String, dynamic>?;
      if (ing == null) continue;
      allKeys.addAll(ing.keys.cast<String>());
    }

    final unmapped = <String>[];
    for (final key in allKeys) {
      final label = nutrientLabel(key);
      // _humanize() fallback은 베이스를 단순히 Title Case로 변환합니다.
      // 한글 매핑이 있는 키는 한글 문자가 포함되거나 약어(BCAA/CLA 등)로
      // 매핑됩니다 — 영문이 그대로 노출되는 케이스(Collagen Peptide 등)만
      // 누락으로 잡습니다. ASCII-only fallback을 검출.
      final isAsciiHumanized =
          RegExp(r'^[A-Za-z0-9 \-/]+$').hasMatch(label) &&
              !_knownAsciiAbbreviations.contains(label);
      if (isAsciiHumanized) {
        unmapped.add('$key → $label');
      }
    }

    expect(
      unmapped,
      isEmpty,
      reason: '\n매핑 누락 영양소(영문 fallback): \n${unmapped.join('\n')}',
    );
  });
}

/// 한글로 옮길 수 없거나 약어 그대로가 자연스러운 라벨들 — 매핑 검사에서
/// 제외합니다. 사용자에게 보여도 어색하지 않은 케이스.
const Set<String> _knownAsciiAbbreviations = {
  'BCAA',
  'EAA',
  'AAKG',
  'EPA',
  'DHA',
  'ALA',
  'GABA',
  'NAC',
  'CLA',
  '5-HTP',
  'MSM',
  'MCT오일', // contains Korean
  'HCA (가르시니아)', // contains Korean
};
