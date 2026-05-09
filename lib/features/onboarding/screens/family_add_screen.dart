import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/data/models/product_model.dart';
import '../../../core/data/product_repository.dart';
import '../../../core/notifications/notification_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/alyak_buttons.dart';
import '../../../core/widgets/alyak_card.dart';
import '../../../core/widgets/intake_timing_badge.dart';
import '../../../core/widgets/product_image.dart';
import '../../../core/widgets/step_indicator.dart';
import '../../family/models/family_member.dart';
import '../../family/providers/family_provider.dart';
import '../widgets/chat_message.dart';

/// Toss-style chat to register a new family member.
/// Steps (max 17 — most users see fewer because of age/sex skips):
///   1 relationship · 2 name · 3 birthYear · 4 sex (only when relationship
///   doesn't imply it) · 5 medical disclaimer (only when age < 14) ·
///   6 height/weight · 7 pregnancy/lactation (combined, female 20–50) ·
///   8 blood type (optional, all ages) ·
///   9 smoking · 10 drinking (dropped) · 11 diet (4+) · 12 sleep · 13 stress
///   (dropped) · 14 allergies · 15 medications (1+) ·
///   16 products (opens inline picker sheet) · 17 complete.
class FamilyAddScreen extends ConsumerStatefulWidget {
  /// Optional preset relationship — when entering from the welcome
  /// screen's "나부터 등록하기" CTA we skip step 1.
  final Relationship? presetRelationship;
  const FamilyAddScreen({super.key, this.presetRelationship});

  @override
  ConsumerState<FamilyAddScreen> createState() => _FamilyAddScreenState();
}

class _FamilyAddScreenState extends ConsumerState<FamilyAddScreen> {
  final _scrollCtrl = ScrollController();
  final _draft = _Draft();
  int _step = 1;
  static const int _totalSteps = 17;

