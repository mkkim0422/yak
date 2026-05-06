// Locks in the persona-driven simplification:
//  * 4-row entry list ("영양제 새로 사고 싶어요" 등) is gone — single CTA "영양제 사러 가기" stands in.
//  * compact family card no longer surfaces deficit-name lists or "{N}개 부족" pill.
//  * AppColors.alertBorder/alertInk now resolves to the amber palette, not red.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:alyak/core/data/product_repository.dart';
import 'package:alyak/core/theme/app_colors.dart';
import 'package:alyak/features/family/models/family_member.dart';
import 'package:alyak/features/family/providers/family_provider.dart';
import 'package:alyak/features/home/screens/home_screen.dart';
import 'package:alyak/features/home/widgets/family_member_card.dart';

GoRouter _router(Widget home) => GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(path: '/', builder: (_, _) => home),
        GoRoute(
          path: '/recommendation/:id',
          builder: (_, state) =>
              Scaffold(body: Text('rec-${state.pathParameters['id']}')),
        ),
        GoRoute(
          path: '/onboarding/family-add',
          builder: (_, _) => const Scaffold(body: Text('add-family')),
        ),
        GoRoute(
          path: '/family/:id',
          builder: (_, state) =>
              Scaffold(body: Text('detail-${state.pathParameters['id']}')),
        ),
        GoRoute(
          path: '/settings',
          builder: (_, _) => const Scaffold(body: Text('settings')),
        ),
      ],
    );

ProviderScope _scope(Widget child, List<FamilyMember> members) {
  return ProviderScope(
    overrides: [
      productRepositoryProvider.overrideWithValue(ProductRepository()),
      familyMembersProvider.overrideWith((ref) {
        final n = FamilyMembersNotifier(
          InMemoryFamilyStorage(),
          onMemberRemoved: noopMemberRemoved,
        );
        n.debugReplace(members);
        return n;
      }),
    ],
    child: child,
  );
}

FamilyMember _member(String id, String name) {
  final now = DateTime(2026, 1, 1);
  return FamilyMember(
    id: id,
    name: name,
    relationship: Relationship.self,
    birthYear: 1990,
    sex: Sex.female,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  testWidgets('HomeScreen no longer renders the four-entry menu', (tester) async {
    tester.view.physicalSize = const Size(900, 2200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(_scope(
      MaterialApp.router(
        routerConfig: _router(const HomeScreen()),
      ),
      [_member('m1', '본인')],
    ));
    await tester.pump();

    // Old menu titles must be gone.
    expect(find.text('영양제 새로 사고 싶어요'), findsNothing);
    expect(find.text('지금 먹는 것 점검하기'), findsNothing);
    expect(find.text('증상에 맞는 영양제'), findsNothing);
    expect(find.text('가족 관리'), findsNothing);
    expect(find.text('🎯 무엇을 도와드릴까요?'), findsNothing);

    // New CTA in its place.
    expect(find.text('영양제 사러 가기'), findsOneWidget);
  });

  testWidgets('compact family card shows positive copy only', (tester) async {
    final members = [
      _member('m1', '본인'),
      _member('m2', '아내'),
    ];
    await tester.pumpWidget(_scope(
      MaterialApp.router(routerConfig: _router(const HomeScreen())),
      members,
    ));
    await tester.pump();

    expect(find.byType(FamilyMemberCard), findsNWidgets(2));

    // No "{N}개 부족" pill, no "충분" pill — just the takings count.
    expect(find.textContaining('개 부족'), findsNothing);
    expect(find.text('충분'), findsNothing);
    expect(find.textContaining('💊 0개 복용 중'), findsNWidgets(2));
  });

  test('alertBorder/alertInk resolve to the amber palette (not red)', () {
    expect(AppColors.alertBorder, AppColors.warnBorder);
    expect(AppColors.alertInk, AppColors.warnInk);
    // Brand palette is teal, not Toss blue.
    expect(AppColors.primary, const Color(0xFF00ACC1));
  });
}
