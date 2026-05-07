import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:alyak/features/onboarding/screens/onboarding_screen.dart';

/// flutter_secure_storage's platform channel name. We mock it so the
/// `_finish()` write doesn't blow up in the unit-test environment.
const _kSecureStorageChannel =
    MethodChannel('plugins.it_nomads.com/flutter_secure_storage');

Map<String, String> _backing = <String, String>{};

void _installSecureStorageMock() {
  TestWidgetsFlutterBinding.ensureInitialized();
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(_kSecureStorageChannel, (call) async {
    switch (call.method) {
      case 'write':
        final key = call.arguments['key'] as String;
        final value = call.arguments['value'] as String?;
        if (value == null) {
          _backing.remove(key);
        } else {
          _backing[key] = value;
        }
        return null;
      case 'read':
        return _backing[call.arguments['key'] as String];
      case 'delete':
        _backing.remove(call.arguments['key'] as String);
        return null;
      case 'deleteAll':
        _backing.clear();
        return null;
      case 'containsKey':
        return _backing.containsKey(call.arguments['key'] as String);
      case 'readAll':
        return Map<String, String>.from(_backing);
    }
    return null;
  });
}

GoRouter _routerFor({required Widget initial}) {
  return GoRouter(
    initialLocation: '/start',
    routes: [
      GoRoute(path: '/start', builder: (_, _) => initial),
      GoRoute(
        path: '/boot',
        builder: (_, _) => const _Sentinel(text: 'BOOT'),
      ),
    ],
  );
}

class _Sentinel extends StatelessWidget {
  final String text;
  const _Sentinel({required this.text});
  @override
  Widget build(BuildContext context) => WidgetsApp(
        color: const Color(0xFFFFFFFF),
        builder: (_, _) => Text(text),
      );
}

void main() {
  setUp(() {
    _backing = <String, String>{};
    _installSecureStorageMock();
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_kSecureStorageChannel, null);
  });

  group('OnboardingScreen — first-run tour', () {
    testWidgets('renders first slide with title + skip + 다음 button',
        (tester) async {
      final router = _routerFor(initial: const OnboardingScreen());
      await tester.pumpWidget(WidgetsApp.router(
        color: const Color(0xFFFFFFFF),
        routerConfig: router,
      ));
      await tester.pumpAndSettle();

      expect(find.textContaining('우리 가족 영양제'), findsOneWidget);
      expect(find.text('건너뛰기'), findsOneWidget);
      expect(find.text('다음'), findsOneWidget);
      // Last-slide CTA should NOT appear yet.
      expect(find.text('시작하기'), findsNothing);
    });

    testWidgets('skip button hides on the last slide; CTA reads 시작하기',
        (tester) async {
      final router = _routerFor(initial: const OnboardingScreen());
      await tester.pumpWidget(WidgetsApp.router(
        color: const Color(0xFFFFFFFF),
        routerConfig: router,
      ));
      await tester.pumpAndSettle();

      // Tap 다음 three times to reach slide 4.
      for (var i = 0; i < 3; i++) {
        await tester.tap(find.text('다음'));
        await tester.pumpAndSettle();
      }
      expect(find.text('시작하기'), findsOneWidget);
      expect(find.text('다음'), findsNothing);
      expect(find.text('건너뛰기'), findsNothing);
    });

    testWidgets('시작하기 marks onboardingComplete and goes to /boot',
        (tester) async {
      final router = _routerFor(initial: const OnboardingScreen());
      await tester.pumpWidget(WidgetsApp.router(
        color: const Color(0xFFFFFFFF),
        routerConfig: router,
      ));
      await tester.pumpAndSettle();
      for (var i = 0; i < 3; i++) {
        await tester.tap(find.text('다음'));
        await tester.pumpAndSettle();
      }
      await tester.tap(find.text('시작하기'));
      await tester.pumpAndSettle();

      // Storage flag persisted for the boot router to read on next launch.
      expect(_backing['alyak.onboardingComplete'], '1');
      // Router pushed onto /boot sentinel.
      expect(find.text('BOOT'), findsOneWidget);
    });

    testWidgets('건너뛰기 also marks completion (skip → /boot)',
        (tester) async {
      final router = _routerFor(initial: const OnboardingScreen());
      await tester.pumpWidget(WidgetsApp.router(
        color: const Color(0xFFFFFFFF),
        routerConfig: router,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('건너뛰기'));
      await tester.pumpAndSettle();

      expect(_backing['alyak.onboardingComplete'], '1');
      expect(find.text('BOOT'), findsOneWidget);
    });

    testWidgets('renders all 4 slide titles when paged through',
        (tester) async {
      final router = _routerFor(initial: const OnboardingScreen());
      await tester.pumpWidget(WidgetsApp.router(
        color: const Color(0xFFFFFFFF),
        routerConfig: router,
      ));
      await tester.pumpAndSettle();

      const titles = [
        '우리 가족 영양제',
        '검증된 250개 영양제',
        '결정 시점에만',
        '지금 시작해보세요',
      ];
      for (var i = 0; i < titles.length; i++) {
        expect(find.textContaining(titles[i]), findsOneWidget,
            reason: 'slide $i title: ${titles[i]}');
        if (i < titles.length - 1) {
          await tester.tap(find.text('다음'));
          await tester.pumpAndSettle();
        }
      }
    });
  });
}
