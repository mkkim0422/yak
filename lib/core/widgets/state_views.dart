import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_typography.dart';
import 'alyak_buttons.dart';

/// Empty-state placeholder used across screens (no family / no products /
/// no search results). Visual matches `design/screens-states.jsx` —
/// emoji + heading + caption + optional primary action.
class EmptyStateView extends StatelessWidget {
  final String emoji;
  final String title;
  final String? message;
  final String? primaryLabel;
  final VoidCallback? onPrimary;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;
  final EdgeInsetsGeometry padding;

  const EmptyStateView({
    super.key,
    required this.emoji,
    required this.title,
    this.message,
    this.primaryLabel,
    this.onPrimary,
    this.secondaryLabel,
    this.onSecondary,
    this.padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: padding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 44)),
            const SizedBox(height: 16),
            Text(
              title,
              style: AppTypography.heading2.copyWith(fontSize: 17),
              textAlign: TextAlign.center,
            ),
            if (message != null) ...[
              const SizedBox(height: 6),
              Text(
                message!,
                style: AppTypography.caption.copyWith(fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ],
            if (primaryLabel != null && onPrimary != null) ...[
              const SizedBox(height: 20),
              PrimaryButton(
                label: primaryLabel!,
                size: AlyakButtonSize.md,
                onPressed: onPrimary,
              ),
            ],
            if (secondaryLabel != null && onSecondary != null) ...[
              const SizedBox(height: 8),
              AlyakTextButton(
                label: secondaryLabel!,
                color: AppColors.muted,
                onPressed: onSecondary,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Loading spinner with the design's soft-teal halo. No shimmer placeholders
/// (out of scope for v1 polish per `미세 효과 X` rule).
class LoadingStateView extends StatelessWidget {
  final String? title;
  final String? message;

  const LoadingStateView({
    super.key,
    this.title,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: AppColors.primarySoft,
                shape: BoxShape.circle,
              ),
              child: const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor:
                      AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
            ),
            if (title != null) ...[
              const SizedBox(height: 18),
              Text(
                title!,
                style: AppTypography.title.copyWith(fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ],
            if (message != null) ...[
              const SizedBox(height: 4),
              Text(
                message!,
                style: AppTypography.caption.copyWith(fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Friendly error placeholder. `onRetry` shows a primary retry button when
/// supplied; `onSecondary` adds an additional text button (e.g. "홈으로").
class ErrorStateView extends StatelessWidget {
  final String? emoji;
  final String title;
  final String? message;
  final String? retryLabel;
  final VoidCallback? onRetry;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  const ErrorStateView({
    super.key,
    this.emoji = '😵‍💫',
    this.title = '잠깐 문제가 생겼어요',
    this.message,
    this.retryLabel = '다시 시도',
    this.onRetry,
    this.secondaryLabel,
    this.onSecondary,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji ?? '😵‍💫', style: const TextStyle(fontSize: 44)),
            const SizedBox(height: 14),
            Text(
              title,
              style: AppTypography.heading2.copyWith(fontSize: 18),
              textAlign: TextAlign.center,
            ),
            if (message != null) ...[
              const SizedBox(height: 6),
              Text(
                message!,
                style: AppTypography.caption.copyWith(fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ],
            if (onRetry != null) ...[
              const SizedBox(height: 20),
              PrimaryButton(
                label: retryLabel ?? '다시 시도',
                size: AlyakButtonSize.md,
                onPressed: onRetry,
              ),
            ],
            if (secondaryLabel != null && onSecondary != null) ...[
              const SizedBox(height: 4),
              AlyakTextButton(
                label: secondaryLabel!,
                color: AppColors.muted,
                onPressed: onSecondary,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Inline empty card used inside lists / sections (eg. recommendation
/// rollups, member screens). Renders as a dashed-border container with
/// a single emoji + caption, matching `design/screens-states.jsx`.
class EmptyInlineCard extends StatelessWidget {
  final String emoji;
  final String message;

  const EmptyInlineCard({
    super.key,
    required this.emoji,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.r16),
        border: Border.all(
          color: AppColors.hairline,
          width: 1.5,
          strokeAlign: BorderSide.strokeAlignInside,
        ),
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 36)),
          const SizedBox(height: 8),
          Text(
            message,
            style: AppTypography.caption.copyWith(fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
