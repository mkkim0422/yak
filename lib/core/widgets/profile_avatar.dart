import 'dart:io';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../../features/family/models/family_member.dart';

/// Avatar that prefers the member's saved profile photo and falls back to
/// the relationship-derived emoji when no photo is on disk. Mirrors
/// [AvatarBadge]'s rounded-square shape so it can drop into existing slots.
class ProfileAvatar extends StatelessWidget {
  final FamilyMember member;
  final double size;

  /// When true, draws a small camera badge in the bottom-right corner —
  /// signals to the user that the avatar is tappable and edits the photo.
  final bool showEditHint;

  const ProfileAvatar({
    super.key,
    required this.member,
    this.size = 56,
    this.showEditHint = false,
  });

  @override
  Widget build(BuildContext context) {
    final radius = size * 0.32;
    final path = member.profileImagePath;
    final hasPhoto = path != null && File(path).existsSync();

    final body = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: hasPhoto ? AppColors.surface : AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: AppColors.hairline, width: 1),
      ),
      clipBehavior: hasPhoto ? Clip.antiAlias : Clip.none,
      child: hasPhoto
          ? Image.file(
              File(path),
              key: ValueKey(path),
              width: size,
              height: size,
              fit: BoxFit.cover,
              gaplessPlayback: true,
              errorBuilder: (_, _, _) => _emoji(),
            )
          : _emoji(),
    );

    if (!showEditHint) return body;

    final hint = size * 0.32;
    return SizedBox(
      width: size + hint * 0.25,
      height: size + hint * 0.25,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          body,
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: hint,
              height: hint,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.surface, width: 2),
              ),
              child: Icon(
                Icons.camera_alt_rounded,
                size: hint * 0.55,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emoji() => Text(
        member.avatarEmoji,
        style: TextStyle(fontSize: size * 0.5, height: 1),
      );
}
