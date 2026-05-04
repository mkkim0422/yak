import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/data/models/product_model.dart';
import '../../../core/data/product_repository.dart';
import '../../../core/notifications/notification_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
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
        title: const Text('영양제 검색'),
        actions: [
          IconButton(icon: const Icon(Icons.close), onPressed: () => context.pop()),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _ctrl,
              decoration: const InputDecoration(
                hintText: '제품명 또는 카테고리',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          if (_query.isNotEmpty && results.isEmpty)
            _Empty(memberId: widget.memberId)
          else
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: results.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, i) {
                  final p = results[i];
                  return _ResultCard(
                    product: p,
                    onPick: () => _pick(p),
                  );
                },
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

class _ResultCard extends StatelessWidget {
  final Product product;
  final VoidCallback onPick;
  const _ResultCard({required this.product, required this.onPick});

  @override
  Widget build(BuildContext context) {
    final ingredients = product.ingredients.keys.take(3).join(', ');
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('💊 ${product.name}',
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(
                  '${product.dailyDose}${product.unit}/일 · '
                  '${product.packageSize}${product.unit} · '
                  '${product.packagePriceKrw.toString()}원',
                  style: AppTypography.caption,
                ),
                if (ingredients.isNotEmpty)
                  Text(ingredients, style: AppTypography.caption),
              ],
            ),
          ),
          FilledButton(onPressed: onPick, child: const Text('선택')),
        ],
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  final String memberId;
  const _Empty({required this.memberId});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Text('🔍', style: TextStyle(fontSize: 32)),
          const SizedBox(height: 8),
          Text('검색 결과가 없어요', style: AppTypography.body1),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () =>
                context.go('/supplement/manual?member=$memberId'),
            child: const Text('직접 추가하기 →'),
          ),
        ],
      ),
    );
  }
}
