import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/alyak_card.dart';
import '../../../core/widgets/chat_bubbles.dart';
import '../widgets/chat_message.dart';

class WelcomeScreen extends StatefulWidget {
  /// Used by tests to skip the artificial delays.
  final bool fastMode;
  const WelcomeScreen({super.key, this.fastMode = false});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final List<String> _messages = [];
  bool _showActions = false;

  @override
  void initState() {
    super.initState();
    _animateMessages();
  }

  Future<void> _wait(Duration d) async {
    if (widget.fastMode) return;
    await Future<void>.delayed(d);
  }

  Future<void> _animateMessages() async {
    await _wait(const Duration(milliseconds: 200));
    if (!mounted) return;
    setState(() => _messages.add('안녕하세요 👋'));

    await _wait(const Duration(milliseconds: 800));
    if (!mounted) return;
    setState(() => _messages.add(
          '알약은 우리 가족이 어떤 영양제를 먹고 있는지,\n'
          '어떤 영양소가 부족한지 알려드려요',
        ));

    await _wait(const Duration(milliseconds: 600));
    if (!mounted) return;
    setState(() => _messages.add('어떻게 시작하실까요?'));

    await _wait(const Duration(milliseconds: 600));
    if (!mounted) return;
    setState(() => _showActions = true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        toolbarHeight: 40,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  children: [
                    for (final m in _messages)
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        child: ChatMessage(
                          text: m,
                          withMark: true,
                          key: ValueKey(m),
                        ),
                      ),
                  ],
                ),
              ),
              AnimatedOpacity(
                opacity: _showActions ? 1 : 0,
                duration: const Duration(milliseconds: 250),
                child: IgnorePointer(
                  ignoring: !_showActions,
                  child: Column(
                    children: [
                      _ChoiceTile(
                        widgetKey: const Key('welcome-self-button'),
                        emoji: '👤',
                        title: '본인부터 등록할게요',
                        sub: '가장 일반적이에요',
                        primary: true,
                        onTap: () => context
                            .push('/onboarding/family-add?relationship=self'),
                      ),
                      const SizedBox(height: 10),
                      _ChoiceTile(
                        widgetKey: const Key('welcome-family-button'),
                        emoji: '👨‍👩‍👧',
                        title: '다른 가족부터요',
                        sub: '아이, 부모님 먼저',
                        onTap: () =>
                            context.push('/onboarding/family-add'),
                      ),
                    ],
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

class _ChoiceTile extends StatelessWidget {
  final Key widgetKey;
  final String emoji;
  final String title;
  final String sub;
  final bool primary;
  final VoidCallback onTap;

  const _ChoiceTile({
    required this.widgetKey,
    required this.emoji,
    required this.title,
    required this.sub,
    required this.onTap,
    this.primary = false,
  });

  @override
  Widget build(BuildContext context) {
    return AlyakCard(
      key: widgetKey,
      padding: const EdgeInsets.all(16),
      onTap: onTap,
      border: primary
          ? Border.all(color: AppColors.primarySoft, width: 1.5)
          : null,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: primary ? AppColors.primarySoft : AppColors.surfaceMuted,
              borderRadius: BorderRadius.circular(AppRadius.r12),
            ),
            child: Text(emoji, style: const TextStyle(fontSize: 20)),
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
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 1),
                Text(sub, style: AppTypography.caption.copyWith(fontSize: 12)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right,
              size: 18, color: AppColors.faint),
        ],
      ),
    );
  }
}

// Re-export for sites that imported it via the welcome screen.
typedef WelcomeMark = AlyakBrandMark;
