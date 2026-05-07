import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:alyak/core/data/product_repository.dart';
import 'package:alyak/core/theme/app_colors.dart';
import 'package:alyak/features/family/models/family_member.dart';
import 'package:alyak/features/family/providers/family_provider.dart';
import 'package:alyak/features/home/providers/member_analysis_provider.dart';
import 'package:alyak/features/home/widgets/family_cards_section.dart';
import 'package:alyak/features/home/widgets/family_member_card.dart';

FamilyMember member(
  String id, {
  String name = '홍길동',
  int age = 40,
  Sex sex = Sex.male,
  Relationship relationship = Relationship.self,
}) {
  final now = DateTime(2026, 1, 1);
  return FamilyMember(
    id: id,
    name: name,
    birthYear: DateTime.now().year - age,
    sex: sex,
    relationship: relationship,
    createdAt: now,
    updatedAt: now,
  );
}

GoRouter _router(Widget child) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => Scaffold(
          body: SingleChildScrollView(child: child),
        ),
      ),
      GoRoute(
        path: '/family/:id',
        builder: (context, state) =>
            Scaffold(body: Text('detail-${state.pathParameters['id']}')),
      ),
      GoRoute(
        path: '/onboarding/family-add',
        builder: (context, state) =>
            const Scaffold(body: Text('add-family-route')),
      ),
    ],
  );
}

FamilyMembersNotifier _notifierFor(List<FamilyMember> members) {
  final notifier = FamilyMembersNotifier(
    InMemoryFamilyStorage(),
    onMemberRemoved: noopMemberRemoved,
  );
  notifier.debugReplace(members);
  return notifier;
}

Widget _wrap(
  List<FamilyMember> members,
  Widget child, {
  Map<String, MemberAnalysis> analysisOverrides = const {},
}) {
  return ProviderScope(
    overrides: [
      productRepositoryProvider.overrideWithValue(ProductRepository()),
      familyMembersProvider.overrideWith((ref) => _notifierFor(members)),
      for (final entry in analysisOverrides.entries)
        memberNutrientAnalysisProvider(entry.key)
            .overrideWithValue(entry.value),
    ],
    child: MaterialApp.router(routerConfig: _router(child)),
  );
}

