import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../family/models/family_member.dart';
import '../../family/providers/family_provider.dart';
import '../widgets/chat_message.dart';

/// Toss-style 16-step chat to register a new family member.
class FamilyAddScreen extends ConsumerStatefulWidget {
  /// Optional preset relationship (e.g. when entering from the welcome
  /// screen's "나부터 등록하기" CTA we skip step 1).
  final Relationship? presetRelationship;
  const FamilyAddScreen({super.key, this.presetRelationship});

  @override
  ConsumerState<FamilyAddScreen> createState() => _FamilyAddScreenState();
}

class _FamilyAddScreenState extends ConsumerState<FamilyAddScreen> {
  final _scrollCtrl = ScrollController();
  final _draft = _Draft();
  int _step = 1;
  static const int _totalSteps = 16;

  @override
  void initState() {
    super.initState();
    final preset = widget.presetRelationship;
    if (preset != null) {
      _draft.relationship = preset;
      if (preset == Relationship.husband ||
          preset == Relationship.father ||
          preset == Relationship.son) {
        _draft.sex = Sex.male;
      } else if (preset == Relationship.wife ||
          preset == Relationship.mother ||
          preset == Relationship.daughter) {
        _draft.sex = Sex.female;
      }
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

  void _next({String? answer}) {
    if (answer != null) _draft.answers.add(_AnsweredEntry(_step, answer));
    setState(() => _step = _step + 1);
    _scrollToEnd();
  }

  void _back() {
    if (_step <= 1) {
      context.pop();
      return;
    }
    setState(() {
      _step = _step - 1;
      _draft.answers.removeWhere((a) => a.step >= _step);
    });
  }

  bool get _isAdult => _draft.age >= 19;
  bool get _isAdultWoman => _isAdult && _draft.sex == Sex.female;

  /// Skip steps that don't apply (e.g. pregnancy for males or kids).
  void _autoAdvanceIfNeeded() {
    if (_step == 6 && !_isAdultWoman) {
      _draft.isPregnant = false;
      _draft.isBreastfeeding = false;
      _next();
      return;
    }
    if (_step == 7 && !_isAdult) {
      _draft.smokingStatus = SmokingStatus.never;
      _next();
      return;
    }
    if (_step == 8 && !_isAdult) {
      _draft.drinkingFrequency = DrinkingFrequency.never;
      _next();
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _autoAdvanceIfNeeded();
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _back,
        ),
        title: Text(
          '$_step / $_totalSteps',
          style: AppTypography.body2,
        ),
        centerTitle: true,
        actions: [
          if (_step < _totalSteps)
            TextButton(
              onPressed: () => _next(answer: null),
              child: const Text('건너뛰기'),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              controller: _scrollCtrl,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
            onAutoSkipNeeded: _autoAdvanceIfNeeded,
          ),
        ],
      ),
    );
  }

  List<Widget> _renderHistory() {
    final widgets = <Widget>[];
    for (var i = 1; i <= _step; i++) {
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
        return '${_draft.name}님의 나이를 알려주세요';
      case 4:
        return '성별이 어떻게 되세요?';
      case 5:
        return '키와 몸무게를 알려주세요 (선택)';
      case 6:
        return '혹시 임신 또는 수유 중이신가요?';
      case 7:
        return '흡연하시나요?';
      case 8:
        return '음주는 어떠세요?';
      case 9:
        return '평소 식단은 어떠신가요?';
      case 10:
        return '보통 몇 시간 주무세요?';
      case 11:
        return '스트레스 정도는?';
      case 12:
        return '알레르기 있으시나요? (선택)';
      case 13:
        return '현재 복용 중인 약이 있나요? (선택)';
      case 14:
        return '최근 받으신 검진 결과 입력하시겠어요? (선택)';
      case 15:
        return '현재 드시는 영양제가 있나요? (선택)';
      default:
        return '${_draft.name}님 등록 완료! 🎉';
    }
  }

  Future<void> _save() async {
    if (_draft.relationship == null || _draft.name.isEmpty || _draft.age <= 0) {
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
      age: _draft.age,
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
      createdAt: now,
      updatedAt: now,
    );
    final controller = ref.read(familyControllerProvider);
    final wasFirst = controller.members.isEmpty;
    await controller.addMember(member);
    if (!mounted) return;
    if (wasFirst) {
      // First-ever member onboarding -> wire notification preferences next.
      context.go('/onboarding/notification');
    } else if (GoRouter.of(context).canPop()) {
      context.pop();
    } else {
      context.go('/home');
    }
  }
}

class _Draft {
  Relationship? relationship;
  String name = '';
  int age = 0;
  Sex sex = Sex.male;
  double? heightCm;
  double? weightKg;
  bool isPregnant = false;
  bool isBreastfeeding = false;
  SmokingStatus smokingStatus = SmokingStatus.never;
  DrinkingFrequency drinkingFrequency = DrinkingFrequency.never;
  DietQuality dietQuality = DietQuality.average;
  SleepHours sleepHours = SleepHours.sevenToNine;
  StressLevel stressLevel = StressLevel.low;
  final List<String> allergies = [];
  final List<String> medications = [];
  final List<_AnsweredEntry> answers = [];

