import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/security/secure_storage.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

const String kConsentMetaKey = 'alyak.privacyConsent.meta';
const Color kPrimaryActionColor = Color(0xFF3182F6);

class PrivacyConsentScreen extends ConsumerStatefulWidget {
  const PrivacyConsentScreen({super.key});

  @override
  ConsumerState<PrivacyConsentScreen> createState() =>
      _PrivacyConsentScreenState();
}

class _PrivacyConsentScreenState extends ConsumerState<PrivacyConsentScreen> {
  bool _consentChecked = false;
  bool _ageChecked = false;
  bool _saving = false;

  bool get _canProceed => _consentChecked && _ageChecked && !_saving;

  Future<void> _onProceed() async {
    if (!_canProceed) return;
    setState(() => _saving = true);
    // Boot logic already keys off this exact value, so keep it as '1'.
    await SecureStorage.write(SecureKeys.privacyConsent, '1');
    await SecureStorage.write(
      kConsentMetaKey,
      jsonEncode({
        'consented': true,
        'consentedAt': DateTime.now().toIso8601String(),
        'version': '1.0',
        'ageAcknowledged': true,
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
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
          children: [
            const SizedBox(height: 24),
            Center(
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(
                  child: Text('💊', style: TextStyle(fontSize: 32)),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(AppStrings.appName,
                textAlign: TextAlign.center,
                style: AppTypography.heading1.copyWith(fontSize: 28)),
            const SizedBox(height: 4),
            Text(AppStrings.appNameSubtitle,
                textAlign: TextAlign.center, style: AppTypography.body2),
            const SizedBox(height: 32),
            Text('시작하기 전에 알려드려요',
                style: AppTypography.heading3.copyWith(fontSize: 18)),
            const SizedBox(height: 16),
            const _Section(
              icon: '📋',
              title: '수집하는 정보',
              items: [
                '가족 정보 (이름, 나이, 성별)',
                '건강 정보 (검진 결과, 알레르기)',
                '복용 영양제 정보',
              ],
            ),
            const _Section(
              icon: '🎯',
              title: '사용 목적',
              items: ['영양제 추천', '부족 영양소 분석', '복용 알림'],
            ),
            const _Section(
              icon: '🔒',
              title: '안전한 보관',
              items: [
                '모든 데이터는 본인 폰에만 저장',
                'AES-256 암호화',
                '외부 서버 전송 없음',
              ],
            ),
            const _Section(
              icon: '🗑️',
              title: '언제든 삭제 가능',
              items: ['설정에서 모든 데이터 즉시 삭제'],
            ),
            const SizedBox(height: 8),
            CheckboxListTile(
              key: const Key('consent-checkbox'),
              value: _consentChecked,
              onChanged: (v) => setState(() => _consentChecked = v ?? false),
              title: const Text('위 내용에 동의합니다 (필수)'),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
            CheckboxListTile(
              key: const Key('age-checkbox'),
              value: _ageChecked,
              onChanged: (v) => setState(() => _ageChecked = v ?? false),
              title: const Text('만 14세 이상입니다 (필수)'),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                key: const Key('proceed-button'),
                style: FilledButton.styleFrom(
                  backgroundColor: kPrimaryActionColor,
                  disabledBackgroundColor:
                      kPrimaryActionColor.withValues(alpha: 0.3),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _canProceed ? _onProceed : null,
                child: const Text('동의하고 시작하기',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: TextButton(
                onPressed: () => context.push('/privacy-policy'),
                child: const Text('개인정보 처리방침 전문 보기 →'),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String icon;
  final String title;
  final List<String> items;
  const _Section({
    required this.icon,
    required this.title,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$icon $title',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              )),
          const SizedBox(height: 6),
          for (final item in items)
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 2),
              child: Text('• $item', style: AppTypography.body2),
            ),
        ],
      ),
    );
  }
}
