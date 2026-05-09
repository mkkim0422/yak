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
///   1~4명 → large 카드 세로 스택 (보충 필요 영양소는 멤버 상세에서만 노출)
///   5명+ → compact 2-col 그리드 (작은 카드)
class _DynamicLayout extends StatelessWidget {
  final List<FamilyMember> members;
  const _DynamicLayout({required this.members});

  @override
  Widget build(BuildContext context) {
    if (members.length <= 4) {
      final children = <Widget>[];
      for (var i = 0; i < members.length; i++) {
        if (i > 0) children.add(const SizedBox(height: 10));
        children.add(FamilyMemberCard(
          member: members[i],
          variant: FamilyCardVariant.large,
        ));
      }
      return Column(children: children);
    }
    // 5명+
    final rows = <Widget>[];
    for (var i = 0; i < members.length; i += 2) {
      if (rows.isNotEmpty) rows.add(const SizedBox(height: 10));
      rows.add(IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: FamilyMemberCard(
                member: members[i],
                variant: FamilyCardVariant.compact,
              ),
            ),
            const SizedBox(width: 10),
            if (i + 1 < members.length)
              Expanded(
                child: FamilyMemberCard(
                  member: members[i + 1],
                  variant: FamilyCardVariant.compact,
                ),
              )
            else
              const Expanded(child: SizedBox()),
          ],
        ),
      ));
    }
    return Column(children: rows);
  }
}
