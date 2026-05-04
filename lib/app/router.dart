import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/l10n/app_strings.dart';
import '../core/security/secure_storage.dart';
import '../core/security/session_guard.dart';
import '../core/theme/app_colors.dart';
import '../features/current_check/screens/current_check_screen.dart';
import '../features/family/providers/family_provider.dart';
import '../features/family/screens/family_products_screen.dart';
import '../features/family/screens/health_checkup_input_screen.dart';
import '../features/family/screens/manual_supplement_input_screen.dart';
import '../features/family/screens/member_detail_screen.dart';
import '../features/family/screens/recommendation_detail_screen.dart';
import '../features/family/screens/supplement_search_screen.dart';
import '../features/home/screens/home_screen.dart';
import '../features/onboarding/screens/family_add_screen.dart';

class _BootDecision {
  const _BootDecision(this.target);
  final String target;
}

Future<_BootDecision> _decideBootRoute() async {
  final guard = SessionGuard();
  if (await guard.isExpired()) {
    await SecureStorage.wipe();
    return const _BootDecision('/privacy-consent');
  }

  final consent = await SecureStorage.read(SecureKeys.privacyConsent);
  if (consent != '1') return const _BootDecision('/privacy-consent');

  // Stage 3 recovery: family roster lives under family.members.list now.
  final familyIndex = await SecureStorage.read(kFamilyMembersListKey);
  final hasFamily = familyIndex != null && familyIndex.trim().isNotEmpty &&
      familyIndex.trim() != '[]';
  if (!hasFamily) return const _BootDecision('/onboarding/welcome');

  await guard.touch();
  return const _BootDecision('/home');
}

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/boot',
    routes: [
      GoRoute(path: '/boot', builder: (context, state) => const _BootScreen()),
      GoRoute(
        path: '/privacy-consent',
        builder: (context, state) =>
            const _Placeholder(title: '개인정보 동의'),
      ),
      GoRoute(
        path: '/onboarding/welcome',
        builder: (context, state) =>
            const _Placeholder(title: '시작하기'),
      ),
      GoRoute(
        path: '/onboarding/family-select',
        builder: (context, state) =>
            const _Placeholder(title: '가족 등록 방식 선택'),
      ),
      GoRoute(
        path: '/onboarding/family-add',
        builder: (context, state) => const FamilyAddScreen(),
      ),
      GoRoute(
        path: '/onboarding/notification',
        builder: (context, state) =>
            const _Placeholder(title: '알림 설정'),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/family/:id',
        builder: (context, state) =>
            MemberDetailScreen(memberId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/family/:id/edit',
        builder: (context, state) =>
            const _Placeholder(title: '가족 정보 수정'),
      ),
      GoRoute(
        path: '/family/:id/products',
        builder: (context, state) =>
            FamilyProductsScreen(memberId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/current-check/:memberId',
        builder: (context, state) =>
            CurrentCheckScreen(memberId: state.pathParameters['memberId']!),
      ),
      GoRoute(
        path: '/family-management',
        builder: (context, state) =>
            const _Placeholder(title: '가족 관리'),
      ),
      GoRoute(
        path: '/recommendation/:memberId',
        builder: (context, state) => RecommendationDetailScreen(
          memberId: state.pathParameters['memberId']!,
        ),
      ),
      GoRoute(
        path: '/supplement/search',
        builder: (context, state) {
          final memberId = state.uri.queryParameters['member'] ?? '';
          return SupplementSearchScreen(memberId: memberId);
        },
      ),
      GoRoute(
        path: '/supplement/manual',
        builder: (context, state) {
          final memberId = state.uri.queryParameters['member'] ?? '';
          return ManualSupplementInputScreen(memberId: memberId);
        },
      ),
      GoRoute(
        path: '/supplement-guide/:supplementId',
        builder: (context, state) =>
            const _Placeholder(title: '복용 가이드'),
      ),
      GoRoute(
        path: '/symptom-search',
        builder: (context, state) =>
            const _Placeholder(title: '증상으로 찾기'),
      ),
      GoRoute(
        path: '/health-checkup/:memberId',
        builder: (context, state) => HealthCheckupInputScreen(
          memberId: state.pathParameters['memberId']!,
        ),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) =>
            const _Placeholder(title: '설정'),
      ),
      GoRoute(
        path: '/admin',
        builder: (context, state) =>
            const _Placeholder(title: '관리자'),
      ),
    ],
  );
});

class _BootScreen extends StatefulWidget {
  const _BootScreen();

  @override
  State<_BootScreen> createState() => _BootScreenState();
}

class _BootScreenState extends State<_BootScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final decision = await _decideBootRoute();
      if (!mounted) return;
      context.go(decision.target);
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(title)),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.medical_services_outlined,
                size: 56,
                color: AppColors.primary,
              ),
              const SizedBox(height: 16),
              Text(
                AppStrings.appName,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                '화면 준비 중',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