void main() {
  group('FamilyCardsSection layouts', () {
    testWidgets('count == 0 → empty state', (tester) async {
      await tester.pumpWidget(_wrap(const [], const FamilyCardsSection()));
      await tester.pump();
      expect(find.text('가족을 추가해 주세요'), findsOneWidget);
      expect(find.text('+ 가족 추가하기'), findsOneWidget);
    });

    testWidgets('count == 1 → large card with relationship label',
        (tester) async {
      final m = member('m1', name: '김민기');
      await tester.pumpWidget(_wrap([m], const FamilyCardsSection()));
      await tester.pump();
      expect(find.textContaining('김민기'), findsWidgets);
      expect(find.textContaining('본인'), findsWidgets);
    });

    testWidgets('count == 2 → two compact cards', (tester) async {
      final members = [member('m1', name: 'A'), member('m2', name: 'B')];
      await tester.pumpWidget(_wrap(members, const FamilyCardsSection()));
      await tester.pump();
      expect(find.byType(FamilyMemberCard), findsNWidgets(2));
    });

    testWidgets('count == 3 → 1 main + 2 compact', (tester) async {
      final members = [
        member('m1', name: 'A'),
        member('m2', name: 'B'),
        member('m3', name: 'C'),
      ];
      await tester.pumpWidget(_wrap(members, const FamilyCardsSection()));
      await tester.pump();
      expect(find.byType(FamilyMemberCard), findsNWidgets(3));
    });

    testWidgets('count == 4 → 2x2 grid', (tester) async {
      final members =
          List.generate(4, (i) => member('m$i', name: 'M$i'));
      await tester.pumpWidget(_wrap(members, const FamilyCardsSection()));
      await tester.pump();
      expect(find.byType(FamilyMemberCard), findsNWidgets(4));
    });

    testWidgets('count == 5 → grid renders 5 cards', (tester) async {
      final members =
          List.generate(5, (i) => member('m$i', name: 'M$i'));
      await tester.pumpWidget(_wrap(members, const FamilyCardsSection()));
      await tester.pump();
      expect(find.byType(FamilyMemberCard), findsNWidgets(5));
    });
  });

  // After the persona-driven tone-down the card surface is a calm white with
  // a hairline border on every variant — no more colored top stripes or
  // status outlines. The status signal lives entirely in the small dot
  // (compact) or the soft greyed deficit summary (large).
  group('Card surface stays neutral', () {
    testWidgets('zero deficits → hairline border, no status tint',
        (tester) async {
      final m = member('m1');
      await tester.pumpWidget(
        _wrap(
          [m],
          FamilyMemberCard(member: m),
          analysisOverrides: {m.id: MemberAnalysis.empty()},
        ),
      );
      await tester.pump();
      final container = tester.widget<Container>(find
          .descendant(
            of: find.byType(FamilyMemberCard),
            matching: find.byType(Container),
          )
          .first);
      final deco = container.decoration as BoxDecoration;
      final border = deco.border as Border;
      expect(border.top.color, AppColors.hairline);
    });

    testWidgets('three deficits → still hairline border', (tester) async {
      final m = member('m1');
      final analysis = MemberAnalysis(
        deficits: [
          for (int i = 0; i < 3; i++)
            NutrientDeficit(
              nutrient: 'n$i',
              displayName: 'N$i',
              current: 0,
              recommended: 100,
              percentage: 0,
            ),
        ],
        sufficient: const [],
        currentProductCount: 0,
      );
      await tester.pumpWidget(
        _wrap(
          [m],
          FamilyMemberCard(member: m),
          analysisOverrides: {m.id: analysis},
        ),
      );
      await tester.pump();
      final container = tester.widget<Container>(find
          .descendant(
            of: find.byType(FamilyMemberCard),
            matching: find.byType(Container),
          )
          .first);
      final deco = container.decoration as BoxDecoration;
      final border = deco.border as Border;
      expect(border.top.color, AppColors.hairline);
    });
  });

  group('MemberAnalysis statusText', () {
    test('empty deficits → 충분히 섭취중', () {
      const a = MemberAnalysis(
        deficits: [],
        sufficient: [],
        currentProductCount: 0,
      );
      expect(a.statusText, '충분히 섭취중');
    });

    test('N deficits → "N개 부족" 텍스트', () {
      final a = MemberAnalysis(
        deficits: [
          for (int i = 0; i < 2; i++)
            NutrientDeficit(
              nutrient: 'n$i',
              displayName: 'N$i',
              current: 0,
              recommended: 100,
              percentage: 0,
            ),
        ],
        sufficient: const [],
        currentProductCount: 0,
      );
      expect(a.statusText, '2개 부족');
    });

    // statusEmoji getter는 V1 가족 카드 톤다운에서 dead-getter로 제거됨.
    // 가족 카드의 _StatusDot은 영양제 등록 여부(회색/청록)만 표시하며,
    // 부족/주의 표시는 멤버 진입 후 보충 영양소 카드에서만 노출됩니다.
  });

  group('FamilyMember avatar emoji', () {
    test('relationship + age picks correct emoji', () {
      expect(member('m', relationship: Relationship.self).avatarEmoji, '👤');
      expect(
          member('m', relationship: Relationship.son, age: 8).avatarEmoji,
          '👦');
      expect(
          member('m', relationship: Relationship.son, age: 16).avatarEmoji,
          '🧑');
      expect(
          member('m', relationship: Relationship.mother, age: 70).avatarEmoji,
          '👵');
      expect(
          member('m', relationship: Relationship.father, age: 50).avatarEmoji,
          '👨');
    });
  });
}
