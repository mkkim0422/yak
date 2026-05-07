import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/data/models/product_model.dart';
import '../../../core/data/product_repository.dart';
import '../../../core/notifications/notification_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/state_views.dart';
import '../models/family_member.dart';
import '../providers/family_provider.dart';

class FamilyProductsScreen extends ConsumerWidget {
  final String memberId;
  const FamilyProductsScreen({super.key, required this.memberId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final member = ref.watch(familyControllerProvider).getMember(memberId);
    if (member == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(backgroundColor: AppColors.background, elevation: 0),
        body: const ErrorStateView(
          emoji: '🔎',
          title: '가족 멤버를 찾을 수 없어요',
          message: '삭제됐거나 잘못된 링크일 수 있어요.',
        ),
      );
    }
    final repo = ref.watch(productRepositoryProvider);
    final products = member.currentProductIds
        .map(repo.getById)
        .whereType<Product>()
        .toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text('${member.name}님 영양제')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('섭취중', style: AppTypography.heading3),
          const SizedBox(height: 12),
          if (products.isEmpty && member.manualProducts.isEmpty)
            _EmptyState(onAdd: () => _openAddSheet(context, memberId))
          else ...[
            for (final p in products)
              _ProductCard(
                title: p.name,
                subtitle: '${p.dailyDose}${p.unit} / 일 · ${p.packageSize}${p.unit}',
                onRemove: () => _removeProduct(ref, member, p.id),
              ),
            for (final m in member.manualProducts)
              _ProductCard(
                title: m.name,
                subtitle:
                    '${m.dailyDose}/일 · ${m.packageSize} · 시작 ${DateFormat('yyyy.MM.dd').format(m.startedAt)}',
                onRemove: () => _removeManual(ref, member, m.id),
              ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('영양제 추가'),
              onPressed: () => _openAddSheet(context, memberId),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _removeProduct(
    WidgetRef ref,
    FamilyMember member,
    String productId,
  ) async {
    final updated = member.copyWith(
      currentProductIds:
          member.currentProductIds.where((id) => id != productId).toList(),
    );
    await ref.read(familyControllerProvider).updateMember(updated);
    await ref.read(notificationServiceProvider).cancelReorderReminder(
          memberId: member.id,
          productId: productId,
        );
  }

  Future<void> _removeManual(
    WidgetRef ref,
    FamilyMember member,
    String manualId,
  ) async {
    final updated = member.copyWith(
      manualProducts:
          member.manualProducts.where((m) => m.id != manualId).toList(),
    );
    await ref.read(familyControllerProvider).updateMember(updated);
    await ref.read(notificationServiceProvider).cancelReorderReminder(
          memberId: member.id,
          productId: manualId,
        );
  }
}

void _openAddSheet(BuildContext context, String memberId) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheetCtx) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.search),
              title: const Text('영양제 검색 (DB + 식약처)'),
              onTap: () {
                Navigator.of(sheetCtx).pop();
                sheetCtx.push('/supplement/search?member=$memberId');
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit_note),
              title: const Text('직접 추가'),
              onTap: () {
                Navigator.of(sheetCtx).pop();
                sheetCtx.push('/supplement/manual?member=$memberId');
              },
            ),
            const ListTile(
              leading: Icon(Icons.camera_alt_outlined, color: Colors.grey),
              title: Text('라벨 촬영', style: TextStyle(color: Colors.grey)),
              subtitle: Text('Phase 2 예정', style: TextStyle(color: Colors.grey)),
              enabled: false,
            ),
            const SizedBox(height: 12),
          ],
        ),
      );
    },
  );
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text('아직 등록된 영양제가 없어요', style: AppTypography.body1),
          const SizedBox(height: 12),
          FilledButton(onPressed: onAdd, child: const Text('+ 영양제 추가')),
        ],
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onRemove;
  const _ProductCard({
    required this.title,
    required this.subtitle,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          const Text('💊', style: TextStyle(fontSize: 22)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(subtitle, style: AppTypography.caption),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: onRemove,
            tooltip: '삭제',
          ),
        ],
      ),
    );
  }
}