  @override
  void initState() {
    super.initState();
    final preset = widget.presetRelationship;
    if (preset != null) {
      _draft.relationship = preset;
      final implied = _impliedSex(preset);
      if (implied != null) _draft.sex = implied;
      _draft.answers.add(_AnsweredEntry(1, preset.label));
      _step = 2;
    }
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollCtrl.hasClients) return;
      _scrollCtrl.animateTo(
        _scrollCtrl.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  bool shouldShowStep(int step) => _shouldShow(step, _draft);

  /// step 7 임신/수유 선택 (해당 없음 외) — 산부인과 상담 동의 게이트
  Future<void> _onPickPregLact(String label) async {
    await _gateAndNext(
      title: '🤰 임신·수유 중 영양제 안내',
      body: '· 비타민A·D·E 등은 과다 시 태아·영아에 영향을 줄 수 있어요\n'
          '· 한방 영양제는 산부인과와 반드시 상의하세요\n'
          '· 본 앱 추천은 한국인 영양소 섭취기준 기반 일반 정보이며,\n'
          '  개인 임신·수유 상태별 처방을 대체하지 않습니다',
      checkLabel: '산부인과와 상의 후 영양제 복용을 결정하겠습니다',
      answer: label,
    );
  }

  /// step 15 약물 1개 이상 선택 — 약사·의사 상담 동의 게이트
  Future<void> _onPickMedications(List<String> picked, String label) async {
    if (picked.isEmpty) {
      _next(answer: label);
      return;
    }
    await _gateAndNext(
      title: '💊 복용 중인 약 — 영양제 상호작용',
      body: '선택하신 약: ${picked.join(", ")}\n\n'
          '· 혈압약 + 칼슘/마그네슘 → 혈압 변동 가능\n'
          '· 갑상선약 + 철분/칼슘 → 흡수 방해\n'
          '· 항응고제 + 오메가3/비타민K → 출혈 위험\n'
          '· 당뇨약 + 크롬/베르베린 → 혈당 변동\n\n'
          '본 앱은 일반 정보를 제공하며,\n'
          '약물 상호작용은 약사·의사와 반드시 상의하세요.',
      checkLabel: '영양제 복용 전 약사·의사와 상의하겠습니다',
      answer: label,
    );
  }

  /// step 14 알레르기 1개 이상 선택 — 라벨 확인 안내 (체크박스 없음)
  Future<void> _onPickAllergies(List<String> picked, String label) async {
    if (picked.isEmpty) {
      _next(answer: label);
      return;
    }
    await showDialog<void>(
      context: context,
      builder: (dctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.r20),
        ),
        title: const Text('ℹ️ 영양제 라벨을 꼭 확인해주세요'),
        content: const Text(
          '영양제 캡슐·코팅·보조제에 유당·대두·갑각류·효모 등이 포함될 수 '
          '있어요. 알레르기 성분이 들어 있는지 라벨을 확인 후 복용하세요.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dctx).pop(),
            child: const Text('알겠어요'),
          ),
        ],
      ),
    );
    if (mounted) _next(answer: label);
  }

  void _next({String? answer}) {
    if (answer != null) _draft.answers.add(_AnsweredEntry(_step, answer));
    var next = _step + 1;
    while (next < _totalSteps && !shouldShowStep(next)) {
      next++;
    }
    setState(() => _step = next);
    _scrollToEnd();
  }

  /// 모달로 면책 동의를 받고 동의 시 _next() 진행. 거부/취소 시 step 유지.
  /// title/body/checkLabel은 화면별 컨텍스트.
  Future<void> _gateAndNext({
    required String title,
    required String body,
    required String checkLabel,
    required String answer,
  }) async {
    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dctx) => _ConsentGateDialog(
        title: title,
        body: body,
        checkLabel: checkLabel,
      ),
    );
    if (ok == true && mounted) _next(answer: answer);
  }

  void _back() {
    var prev = _step - 1;
    while (prev >= 1 && !shouldShowStep(prev)) {
      prev--;
    }
    if (prev < 1) {
      _confirmCancel();
      return;
    }
    setState(() {
      _step = prev;
      _draft.answers.removeWhere((a) => a.step >= _step);
    });
  }

  Future<void> _confirmCancel() async {
    if (_draft.answers.isEmpty) {
      if (mounted) context.pop();
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (dctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.r20),
        ),
        title: const Text('가족 등록을 취소하시겠어요?'),
        content: const Text('입력한 정보는 저장되지 않습니다'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dctx).pop(false),
            child: const Text('계속 작성'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            onPressed: () => Navigator.of(dctx).pop(true),
            child: const Text('취소'),
          ),
        ],
      ),
    );
    if (ok == true && mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _confirmCancel();
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, size: 20),
            onPressed: _back,
          ),
          title: StepIndicator(step: _step, total: _totalSteps),
          centerTitle: true,
          actions: [
            if (_step < _totalSteps && _step != 5)
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: TextButton(
                  onPressed: () => _next(answer: null),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.muted,
                    textStyle: const TextStyle(
                      fontFamily: AppTypography.family,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  child: const Text('건너뛰기'),
                ),
              ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: ListView(
                controller: _scrollCtrl,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                children: _renderHistory(),
              ),
            ),
            _StepInput(
              step: _step,
              draft: _draft,
              onAnswer: (label) => _next(answer: label),
              onSubmitDraft: _draft.set,
              onComplete: _save,
              onSkip: () => _next(answer: null),
              onOpenProductSheet: _openProductSheet,
              onPickHighRiskPregLact: _onPickPregLact,
              onPickMedications: _onPickMedications,
              onPickAllergies: _onPickAllergies,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openProductSheet() async {
    final picked = await showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _ProductPickerSheet(
        initial: _draft.pendingCuratedProductIds,
      ),
    );
    if (picked == null) return;
    if (!mounted) return;
    _draft.pendingCuratedProductIds = picked;
    _next(
      answer: picked.isEmpty
          ? '없음'
          : '${picked.length}개 영양제 추가',
    );
  }

  List<Widget> _renderHistory() {
    final widgets = <Widget>[];
    for (var i = 1; i <= _step; i++) {
      if (!shouldShowStep(i) && i != _step) continue;
      widgets.add(ChatMessage(text: _botPrompt(i), fromUser: false));
      final answered = _draft.answers.where((a) => a.step == i).toList();
      for (final a in answered) {
        widgets.add(ChatMessage(text: a.label, fromUser: true));
      }
    }
    return widgets;
  }

  String _botPrompt(int step) {
    switch (step) {
      case 1:
        return '안녕하세요 👋\n어떤 가족을 추가하실까요?';
      case 2:
        return '${_draft.relationship?.label ?? '가족'}의 이름을 알려주세요';
      case 3:
        return '${_draft.name}님의 출생년도를 알려주세요';
      case 4:
        return '성별이 어떻게 되세요?';
      case 5:
        if (_draft.age < 1) {
          return '⚠️ 잠깐, 알려드릴게요\n'
              '영아 영양제는 반드시 소아과 상담을 받으세요.\n'
              '이 앱은 정보 참고용이며 의학적 진단을 대체하지 않습니다.';
        }
        if (_draft.age < 4) {
          return '⚠️ 알려드릴게요\n'
              '이 시기는 정상 식단으로 충분한 경우가 많아요.\n'
              '영양제 필요 여부는 소아과와 상담하세요.';
        }
        return '⚠️ 알려드릴게요\n'
            '어린이 영양제는 성장·발달에 영향을 줄 수 있어요.\n'
            '복용 전 소아과·약사 상담을 권장해요.\n'
            '본 앱은 정보 참고용이며 의학적 진단을 대체하지 않습니다.';
      case 6:
        return '키와 몸무게를 알려주세요 (선택)';
      case 7:
        return '임신 또는 수유 중이신가요?';
      case 8:
        return '혈액형을 알려주세요 (선택)';
      // step 9 (smoking) / 10 (drinking) — KDRIs에 별도 권장량 없음. 채팅
      // 흐름에서 제거됨. 봇 프롬프트는 도달 시 빈 문자열 폴백.
      case 11:
        return '평소 식단은 어떠신가요?';
      // step 12 (sleep) / 13 (stress) — KDRIs에 별도 권장량 없음. 채팅
      // 흐름에서 제거됨.
      case 14:
        return '알레르기 있으시나요? (선택)';
      case 15:
        return '현재 복용 중인 약이 있나요? (선택)';
      case 16:
        return '현재 드시는 영양제가 있나요? (선택)';
      default:
        return '${_draft.name}님 등록 완료! 🎉';
    }
  }

  Future<void> _save() async {
    if (_draft.relationship == null ||
        _draft.name.isEmpty ||
        _draft.birthYear <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('필수 정보를 입력해주세요')),
      );
      return;
    }
    final now = DateTime.now();
    final id = 'fm_${now.microsecondsSinceEpoch}';
    final member = FamilyMember(
      id: id,
      name: _draft.name,
      relationship: _draft.relationship!,
      birthYear: _draft.birthYear,
      sex: _draft.sex,
      heightCm: _draft.heightCm,
      weightKg: _draft.weightKg,
      smokingStatus: _draft.smokingStatus,
      drinkingFrequency: _draft.drinkingFrequency,
      dietQuality: _draft.dietQuality,
      sleepHours: _draft.sleepHours,
      stressLevel: _draft.stressLevel,
      allergies: List.unmodifiable(_draft.allergies),
      medications: List.unmodifiable(_draft.medications),
      isPregnant: _draft.isPregnant,
      isBreastfeeding: _draft.isBreastfeeding,
      bloodType: _draft.bloodType,
      currentProductIds: List.unmodifiable(_draft.pendingCuratedProductIds),
      createdAt: now,
      updatedAt: now,
    );
    final controller = ref.read(familyControllerProvider);
    final wasFirst = controller.members.isEmpty;
    await controller.addMember(member);

    // Schedule re-order reminders for any inline-picked supplements.
    for (final pid in _draft.pendingCuratedProductIds) {
      try {
        final p = ref.read(productRepositoryProvider).getById(pid);
        if (p == null) continue;
        final dailyDose = p.dailyDose <= 0 ? 1 : p.dailyDose;
        final daysOfStock = p.packageSize ~/ dailyDose;
        final remind = (daysOfStock - 5).clamp(7, 365);
        await ref
            .read(notificationServiceProvider)
            .scheduleProductReorderReminder(
              memberId: member.id,
              productId: pid,
              daysFromNow: remind,
            );
      } catch (_) {
        // Reminder scheduling is best-effort — do not block sign-up.
      }
    }

    if (!mounted) return;

    if (wasFirst) {
      context.go('/onboarding/notification');
    } else if (GoRouter.of(context).canPop()) {
      context.pop();
    } else {
      context.go('/home');
    }
  }
}

