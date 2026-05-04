import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/notifications/notification_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../onboarding/widgets/chat_message.dart';
import '../models/family_member.dart';
import '../providers/family_provider.dart';

class HealthCheckupInputScreen extends ConsumerStatefulWidget {
  final String memberId;
  const HealthCheckupInputScreen({super.key, required this.memberId});

  @override
  ConsumerState<HealthCheckupInputScreen> createState() =>
      _HealthCheckupInputScreenState();
}

class _HealthCheckupInputScreenState
    extends ConsumerState<HealthCheckupInputScreen> {
  final _scroll = ScrollController();
  final _draft = _CheckupDraft();
  int _step = 1;
  static const int _totalSteps = 14;

  void _next({String? answer}) {
    if (answer != null) _draft.answers.add((_step, answer));
    setState(() => _step += 1);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _back() {
    if (_step <= 1) {
      context.pop();
      return;
    }
    setState(() {
      _step -= 1;
      _draft.answers.removeWhere((a) => a.$1 >= _step);
    });
  }

  Future<void> _save() async {
    final member = ref.read(familyControllerProvider).getMember(widget.memberId);
    if (member == null) {
      context.pop();
      return;
    }
    final checkup = HealthCheckup(
      checkupDate: _draft.date ?? DateTime.now(),
      totalCholesterol: _draft.totalCholesterol,
      ldl: _draft.ldl,
      hdl: _draft.hdl,
      triglycerides: _draft.triglycerides,
      fastingGlucose: _draft.fastingGlucose,
      hba1c: _draft.hba1c,
      hemoglobin: _draft.hemoglobin,
      alt: _draft.alt,
      ast: _draft.ast,
      vitaminD: _draft.vitaminD,
      systolicBp: _draft.systolicBp,
      diastolicBp: _draft.diastolicBp,
    );
    await ref
        .read(familyControllerProvider)
        .updateMember(member.copyWith(lastCheckup: checkup));
    await ref.read(notificationServiceProvider).scheduleCheckupReminder(
          memberId: widget.memberId,
          checkupDate: checkup.checkupDate,
        );
    if (!mounted) return;
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _back,
        ),
        title: Text('$_step / $_totalSteps', style: AppTypography.body2),
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
              controller: _scroll,
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              children: [
                for (var i = 1; i <= _step; i++) ..._messagesFor(i),
              ],
            ),
          ),
          _buildInput(),
        ],
      ),
    );
  }

  List<Widget> _messagesFor(int i) {
    final widgets = <Widget>[];
    if (i <= _stepSpecs.length) {
      final spec = _stepSpecs[i - 1];
      widgets.add(ChatMessage(text: spec.prompt, fromUser: false));
      if (spec.hint != null) {
        widgets.add(ChatMessage(text: spec.hint!, fromUser: false));
      }
    } else {
      widgets.add(const ChatMessage(text: '검진 정보 저장 완료!', fromUser: false));
    }
    for (final a in _draft.answers.where((a) => a.$1 == i)) {
      widgets.add(ChatMessage(text: a.$2, fromUser: true));
    }
    return widgets;
  }

  Widget _buildInput() {
    Widget child;
    if (_step == 1) {
      child = _DateInput(
        onPicked: (d) {
          _draft.date = d;
          _next(answer: DateFormat('yyyy.MM.dd').format(d));
        },
      );
    } else if (_step >= 2 && _step <= 13) {
      final spec = _stepSpecs[_step - 1];
      child = _NumberInput(
        suffix: spec.unit,
        onSubmit: (v) {
          spec.assign(_draft, v);
          _next(answer: v == null ? '건너뛰기' : '$v ${spec.unit ?? ''}');
        },
      );
    } else {
      child = SizedBox(
        width: double.infinity,
        child: FilledButton(onPressed: _save, child: const Text('저장')),
      );
    }
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: SafeArea(top: false, child: child),
    );
  }
}

