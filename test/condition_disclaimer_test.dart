// 컨디션(증상) 검색 화면의 식품표시광고법 면책 배너 회귀 테스트.
// 식품표시광고법 시행령 별표1 면제 조건 충족 문구를 화면 진입 시
// 사용자가 즉시 볼 수 있어야 한다.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:alyak/core/data/supplement_repository.dart';
import 'package:alyak/core/l10n/app_strings.dart';
import 'package:alyak/features/symptom/screens/symptom_search_screen.dart';

GoRouter _routerWith(Widget child) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (context, state) => child),
      GoRoute(
        path: '/home',
        builder: (context, state) => const Scaffold(body: Text('home')),
      ),
    ],
  );
}

ProviderScope _scope({required Widget child}) {
  return ProviderScope(
    overrides: [
      supplementRepositoryProvider.overrideWithValue(SupplementRepository()),
    ],
    child: child,
  );
}

void main() {
  group('AppStrings.conditionScreenLegalDisclaimer', () {
    test('식약처 면제 조건 핵심 표현을 정확히 포함', () {
      expect(
        AppStrings.conditionScreenLegalDisclaimer,
        contains('직접적인 관련이 없습니다'),
      );
      expect(
        AppStrings.conditionScreenLegalDisclaimer,
        contains('의료진과 상담'),
      );
    });
  });

  group('SymptomSearchScreen 면책 배너', () {
    testWidgets('진입 직후 면책 배너 두 핵심 키워드가 보인다', (tester) async {
      tester.view.physicalSize = const Size(900, 1800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_scope(
        child: MaterialApp.router(
          routerConfig: _routerWith(const SymptomSearchScreen()),
        ),
      ));
      await tester.pump();

      expect(
        find.byKey(const Key('condition-legal-disclaimer')),
        findsOneWidget,
      );
      expect(
        find.textContaining('직접적인 관련이 없습니다'),
        findsOneWidget,
      );
      expect(
        find.textContaining('의료진과 상담'),
        findsOneWidget,
      );
    });
  });
}
