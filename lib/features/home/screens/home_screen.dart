import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/alyak_buttons.dart';
import '../../../core/widgets/disclaimer_footer.dart';
import '../../../core/widgets/state_views.dart';
import '../../family/providers/family_provider.dart';
import '../widgets/family_cards_section.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasFamily = ref.watch(familyProvider).members.isNotEmpty;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const _HomeHeader(),
            const SizedBox(height: 8),
            if (hasFamily) ...[
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 4, 20, 0),
                child: FamilyCardsSection(),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SecondaryButton(
                  label: '+ 가족 추가하기',
                  full: true,
                  size: AlyakButtonSize.md,
                  onPressed: () => context.push('/onboarding/family-add'),
                ),
              ),
            ] else ...[
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 8, 20, 0),
                child: _EmptyFamilyHero(),
              ),
            ],
            const SizedBox(height: 16),
            const DisclaimerFooter(),
          ],
        ),
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '안녕하세요 👋',
                  style: AppTypography.caption.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '우리 가족 영양제',
                  style: AppTypography.heading1.copyWith(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          _SettingsBell(
            onTap: () => context.push('/settings'),
          ),
        ],
      ),
    );
  }
}

class _SettingsBell extends StatelessWidget {
  final VoidCallback onTap;
  const _SettingsBell({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.r12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.r12),
        child: Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.r12),
            boxShadow: AppShadows.card,
          ),
          child: const Icon(Icons.settings_outlined,
              color: AppColors.ink, size: 20),
        ),
      ),
    );
  }
}

/// Shown when the user has no family members yet. Replaces the supplements
/// CTA with a focused "add family" affordance — that's the only meaningful
/// action when the family list is empty.
class _EmptyFamilyHero extends StatelessWidget {
  const _EmptyFamilyHero();

  @override
  Widget build(BuildContext context) {
    return EmptyStateView(
      emoji: '👨‍👩‍👧',
      title: '가족을 추가해서\n영양제를 관리해보세요',
      message: '한 폰에서 4명까지 관리할 수 있어요',
      primaryLabel: '+ 가족 추가하기',
      onPrimary: () => context.push('/onboarding/family-add'),
    );
  }
}
