import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/l10n/app_strings.dart';
import '../core/legal/legal_documents.dart';
import '../core/security/secure_storage.dart';
import '../core/security/session_guard.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../core/widgets/state_views.dart';
import '../features/current_check/screens/current_check_screen.dart';
import '../features/family/models/family_member.dart';
import '../features/family/providers/family_provider.dart';
import '../features/family/screens/category_detail_screen.dart';
import '../features/family/screens/family_edit_screen.dart';
import '../features/family/screens/family_management_screen.dart';
import '../features/family/screens/family_products_screen.dart';
import '../features/family/screens/manual_supplement_input_screen.dart';
import '../features/family/screens/member_detail_screen.dart';
import '../features/family/screens/recommendation_detail_screen.dart';
import '../features/family/screens/supplement_search_screen.dart';
import '../features/home/screens/home_screen.dart';
import '../features/onboarding/screens/family_add_screen.dart';
import '../features/onboarding/screens/notification_setup_screen.dart';
import '../features/onboarding/screens/onboarding_screen.dart';
import '../features/onboarding/screens/privacy_consent_screen.dart';
import '../features/onboarding/screens/welcome_screen.dart';
import '../features/settings/screens/settings_screen.dart';
import '../features/supplements/screens/product_detail_screen.dart';
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

  // First-run education tour. Sits between privacy consent and the welcome
  // chat — once shown, we never replay it on boot. Settings exposes a
  // "다시 보기" entry that pushes /onboarding directly with `fromSettings`.
  final onboardingDone =
      await SecureStorage.read(SecureKeys.onboardingComplete);
  if (onboardingDone != '1') return const _BootDecision('/onboarding');

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
        path: '/terms',
        builder: (context, state) => const _TermsScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) {
          final fromSettings =
              state.uri.queryParameters['from'] == 'settings';
          return OnboardingScreen(fromSettings: fromSettings);
        },
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
        path: '/recommendation/:memberId/category/:category',
        builder: (context, state) => CategoryDetailScreen(
          memberId: state.pathParameters['memberId']!,
          categoryKey: state.pathParameters['category']!,
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
        path: '/supplement/manual/edit/:entryId',
        builder: (context, state) {
          final memberId = state.uri.queryParameters['member'] ?? '';
          return ManualSupplementInputScreen(
            memberId: memberId,
            editEntryId: state.pathParameters['entryId'],
          );
        },
      ),
      GoRoute(
        path: '/product/:productId',
        builder: (context, state) => ProductDetailScreen(
          productId: state.pathParameters['productId']!,
          // Optional ?member=ID — when supplied, the detail screen renders
          // 권장량 대비 4단계 평가 (충분/부족/많음/정보없음) per row.
          memberId: state.uri.queryParameters['member'],
        ),
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
    return _LegalDocScreen(
      title: '개인정보 처리방침',
      body: kPrivacyPolicyMarkdown,
    );
  }
}

class _TermsScreen extends StatelessWidget {
  const _TermsScreen();
  @override
  Widget build(BuildContext context) {
    return _LegalDocScreen(
      title: '이용약관',
      body: kTermsOfServiceMarkdown,
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
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(AppStrings.disclaimerNotMedicalAdvice,
              style: AppTypography.body1),
          const SizedBox(height: 12),
          Text(AppStrings.disclaimerText, style: AppTypography.body2),
          const SizedBox(height: 12),
          Text(AppStrings.disclaimerNutrient, style: AppTypography.body2),
          const SizedBox(height: 24),
          Text(
            kMedicalDisclaimerShort,
            style: AppTypography.body2.copyWith(
              fontSize: 13,
              height: 1.6,
              color: AppColors.ink2,
            ),
          ),
        ],
      ),
    );
  }
}

/// 약관 / 처리방침 등 긴 본문을 가독성 있는 단순 ListView로 렌더.
/// Markdown 패키지 의존을 피하기 위해 단순 분할 + 굵은 헤더 처리.
class _LegalDocScreen extends StatelessWidget {
  final String title;
  final String body;
  const _LegalDocScreen({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    final blocks = body.split('\n\n');
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(title)),
      body: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        itemCount: blocks.length,
        itemBuilder: (_, i) {
          final block = blocks[i].trim();
          if (block.isEmpty) return const SizedBox(height: 4);
          if (block.startsWith('---')) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(color: AppColors.divider, thickness: 1),
            );
          }
          // **굵은 헤더** 처리.
          if (block.startsWith('**') && block.endsWith('**')) {
            final txt = block.substring(2, block.length - 2);
            return Padding(
              padding: const EdgeInsets.fromLTRB(0, 16, 0, 8),
              child: Text(
                txt,
                style: AppTypography.heading3.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            );
          }
          // 시행일/버전 같은 메타 라인.
          if (block.startsWith('시행일:') || block.startsWith('버전:')) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text(
                block,
                style: AppTypography.caption.copyWith(
                  fontSize: 12,
                  color: AppColors.muted,
                ),
              ),
            );
          }
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(
              block,
              style: AppTypography.body2.copyWith(
                fontSize: 13.5,
                color: AppColors.ink2,
                height: 1.7,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _NotFoundScreen extends StatelessWidget {
  const _NotFoundScreen();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text('찾을 수 없어요'),
      ),
      body: ErrorStateView(
        emoji: '🔎',
        title: '요청하신 화면을 찾을 수 없어요',
        message: '잘못된 링크이거나 삭제된 화면일 수 있어요.',
        retryLabel: '홈으로',
        onRetry: () => context.go('/home'),
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