/// Returns the implied biological sex for a relationship, if obvious.
/// `null` means "ask the user" (self / other).
Sex? _impliedSex(Relationship r) {
  switch (r) {
    case Relationship.husband:
    case Relationship.father:
    case Relationship.son:
      return Sex.male;
    case Relationship.wife:
    case Relationship.mother:
    case Relationship.daughter:
      return Sex.female;
    case Relationship.self:
    case Relationship.other:
      return null;
  }
}

class _Draft {
  Relationship? relationship;
  String name = '';
  int birthYear = DateTime.now().year - 30;
  Sex sex = Sex.male;
  double? heightCm;
  double? weightKg;
  bool isPregnant = false;
  bool isBreastfeeding = false;
  SmokingStatus smokingStatus = SmokingStatus.never;
  DrinkingFrequency drinkingFrequency = DrinkingFrequency.never;
  // Default 'good' — 채팅 step 11이 균형/부족 2지선만 받으므로 average는
  // 도달 불가. legacy enum 호환을 위해 enum 자체는 남깁니다.
  DietQuality dietQuality = DietQuality.good;
  SleepHours sleepHours = SleepHours.sevenToNine;
  StressLevel stressLevel = StressLevel.low;
  final List<String> allergies = [];
  final List<String> medications = [];
  final List<_AnsweredEntry> answers = [];

  /// ABO + Rh blood type (선택). null = 입력 건너뜀 / 모름.
  String? bloodType;

  /// Curated 250-DB product ids that the user picked in the chat-end product
  /// sheet. Applied to `member.currentProductIds` on save.
  List<String> pendingCuratedProductIds = const [];

  /// Live age = currentYear - birthYear.
  int get age => DateTime.now().year - birthYear;

  void set(void Function(_Draft) f) => f(this);
}

