// PART 9 컨벤션: "영문 괄호(KDRIs 등) 사용자 면 노출 X".
// 멤버 상세 화면 + 면책 푸터 톤다운 회귀 가드. 코드 주석/내부 식별자/
// 처리방침의 영문 표기는 검사 범위 밖.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:alyak/core/widgets/disclaimer_footer.dart';

void main() {
  group('PART 9 — 영문 괄호 사용자 노출 금지', () {
    testWidgets('DisclaimerFooter 본문에 KDRIs 없고 2줄 톤다운', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: DisclaimerFooter()),
      ));
      await tester.pump();
      expect(find.textContaining('KDRIs'), findsNothing);
      expect(find.textContaining('(KDRI'), findsNothing);
      expect(find.textContaining('일반 영양 정보를 제공해요'), findsOneWidget);
      expect(find.textContaining('의사·약사 지시를 우선'), findsOneWidget);
    });

    testWidgets('ProductInfoDisclaimer 본문에 KDRIs 미포함', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: ProductInfoDisclaimer()),
      ));
      await tester.pump();
      expect(find.textContaining('KDRIs'), findsNothing);
      expect(find.textContaining('제품 라벨 기반'), findsOneWidget);
    });
  });
}
