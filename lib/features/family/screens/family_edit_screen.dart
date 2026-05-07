import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/services/profile_photo_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/profile_avatar.dart';
import '../../../core/widgets/state_views.dart';
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
  // Default 'good' — edit 화면 dropdown items가 good/poor 2개라
  // 'average'는 hydrate 폴백에서 'good'으로 정규화됩니다.
  DietQuality _diet = DietQuality.good;
  SleepHours _sleep = SleepHours.sevenToNine;
  StressLevel _stress = StressLevel.low;
  bool _isPregnant = false;
  bool _isBreastfeeding = false;
  late final Set<String> _allergies;
  late final Set<String> _medications;
  bool _initialized = false;

  final ProfilePhotoService _photoService = ProfilePhotoService();

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
    // dropdown items가 good/poor 2개로 단순화됐으므로 legacy 'average'는
    // 'good'으로 정규화 (DropdownButtonFormField initialValue가 items에
    // 없을 때의 assertion을 막기 위함).
    _diet = m.dietQuality == DietQuality.average
        ? DietQuality.good
        : m.dietQuality;
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

  Future<void> _changePhoto(FamilyMember member) async {
    final choice = await showModalBottomSheet<_PhotoAction>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      showDragHandle: true,
      builder: (sheetCtx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('프로필 사진 변경',
                  style: AppTypography.heading2.copyWith(fontSize: 17)),
              const SizedBox(height: 12),
              _photoTile(
                emoji: '📷',
                title: '카메라로 찍기',
                onTap: () =>
                    Navigator.of(sheetCtx).pop(_PhotoAction.camera),
              ),
              const SizedBox(height: 8),
              _photoTile(
                emoji: '🖼️',
                title: '갤러리에서 선택',
                onTap: () =>
                    Navigator.of(sheetCtx).pop(_PhotoAction.gallery),
              ),
              if (member.profileImagePath != null) ...[
                const SizedBox(height: 8),
                _photoTile(
                  emoji: '🔄',
                  title: '기본 이모지로 복원',
                  onTap: () =>
                      Navigator.of(sheetCtx).pop(_PhotoAction.reset),
                ),
              ],
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.of(sheetCtx).pop(),
                child: const Text('취소'),
              ),
            ],
          ),
        ),
      ),
    );
    if (choice == null) return;

    if (choice == _PhotoAction.reset) {
      await _photoService.deleteIfExists(member.profileImagePath);
      final updated = member.copyWith(profileImagePath: null);
      await ref.read(familyControllerProvider).updateMember(updated);
      if (!mounted) return;
      _toast('기본 이모지로 복원했어요');
      return;
    }

    try {
      final picked = choice == _PhotoAction.camera
          ? await _photoService.pickFromCamera()
          : await _photoService.pickFromGallery();
      if (picked == null) return;

      final saved = await _photoService.saveForMember(
        memberId: member.id,
        src: picked,
      );
      // Wipe the previous file before persisting the new path.
      await _photoService.deleteIfExists(member.profileImagePath);
      final updated = member.copyWith(profileImagePath: saved);
      await ref.read(familyControllerProvider).updateMember(updated);
      if (!mounted) return;
      _toast('프로필 사진이 변경됐어요');
    } catch (e) {
      if (!mounted) return;
      _toast('사진을 가져올 수 없어요. 권한을 확인해주세요');
    }
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
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
    // Watch the list itself (not the controller) so build() re-runs when
    // the member is mutated — e.g. after a profile-photo change. The
    // earlier `ref.watch(familyControllerProvider)` returned the notifier
    // instance, which does not trigger rebuilds on state changes.
    ref.watch(familyMembersProvider);
    final member =
        ref.read(familyControllerProvider).getMember(widget.memberId);
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
          _PhotoSection(
            member: member,
            onChange: () => _changePhoto(member),
          ),
          const SizedBox(height: 16),
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
          _section('생활'),
          // 흡연 / 음주 / 수면 / 스트레스 입력은 KDRIs 2025 정렬로 제거
          // (한국 영양소 섭취기준에 별도 권장량이 없습니다). 식단만
          // 종합비타민 일반 권고 분기 용도로 유지하고, 균형/부족 2지선으로
          // 단순화합니다.
          _dropdown<DietQuality>(
            label: '식단',
            value: _diet,
            items: const {
              DietQuality.good: '균형 잡힘',
              DietQuality.poor: '부족 (편식·외식 잦음)',
            },
            onChanged: (v) => setState(() => _diet = v),
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

enum _PhotoAction { camera, gallery, reset }

class _PhotoSection extends StatelessWidget {
  final FamilyMember member;
  final VoidCallback onChange;

  const _PhotoSection({required this.member, required this.onChange});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: onChange,
            child: ProfileAvatar(
              member: member,
              size: 96,
              showEditHint: true,
            ),
          ),
          const SizedBox(height: 12),
          Material(
            color: AppColors.primarySoft,
            borderRadius: BorderRadius.circular(AppRadius.r12),
            child: InkWell(
              borderRadius: BorderRadius.circular(AppRadius.r12),
              onTap: onChange,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.camera_alt_rounded,
                        size: 16, color: AppColors.primaryInk),
                    const SizedBox(width: 6),
                    Text(
                      '사진 변경하기',
                      style: AppTypography.title.copyWith(
                        fontSize: 13,
                        color: AppColors.primaryInk,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Widget _photoTile({
  required String emoji,
  required String title,
  required VoidCallback onTap,
}) {
  return Material(
    color: AppColors.surfaceMuted,
    borderRadius: BorderRadius.circular(AppRadius.r12),
    child: InkWell(
      borderRadius: BorderRadius.circular(AppRadius.r12),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: AppTypography.title.copyWith(fontSize: 14.5),
              ),
            ),
            const Icon(Icons.chevron_right,
                size: 18, color: AppColors.faint),
          ],
        ),
      ),
    ),
  );
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
