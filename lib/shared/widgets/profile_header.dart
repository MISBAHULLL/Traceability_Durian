import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Header profil bersama untuk semua role.
///
/// Menampilkan avatar, nama lengkap, dan label peran dengan badge.
class ProfileHeader extends StatelessWidget {
  const ProfileHeader({
    super.key,
    required this.fullName,
    required this.roleLabel,
    this.avatar,
    this.avatarSize = 96,
  });

  final String fullName;
  final String roleLabel;
  final Widget? avatar;
  final double avatarSize;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          avatar ?? _defaultAvatar(fullName, avatarSize),
          const SizedBox(height: 16),
          Text(
            fullName,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.black,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primaryContainer.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              roleLabel,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _defaultAvatar(String fullName, double size) {
    final initial = fullName.isNotEmpty
        ? fullName.trim().substring(0, 1).toUpperCase()
        : '?';
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.primaryContainer.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(size * 0.35),
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: TextStyle(
          fontSize: size * 0.36,
          fontWeight: FontWeight.w800,
          color: AppColors.primaryContainer,
        ),
      ),
    );
  }
}
