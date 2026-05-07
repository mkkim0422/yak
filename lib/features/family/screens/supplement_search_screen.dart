import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/data/models/product_model.dart';
import '../../../core/data/nutrient_labels.dart';
import '../../../core/data/product_repository.dart';
import '../../../core/notifications/notification_provider.dart';
import '../../../core/services/conflict_checker.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/alyak_buttons.dart';
import '../../../core/widgets/alyak_card.dart';
import '../../../core/widgets/conflict_section.dart';
import '../../../core/widgets/product_image.dart';
import '../../../core/widgets/state_views.dart';
import '../providers/family_provider.dart';

/// Local-DB only supplement search. Future stages will layer 식약처 + Naver
/// product APIs on top via the same selection callback.
class SupplementSearchScreen extends ConsumerStatefulWidget {
  final String memberId;
  const SupplementSearchScreen({super.key, required this.memberId});

  @override
  ConsumerState<SupplementSearchScreen> createState() =>
      _SupplementSearchScreenState();
}

class _SupplementSearchScreenState
    extends ConsumerState<SupplementSearchScreen> {
  final _ctrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(productRepositoryProvider);
    final results = repo.search(_query);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => context.pop(),
        ),
        title: const Text('영양제 검색'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: _SearchBar(
              controller: _ctrl,
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          if (_query.isEmpty)
            Expanded(child: _SearchEmptyHint())
          else if (results.isEmpty)
            Expanded(child: _NoResults(memberId: widget.memberId))
          else
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                children: [
                  Row(
                    children: [
                      Text(
                        '✅ 우리가 검증한 제품',
                        style: AppTypography.title.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${results.length}',
                        style: AppTypography.caption.copyWith(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  for (final p in results) ...[
                    _ResultCard(product: p, onPick: () => _pick(p)),
                    const SizedBox(height: 8),
                  ],
                  const SizedBox(height: 12),
                  SecondaryButton(
                    label: '+ 직접 추가하기',
                    full: true,
                    size: AlyakButtonSize.md,
                    onPressed: () => context
                        .go('/supplement/manual?member=${widget.memberId}'),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _pick(Product product) async {
    final controller = ref.read(familyControllerProvider);
    final member = controller.getMember(widget.memberId);
    if (member == null) return;
    if (member.currentProductIds.contains(product.id)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('이미 추가된 영양제예요')),
      );
      return;
    }

    final repo = ref.read(productRepositoryProvider);
    final currentProducts = member.currentProductIds
        .map(repo.getById)
        .whereType<Product>()
        .toList(growable: false);
    final added = ConflictChecker.diff(
      member: member,
      products: currentProducts,
      manuals: member.manualProducts,
      candidate: product,
    );
    if (added.isNotEmpty && mounted) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (dctx) => ConflictAddDialog(
          conflicts: added,
          productName: product.name,
          onCancel: () => Navigator.of(dctx).pop(false),
          onConfirm: () => Navigator.of(dctx).pop(true),
        ),
      );
      if (ok != true) return;
    }
    if (!mounted) return;

    final updated = member.copyWith(
      currentProductIds: [...member.currentProductIds, product.id],
    );
    await controller.updateMember(updated);
    final dailyDose = product.dailyDose <= 0 ? 1 : product.dailyDose;
    final daysOfStock = product.packageSize ~/ dailyDose;
    final remind = (daysOfStock - 5).clamp(7, 365);
    await ref.read(notificationServiceProvider).scheduleProductReorderReminder(
          memberId: widget.memberId,
          productId: product.id,
          daysFromNow: remind,
        );
    if (!mounted) return;
    context.pop();
  }
}

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  const _SearchBar({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.r14),
        boxShadow: AppShadows.card,
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: AppTypography.body1.copyWith(fontSize: 14.5),
        decoration: InputDecoration(
          hintText: '영양제 이름이나 성분',
          hintStyle: AppTypography.body1.copyWith(
            fontSize: 14.5,
            color: AppColors.faint,
          ),
          prefixIcon:
              const Icon(Icons.search, size: 20, color: AppColors.muted),
          border: const OutlineInputBorder(borderSide: BorderSide.none),
          enabledBorder: const OutlineInputBorder(borderSide: BorderSide.none),
          focusedBorder: const OutlineInputBorder(borderSide: BorderSide.none),
          filled: true,
          fillColor: Colors.transparent,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  final Product product;
  final VoidCallback onPick;
  const _ResultCard({required this.product, required this.onPick});

  @override
  Widget build(BuildContext context) {
    final ingredients =
        product.ingredients.keys.take(3).map(nutrientLabel).join(', ');
    final hasIngredients = product.ingredients.isNotEmpty;
    final analysisBadge = hasIngredients
        ? const _Badge(
            label: '✅ 정확 분석 가능',
            bg: AppColors.okBg,
            fg: AppColors.okInk,
          )
        : const _Badge(
            label: '📋 라벨 확인 필요',
            bg: AppColors.warnBg,
            fg: AppColors.warnInk,
          );
    return AlyakCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          ProductImage(product: product, size: 64),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  product.name,
                  style: AppTypography.title.copyWith(fontSize: 14.5),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  product.scheduleLabel,
                  style: AppTypography.caption.copyWith(
                    fontSize: 12,
                    color: AppColors.ink2,
                  ),
                ),
                if (ingredients.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    '채워주는 영양소: $ingredients',
                    style: AppTypography.body2.copyWith(
                      fontSize: 11.5,
                      color: AppColors.muted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 6),
                analysisBadge,
              ],
            ),
          ),
          const SizedBox(width: 8),
          PrimaryButton(
            label: '선택',
            size: AlyakButtonSize.sm,
            onPressed: onPick,
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color bg;
  final Color fg;
  const _Badge({required this.label, required this.bg, required this.fg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: AppTypography.micro.copyWith(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          color: fg,
        ),
      ),
    );
  }
}

class _SearchEmptyHint extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const EmptyStateView(
      emoji: '💊',
      title: '어떤 영양제를 찾고 계세요?',
      message: '제품명, 성분, 브랜드로 검색할 수 있어요.',
    );
  }
}