/// Test-only handle on the persona-aware step gating, so persona
/// scenarios can be asserted without driving the full chat UI.
@visibleForTesting
bool debugShouldShowStep({
  required int step,
  required Relationship relationship,
  required Sex sex,
  required int age,
}) {
  final draft = _Draft()
    ..relationship = relationship
    ..sex = sex
    ..birthYear = DateTime.now().year - age;
  return _shouldShow(step, draft);
}

/// Test-only handle on the relationship → implied-sex map.
@visibleForTesting
Sex? debugImpliedSex(Relationship r) => _impliedSex(r);

/// Single source of truth for whether a chat step applies to the
/// person being added. Persona-driven gates:
///   * Step 4 (sex): only when the relationship doesn't imply it (self/other).
///   * Step 7 (pregnancy + lactation, combined): female 20–50.
///   * Step 8: deprecated no-op (kept so the step counter stays at 17 in
///     existing UX dialogs).
///   * Step 8 (blood type): all ages, optional.
///   * Step 9, 10, 12, 13 (smoking / drinking / sleep / stress): DROPPED in
///     KDRIs 2025 alignment — Korean dietary references don't define
///     condition-specific RDAs for these lifestyle variables, so asking
///     them only added noise. The fields stay on FamilyMember (defaults)
///     so legacy member rosters still deserialize cleanly.
///   * Step 11 (diet): 4+, simplified to 균형/부족 2-choice.
///   * Step 14 (allergies): all ages.
///   * Step 15 (medications): 1+.
bool _shouldShow(int step, _Draft d) {
  switch (step) {
    case 1:
    case 2:
    case 3:
      return true;
    case 4:
      // Skip when relationship implies sex.
      final r = d.relationship;
      return r == null || _impliedSex(r) == null;
    case 5: // medical disclaimer (만 14세 미만 자녀)
      return d.age < 14;
    case 6: // height/weight
      return true;
    case 7: // combined pregnancy + lactation
      return d.sex == Sex.female && d.age >= 20 && d.age <= 50;
    case 8: // blood type (NEW, optional)
      return true;
    case 9:
    case 10:
      return false; // smoking / drinking — KDRIs 정렬로 제거
    case 11:
      return d.age >= 4; // 식단 (간소화: 균형/부족)
    case 12:
    case 13:
      return false; // sleep / stress — KDRIs 정렬로 제거
    case 14:
      return true;
    case 15:
      return d.age >= 1;
    case 16:
      return true;
    case 17:
      return true;
    default:
      return true;
  }
}

class _AnsweredEntry {
  final int step;
  final String label;
  _AnsweredEntry(this.step, this.label);
}

class _StepInput extends StatelessWidget {
  final int step;
  final _Draft draft;
  final void Function(String label) onAnswer;
  final void Function(void Function(_Draft)) onSubmitDraft;
  final VoidCallback onComplete;
  final VoidCallback onSkip;
  final VoidCallback onOpenProductSheet;
  final void Function(String label) onPickHighRiskPregLact;
  final void Function(List<String> picked, String label) onPickMedications;
  final void Function(List<String> picked, String label) onPickAllergies;

  const _StepInput({
    required this.step,
    required this.draft,
    required this.onAnswer,
    required this.onSubmitDraft,
    required this.onComplete,
    required this.onSkip,
    required this.onOpenProductSheet,
    required this.onPickHighRiskPregLact,
    required this.onPickMedications,
    required this.onPickAllergies,
  });

