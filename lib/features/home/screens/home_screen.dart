import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/alyak_buttons.dart';
import '../../../core/widgets/disclaimer_footer.dart';
import '../../../core/widgets/member_picker_sheet.dart';
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
            if (hasFamily) ...[
              const SizedBox(height: 4),
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 4, 20, 0),
                child: _PrimaryCta(),
              ),
              const SizedBox(height: 24),
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 0, 20, 0),
                child: FamilyCardsSection(),
              ),
            ] else ...[
              const SizedBox(height: 12),
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: FamilyCardsSection(),
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

/// Single primary CTA — replaces the four-row entry list. Drives the user
/// through the "buy supplements" flow (the most important action) and falls
/// back to the member picker when 2+ members exist.
class _PrimaryCta extends ConsumerWidget {
  const _PrimaryCta();

  Future<void> _onTap(BuildContext context, WidgetRef ref) async {
    final id = await pickMemberId(
      context,
      ref,
      purpose: '누구의 영양제를 추천받을까요?',
    );
    if (id == null || !context.mounted) return;
    context.push('/recommendation/$id');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Material(
      color: AppColors.primary,
      borderRadius: BorderRadius.circular(AppRadius.r16),
      child: InkWell(
        onTap: () => _onTap(context, ref),
        borderRadius: BorderRadius.circular(AppRadius.r16),
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(AppRadius.r16),
            boxShadow: const [
              BoxShadow(
                color: Color(0x2200ACC1),
                blurRadius: 16,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(AppRadius.r12),
                ),
                child: const Text('💊', style: TextStyle(fontSize: 22)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '영양제 사러 가기',
                      style: AppTypography.title.copyWith(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '부족한 영양소와 추천 제품을 알려드려요',
                      style: AppTypography.caption.copyWith(
                        fontSize: 12.5,
                        color: Colors.white.withValues(alpha: 0.92),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right,
                  color: Colors.white, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}

/// Empty-state CTA used when the family is empty.
@visibleForTesting
class HomeAddFamilyCta extends StatelessWidget {
  const HomeAddFamilyCta({super.key});

  @override
  Widget build(BuildContext context) {
    return PrimaryButton(
      label: '+ 가족 추가하기',
      full: true,
      onPressed: () => context.push('/onboarding/family-add'),
    );
  }
}
