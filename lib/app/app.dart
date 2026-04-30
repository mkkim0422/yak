import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/l10n/app_strings.dart';
import '../core/security/screen_security.dart';
import '../core/theme/app_theme.dart';
import 'router.dart';

class AlyakApp extends ConsumerWidget {
  const AlyakApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      routerConfig: router,
      builder: (context, child) =>
          SecureAppShell(child: child ?? const SizedBox.shrink()),
    );
  }
}