  @override
  Widget build(BuildContext context) {
    final padding = const EdgeInsets.fromLTRB(16, 12, 16, 16);
    Widget child;
    switch (step) {
      case 1:
        child = _RelationshipPicker(
          onPicked: (r) {
            onSubmitDraft((d) {
              d.relationship = r;
              final implied = _impliedSex(r);
              if (implied != null) d.sex = implied;
            });
            onAnswer(r.label);
          },
        );
        break;
      case 2:
        child = _NameInput(
          presetName: _suggestedName(draft.relationship),
          onSubmit: (name) {
            onSubmitDraft((d) => d.name = name);
            onAnswer(name);
          },
        );
        break;
      case 3:
        child = _BirthYearInput(
          onSubmit: (year) async {
            onSubmitDraft((d) => d.birthYear = year);
            final age = DateTime.now().year - year;
            final answerText = '$year년생 (만 $age세)';
            // 만 14세 미만 자녀 등록 시 법정대리인 동의 필수
            // (개인정보 보호법 제22조의2)
            if (age < 14 && context.mounted) {
              final ok = await showDialog<bool>(
                context: context,
                barrierDismissible: false,
                builder: (dctx) => const _ConsentGateDialog(
                  title: '🧒 보호자 동의가 필요해요',
                  body: '「개인정보 보호법」 제22조의2에 따라 만 14세 미만 가족 '
                      '구성원의 개인정보는 법정대리인의 동의가 필요해요.',
                  checkLabel: '본인은 이 가족 구성원의 보호자(법정대리인)이며, '
                      '개인정보 처리에 동의합니다',
                ),
              );
              if (ok != true) return; // 거부 시 step 3 유지
            }
            onAnswer(answerText);
          },
        );
        break;
      case 4:
        child = _ChoiceRow(
          options: const [('남자', Sex.male), ('여자', Sex.female)],
          onPick: (label, value) {
            onSubmitDraft((d) => d.sex = value);
            onAnswer(label);
          },
        );
        break;
      case 5:
        child = _MinorGuardianCheckbox(
          onConfirm: () => onAnswer('확인 · 보호자 동의'),
        );
        break;
      case 6:
        child = _HeightWeightInput(
          onSubmit: (h, w) {
            onSubmitDraft((d) {
              d.heightCm = h;
              d.weightKg = w;
            });
            final parts = <String>[];
            if (h != null) parts.add('${h.toStringAsFixed(0)}cm');
            if (w != null) parts.add('${w.toStringAsFixed(0)}kg');
            onAnswer(parts.isEmpty ? '건너뛰기' : parts.join(' / '));
          },
        );
        break;
      case 7:
        child = _ChoiceRow(
          options: const [
            ('임신 중', _PregLact.pregnant),
            ('수유 중', _PregLact.lactating),
            ('임신 + 수유', _PregLact.both),
            ('해당 없음', _PregLact.none),
          ],
          onPick: (label, value) {
            onSubmitDraft((d) {
              d.isPregnant = value == _PregLact.pregnant ||
                  value == _PregLact.both;
              d.isBreastfeeding = value == _PregLact.lactating ||
                  value == _PregLact.both;
            });
            if (value == _PregLact.none) {
              onAnswer(label);
            } else {
              onPickHighRiskPregLact(label);
            }
          },
        );
        break;
      case 8:
        child = _BloodTypePicker(
          onPick: (bt) {
            onSubmitDraft((d) => d.bloodType = bt);
            onAnswer(bt ?? '모름');
          },
        );
        break;
      // step 9 (smoking) / step 10 (drinking) — 채팅 흐름에서 제거됨.
      // _shouldShow에서 false 반환하므로 도달하지 않습니다.
      case 11:
        child = _ChoiceRow(
          options: const [
            ('균형 잡혀요', DietQuality.good),
            ('부족해요 (편식·외식 잦음)', DietQuality.poor),
          ],
          onPick: (label, value) {
            onSubmitDraft((d) => d.dietQuality = value);
            onAnswer(label);
          },
        );
        break;
      // step 12 (sleep) / step 13 (stress) — 채팅 흐름에서 제거됨.
      // _shouldShow에서 false 반환하므로 도달하지 않습니다.
      case 14:
        child = _MultiSelect(
          options: const ['우유', '갑각류', '생선', '대두', '효모', '땅콩', '밀', '기타'],
          initial: draft.allergies,
          noneLabel: '없음',
          onSubmit: (picked) {
            onSubmitDraft((d) {
              d.allergies
                ..clear()
                ..addAll(picked);
            });
            final label = picked.isEmpty ? '없음' : picked.join(', ');
            onPickAllergies(picked, label);
          },
        );
        break;
      case 15:
        child = _MultiSelect(
          options: const [
            '혈압약', '당뇨약', '고지혈증약', '항응고제', '갑상선약', '기타',
          ],
          initial: draft.medications,
          noneLabel: '없음',
          onSubmit: (picked) {
            onSubmitDraft((d) {
              d.medications
                ..clear()
                ..addAll(picked);
            });
            final label = picked.isEmpty ? '없음' : picked.join(', ');
            onPickMedications(picked, label);
          },
        );
        break;
      case 16:
        child = Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => onAnswer('없음'),
                child: const Text('없음'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FilledButton(
                onPressed: onOpenProductSheet,
                child: const Text('영양제 등록하기'),
              ),
            ),
          ],
        );
        break;
      default:
        child = SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: onComplete,
            child: const Text('완료'),
          ),
        );
    }
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      padding: padding,
      child: SafeArea(top: false, child: child),
    );
  }
}

String _suggestedName(Relationship? r) {
  if (r == null) return '';
  switch (r) {
    case Relationship.self:
      return '본인';
    case Relationship.husband:
      return '남편';
    case Relationship.wife:
      return '아내';
    case Relationship.father:
      return '아빠';
    case Relationship.mother:
      return '엄마';
    default:
      return '';
  }
}

class _RelationshipPicker extends StatelessWidget {
  final void Function(Relationship) onPicked;
  const _RelationshipPicker({required this.onPicked});

