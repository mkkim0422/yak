import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_shadows.dart';

/// Base surface card. Mirrors `Card` in `design/components.jsx`.
class AlyakCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color background;
  final BoxBorder? border;
  final List<BoxShadow> shadow;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? margin;

  const AlyakCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = AppRadius.r16,
    this.background = AppColors.surface,
    this.border,
    this.shadow = AppShadows.card,
    this.onTap,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final Widget content = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(radius),
        border: border,
        boxShadow: shadow,
      ),
      child: child,
    );
    final wrapped = onTap == null
        ? content
        : Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(radius),
              child: content,
            ),
          );
    if (margin == null) return wrapped;
    return Padding(padding: margin!, child: wrapped);
  }
}
