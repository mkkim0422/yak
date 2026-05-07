import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/security/secure_storage.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/alyak_buttons.dart';

/// First-run onboarding tour. 4 slides explaining the app's value
/// proposition (가족 단위 / 검증 데이터 / 알림 적음 / 시작하기). Shown only
/// once per install — gated by `SecureKeys.onboardingComplete` in the boot
/// router. Re-entry is possible from Settings → "온보딩 다시 보기".
class OnboardingScreen extends StatefulWidget {
  /// When true (Settings re-entry), [_finish] pops the route instead of
  /// navigating to /boot — the user came from inside the app and expects
  /// to return to where they left off.
  final bool fromSettings;

  const OnboardingScreen({super.key, this.fromSettings = false});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _ctrl = PageController();
  int _page = 0;

  static const _slides = <_Slide>[
    _Slide(
      emoji: '👨‍👩‍👧‍👦',
      accentColor: AppColors.primarySoft,
      title: '우리 가족 영양제,\n한 번에 관리해요',
      body: '엄마, 아빠, 아이, 조부모까지\n각자에게 맞는 영양제를 찾아드려요.',
    ),
    _Slide(
      emoji: '💊',
      accentColor: AppColors.okBg,
      title: '검증된 250개 영양제',
      body: '라벨 검증된 영양제 정보로\n내 가족에게 맞는 영양소를 추천해요.',
    ),
    _Slide(
      emoji: '🔔',
      accentColor: AppColors.warnBg,
      title: '결정 시점에만\n도와드려요',
      body: '매일 알림 X, 트래킹 X.\n필요할 때만 가족 영양제를 챙기세요.',
    ),
    _Slide(
      emoji: '✨',
      accentColor: AppColors.primarySoft,
      title: '지금 시작해보세요',
      body: '가족을 추가하면\n영양제 추천을 받을 수 있어요.',
      ctaLabel: '시작하기',
    ),
  ];

  bool get _isLast => _page == _slides.length - 1;

  Future<void> _finish() async {
    await SecureStorage.write(SecureKeys.onboardingComplete, '1');
    if (!mounted) return;
    if (widget.fromSettings) {
      context.pop();
    } else {
      context.go('/boot');
    }
  }

  void _next() {
    if (_isLast) {
      _finish();
      return;
    }
    _ctrl.nextPage(
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar — skip on first 3 slides only.
            SizedBox(
              height: 48,
              child: Row(
                children: [
                  const SizedBox(width: 8),
                  if (widget.fromSettings)
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                      onPressed: () => context.pop(),
                    )
                  else
                    const SizedBox(width: 40),
                  const Spacer(),
                  if (!_isLast)
                    Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: TextButton(
                        onPressed: _finish,
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.muted,
                          textStyle: AppTypography.title.copyWith(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        child: const Text('건너뛰기'),
                      ),
                    ),
                ],
              ),
            ),
            // Slides — PageView swipe + button.
            Expanded(
              child: PageView.builder(
                controller: _ctrl,
                onPageChanged: (i) => setState(() => _page = i),
                itemCount: _slides.length,
                itemBuilder: (_, i) => _SlideView(slide: _slides[i]),
              ),
            ),
            _Indicator(count: _slides.length, current: _page),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: PrimaryButton(
                label: _isLast
                    ? (_slides.last.ctaLabel ?? '시작하기')
                    : '다음',
                full: true,
                onPressed: _next,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Slide {
  final String emoji;
  final Color accentColor;
  final String title;
  final String body;
  final String? ctaLabel;
  const _Slide({
    required this.emoji,
    required this.accentColor,
    required this.title,
    required this.body,
    this.ctaLabel,
  });
}

class _SlideView extends StatelessWidget {
  final _Slide slide;
  const _SlideView({required this.slide});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Hero illustration — emoji in a tinted soft circle. No SVG asset
          // dependency: design tokens carry the visual weight.
          Container(
            width: 180,
            height: 180,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: slide.accentColor,
              shape: BoxShape.circle,
            ),
            child: Text(slide.emoji, style: const TextStyle(fontSize: 88)),
          ),
          const SizedBox(height: 36),
          Text(
            slide.title,
            textAlign: TextAlign.center,
            style: AppTypography.heading1.copyWith(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            slide.body,
            textAlign: TextAlign.center,
            style: AppTypography.body1.copyWith(
              fontSize: 15,
              color: AppColors.ink2,
              height: 1.55,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _Indicator extends StatelessWidget {
  final int count;
  final int current;
  const _Indicator({required this.count, required this.current});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < count; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: i == current ? 24 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: i == current ? AppColors.primary : AppColors.hairline,
              borderRadius: BorderRadius.circular(AppRadius.r8),
            ),
          ),
      ],
    );
  }
}
