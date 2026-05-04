import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/notifications/notification_provider.dart';
import '../../../core/security/secure_storage.dart';
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

/// SecureStorage key for the local "정보 등록 요청" queue. Stored locally
/// only — the queue is read by Settings → admin → export later.
const String kProductRegistrationRequestsKey = 'product.registration.requests';

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
  String _category = _categories.first;

  @override
  void dispose() {
    _name.dispose();
    _brand.dispose();
    _dose.dispose();
    _packageSize.dispose();
    super.dispose();
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

    final manual = ManualProductEntry(
      id: 'manual_${DateTime.now().microsecondsSinceEpoch}',
      name: name,
      brand: _brand.text.trim().isEmpty ? null : _brand.text.trim(),
      category: _category,
      dailyDose: dose,
      packageSize: packageSize,
      ingredients: const {},
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

  Future<void> _requestRegistration() async {
    final ctrl = TextEditingController(text: _name.text.trim());
    final brandCtrl = TextEditingController(text: _brand.text.trim());
    final ok = await showDialog<bool>(
      context: context,
      builder: (dctx) => AlertDialog(
        title: const Text('정보 등록 요청'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '제품명/브랜드를 알려주세요. 검토 후 정확한 함량 데이터로 추가합니다.',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              decoration: const InputDecoration(
                labelText: '제품명',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: brandCtrl,
              decoration: const InputDecoration(
                labelText: '브랜드 (선택)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dctx).pop(false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dctx).pop(true),
            child: const Text('보내기'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final entry =
        '${DateTime.now().toIso8601String()}|${ctrl.text.trim()}|${brandCtrl.text.trim()}';
    final existing = await SecureStorage.read(kProductRegistrationRequestsKey);
    final next = existing == null || existing.isEmpty
        ? entry
        : '$existing\n$entry';
    await SecureStorage.write(kProductRegistrationRequestsKey, next);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('등록 요청을 받았어요')),
    );
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
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.warningLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '함량 정보는 입력하지 않습니다.\n'
              '재구매 알림과 가족별 복용 기록 용도로만 저장돼요.\n'
              '정확한 영양 분석을 원하시면 아래 "정보 등록 요청"을 눌러주세요.',
              style: AppTypography.body2,
            ),
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
            onChanged: (v) =>
                setState(() => _category = v ?? _categories.first),
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
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly
                      ],
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
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly
                      ],
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
          const SizedBox(height: 24),
          OutlinedButton.icon(
            icon: const Icon(Icons.send_outlined),
            label: const Text('정보 등록 요청 (정확한 함량 데이터 추가)'),
            onPressed: _requestRegistration,
          ),
          const SizedBox(height: 12),
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
