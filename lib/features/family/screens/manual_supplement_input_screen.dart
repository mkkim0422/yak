import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/notifications/notification_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../models/family_member.dart';
import '../providers/family_provider.dart';

const List<String> _categories = [
  '종합비타민',
  '비타민D',
  '오메가3',
  '유산균',
  '마그네슘',
  '칼슘',
  '철분',
  '아연',
  '루테인',
  '코엔자임Q10',
  '기타',
];

class ManualSupplementInputScreen extends ConsumerStatefulWidget {
  final String memberId;
  const ManualSupplementInputScreen({super.key, required this.memberId});

  @override
  ConsumerState<ManualSupplementInputScreen> createState() =>
      _ManualSupplementInputScreenState();
}

class _ManualSupplementInputScreenState
    extends ConsumerState<ManualSupplementInputScreen> {
  final _name = TextEditingController();
  final _brand = TextEditingController();
  final _dose = TextEditingController(text: '1');
  final _packageSize = TextEditingController(text: '60');
  final _price = TextEditingController();
  final List<_IngredientField> _ingredientFields = [];
  String _category = _categories.first;

  @override
  void dispose() {
    _name.dispose();
    _brand.dispose();
    _dose.dispose();
    _packageSize.dispose();
    _price.dispose();
    for (final f in _ingredientFields) {
      f.dispose();
    }
    super.dispose();
  }

  void _addIngredient() {
    setState(() => _ingredientFields.add(_IngredientField()));
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    final dose = int.tryParse(_dose.text);
    final packageSize = int.tryParse(_packageSize.text);

    if (name.isEmpty || dose == null || dose <= 0 || packageSize == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('필수 항목을 입력해주세요')),
      );
      return;
    }

    final ingredients = <String, double>{};
    for (final f in _ingredientFields) {
      final key = f.key.text.trim();
      final amount = double.tryParse(f.value.text) ?? 0;
      if (key.isEmpty || amount <= 0) continue;
      ingredients[key] = amount;
    }

    final manual = ManualProductEntry(
      id: 'manual_${DateTime.now().microsecondsSinceEpoch}',
      name: name,
      brand: _brand.text.trim().isEmpty ? null : _brand.text.trim(),
      category: _category,
      dailyDose: dose,
      packageSize: packageSize,
      priceKrw: int.tryParse(_price.text),
      ingredients: ingredients,
      startedAt: DateTime.now(),
    );

    final controller = ref.read(familyControllerProvider);
    final member = controller.getMember(widget.memberId);
    if (member == null) return;
    final updated = member.copyWith(
      manualProducts: [...member.manualProducts, manual],
    );
    await controller.updateMember(updated);

    final daysOfStock = packageSize ~/ dose;
    final remind = (daysOfStock - 5).clamp(7, 365);
    await ref.read(notificationServiceProvider).scheduleProductReorderReminder(
          memberId: widget.memberId,
          productId: manual.id,
          daysFromNow: remind,
        );
    if (!mounted) return;
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('영양제 직접 추가'),
        actions: [
          TextButton(onPressed: _save, child: const Text('저장')),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            '라벨을 보고 입력해주세요\n'
            '성분을 입력하지 않으면 영양 분석이 정확하지 않을 수 있어요',
            style: AppTypography.body2,
          ),
          const SizedBox(height: 16),
          _label('제품명 *'),
          TextField(
            controller: _name,
            decoration: const InputDecoration(border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          _label('카테고리 *'),
          DropdownButtonFormField<String>(
            initialValue: _category,
            items: [
              for (final c in _categories)
                DropdownMenuItem(value: c, child: Text(c)),
            ],
            onChanged: (v) => setState(() => _category = v ?? _categories.first),
            decoration: const InputDecoration(border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('1일 복용량 *'),
                    TextField(
                      controller: _dose,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('한 통 사이즈 *'),
                    TextField(
                      controller: _packageSize,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _label('브랜드 (선택)'),
          TextField(
            controller: _brand,
            decoration: const InputDecoration(border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          _label('가격 원 (선택)'),
          TextField(
            controller: _price,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(border: OutlineInputBorder()),
          ),
          const SizedBox(height: 16),
          _label('영양 성분 (선택, 반복 가능)'),
          for (final f in _ingredientFields)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: f.key,
                      decoration: const InputDecoration(
                        labelText: '성분 키 (예: vitamin_d_iu)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 110,
                    child: TextField(
                      controller: f.value,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: '함량',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          OutlinedButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('성분 추가'),
            onPressed: _addIngredient,
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _save,
            child: const Text('저장'),
          ),
        ],
      ),
    );
  }
}

Widget _label(String text) => Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(text, style: AppTypography.body2),
    );

class _IngredientField {
  final TextEditingController key = TextEditingController();
  final TextEditingController value = TextEditingController();
  void dispose() {
    key.dispose();
    value.dispose();
  }
}
