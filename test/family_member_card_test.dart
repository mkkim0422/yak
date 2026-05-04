import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:alyak/core/data/models/family_input.dart';
import 'package:alyak/core/theme/app_colors.dart';
import 'package:alyak/features/family/models/family_member.dart';
import 'package:alyak/features/family/providers/family_provider.dart';
import 'package:alyak/features/home/providers/member_analysis_provider.dart';
import 'package:alyak/features/home/widgets/family_cards_section.dart';
import 'package:alyak/features/home/widgets/family_member_card.dart';

FamilyMember _member(
  String id, {
  String name = '홍길동',
  int age = 40,
  Gender gender = Gender.male,
  FamilyRelationship relationship = FamilyRelationship.self,
}) {
  return FamilyMember(
    id: id,
    relationship: relationship,
    input: FamilyInput(
      name: name,
      age: age,
      gender: gender,
      ageGroup: ageGroupFromAge(age),
    ),
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

Widget _wrap(List<FamilyMember> members, Widget child) {
  return ProviderScope(
    overrides: [
      familyProvider.overrideWith(
        (ref) => FamilyMembersNotifier()..setMembers(members),
      ),
    ],
    child: MaterialApp.router(routerConfig: _router(child)),
  );
}

void main() {
  group('FamilyCardsSection layouts', () {
    testWidgets('count == 0 → empty state', (tester) async {
      await tester.pumpWidget(_wrap(const [], const FamilyCardsSection()));
      await tester.pump();
      expect(find.text('아직 등록된 가족이 없어요'), findsOneWidget);
      expect(find.text('+ 가족 추가하기'), findsOneWidget);
    });

    testWidgets('count == 1 → large card with relationship label',
        (tester) async {
      final m = _member('m1', name: '김민기');
      await tester.pumpWidget(_wrap([m], const FamilyCardsSection()));
      await tester.pump();
      expect(find.textContaining('김민기'), findsWidgets);
      expect(find.textContaining('본인'), findsWidgets);
    });

    testWidgets('count == 2 → two compact cards', (tester) async {
      final members = [_member('m1', name: 'A'), _member('m2', name: 'B')];
      await tester.pumpWidget(_wrap(members, const FamilyCardsSection()));
      await tester.pump();
      expect(find.byType(FamilyMemberCard), findsNWidgets(2));
    });

    testWidgets('count == 3 → 1 main + 2 compact', (tester) async {
      final members = [
        _member('m1', name: 'A'),
        _member('m2', name: 'B'),
        _member('m3', name: 'C'),
      ];
      await tester.pumpWidget(_wrap(members, const FamilyCardsSection()));
      await tester.pump();
      expect(find.byType(FamilyMemberCard), findsNWidgets(3));
    });

    testWidgets('count == 4 → 2x2 grid', (tester) async {
      final members = List.generate(
          4, (i) => _member('m$i', name: 'M$i'));
      await tester.pumpWidget(_wrap(members, const FamilyCardsSection()));
      await tester.pump();
      expect(find.byType(FamilyMemberCard), findsNWidgets(4));
    });

    testWidgets('count == 5 → grid renders 5 cards', (tester) async {
      final members = List.generate(
          5, (i) => _member('m$i', name: 'M$i'));
      await tester.pumpWidget(_wrap(members, const FamilyCardsSection()));
      await tester.pump();
      expect(find.byType(FamilyMemberCard), findsNWidgets(5));
    });
  });

  group('Card color coding by deficit count', () {
    testWidgets('zero deficits → success palette', (tester) async {
      final m = _member('m1');
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            familyProvider.overrideWith(
              (ref) => FamilyMembersNotifier()..setMembers([m]),
            ),
            memberNutrientAnalysisProvider(m.id).overrideWithValue(
              MemberAnalysis.empty(),
            ),
          ],
          child: MaterialApp.router(
            routerConfig: _router(
              FamilyMemberCard(member: m),
            ),
          ),
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
      expect(deco.color, AppColors.successLight);
    });

    testWidgets('three deficits → attention palette', (tester) async {
      final m = _member('m1');
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
        lastCheckupDate: null,
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            familyProvider.overrideWith(
              (ref) => FamilyMembersNotifier()..setMembers([m]),
            ),
            memberNutrientAnalysisProvider(m.id).overrideWithValue(analysis),
          ],
          child: MaterialApp.router(
            routerConfig: _router(FamilyMemberCard(member: m)),
          ),
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
      expect(deco.color, AppColors.attentionLight);
    });
  });

  group('MemberAnalysis status text', () {
    test('empty deficits → 충분', () {
      const a = MemberAnalysis(
        deficits: [],
        sufficient: [],
        currentProductCount: 0,
        lastCheckupDate: null,
      );
      expect(a.statusText, '충분히 챙기시는 중');
      expect(a.statusEmoji, '✅');
    });

    test('two deficits → ⚠️', () {
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
        lastCheckupDate: null,
      );
      expect(a.statusEmoji, '⚠️');
      expect(a.statusText, '2개 부족');
    });

    test('four deficits → 🟠', () {
      final a = MemberAnalysis(
        deficits: [
          for (int i = 0; i < 4; i++)
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
        lastCheckupDate: null,
      );
      expect(a.statusEmoji, '🟠');
    });
  });

  group('FamilyMember avatar emoji', () {
    test('relationship + age picks correct emoji', () {
      expect(_member('m', relationship: FamilyRelationship.self).avatarEmoji,
          '👤');
      expect(
          _member('m', relationship: FamilyRelationship.childSon, age: 8)
              .avatarEmoji,
          '👦');
      expect(
          _member('m', relationship: FamilyRelationship.childSon, age: 16)
              .avatarEmoji,
          '🧑');
      expect(
          _member('m', relationship: FamilyRelationship.parentMother, age: 70)
              .avatarEmoji,
          '👵');
      expect(
          _member('m', relationship: FamilyRelationship.parentFather, age: 50)
              .avatarEmoji,
          '👨');
    });
  });
}