  void set(void Function(_Draft) f) => f(this);
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
  final VoidCallback onAutoSkipNeeded;

  const _StepInput({
    required this.step,
    required this.draft,
    required this.onAnswer,
    required this.onSubmitDraft,
    required this.onComplete,
    required this.onSkip,
    required this.onAutoSkipNeeded,
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
              if (r == Relationship.husband ||
                  r == Relationship.father ||
                  r == Relationship.son) {
                d.sex = Sex.male;
              }
              if (r == Relationship.wife ||
                  r == Relationship.mother ||
                  r == Relationship.daughter) {
                d.sex = Sex.female;
              }
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
        child = _AgeInput(onSubmit: (age) {
          onSubmitDraft((d) => d.age = age);
          onAnswer('$age세');
        });
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
      case 6:
        child = _ChoiceRow(
          options: const [
            ('임신 중', _PregState.pregnant),
            ('수유 중', _PregState.breastfeeding),
            ('해당 없음', _PregState.none),
          ],
          onPick: (label, value) {
            onSubmitDraft((d) {
              d.isPregnant = value == _PregState.pregnant;
              d.isBreastfeeding = value == _PregState.breastfeeding;
            });
            onAnswer(label);
          },
        );
        break;
      case 7:
        child = _ChoiceRow(
          options: const [
            ('안 함', SmokingStatus.never),
            ('끊었어요', SmokingStatus.former),
            ('현재 흡연', SmokingStatus.current),
          ],
          onPick: (label, value) {
            onSubmitDraft((d) => d.smokingStatus = value);
            onAnswer(label);
          },
        );
        break;
      case 8:
        child = _ChoiceRow(
          options: const [
            ('안 함', DrinkingFrequency.never),
            ('주 1-2회', DrinkingFrequency.weekly),
            ('거의 매일', DrinkingFrequency.daily),
          ],
          onPick: (label, value) {
            onSubmitDraft((d) => d.drinkingFrequency = value);
            onAnswer(label);
          },
        );
        break;
      case 9:
        child = _ChoiceRow(
          options: const [
            ('좋음 (균형)', DietQuality.good),
            ('보통', DietQuality.average),
            ('부족함', DietQuality.poor),
          ],
          onPick: (label, value) {
            onSubmitDraft((d) => d.dietQuality = value);
            onAnswer(label);
          },
        );
        break;
      case 10:
        child = _ChoiceRow(
          options: const [
            ('5h 미만', SleepHours.less5),
            ('5–7h', SleepHours.fiveToSeven),
            ('7–9h', SleepHours.sevenToNine),
            ('9h+', SleepHours.more9),
          ],
          onPick: (label, value) {
            onSubmitDraft((d) => d.sleepHours = value);
            onAnswer(label);
          },
        );
        break;
      case 11:
        child = _ChoiceRow(
          options: const [
            ('낮음', StressLevel.low),
            ('보통', StressLevel.medium),
            ('높음', StressLevel.high),
          ],
          onPick: (label, value) {
            onSubmitDraft((d) => d.stressLevel = value);
            onAnswer(label);
          },
        );
        break;
      case 12:
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
            onAnswer(picked.isEmpty ? '없음' : picked.join(', '));
          },
        );
        break;
      case 13:
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
            onAnswer(picked.isEmpty ? '없음' : picked.join(', '));
          },
        );
        break;
      case 14:
      case 15:
        child = Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: onSkip,
                child: const Text('건너뛰기'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FilledButton(
                onPressed: () => onAnswer(step == 14 ? '입력하기' : '추가하기'),
                child: Text(step == 14 ? '검진 입력' : '영양제 추가'),
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
      color: AppColors.surface,
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
      ('👤 본인', Relationship.self),
      ('👨 남편', Relationship.husband),
      ('👩 아내', Relationship.wife),
      ('👦 아들', Relationship.son),
      ('👧 딸', Relationship.daughter),
      ('👴 아빠', Relationship.father),
      ('👵 엄마', Relationship.mother),
      ('👤 기타', Relationship.other),
    ];
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 4,
      childAspectRatio: 1.4,
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      children: [
        for (final e in entries)
          OutlinedButton(
            onPressed: () => onPicked(e.$2),
            child: Text(e.$1, textAlign: TextAlign.center),
          ),
      ],
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

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.presetName);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _ctrl,
            decoration: const InputDecoration(
              hintText: '이름',
              border: OutlineInputBorder(),
            ),
            onSubmitted: (v) => _submit(v),
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

class _AgeInput extends StatefulWidget {
  final void Function(int) onSubmit;
  const _AgeInput({required this.onSubmit});

  @override
  State<_AgeInput> createState() => _AgeInputState();
}

class _AgeInputState extends State<_AgeInput> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _ctrl,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
              hintText: '나이 (0–120)',
              border: OutlineInputBorder(),
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
    final age = int.tryParse(_ctrl.text);
    if (age == null || age < 0 || age > 120) return;
    widget.onSubmit(age);
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
          OutlinedButton(
            onPressed: () => onPick(o.$1, o.$2),
            child: Text(o.$1),
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
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
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

enum _PregState { pregnant, breastfeeding, none }
