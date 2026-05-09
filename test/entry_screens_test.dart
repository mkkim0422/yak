import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:alyak/core/legal/legal_documents.dart';
import 'package:alyak/core/notifications/notification_provider.dart';
import 'package:alyak/core/notifications/notification_service.dart';
import 'package:alyak/features/family/models/family_member.dart';
import 'package:alyak/features/family/providers/family_provider.dart';
import 'package:alyak/features/family/screens/family_management_screen.dart';
import 'package:alyak/features/onboarding/screens/notification_setup_screen.dart';
import 'package:alyak/features/onboarding/screens/privacy_consent_screen.dart';
import 'package:alyak/features/onboarding/screens/welcome_screen.dart';

class _StubNotificationService extends NotificationService {
  bool requestedPermission = false;
  TimeOfDay? lastMorning;
  TimeOfDay? lastEvening;
  bool didCancelAll = false;

  @override
  Future<void> ensureInitialized() async {}

  @override
  Future<bool> requestPermission() async {
    requestedPermission = true;
    return true;
  }

  @override
  Future<void> rescheduleDaily({
    TimeOfDay? morning,
    TimeOfDay? evening,
    int familyCount = 1,
  }) async {
    lastMorning = morning;
    lastEvening = evening;
  }

  @override
  Future<void> cancelAll() async {
    didCancelAll = true;
  }
}

GoRouter _routerWith(Widget child, {String path = '/'}) {
  return GoRouter(
    initialLocation: path,
    routes: [
      GoRoute(path: path, builder: (context, state) => child),
      GoRoute(
        path: '/onboarding/welcome',
        builder: (context, state) =>
            const Scaffold(body: Text('welcome-route')),
      ),
      GoRoute(
        path: '/onboarding/family-add',
        builder: (context, state) =>
            const Scaffold(body: Text('family-add-route')),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const Scaffold(body: Text('home-route')),
      ),
      GoRoute(
        path: '/family/:id/edit',
        builder: (context, state) =>
            Scaffold(body: Text('edit-${state.pathParameters['id']}')),
      ),
    ],
  );
}

ProviderScope _scope({
  required Widget child,
  NotificationService? notifService,
  List<FamilyMember> members = const [],
}) {
  return ProviderScope(
    overrides: [
      notificationServiceProvider
          .overrideWithValue(notifService ?? _StubNotificationService()),
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

FamilyMember _member({
  String id = 'm1',
  String name = '홍길동',
  Relationship relationship = Relationship.self,
  int age = 40,
}) {
  final now = DateTime(2026, 1, 1);
  return FamilyMember(
    id: id,
    name: name,
    relationship: relationship,
    birthYear: DateTime.now().year - age,
    sex: Sex.male,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  group('PrivacyConsentScreen', () {
    testWidgets('proceed button is disabled until all three checkboxes ticked',
        (tester) async {
      // Tall viewport so the entire ListView fits — no lazy clipping.
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_scope(
        child: MaterialApp.router(
          routerConfig: _routerWith(const PrivacyConsentScreen()),
        ),
      ));
      await tester.pumpAndSettle();

      FilledButton btn() => tester.widget<FilledButton>(
            find.byKey(const Key('proceed-button')),
          );

      expect(btn().onPressed, isNull);

      await tester.tap(find.byKey(const Key('consent-checkbox')));
      await tester.pumpAndSettle();
      expect(btn().onPressed, isNull);

      await tester.tap(find.byKey(const Key('sensitive-checkbox')));
      await tester.pumpAndSettle();
      expect(btn().onPressed, isNull);

      await tester.tap(find.byKey(const Key('age-checkbox')));
      await tester.pumpAndSettle();
      expect(btn().onPressed, isNotNull);
    });
  });

  group('WelcomeScreen', () {
    testWidgets('renders all messages and exposes the two CTA buttons',
        (tester) async {
      await tester.pumpWidget(_scope(
        child: MaterialApp.router(
          routerConfig: _routerWith(const WelcomeScreen(fastMode: true)),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.textContaining('안녕하세요'), findsOneWidget);
      expect(find.textContaining('알약은 우리 가족'), findsOneWidget);
      expect(find.textContaining('어떻게 시작하실까요'), findsOneWidget);
      expect(find.byKey(const Key('welcome-self-button')), findsOneWidget);
      expect(find.byKey(const Key('welcome-family-button')), findsOneWidget);
    });
  });

  group('NotificationSetupScreen', () {
    testWidgets('time formatting helper round-trips', (tester) async {
      const t = TimeOfDay(hour: 7, minute: 30);
      expect(formatTimeOfDay(t), '07:30');
      expect(parseStoredTime('20:00', t),
          const TimeOfDay(hour: 20, minute: 0));
      expect(parseStoredTime(null, t), t);
      expect(parseStoredTime('garbage', t), t);
    });
  });

  group('FamilyManagementScreen', () {
    testWidgets('renders one row per member with edit/delete buttons',
        (tester) async {
      await tester.pumpWidget(_scope(
        members: [
          _member(id: 'm1', name: '김민기'),
          _member(
              id: 'm2', name: '김민지', relationship: Relationship.wife),
        ],
        child: MaterialApp.router(
          routerConfig: _routerWith(const FamilyManagementScreen()),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.textContaining('김민기'), findsOneWidget);
      expect(find.textContaining('김민지'), findsOneWidget);
      expect(find.text('수정'), findsNWidgets(2));
      expect(find.text('삭제'), findsNWidgets(2));
    });

    testWidgets('delete confirmation has cancel + 삭제 actions', (tester) async {
      await tester.pumpWidget(_scope(
        members: [_member(id: 'm1', name: '김민기')],
        child: MaterialApp.router(
          routerConfig: _routerWith(const FamilyManagementScreen()),
        ),
      ));
      await tester.pumpAndSettle();
      await tester.tap(find.text('삭제'));
      await tester.pumpAndSettle();
      expect(find.text('김민기님을 삭제하시겠어요?'), findsOneWidget);
      expect(find.text('취소'), findsOneWidget);
      // Two "삭제" texts now: button in row + button in dialog
      expect(find.text('삭제'), findsNWidgets(2));
    });
  });

  group('처리방침 v1.2', () {
    test('버전 1.2, 30일 자동 삭제 조항 포함, 검진 미언급, 외부 SDK 명칭 미포함', () {
      expect(kPrivacyPolicyVersion, '1.2');
      expect(kPrivacyPolicyMarkdown, contains('30일 이상'));
      expect(kPrivacyPolicyMarkdown, contains('자동으로 삭제'));
      expect(kPrivacyPolicyMarkdown, isNot(contains('건강검진')));
      expect(kPrivacyPolicyMarkdown.toLowerCase(), isNot(contains('anthropic')));
    });
  });
}
