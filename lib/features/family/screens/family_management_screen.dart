import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../models/family_member.dart';
import '../providers/family_provider.dart';

class FamilyManagementScreen extends ConsumerWidget {
  const FamilyManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final members = ref.watch(familyMembersProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('가족 관리'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.push('/onboarding/family-add'),
            tooltip: '추가',
          ),
        ],
      ),
      body: members.isEmpty
          ? _Empty(
              onAdd: () => context.push('/onboarding/family-add'),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: members.length,
              itemBuilder: (context, i) {
                final m = members[i];
                return _MemberRow(
                  member: m,
                  onEdit: () => context.push('/family/${m.id}/edit'),
                  onDelete: () => _confirmDelete(context, ref, m),
                );
              },
            ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    FamilyMember member,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dctx) => AlertDialog(
        title: Text('${member.name}님을 삭제하시겠어요?'),
        content: const Text('모든 영양제, 검진 기록도 함께 삭제돼요.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dctx).pop(false),
            child: const Text('취소'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.of(dctx).pop(true),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(familyControllerProvider).removeMember(member.id);
  }
}

class _MemberRow extends StatelessWidget {
  final FamilyMember member;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _MemberRow({
    required this.member,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final productCount =
        member.currentProductIds.length + member.manualProducts.length;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(member.avatarEmoji, style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${member.name} (${member.relationship.label})',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text('${member.ageLabel} ${member.sex.label}',
              style: AppTypography.body2),
          const SizedBox(height: 2),
          Text('영양제 $productCount개', style: AppTypography.caption),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(onPressed: onEdit, child: const Text('수정')),
              const SizedBox(width: 4),
              TextButton(
                style: TextButton.styleFrom(foregroundColor: AppColors.error),
                onPressed: onDelete,
                child: const Text('삭제'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  final VoidCallback onAdd;
  const _Empty({required this.onAdd});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('가족이 없어요', style: AppTypography.body1),
          const SizedBox(height: 12),
          FilledButton(onPressed: onAdd, child: const Text('+ 가족 추가')),
        ],
      ),
    );
  }
}
