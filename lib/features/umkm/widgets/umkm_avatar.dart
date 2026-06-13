import 'dart:io' show File;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../models/umkm_profile.dart';

class UmkmAvatar extends StatelessWidget {
  const UmkmAvatar({
    super.key,
    required this.profile,
    this.size = 64,
    this.showEditButton = false,
    this.onEdit,
  });

  final UmkmProfile profile;
  final double size;
  final bool showEditButton;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final avatar = _buildAvatar();
    if (!showEditButton) return avatar;

    return Stack(
      children: [
        avatar,
        Positioned(
          right: 0,
          bottom: 0,
          child: GestureDetector(
            onTap: onEdit,
            child: Container(
              width: size * 0.35,
              height: size * 0.35,
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.white, width: 2),
              ),
              alignment: Alignment.center,
              child: Icon(
                Icons.camera_alt_rounded,
                size: size * 0.18,
                color: AppColors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAvatar() {
    if (profile.imageBytes != null) {
      return _clipImage(Image.memory(profile.imageBytes!, fit: BoxFit.cover));
    }

    final path = profile.imagePath;
    if (path != null && path.isNotEmpty) {
      final image = kIsWeb
          ? Image.network(path, fit: BoxFit.cover)
          : Image.file(File(path), fit: BoxFit.cover);
      return _clipImage(image);
    }

    final source = profile.name.trim().isNotEmpty
        ? profile.name.trim()
        : profile.ownerName.trim();
    final initial = source.isEmpty ? 'U' : source[0].toUpperCase();
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: AppColors.primaryContainer,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: TextStyle(
          fontSize: size * 0.34,
          fontWeight: FontWeight.w800,
          color: AppColors.white,
        ),
      ),
    );
  }

  Widget _clipImage(Image image) {
    return ClipOval(
      child: SizedBox(width: size, height: size, child: image),
    );
  }
}
