import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/security/secure_storage.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/alyak_card.dart';
import '../../../core/widgets/chat_bubbles.dart';

const String kConsentMetaKey = 'alyak.privacyConsent.meta';

class PrivacyConsentScreen extends ConsumerStatefulWidget {
  const PrivacyConsentScreen({super.key});

  @override
  ConsumerState<PrivacyConsentScreen> createState() =>
      _PrivacyConsentScreenState();
}

class _PrivacyConsentScreenState extends ConsumerState<PrivacyConsentScreen> {
  bool _consentChecked = false;
  bool _sensitiveChecked = false;
  bool _ageChecked = false;
  bool _saving = false;

  bool get _canProceed =>
      _consentChecked && _sensitiveChecked && _ageChecked && !_saving;

  Future<void> _onProceed() async {
    if (!_canProceed) return;
    setState(() => _saving = true);
    await SecureStorage.write(SecureKeys.privacyConsent, '1');
    await SecureStorage.write(
      kConsentMetaKey,
      jsonEncode({
        'consented': true,
        'consentedAt': DateTime.now().toIso8601String(),
        'version': '1.1',
        'ageAcknowledged': true,
        'sensitiveDataConsent': true,
      }),
    );
    if (!mounted) return;
    context.go('/onboarding/welcome');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const AlyakBrandMark(size: 28),
                  const SizedBox(width: 10),
                  Text(
                    '알약',
                    style: AppTypography.heading2.copyWith(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    Text(
                      '시작하기 전에\n한 가지만 알려드릴게요',
                      style: AppTypography.heading1.copyWith(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text.rich(
                      TextSpan(
                        style: AppTypography.body1.copyWith(
                          fontSize: 14,
                          color: AppColors.muted,
                          height: 1.55,
                        ),
                        children: [
                          const TextSpan(text: '가족 정보는 '),
                          TextSpan(
                            text: '이 폰에만 ',
                            style: AppTypography.body1.copyWith(
                              fontSize: 14,
                              color: AppColors.ink2,
                              fontWeight: FontWeight.w700,
                              height: 1.55,
                            ),
                          ),
                          const TextSpan(text: '저장돼요.\n서버로 보내지 않아요.'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    const _PromiseCard(
                        emoji: '🔒',
                        title: '내 폰에만 저장',
                        sub: '가족 정보, 영양제, 모든 기록'),
                    const SizedBox(height: 10),
                    const _PromiseCard(
                        emoji: '🚫',
                        title: '광고 없음',
                        sub: '제휴 / 추천 / 자사몰 없어요'),
                    const SizedBox(height: 10),
                    const _PromiseCard(
                        emoji: '🩺',
                        title: '의료 행위 아님',
                        sub: '의사·약사 진단을 대체하지 않아요'),
                    const SizedBox(height: 18),
                    _ConsentCheckbox(
                      key: const Key('consent-checkbox'),
                      value: _consentChecked,
                      label: '위 내용에 동의합니다 (필수)',
                      onChanged: (v) =>
                          setState(() => _consentChecked = v),
                    ),
                    const SizedBox(height: 6),
                    _ConsentCheckbox(
                      key: const Key('sensitive-checkbox'),
                      value: _sensitiveChecked,
                      label: '건강정보(임신/수유, 만성질환, 복약, 알레르기, '
                          '혈액형, 검진결과) 수집·이용에 동의합니다 (필수)',
                      onChanged: (v) =>
                          setState(() => _sensitiveChecked = v),
                    ),
                    const SizedBox(height: 6),
                    _ConsentCheckbox(
                      key: const Key('age-checkbox'),
                      value: _ageChecked,
                      label: '만 14세 이상입니다 (필수)',
                      onChanged: (v) => setState(() => _ageChecked = v),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton(
                  key: const Key('proceed-button'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    disabledBackgroundColor: AppColors.ghost,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppRadius.r14),
                    ),
                    textStyle: const TextStyle(
                      fontFamily: AppTypography.family,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  onPressed: _canProceed ? _onProceed : null,
                  child: const Text('네, 시작할게요'),
                ),
              ),
              Center(
                child: TextButton(
                  onPressed: () => context.push('/privacy-policy'),
                  child: Text(
                    '자세히 보기',
                    style: AppTypography.title.copyWith(
                      fontSize: 14,
                      color: AppColors.muted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PromiseCard extends StatelessWidget {
  final String emoji;
  final String title;
  final String sub;
  const _PromiseCard({
    required this.emoji,
    required this.title,
    required this.sub,
  });

  @override
  Widget build(BuildContext context) {
    return AlyakCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(AppRadius.r10),
            ),
            child: Text(emoji, style: const TextStyle(fontSize: 18)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: AppTypography.title.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 1),
                Text(sub, style: AppTypography.caption.copyWith(fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ConsentCheckbox extends StatelessWidget {
  final bool value;
  final String label;
  final ValueChanged<bool> onChanged;
  const _ConsentCheckbox({
    super.key,
    required this.value,
    required this.label,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(AppRadius.r12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
        child: Row(
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: Checkbox(
                value: value,
                onChanged: (v) => onChanged(v ?? false),
                activeColor: AppColors.primary,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                side: const BorderSide(color: AppColors.hairline, width: 1.5),
              ),
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
