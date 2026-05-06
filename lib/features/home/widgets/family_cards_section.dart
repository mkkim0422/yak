import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/alyak_buttons.dart';
import '../../family/models/family_member.dart';
import '../../family/providers/family_provider.dart';
import 'family_member_card.dart';

class FamilyCardsSection extends ConsumerWidget {
  const FamilyCardsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final family = ref.watch(familyProvider);
    final members = family.members;

    if (members.isEmpty) {
      return const _EmptyFamilyState();
    }

    return _DynamicLayout(members: members);
  }
}

class _EmptyFamilyState extends StatelessWidget {
  const _EmptyFamilyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.r20),
        border: Border.all(
          color: AppColors.hairline,
          width: 1.5,
          style: BorderStyle.solid,
        ),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        children: [
          const Text('👨‍👩‍👧‍👦', style: TextStyle(fontSize: 36)),
          const SizedBox(height: 8),
          Text(
            '가족을 추가해 주세요',
            style: AppTypography.title.copyWith(
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '한 폰에서 4명까지 관리할 수 있어요.\n1분이면 끝나요.',
            textAlign: TextAlign.center,
            style: AppTypography.body2.copyWith(
              fontSize: 13,
              color: AppColors.muted,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          PrimaryButton(
            label: '+ 가족 추가하기',
            size: AlyakButtonSize.md,
            onPressed: () => context.push('/onboarding/family-add'),
          ),
        ],
      ),
    );
  }
}

/// Variants:
///   1 → large
///   2 → row of compact
///   3 → 1 large + 2 compact
///   4 → 2x2 grid of compact
///   5+ → 2x2 grid + horizontal mini scroll
class _DynamicLayout extends StatelessWidget {
  final List<FamilyMember> members;
  const _DynamicLayout({required this.members});

  @override
  Widget build(BuildContext context) {
    if (members.length == 1) {
      return FamilyMemberCard(
        member: members.first,
        variant: FamilyCardVariant.large,
      );
    }
    if (members.length == 2) {
      return IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: FamilyMemberCard(
                member: members[0],
                variant: FamilyCardVariant.compact,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FamilyMemberCard(
                member: members[1],
                variant: FamilyCardVariant.compact,
              ),
            ),
          ],
        ),
      );
    }
    if (members.length == 3) {
      return Column(
        children: [
          FamilyMemberCard(
            member: members[0],
            variant: FamilyCardVariant.large,
          ),
          const SizedBox(height: 10),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: FamilyMemberCard(
                    member: members[1],
                    variant: FamilyCardVariant.compact,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FamilyMemberCard(
                    member: members[2],
                    variant: FamilyCardVariant.compact,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }
    if (members.length == 4) {
      return _Grid2x2(members: members);
    }
    // 5+
    return Column(
      children: [
        _Grid2x2(members: members.sublist(0, 4)),
        const SizedBox(height: 10),
        _MiniScroll(members: members.sublist(4)),
      ],
    );
  }
}

class _Grid2x2 extends StatelessWidget {
  final List<FamilyMember> members;
  const _Grid2x2({required this.members});

  @override
  Widget build(BuildContext context) {
    Widget row(int a, int b) => IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: FamilyMemberCard(
                  member: members[a],
                  variant: FamilyCardVariant.compact,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FamilyMemberCard(
                  member: members[b],
                  variant: FamilyCardVariant.compact,
                ),
              ),
            ],
          ),
        );

    return Column(
      children: [
        row(0, 1),
        const SizedBox(height: 10),
        row(2, 3),
      ],
    );
  }
}

class _MiniScroll extends StatelessWidget {
  final List<FamilyMember> members;
  const _MiniScroll({required this.members});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 130,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.zero,
        itemCount: members.length + 1,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          if (index == members.length) {
            return _AddSlot(
              onTap: () => context.push('/onboarding/family-add'),
            );
          }
          return SizedBox(
            width: 110,
            child: FamilyMemberCard(
              member: members[index],
              variant: FamilyCardVariant.mini,
            ),
          );
        },
      ),
    );
  }
}

class _AddSlot extends StatelessWidget {
  final VoidCallback onTap;
  const _AddSlot({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.r14),
        onTap: onTap,
        child: Container(
          width: 110,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.r14),
            border: Border.all(
              color: AppColors.hairline,
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('＋', style: TextStyle(fontSize: 18, color: AppColors.muted)),
              const SizedBox(height: 4),
              Text(
                '가족 추가',
                style: AppTypography.caption.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