  @override
  Widget build(BuildContext context) {
    const entries = [
      ('👤', '본인', Relationship.self),
      ('👨', '남편', Relationship.husband),
      ('👩', '아내', Relationship.wife),
      ('👦', '아들', Relationship.son),
      ('👧', '딸', Relationship.daughter),
      ('👴', '아빠', Relationship.father),
      ('👵', '엄마', Relationship.mother),
      ('🙂', '기타', Relationship.other),
    ];
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 4,
      childAspectRatio: 0.95,
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      children: [
        for (final e in entries)
          _RelationTile(
            emoji: e.$1,
            label: e.$2,
            onTap: () => onPicked(e.$3),
          ),
      ],
    );
  }
}

class _RelationTile extends StatelessWidget {
  final String emoji;
  final String label;
  final VoidCallback onTap;
  const _RelationTile({
    required this.emoji,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.r14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.r14),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.r14),
            border: Border.all(color: AppColors.hairline, width: 1.5),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 26)),
              const SizedBox(height: 4),
              Text(
                label,
                style: AppTypography.title.copyWith(fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Blood-type picker — 8 ABO+Rh combinations + "모름". Pure information,
/// not used by the recommender; surfaces only on the profile.
class _BloodTypePicker extends StatelessWidget {
  /// `null` payload = the user chose "모름 / 입력 안 함".
  final void Function(String? bloodType) onPick;
  const _BloodTypePicker({required this.onPick});

  static const _options = <String>['A+', 'A-', 'B+', 'B-', 'O+', 'O-', 'AB+', 'AB-'];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final bt in _options)
              _BloodTypeChip(label: bt, onTap: () => onPick(bt)),
          ],
        ),
        const SizedBox(height: 8),
        OutlinedButton(
          onPressed: () => onPick(null),
          child: const Text('모름 / 건너뛰기'),
        ),
      ],
    );
  }
}

class _BloodTypeChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _BloodTypeChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.r12),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.r12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.r12),
            border: Border.all(color: AppColors.hairline, width: 1.5),
          ),
          child: Text(
            label,
            style: AppTypography.title.copyWith(
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _NameInput extends StatefulWidget {
  final String presetName;
  final void Function(String) onSubmit;
  const _NameInput({required this.presetName, required this.onSubmit});

  @override
  State<_NameInput> createState() => _NameInputState();
}

class _NameInputState extends State<_NameInput> {
  late final TextEditingController _ctrl;
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.presetName);
    if (widget.presetName.isNotEmpty) {
      _ctrl.selection = TextSelection(
        baseOffset: 0,
        extentOffset: widget.presetName.length,
      );
    }
    // Bring up the soft keyboard as soon as this step is shown.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focus.requestFocus();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _ctrl,
            focusNode: _focus,
            autofocus: true,
            autocorrect: false,
            enableSuggestions: false,
            keyboardType: TextInputType.text,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(
              hintText: '이름을 입력해주세요',
              border: OutlineInputBorder(),
            ),
            onSubmitted: _submit,
          ),
        ),
        const SizedBox(width: 8),
        FilledButton(
          onPressed: () => _submit(_ctrl.text),
          child: const Text('다음'),
        ),
      ],
    );
  }

  void _submit(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return;
    widget.onSubmit(trimmed);
  }
}

class _BirthYearInput extends StatefulWidget {
  final void Function(int year) onSubmit;
  const _BirthYearInput({required this.onSubmit});

  @override
  State<_BirthYearInput> createState() => _BirthYearInputState();
}

class _BirthYearInputState extends State<_BirthYearInput> {
  final _ctrl = TextEditingController();
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focus.requestFocus();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now().year;
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _ctrl,
            focusNode: _focus,
            autofocus: true,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(4),
            ],
            decoration: InputDecoration(
              hintText: '출생년도 (예: 1990)',
              helperText: '올해는 $now년',
              border: const OutlineInputBorder(),
            ),
            onSubmitted: (_) => _submit(),
          ),
        ),
        const SizedBox(width: 8),
        FilledButton(onPressed: _submit, child: const Text('다음')),
      ],
    );
  }

  void _submit() {
    final year = int.tryParse(_ctrl.text);
    final now = DateTime.now().year;
    if (year == null || year < (now - 120) || year > now) return;
    widget.onSubmit(year);
  }
}

