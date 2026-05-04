import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
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
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  children: [
                    for (final m in _messages)
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        child: ChatMessage(text: m, key: ValueKey(m)),
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
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          key: const Key('welcome-self-button'),
                          onPressed: () => context.push(
                              '/onboarding/family-add?relationship=self'),
                          style: FilledButton.styleFrom(
                            padding:
                                const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('👤  나부터 등록하기',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w600)),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          key: const Key('welcome-family-button'),
                          onPressed: () =>
                              context.push('/onboarding/family-add'),
                          style: OutlinedButton.styleFrom(
                            padding:
                                const EdgeInsets.symmetric(vertical: 14),
                            foregroundColor: AppColors.textPrimary,
                            side: BorderSide(
                                color: AppColors.primary
                                    .withValues(alpha: 0.4)),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text('👨‍👩‍👧  가족 먼저 등록하기',
                              style: AppTypography.body1.copyWith(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600)),
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
    );
  }
}
