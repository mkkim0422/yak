// Verifies the 0/1/N branching of pickMemberId. Spawns a tiny shell screen
// that calls pickMemberId on tap and inspects what flows back.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:alyak/core/widgets/member_picker_sheet.dart';
import 'package:alyak/features/family/models/family_member.dart';
import 'package:alyak/features/family/providers/family_provider.dart';

FamilyMember _member(String id, String name, {Relationship rel = Relationship.self}) {
  final now = DateTime(2026, 1, 1);
  return FamilyMember(
    id: id,
    name: name,
    relationship: rel,
    birthYear: 1990,
    sex: Sex.female,
    createdAt: now,
    updatedAt: now,
  );
}

ProviderScope _scope({
  required Widget child,
  List<FamilyMember> members = const [],
}) {
  return ProviderScope(
    overrides: [
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

class _Probe extends ConsumerStatefulWidget {
  final void Function(String?) onResult;
  const _Probe({required this.onResult});

  @override
  ConsumerState<_Probe> createState() => _ProbeState();
}

class _ProbeState extends ConsumerState<_Probe> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: TextButton(
        onPressed: () async {
          final id = await pickMemberId(
            context,
            ref,
            purpose: '누구의 영양제를 추천받을까요?',
          );
          widget.onResult(id);
        },
        child: const Text('GO'),
      ),
    );
  }
}

GoRouter _router(Widget home) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (_, _) => home),
      GoRoute(
        path: '/onboarding/family-add',
        builder: (_, _) => const Scaffold(body: Text('add-family-route')),
      ),
    ],
  );
}

void main() {
  group('pickMemberId', () {
    testWidgets('0 members → empty-state sheet, returns null', (tester) async {
      String? result = 'sentinel';
      await tester.pumpWidget(_scope(
        child: MaterialApp.router(
          routerConfig: _router(_Probe(onResult: (id) => result = id)),
        ),
      ));
      await tester.tap(find.text('GO'));
      await tester.pumpAndSettle();

      expect(find.text('먼저 가족을 추가해주세요'), findsOneWidget);
      expect(find.text('+ 가족 추가하기'), findsOneWidget);

      // Dismiss the sheet by tapping outside (drag handle area).
      Navigator.of(tester.element(find.text('먼저 가족을 추가해주세요'))).pop();
      await tester.pumpAndSettle();
      expect(result, isNull);
    });

    testWidgets('1 member → no UI, returns that id', (tester) async {
      String? result;
      await tester.pumpWidget(_scope(
        members: [_member('m1', '본인')],
        child: MaterialApp.router(
          routerConfig: _router(_Probe(onResult: (id) => result = id)),
        ),
      ));
      await tester.tap(find.text('GO'));
      await tester.pumpAndSettle();

      expect(result, 'm1');
      // No sheet should be visible.
      expect(find.text('누구의 영양제를 추천받을까요?'), findsNothing);
      expect(find.text('먼저 가족을 추가해주세요'), findsNothing);
    });

    testWidgets('2+ members → picker sheet, returns selected id',
        (tester) async {
      String? result;
      await tester.pumpWidget(_scope(
        members: [
          _member('m1', '본인'),
          _member('m2', '아내', rel: Relationship.wife),
        ],
        child: MaterialApp.router(
          routerConfig: _router(_Probe(onResult: (id) => result = id)),
        ),
      ));
      await tester.tap(find.text('GO'));
      await tester.pumpAndSettle();

      expect(find.text('누구의 영양제를 추천받을까요?'), findsOneWidget);
      expect(find.text('본인'), findsOneWidget);
      expect(find.text('아내'), findsOneWidget);

      await tester.tap(find.text('아내'));
      await tester.pumpAndSettle();

      expect(result, 'm2');
    });
  });
}