class _ChoiceRow<T> extends StatelessWidget {
  final List<(String, T)> options;
  final void Function(String label, T value) onPick;
  const _ChoiceRow({required this.options, required this.onPick});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final o in options)
          Material(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.r12),
            child: InkWell(
              borderRadius: BorderRadius.circular(AppRadius.r12),
              onTap: () => onPick(o.$1, o.$2),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.r12),
                  border: Border.all(color: AppColors.hairline, width: 1.5),
                ),
                child: Text(
                  o.$1,
                  style: AppTypography.title.copyWith(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _HeightWeightInput extends StatefulWidget {
  final void Function(double? heightCm, double? weightKg) onSubmit;
  const _HeightWeightInput({required this.onSubmit});

  @override
  State<_HeightWeightInput> createState() => _HeightWeightInputState();
}

class _HeightWeightInputState extends State<_HeightWeightInput> {
  final _h = TextEditingController();
  final _w = TextEditingController();

  @override
  void dispose() {
    _h.dispose();
    _w.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _h,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
            ],
            decoration: const InputDecoration(
              labelText: '키 cm',
              border: OutlineInputBorder(),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: TextField(
            controller: _w,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
            ],
            decoration: const InputDecoration(
              labelText: '몸무게 kg',
              border: OutlineInputBorder(),
            ),
          ),
        ),
        const SizedBox(width: 8),
        FilledButton(
          onPressed: () => widget.onSubmit(
            double.tryParse(_h.text),
            double.tryParse(_w.text),
          ),
          child: const Text('다음'),
        ),
      ],
    );
  }
}

class _MultiSelect extends StatefulWidget {
  final List<String> options;
  final List<String> initial;
  final String noneLabel;
  final void Function(List<String>) onSubmit;
  const _MultiSelect({
    required this.options,
    required this.initial,
    required this.noneLabel,
    required this.onSubmit,
  });

  @override
  State<_MultiSelect> createState() => _MultiSelectState();
}

