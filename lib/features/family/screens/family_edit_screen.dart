import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../models/family_member.dart';
import '../providers/family_provider.dart';

const List<String> kAllergyOptions = [
  '우유', '갑각류', '생선', '대두', '효모', '땅콩', '밀', '기타',
];

const List<String> kMedicationOptions = [
  '혈압약', '당뇨약', '고지혈증약', '항응고제', '갑상선약', '기타',
];

class FamilyEditScreen extends ConsumerStatefulWidget {
  final String memberId;
  const FamilyEditScreen({super.key, required this.memberId});

  @override
  ConsumerState<FamilyEditScreen> createState() => _FamilyEditScreenState();
}

class _FamilyEditScreenState extends ConsumerState<FamilyEditScreen> {
  late final TextEditingController _name;
  late final TextEditingController _birthYear;
  late final TextEditingController _height;
  late final TextEditingController _weight;
  Sex _sex = Sex.male;
  SmokingStatus _smoking = SmokingStatus.never;
  DrinkingFrequency _drinking = DrinkingFrequency.never;
  DietQuality _diet = DietQuality.average;
  SleepHours _sleep = SleepHours.sevenToNine;
  StressLevel _stress = StressLevel.low;
  bool _isPregnant = false;
  bool _isBreastfeeding = false;
  late final Set<String> _allergies;
  late final Set<String> _medications;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController();
    _birthYear = TextEditingController();
    _height = TextEditingController();
    _weight = TextEditingController();
    _allergies = <String>{};
    _medications = <String>{};
  }

  @override
  void dispose() {
    _name.dispose();
    _birthYear.dispose();
    _height.dispose();
    _weight.dispose();
    super.dispose();
  }

  void _hydrate(FamilyMember m) {
    if (_initialized) return;
    _initialized = true;
    _name.text = m.name;
    _birthYear.text = m.birthYear.toString();
    _height.text = m.heightCm?.toStringAsFixed(0) ?? '';
    _weight.text = m.weightKg?.toStringAsFixed(0) ?? '';
    _sex = m.sex;
    _smoking = m.smokingStatus;
    _drinking = m.drinkingFrequency;
    _diet = m.dietQuality;
    _sleep = m.sleepHours;
    _stress = m.stressLevel;
    _isPregnant = m.isPregnant;
    _isBreastfeeding = m.isBreastfeeding;
    _allergies.addAll(m.allergies);
    _medications.addAll(m.medications);
  }

  Future<void> _save(FamilyMember original) async {
    final name = _name.text.trim();
    final year = int.tryParse(_birthYear.text);
    final now = DateTime.now().year;
    if (name.isEmpty ||
        year == null ||
        year < (now - 120) ||
        year > now) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('이름과 출생년도를 확인해주세요')),
      );
      return;
    }
    final updated = original.copyWith(
      name: name,
      birthYear: year,
      sex: _sex,
      heightCm: double.tryParse(_height.text),
      weightKg: double.tryParse(_weight.text),
      smokingStatus: _smoking,
      drinkingFrequency: _drinking,
      dietQuality: _diet,
      sleepHours: _sleep,
      stressLevel: _stress,
      isPregnant: _isPregnant,
      isBreastfeeding: _isBreastfeeding,
      allergies: _allergies.toList(),
      medications: _medications.toList(),
    );
    await ref.read(familyControllerProvider).updateMember(updated);
    if (!mounted) return;
    context.pop();
  }

  Future<void> _delete(FamilyMember m) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dctx) => AlertDialog(
        title: Text('${m.name}님을 삭제하시겠어요?'),
        content: const Text('영양제 기록도 함께 삭제돼요.'),
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
    await ref.read(familyControllerProvider).removeMember(m.id);
    if (!mounted) return;
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final member = ref.watch(familyControllerProvider).getMember(widget.memberId);
    if (member == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('가족 멤버를 찾을 수 없어요')),
      );
    }
    _hydrate(member);
    final yearNow = DateTime.now().year;
    final ageFromForm = yearNow - (int.tryParse(_birthYear.text) ?? yearNow);
    final isAdultWoman = ageFromForm >= 19 && _sex == Sex.female;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('${member.name} 수정'),
        actions: [
          TextButton(
            onPressed: () => _save(member),
            child: const Text('저장'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _section('기본 정보'),
          _label('이름 *'),
          TextField(
            controller: _name,
            decoration: const InputDecoration(border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('출생년도 *'),
                    TextField(
                      controller: _birthYear,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(4),
                      ],
                      decoration: const InputDecoration(
                          hintText: '예: 1990',
                          border: OutlineInputBorder()),
                      onChanged: (_) => setState(() {}),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('성별 *'),
                    SegmentedButton<Sex>(
                      segments: const [
                        ButtonSegment(value: Sex.male, label: Text('남')),
                        ButtonSegment(value: Sex.female, label: Text('여')),
                      ],
                      selected: {_sex},
                      onSelectionChanged: (s) =>
                          setState(() => _sex = s.first),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('키 cm'),
                    TextField(
                      controller: _height,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                      ],
                      decoration: const InputDecoration(
                          border: OutlineInputBorder()),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('몸무게 kg'),
                    TextField(
                      controller: _weight,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                      ],
                      decoration: const InputDecoration(
                          border: OutlineInputBorder()),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _section('라이프스타일'),
          _dropdown<SmokingStatus>(
            label: '흡연',
            value: _smoking,
            items: const {
              SmokingStatus.never: '안함',
              SmokingStatus.former: '끊었음',
              SmokingStatus.current: '현재',
            },
            onChanged: (v) => setState(() => _smoking = v),
          ),
          _dropdown<DrinkingFrequency>(
            label: '음주',
            value: _drinking,
            items: const {
              DrinkingFrequency.never: '안함',
              DrinkingFrequency.weekly: '주 1-2회',
              DrinkingFrequency.daily: '거의 매일',
            },
            onChanged: (v) => setState(() => _drinking = v),
          ),
          _dropdown<DietQuality>(
            label: '식단',
            value: _diet,
            items: const {
              DietQuality.good: '좋음',
              DietQuality.average: '보통',
              DietQuality.poor: '부족',
            },
            onChanged: (v) => setState(() => _diet = v),
          ),
          _dropdown<SleepHours>(
            label: '수면',
            value: _sleep,
            items: const {
              SleepHours.less5: '<5h',
              SleepHours.fiveToSeven: '5-7h',
              SleepHours.sevenToNine: '7-9h',
              SleepHours.more9: '>9h',
            },
            onChanged: (v) => setState(() => _sleep = v),
          ),
          _dropdown<StressLevel>(
            label: '스트레스',
            value: _stress,
            items: const {
              StressLevel.low: '낮음',
              StressLevel.medium: '보통',
              StressLevel.high: '높음',
            },
            onChanged: (v) => setState(() => _stress = v),
          ),
          if (isAdultWoman) ...[
            const SizedBox(height: 20),
            _section('건강 (성인 여성)'),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('임신 중'),
              value: _isPregnant,
              onChanged: (v) => setState(() => _isPregnant = v),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('수유 중'),
              value: _isBreastfeeding,
              onChanged: (v) => setState(() => _isBreastfeeding = v),
            ),
          ],
          const SizedBox(height: 20),
          _section('알레르기 (선택)'),
          _chipGrid(
            options: kAllergyOptions,
            selected: _allergies,
            onToggle: (v) => setState(() {
              _allergies.contains(v)
                  ? _allergies.remove(v)
                  : _allergies.add(v);
            }),
          ),
          const SizedBox(height: 20),
          _section('복용 약 (선택)'),
          _chipGrid(
            options: kMedicationOptions,
            selected: _medications,
            onToggle: (v) => setState(() {
              _medications.contains(v)
                  ? _medications.remove(v)
                  : _medications.add(v);
            }),
          ),
          const SizedBox(height: 28),
          _section('위험 영역'),
          OutlinedButton.icon(
            icon: const Icon(Icons.delete_outline, color: AppColors.error),
            label: const Text('가족에서 삭제',
                style: TextStyle(color: AppColors.error)),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: AppColors.error.withValues(alpha: 0.5)),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            onPressed: () => _delete(member),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

Widget _section(String title) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(title, style: AppTypography.heading3),
    );

Widget _label(String text) => Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(text, style: AppTypography.body2),
    );

Widget _dropdown<T extends Object>({
  required String label,
  required T value,
  required Map<T, String> items,
  required void Function(T) onChanged,
}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      children: [
        SizedBox(width: 80, child: Text(label, style: AppTypography.body1)),
        Expanded(
          child: DropdownButtonFormField<T>(
            initialValue: value,
            items: [
              for (final entry in items.entries)
                DropdownMenuItem(value: entry.key, child: Text(entry.value)),
            ],
            onChanged: (v) {
              if (v != null) onChanged(v);
            },
            decoration: const InputDecoration(
              isDense: true,
              border: OutlineInputBorder(),
            ),
          ),
        ),
      ],
    ),
  );
}

Widget _chipGrid({
  required List<String> options,
  required Set<String> selected,
  required void Function(String) onToggle,
}) {
  return Wrap(
    spacing: 6,
    runSpacing: 6,
    children: [
      for (final opt in options)
        FilterChip(
          label: Text(opt),
          selected: selected.contains(opt),
          onSelected: (_) => onToggle(opt),
        ),
    ],
  );
}
