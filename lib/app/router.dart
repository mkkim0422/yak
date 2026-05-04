import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/l10n/app_strings.dart';
import '../core/security/secure_storage.dart';
import '../core/security/session_guard.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../features/current_check/screens/current_check_screen.dart';
import '../features/family/models/family_member.dart';
import '../features/family/providers/family_provider.dart';
import '../features/family/screens/family_edit_screen.dart';
import '../features/family/screens/family_management_screen.dart';
import '../features/family/screens/family_products_screen.dart';
import '../features/family/screens/health_checkup_input_screen.dart';
import '../features/family/screens/manual_supplement_input_screen.dart';
import '../features/family/screens/member_detail_screen.dart';
import '../features/family/screens/recommendation_detail_screen.dart';
import '../features/family/screens/supplement_search_screen.dart';
import '../features/home/screens/home_screen.dart';
import '../features/onboarding/screens/family_add_screen.dart';
import '../features/onboarding/screens/notification_setup_screen.dart';
import '../features/onboarding/screens/privacy_consent_screen.dart';
import '../features/onboarding/screens/welcome_screen.dart';
import '../features/settings/screens/settings_screen.dart';
import '../features/supplements/screens/supplement_guide_screen.dart';
import '../features/symptom/screens/symptom_search_screen.dart';

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

  final familyIndex = await SecureStorage.read(kFamilyMembersListKey);
  final hasFamily = familyIndex != null &&
      familyIndex.trim().isNotEmpty &&
      familyIndex.trim() != '[]';
  if (!hasFamily) return const _BootDecision('/onboarding/welcome');

  await guard.touch();
  return const _BootDecision('/home');
}

Relationship? _relationshipFromQuery(String? raw) {
  if (raw == null) return null;
  for (final r in Relationship.values) {
    if (r.name == raw) return r;
  }
  return null;
}

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/boot',
    errorBuilder: (context, state) => const _NotFoundScreen(),
    routes: [
      GoRoute(path: '/boot', builder: (context, state) => const _BootScreen()),
      GoRoute(
        path: '/privacy-consent',
        builder: (context, state) => const PrivacyConsentScreen(),
      ),
      GoRoute(
        path: '/privacy-policy',
        builder: (context, state) => const _PrivacyPolicyScreen(),
      ),
      GoRoute(
        path: '/disclaimer',
        builder: (context, state) => const _DisclaimerScreen(),
      ),
      GoRoute(
        path: '/onboarding/welcome',
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: '/onboarding/family-select',
        builder: (context, state) =>
            const _Placeholder(title: '가족 등록 방식 선택'),
      ),
      GoRoute(
        path: '/onboarding/family-add',
        builder: (context, state) {
          final preset = _relationshipFromQuery(
            state.uri.queryParameters['relationship'],
          );
          return FamilyAddScreen(presetRelationship: preset);
        },
      ),
      GoRoute(
        path: '/onboarding/notification',
        builder: (context, state) => const NotificationSetupScreen(),
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
            FamilyEditScreen(memberId: state.pathParameters['id']!),
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
        builder: (context, state) => const FamilyManagementScreen(),
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
        builder: (context, state) => SupplementGuideScreen(
          supplementId: state.pathParameters['supplementId']!,
        ),
      ),
      GoRoute(
        path: '/symptom-search',
        builder: (context, state) => const SymptomSearchScreen(),
      ),
      GoRoute(
        path: '/health-checkup/:memberId',
        builder: (context, state) => HealthCheckupInputScreen(
          memberId: state.pathParameters['memberId']!,
        ),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
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

class _PrivacyPolicyScreen extends StatelessWidget {
  const _PrivacyPolicyScreen();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('개인정보 처리방침')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('개인정보 처리방침', style: AppTypography.heading2),
          const SizedBox(height: 12),
          Text(AppStrings.privacyDataLocal, style: AppTypography.body1),
          const SizedBox(height: 8),
          Text(AppStrings.privacyEncryption, style: AppTypography.body1),
          const SizedBox(height: 8),
          Text(AppStrings.privacyMedicalNote, style: AppTypography.body1),
          const SizedBox(height: 24),
          Text(
            '※ 본 앱은 모든 데이터를 사용자 기기 내에 암호화하여 저장하며, '
            '외부 서버로 전송하지 않습니다.',
            style: AppTypography.body2,
          ),
        ],
      ),
    );
  }
}

class _DisclaimerScreen extends StatelessWidget {
  const _DisclaimerScreen();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('면책 조항')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppStrings.disclaimerNotMedicalAdvice,
                style: AppTypography.body1),
            const SizedBox(height: 12),
            Text(AppStrings.disclaimerText, style: AppTypography.body2),
            const SizedBox(height: 12),
            Text(AppStrings.disclaimerNutrient, style: AppTypography.body2),
          ],
        ),
      ),
    );
  }
}

class _NotFoundScreen extends StatelessWidget {
  const _NotFoundScreen();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('찾을 수 없어요')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('요청하신 화면을 찾을 수 없어요'),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => context.go('/home'),
              child: const Text('홈으로'),
            ),
          ],
        ),
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