class _NoResults extends StatelessWidget {
  final String memberId;
  const _NoResults({required this.memberId});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      children: [
        const EmptyStateView(
          emoji: '🔎',
          title: '검색 결과가 없어요',
          message: '검증된 제품 데이터베이스에\n아직 등록되지 않은 영양제예요.',
          padding: EdgeInsets.symmetric(horizontal: 0),
        ),
        const SizedBox(height: 24),
        _OptionCard(
          emoji: '📝',
          title: '직접 입력하기',
          sub: '라벨을 보고 정보를 입력해 주세요',
          primary: true,
          onTap: () => context.push('/supplement/manual?member=$memberId'),
        ),
      ],
    );
  }
}

class _OptionCard extends StatelessWidget {
  final String emoji;
  final String title;
  final String sub;
  final bool primary;
  final VoidCallback onTap;

  const _OptionCard({
    required this.emoji,
    required this.title,
    required this.sub,
    required this.onTap,
    this.primary = false,
  });

  @override
  Widget build(BuildContext context) {
    return AlyakCard(
      padding: const EdgeInsets.all(16),
      onTap: onTap,
      border: primary
          ? Border.all(color: AppColors.primary, width: 1.5)
          : Border.all(color: AppColors.hairline, width: 1.5),
      background: primary ? AppColors.primarySoft : AppColors.surface,
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: AppTypography.title.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: primary ? AppColors.primaryInk : AppColors.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  sub,
                  style: AppTypography.caption.copyWith(
                    fontSize: 12,
                    color: AppColors.ink2,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right,
            size: 18,
            color: primary ? AppColors.primary : AppColors.faint,
          ),
        ],
      ),
    );
  }
}
