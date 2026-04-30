import 'dart:ui';

import 'package:flutter/material.dart';

import 'session_guard.dart';

/// Wraps the app to provide privacy protections:
/// - Blur overlay when the app moves to background / inactive states.
/// - Updates [SessionGuard] activity timestamps on resume.
///
/// FLAG_SECURE is intentionally NOT enabled during the testing phase.
/// TODO(production): re-enable FLAG_SECURE on Android and a CALayer-based
/// blur snapshot on iOS before release.
class SecureAppShell extends StatefulWidget {
  const SecureAppShell({super.key, required this.child});

  final Widget child;

  @override
  State<SecureAppShell> createState() => _SecureAppShellState();
}

class _SecureAppShellState extends State<SecureAppShell>
    with WidgetsBindingObserver {
  final SessionGuard _sessionGuard = SessionGuard();
  bool _obscured = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _sessionGuard.touch();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    final shouldObscure =
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden;

    if (shouldObscure != _obscured) {
      setState(() => _obscured = shouldObscure);
    }

    if (state == AppLifecycleState.resumed) {
      _sessionGuard.touch();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Stack(
        children: [
          widget.child,
          if (_obscured)
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                child: Container(color: const Color(0x80FFFFFF)),
              ),
            ),
        ],
      ),
    );
  }
}
