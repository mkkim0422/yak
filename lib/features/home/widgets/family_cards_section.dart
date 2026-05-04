import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
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

    Widget layout;
    if (members.length == 1) {
      layout = _SingleMemberLarge(member: members.first);
    } else if (members.length == 2) {
      layout = _TwoMembersRow(members: members);
    } else if (members.length == 3) {
      layout = _ThreeMembersLayout(members: members);
    } else {
      layout = _GridLayout(members: members);
    }

    return Column(
      children: [
        layout,
        const SizedBox(height: 12),
        const _AddMemberButton(),
      ],
    );
  }
}

class _EmptyFamilyState extends StatelessWidget {
  const _EmptyFamilyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Text('👨‍👩‍👧', style: TextStyle(fontSize: 40)),
          const SizedBox(height: 12),
          Text(AppStrings.emptyFamilyTitle, style: AppTypography.heading3),
          const SizedBox(height: 6),
          Text(
            AppStrings.emptyFamilyDescription,
            style: AppTypography.body2,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => context.push('/onboarding/family-add'),
            child: const Text(AppStrings.addFamilyButton),
          ),
        ],
      ),
    );
  }
}

class _SingleMemberLarge extends StatelessWidget {
  final FamilyMember member;
  const _SingleMemberLarge({required this.member});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FamilyMemberCard(member: member, isLarge: true),
    );
  }
}

class _TwoMembersRow extends StatelessWidget {
  final List<FamilyMember> members;
  const _TwoMembersRow({required this.members});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 175,
      child: Row(
        children: [
          Expanded(child: _CompactCardCell(member: members[0])),
          const SizedBox(width: 12),
          Expanded(child: _CompactCardCell(member: members[1])),
        ],
      ),
    );
  }
}

class _ThreeMembersLayout extends StatelessWidget {
  final List<FamilyMember> members;
  const _ThreeMembersLayout({required this.members});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _SingleMemberLarge(member: members[0]),
        const SizedBox(height: 12),
        SizedBox(
          height: 175,
          child: Row(
            children: [
              Expanded(child: _CompactCardCell(member: members[1])),
              const SizedBox(width: 12),
              Expanded(child: _CompactCardCell(member: members[2])),
            ],
          ),
        ),
      ],
    );
  }
}

class _GridLayout extends StatelessWidget {
  final List<FamilyMember> members;
  const _GridLayout({required this.members});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        mainAxisExtent: 175,
      ),
      itemCount: members.length,
      itemBuilder: (context, index) =>
          _CompactCardCell(member: members[index]),
    );
  }
}

class _CompactCardCell extends StatelessWidget {
  final FamilyMember member;
  const _CompactCardCell({required this.member});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 175,
      child: FamilyMemberCard(member: member),
    );
  }
}

class _AddMemberButton extends StatelessWidget {
  const _AddMemberButton();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        icon: const Icon(Icons.add, size: 18),
        label: const Text('가족 추가하기'),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: BorderSide(color: AppColors.primary.withValues(alpha: 0.5)),
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: () => context.push('/onboarding/family-add'),
      ),
    );
  }
}
