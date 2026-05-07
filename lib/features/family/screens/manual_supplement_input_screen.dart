import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/data/models/product_model.dart';
import '../../../core/data/product_repository.dart';
import '../../../core/notifications/notification_provider.dart';
import '../../../core/services/conflict_checker.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/alyak_buttons.dart';
import '../../../core/widgets/alyak_card.dart';
import '../../../core/widgets/conflict_section.dart';
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

const _errorOutline = OutlineInputBorder(
  borderSide: BorderSide(color: AppColors.alertBorder, width: 1.5),
);

class ManualSupplementInputScreen extends ConsumerStatefulWidget {
  final String memberId;

  /// When non-null, the form is in edit mode for a previously-saved
  /// `ManualProductEntry`. Submit overwrites that entry instead of appending.
  final String? editEntryId;

  const ManualSupplementInputScreen({
    super.key,
    required this.memberId,
    this.editEntryId,
  });

  @override
  ConsumerState<ManualSupplementInputScreen> createState() =>
      _ManualSupplementInputScreenState();
}

class _ManualSupplementInputScreenState
    extends ConsumerState<ManualSupplementInputScreen> {
  final _name = TextEditingController();
  final _brand = TextEditingController();
  final _packageSize = TextEditingController(text: '60');
  final _customDose = TextEditingController();
  final _customIntakes = TextEditingController();
  final _intakeNote = TextEditingController();

  String _category = _categories.first;
  IntakeTiming _timing = IntakeTiming.anyTimeAfterMeal;
  // Selected radio for dose-per-intake. -1 means "직접 입력".
  int _doseChoice = 1;
  // Selected radio for intakes-per-day. -1 means "직접 입력".
  int _intakeChoice = 1;

  ManualProductEntry? _editing;

  // Validation error messages keyed by field id. Empty / missing = OK.
  String? _errName;
  String? _errDose;
  String? _errIntakes;
  String? _errPackage;

  // Anchors for scroll-to-first-error.
  final _nameKey = GlobalKey();
  final _doseKey = GlobalKey();
  final _intakesKey = GlobalKey();
  final _packageKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    if (widget.editEntryId != null) {
      final controller = ref.read(familyControllerProvider);
      final member = controller.getMember(widget.memberId);
      final entry = member?.manualProducts.firstWhere(
        (e) => e.id == widget.editEntryId,
        orElse: () => ManualProductEntry(
          id: '',
          name: '',
          category: _categories.first,
          dailyDose: 1,
          packageSize: 0,
          ingredients: const {},
          startedAt: DateTime.now(),
        ),
      );
      if (entry != null && entry.id.isNotEmpty) {
        _editing = entry;
        _name.text = entry.name;
        _brand.text = entry.brand ?? '';
        _packageSize.text = entry.packageSize.toString();
        _category = _categories.contains(entry.category)
            ? entry.category
            : _categories.first;
        _timing = entry.intakeTiming;
        _doseChoice = const [1, 2, 3].contains(entry.dosePerIntake)
            ? entry.dosePerIntake
            : -1;
        if (_doseChoice == -1) {
          _customDose.text = entry.dosePerIntake.toString();
        }
        _intakeChoice = const [1, 2, 3].contains(entry.intakesPerDay)
            ? entry.intakesPerDay
            : -1;
        if (_intakeChoice == -1) {
          _customIntakes.text = entry.intakesPerDay.toString();
        }
        _intakeNote.text = entry.intakeNote ?? '';
      }
    }

  }

  @override
  void dispose() {
    _name.dispose();
    _brand.dispose();
    _packageSize.dispose();
    _customDose.dispose();
    _customIntakes.dispose();
    _intakeNote.dispose();
    super.dispose();
  }

  int? _resolvedDose() {
    if (_doseChoice == -1) {
      final v = int.tryParse(_customDose.text.trim());
      if (v == null || v < 1) return null;
      return v;
    }
    return _doseChoice;
  }

  int? _resolvedIntakes() {
    if (_intakeChoice == -1) {
      final v = int.tryParse(_customIntakes.text.trim());
      if (v == null || v < 1) return null;
      return v;
    }
    return _intakeChoice;
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    final dose = _resolvedDose();
    final intakes = _resolvedIntakes();
    final packageSizeRaw = _packageSize.text.trim();
    final packageSize = int.tryParse(packageSizeRaw);

    setState(() {
      _errName = name.isEmpty ? '제품명을 입력해주세요' : null;
      _errDose = dose == null
          ? (_doseChoice == -1
              ? '1회 복용량을 입력해주세요'
              : '1회 복용량을 선택해주세요')
          : null;
      _errIntakes = intakes == null
          ? (_intakeChoice == -1
              ? '1일 횟수를 입력해주세요'
              : '1일 횟수를 선택해주세요')
          : null;
      _errPackage = (packageSize == null || packageSize < 1)
          ? '한 통 사이즈를 입력해주세요'
          : null;
    });

    final firstError = <(String?, GlobalKey)>[
      (_errName, _nameKey),
      (_errDose, _doseKey),
      (_errIntakes, _intakesKey),
      (_errPackage, _packageKey),
    ].firstWhere((e) => e.$1 != null, orElse: () => (null, _nameKey));

    if (firstError.$1 != null) {
      final ctx = firstError.$2.currentContext;
      if (ctx != null) {
        await Scrollable.ensureVisible(
          ctx,
          duration: const Duration(milliseconds: 250),
          alignment: 0.1,
        );
      }
      return;
    }

    // Re-cast to non-nullable now that validation has passed.
    if (dose == null || intakes == null || packageSize == null) return;

    final dailyDose = dose * intakes;
    // If 1일 2회 이상이면 multiple로 보고 — UI에서 분복 라벨이 합성되도록.
    final timing = intakes >= 2 ? IntakeTiming.multiple : _timing;
    final note = _intakeNote.text.trim().isEmpty
        ? null
        : _intakeNote.text.trim();

    final controller = ref.read(familyControllerProvider);
    final member = controller.getMember(widget.memberId);
    if (member == null) return;

    if (_editing != null) {
      final updatedEntry = _editing!.copyWith(
        name: name,
        brand: _brand.text.trim().isEmpty ? null : _brand.text.trim(),
        category: _category,
        dailyDose: dailyDose,
        packageSize: packageSize,
        intakeTiming: timing,
        dosePerIntake: dose,
        intakesPerDay: intakes,
        intakeNote: note,
      );
      final updated = member.copyWith(
        manualProducts: [
          for (final m in member.manualProducts)
            if (m.id == updatedEntry.id) updatedEntry else m,
        ],
      );
      await controller.updateMember(updated);
    } else {
      final manual = ManualProductEntry(
        id: 'manual_${DateTime.now().microsecondsSinceEpoch}',
        name: name,
        brand: _brand.text.trim().isEmpty ? null : _brand.text.trim(),
        category: _category,
        dailyDose: dailyDose,
        packageSize: packageSize,
        ingredients: const {},
        startedAt: DateTime.now(),
        intakeTiming: timing,
        dosePerIntake: dose,
        intakesPerDay: intakes,
        intakeNote: note,
      );

      // Conflict preview — manual entries lack ingredient totals so only the
      // timing-pile-up rule fires. Still useful for "5 supplements at once".
      final repo = ref.read(productRepositoryProvider);
      final currentProducts = member.currentProductIds
          .map(repo.getById)
          .whereType<Product>()
          .toList(growable: false);
      final beforeAll = ConflictChecker.check(
        member: member,
        products: currentProducts,
        manuals: member.manualProducts,
      );
      final afterAll = ConflictChecker.check(
        member: member,
        products: currentProducts,
        manuals: [...member.manualProducts, manual],
      );
      final added = afterAll.skip(beforeAll.length).toList();
      if (added.isNotEmpty && mounted) {
        final ok = await showDialog<bool>(
          context: context,
          builder: (dctx) => ConflictAddDialog(
            conflicts: added,
            productName: name,
            onCancel: () => Navigator.of(dctx).pop(false),
            onConfirm: () => Navigator.of(dctx).pop(true),
          ),
        );
        if (ok != true) return;
      }
      if (!mounted) return;

      final updated = member.copyWith(
        manualProducts: [...member.manualProducts, manual],
      );
      await controller.updateMember(updated);
      final daysOfStock = packageSize ~/ dailyDose;
      final remind = (daysOfStock - 5).clamp(7, 365);
      await ref
          .read(notificationServiceProvider)
          .scheduleProductReorderReminder(
            memberId: widget.memberId,
            productId: manual.id,
            daysFromNow: remind,
          );
    }

    if (!mounted) return;
    final isEditing = _editing != null;
    context.pop();
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger != null) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            isEditing ? '$name 정보가 수정됐어요' : '$name이(가) 추가됐어요',
          ),
          backgroundColor: AppColors.okInk,
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = _editing != null;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/home'),
        ),
        title: Text(isEditing ? '영양제 수정' : '영양제 직접 추가'),
        actions: [
          TextButton(
            onPressed: _save,
            child: Text(isEditing ? '수정' : '저장'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
        children: [
          AlyakCard(
            background: AppColors.warnBg,
            border: Border.all(
              color: AppColors.warnBorder.withValues(alpha: 0.2),
            ),
            shadow: const [],
            padding: const EdgeInsets.all(14),
            child: Text.rich(
              TextSpan(
                style: AppTypography.body2.copyWith(
                  fontSize: 13,
                  color: AppColors.ink2,
                ),
                children: [
                  TextSpan(
                    text: '⚠️ 함량 정보는 입력하지 않습니다  ',
                    style: AppTypography.title.copyWith(
                      fontSize: 13,
                      color: AppColors.warnInk,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const TextSpan(
                    text:
                        '복용 기록과 재구매 알림 용도로만 저장돼요. 정확한 분석은 라벨 검증된 250개 제품에서만 가능해요.',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          KeyedSubtree(key: _nameKey, child: _label('제품명 *')),
          TextField(
            controller: _name,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              errorText: _errName,
              errorBorder: _errorOutline,
              focusedErrorBorder: _errorOutline,
            ),
            onChanged: (_) {
              if (_errName != null) setState(() => _errName = null);
            },
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
          const SizedBox(height: 16),
          _label('복용 시간 *'),
          _TimingPicker(
            value: _timing,
            onChanged: (t) => setState(() => _timing = t),
          ),
          const SizedBox(height: 16),
          KeyedSubtree(key: _doseKey, child: _label('1회 복용량 *')),
          _RadioWithCustom(
            options: const [1, 2, 3],
            optionLabel: (n) => '$n정',
            selected: _doseChoice,
            onSelect: (v) => setState(() {
              _doseChoice = v;
              _errDose = null;
            }),
            customController: _customDose,
            customSuffix: '정',
            errorText: _errDose,
          ),
          const SizedBox(height: 16),
          KeyedSubtree(key: _intakesKey, child: _label('1일 횟수 *')),
          _RadioWithCustom(
            options: const [1, 2, 3],
            optionLabel: (n) => '$n회',
            selected: _intakeChoice,
            onSelect: (v) => setState(() {
              _intakeChoice = v;
              _errIntakes = null;
            }),
            customController: _customIntakes,
            customSuffix: '회',
            errorText: _errIntakes,
          ),
          const SizedBox(height: 16),
          KeyedSubtree(key: _packageKey, child: _label('한 통 사이즈 *')),
          TextField(
            controller: _packageSize,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              suffixText: '정/포/캡슐',
              errorText: _errPackage,
              errorBorder: _errorOutline,
              focusedErrorBorder: _errorOutline,
            ),
            onChanged: (_) {
              if (_errPackage != null) setState(() => _errPackage = null);
            },
          ),
          const SizedBox(height: 12),
          _label('브랜드 (선택)'),
          TextField(
            controller: _brand,
            decoration: const InputDecoration(border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          _label('복용 메모 (선택)'),
          TextField(
            controller: _intakeNote,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: '예: 공복 또는 식전 30분, 분복 권장',
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 24),
          PrimaryButton(
            label: isEditing ? '수정 저장' : '저장',
            full: true,
            onPressed: _save,
          ),
        ],
      ),
    );
  }
}

Widget _label(String text) => Padding(
      padding: const EdgeInsets.only(bottom: 6, left: 4),
      child: Text(
        text,
        style: AppTypography.body2.copyWith(
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
          color: AppColors.muted,
        ),
      ),
    );

class _TimingPicker extends StatelessWidget {
  final IntakeTiming value;
  final ValueChanged<IntakeTiming> onChanged;
  const _TimingPicker({required this.value, required this.onChanged});

  static const List<(IntakeTiming, String)> _options = [
    (IntakeTiming.morningEmpty, '🌅 오전 식사 전 (공복)'),
    (IntakeTiming.morningAfter, '🌅 오전 식사 후'),
    (IntakeTiming.lunchAfter, '🌞 점심 식사 후'),
    (IntakeTiming.dinnerAfter, '🌙 저녁 식사 후'),
    (IntakeTiming.beforeSleep, '🌙 취침 전'),
    (IntakeTiming.anyTimeAfterMeal, '🍴 식후 (시간 무관)'),
    (IntakeTiming.withMeal, '🍴 식사 중'),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final (t, label) in _options)
          _RadioRow(
            selected: t == value,
            label: label,
            onTap: () => onChanged(t),
          ),
      ],
    );
  }
}

class _RadioRow extends StatelessWidget {
  final bool selected;
  final String label;
  final VoidCallback onTap;
  const _RadioRow({
    required this.selected,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.r10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        child: Row(
          children: [
            Icon(
              selected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: selected ? AppColors.primary : AppColors.faint,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: AppTypography.body1.copyWith(fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RadioWithCustom extends StatelessWidget {
  final List<int> options;
  final String Function(int) optionLabel;
  final int selected;
  final ValueChanged<int> onSelect;
  final TextEditingController customController;
  final String customSuffix;
  final String? errorText;

  const _RadioWithCustom({
    required this.options,
    required this.optionLabel,
    required this.selected,
    required this.onSelect,
    required this.customController,
    required this.customSuffix,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final n in options)
          _RadioRow(
            selected: n == selected,
            label: optionLabel(n),
            onTap: () => onSelect(n),
          ),
        _RadioRow(
          selected: selected == -1,
          label: '직접 입력',
          onTap: () => onSelect(-1),
        ),
        if (selected == -1)
          Padding(
            padding: const EdgeInsets.fromLTRB(34, 4, 0, 0),
            child: TextField(
              controller: customController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(3),
              ],
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
                suffixText: customSuffix,
                errorBorder: _errorOutline,
                focusedErrorBorder: _errorOutline,
                errorText: errorText != null ? '' : null, // border-only
              ),
            ),
          ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(left: 4, top: 4),
            child: Text(
              errorText!,
              style: const TextStyle(
                color: AppColors.alertInk,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }
}
