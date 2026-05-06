import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/data/models/product_model.dart';
import '../../../core/data/product_repository.dart';
import '../../../core/notifications/notification_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/alyak_buttons.dart';
import '../../../core/widgets/alyak_card.dart';
import '../../../core/widgets/product_photo.dart';
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
    final ingredients = product.ingredients.keys.take(3).join(', ');
    final meta = '${product.dailyDose}${product.unit}/일 · '
        '${product.packageSize}${product.unit}';
    return AlyakCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          const ProductPhoto(label: '제품', verified: true),
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
                Text(meta, style: AppTypography.caption.copyWith(fontSize: 12)),
                if (ingredients.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    ingredients,
                    style: AppTypography.body2.copyWith(
                      fontSize: 12,
                      color: AppColors.ink2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.okBg,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '✅ 정확 분석 가능',
                    style: AppTypography.micro.copyWith(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.okInk,
                    ),
                  ),
                ),
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

class _SearchEmptyHint extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('💊', style: TextStyle(fontSize: 44)),
            const SizedBox(height: 16),
            Text(
              '어떤 영양제를 찾고 계세요?',
              style: AppTypography.heading2.copyWith(fontSize: 17),
            ),
            const SizedBox(height: 6),
            Text(
              '제품명, 성분, 브랜드로 검색할 수 있어요.',
              style: AppTypography.caption.copyWith(fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _NoResults extends StatelessWidget {
  final String memberId;
  const _NoResults({required this.memberId});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🔎', style: TextStyle(fontSize: 44)),
            const SizedBox(height: 16),
            Text(
              '검색 결과가 없어요',
              style: AppTypography.heading2.copyWith(fontSize: 17),
            ),
            const SizedBox(height: 6),
            Text(
              '검증된 제품 데이터베이스에\n아직 등록되지 않은 영양제예요.',
              style: AppTypography.caption.copyWith(fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              label: '+ 직접 추가하기',
              size: AlyakButtonSize.md,
              onPressed: () =>
                  context.go('/supplement/manual?member=$memberId'),
            ),
          ],
        ),
      ),
    );
  }
}