class _MultiSelectState extends State<_MultiSelect> {
  late final Set<String> _selected = {...widget.initial};

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final opt in widget.options)
              FilterChip(
                label: Text(opt),
                selected: _selected.contains(opt),
                onSelected: (v) => setState(() {
                  v ? _selected.add(opt) : _selected.remove(opt);
                }),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => widget.onSubmit(const []),
                child: Text(widget.noneLabel),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FilledButton(
                onPressed: () => widget.onSubmit(_selected.toList()),
                child: const Text('다음'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

enum _PregLact { pregnant, lactating, both, none }

/// Inline product picker shown at the end of the family-add chat. Lets the
/// user search the curated 250-DB and pile up several products in one shot,
/// then apply them to `member.currentProductIds` when the family member is
/// finally saved. Pops with the picked id list (`null` = cancelled).
class _ProductPickerSheet extends ConsumerStatefulWidget {
  final List<String> initial;
  const _ProductPickerSheet({required this.initial});

  @override
  ConsumerState<_ProductPickerSheet> createState() =>
      _ProductPickerSheetState();
}

class _ProductPickerSheetState extends ConsumerState<_ProductPickerSheet> {
  final _searchCtrl = TextEditingController();
  String _query = '';
  late final List<String> _picked = [...widget.initial];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _confirmCancel() async {
    if (_picked.isEmpty) {
      Navigator.of(context).pop<List<String>>(<String>[]);
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (dctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.r20),
        ),
        title: const Text('취소하시겠어요?'),
        content: Text('선택한 영양제 ${_picked.length}개가 사라집니다'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dctx).pop(false),
            child: const Text('계속 추가'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            onPressed: () => Navigator.of(dctx).pop(true),
            child: const Text('취소'),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      Navigator.of(context).pop<List<String>>(<String>[]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(productRepositoryProvider);
    final results =
        _query.trim().isEmpty ? const <Product>[] : repo.search(_query);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _confirmCancel();
      },
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.85,
            child: Column(
              children: [
                _Header(onClose: _confirmCancel),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                  child: TextField(
                    controller: _searchCtrl,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: '영양제 이름이나 성분',
                      prefixIcon: const Icon(Icons.search,
                          size: 20, color: AppColors.muted),
                      border: const OutlineInputBorder(),
                    ),
                    onChanged: (v) => setState(() => _query = v),
                  ),
                ),
                Expanded(
                  child: _query.trim().isEmpty
                      ? const _SearchEmptyHint()
                      : ListView(
                          padding:
                              const EdgeInsets.fromLTRB(20, 4, 20, 12),
                          children: [
                            for (final p in results)
                              Padding(
                                padding:
                                    const EdgeInsets.only(bottom: 8),
                                child: _ResultRow(
                                  product: p,
                                  picked: _picked.contains(p.id),
                                  onAdd: () => setState(
                                      () => _picked.add(p.id)),
                                  onRemove: () => setState(
                                      () => _picked.remove(p.id)),
                                ),
                              ),
                            if (results.isEmpty)
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 24),
                                child: Text(
                                  '검색 결과가 없어요',
                                  style: AppTypography.body2,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                          ],
                        ),
                ),
                if (_picked.isNotEmpty) _PickedSummary(
                  ids: _picked,
                  repo: repo,
                  onRemove: (id) => setState(() => _picked.remove(id)),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  child: PrimaryButton(
                    label: _picked.isEmpty
                        ? '없이 계속하기'
                        : '${_picked.length}개 등록 완료',
                    full: true,
                    onPressed: () =>
                        Navigator.of(context).pop<List<String>>(_picked),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final VoidCallback onClose;
  const _Header({required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 8, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '드시는 영양제 추가',
              style: AppTypography.heading2.copyWith(fontSize: 17),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 22),
            onPressed: onClose,
            tooltip: '닫기',
          ),
        ],
      ),
    );
  }
}

class _SearchEmptyHint extends StatelessWidget {
  const _SearchEmptyHint();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('💊', style: TextStyle(fontSize: 36)),
            const SizedBox(height: 8),
            Text(
              '제품명, 성분, 브랜드로 검색해보세요',
              style: AppTypography.caption.copyWith(fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  final Product product;
  final bool picked;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  const _ResultRow({
    required this.product,
    required this.picked,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return AlyakCard(
      padding: const EdgeInsets.all(12),
      onTap: picked ? onRemove : onAdd,
      child: Row(
        children: [
          ProductImage(product: product, size: 56),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  product.name,
                  style: AppTypography.title.copyWith(fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      product.scheduleLabel,
                      style: AppTypography.caption.copyWith(
                        fontSize: 12,
                        color: AppColors.ink2,
                      ),
                    ),
                    IntakeTimingBadge(timing: product.intakeTiming),
                  ],
                ),
              ],
            ),
          ),
          Icon(
            picked ? Icons.check_circle : Icons.add_circle_outline,
            color: picked ? AppColors.primary : AppColors.faint,
            size: 24,
          ),
        ],
      ),
    );
  }
}

class _PickedSummary extends StatelessWidget {
  final List<String> ids;
  final ProductRepository repo;
  final ValueChanged<String> onRemove;

  const _PickedSummary({
    required this.ids,
    required this.repo,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      decoration: const BoxDecoration(
        color: AppColors.surfaceMuted,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '추가된 영양제 ${ids.length}개',
            style: AppTypography.title.copyWith(
              fontSize: 13,
              color: AppColors.muted,
            ),
          ),
          const SizedBox(height: 6),
          for (final id in ids)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '· ${repo.getById(id)?.name ?? id}',
                      style: AppTypography.body2.copyWith(fontSize: 13),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline,
                        size: 18, color: AppColors.muted),
                    onPressed: () => onRemove(id),
                    tooltip: '삭제',
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// step 5 어린이 영양제 면책 — 보호자 동의 체크박스 + 다음 버튼.
/// 만 14세 미만 등록 시 노출됨.
class _MinorGuardianCheckbox extends StatefulWidget {
  final VoidCallback onConfirm;
  const _MinorGuardianCheckbox({required this.onConfirm});

  @override
  State<_MinorGuardianCheckbox> createState() =>
      _MinorGuardianCheckboxState();
}

class _MinorGuardianCheckboxState extends State<_MinorGuardianCheckbox> {
  bool _checked = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: () => setState(() => _checked = !_checked),
          borderRadius: BorderRadius.circular(AppRadius.r12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
            child: Row(
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: Checkbox(
                    value: _checked,
                    onChanged: (v) => setState(() => _checked = v ?? false),
                    activeColor: AppColors.primary,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                    side:
                        const BorderSide(color: AppColors.hairline, width: 1.5),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '보호자로서 위 내용을 확인했고, 영양제 복용은 전문가와 '
                    '상담 후 결정하겠습니다 (필수)',
                    style: AppTypography.body2.copyWith(fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: _checked ? widget.onConfirm : null,
            child: const Text('다음'),
          ),
        ),
      ],
    );
  }
}

/// 임신/수유, 약물 등 고위험군 진입 시 띄우는 동의 모달.
/// `Navigator.pop(true)` = 동의, `Navigator.pop(false)` = 취소(step 유지).
class _ConsentGateDialog extends StatefulWidget {
  final String title;
  final String body;
  final String checkLabel;

  const _ConsentGateDialog({
    required this.title,
    required this.body,
    required this.checkLabel,
  });

  @override
  State<_ConsentGateDialog> createState() => _ConsentGateDialogState();
}

class _ConsentGateDialogState extends State<_ConsentGateDialog> {
  bool _checked = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.r20),
      ),
      title: Text(widget.title),
      content: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.55,
          maxWidth: 360,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.body,
                style: AppTypography.body2.copyWith(fontSize: 13.5, height: 1.55),
              ),
              const SizedBox(height: 14),
              InkWell(
                onTap: () => setState(() => _checked = !_checked),
                borderRadius: BorderRadius.circular(AppRadius.r12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 22,
                        height: 22,
                        child: Checkbox(
                          value: _checked,
                          onChanged: (v) =>
                              setState(() => _checked = v ?? false),
                          activeColor: AppColors.primary,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                          side: const BorderSide(
                              color: AppColors.hairline, width: 1.5),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          widget.checkLabel,
                          style: AppTypography.body2.copyWith(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('취소'),
        ),
        FilledButton(
          onPressed: _checked ? () => Navigator.of(context).pop(true) : null,
          child: const Text('확인'),
        ),
      ],
    );
  }
}