class _DateInput extends StatelessWidget {
  final void Function(DateTime) onPicked;
  const _DateInput({required this.onPicked});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        icon: const Icon(Icons.calendar_today),
        label: const Text('검진 날짜 선택'),
        onPressed: () async {
          final now = DateTime.now();
          final picked = await showDatePicker(
            context: context,
            initialDate: now,
            firstDate: DateTime(now.year - 5),
            lastDate: now,
          );
          if (picked != null) onPicked(picked);
        },
      ),
    );
  }
}

class _NumberInput extends StatefulWidget {
  final String? suffix;
  final void Function(double? value) onSubmit;
  const _NumberInput({this.suffix, required this.onSubmit});

  @override
  State<_NumberInput> createState() => _NumberInputState();
}

class _NumberInputState extends State<_NumberInput> {
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
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
            ],
            decoration: InputDecoration(
              hintText: widget.suffix == null ? '값' : '값 ${widget.suffix}',
              border: const OutlineInputBorder(),
            ),
          ),
        ),
        const SizedBox(width: 8),
        OutlinedButton(
          onPressed: () => widget.onSubmit(null),
          child: const Text('건너뛰기'),
        ),
        const SizedBox(width: 8),
        FilledButton(
          onPressed: () => widget.onSubmit(double.tryParse(_ctrl.text)),
          child: const Text('다음'),
        ),
      ],
    );
  }
}

typedef _Assign = void Function(_CheckupDraft d, double? v);

class _StepSpec {
  final String prompt;
  final String? hint;
  final String? unit;
  final _Assign assign;
  const _StepSpec(this.prompt, this.hint, this.unit, this.assign);
}

class _CheckupDraft {
  DateTime? date;
  double? totalCholesterol;
  double? ldl;
  double? hdl;
  double? triglycerides;
  double? fastingGlucose;
  double? hba1c;
  double? hemoglobin;
  double? alt;
  double? ast;
  double? vitaminD;
  int? systolicBp;
  int? diastolicBp;
  final List<(int, String)> answers = [];
}

final List<_StepSpec> _stepSpecs = [
  const _StepSpec('언제 검진받으셨어요?', null, null, _noop),
  _StepSpec('총 콜레스테롤을 알려주세요', '정상 < 200 mg/dL', 'mg/dL',
      (d, v) => d.totalCholesterol = v),
  _StepSpec('LDL 콜레스테롤은요?', '정상 < 130 mg/dL', 'mg/dL',
      (d, v) => d.ldl = v),
  _StepSpec('HDL 콜레스테롤은요?', '남 ≥ 40, 여 ≥ 50', 'mg/dL',
      (d, v) => d.hdl = v),
  _StepSpec('중성지방은요?', '정상 < 150 mg/dL', 'mg/dL',
      (d, v) => d.triglycerides = v),
  _StepSpec('공복 혈당은요?', '정상 < 100 mg/dL', 'mg/dL',
      (d, v) => d.fastingGlucose = v),
  _StepSpec('당화혈색소(HbA1c)는요?', '정상 < 5.7%', '%',
      (d, v) => d.hba1c = v),
  _StepSpec('헤모글로빈은요?', '남 ≥ 13, 여 ≥ 12 g/dL', 'g/dL',
      (d, v) => d.hemoglobin = v),
  _StepSpec('ALT는요?', '정상 ≤ 40 U/L', 'U/L',
      (d, v) => d.alt = v),
  _StepSpec('AST는요?', '정상 ≤ 40 U/L', 'U/L',
      (d, v) => d.ast = v),
  _StepSpec('비타민 D는요?', '정상 ≥ 30 ng/mL', 'ng/mL',
      (d, v) => d.vitaminD = v),
  _StepSpec('수축기 혈압은요?', '정상 < 130 mmHg', 'mmHg',
      (d, v) => d.systolicBp = v?.toInt()),
  _StepSpec('이완기 혈압은요?', '정상 < 85 mmHg', 'mmHg',
      (d, v) => d.diastolicBp = v?.toInt()),
];

void _noop(_CheckupDraft d, double? v) {}
