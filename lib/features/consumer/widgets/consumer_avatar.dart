import 'dart:io' show File;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_colors.dart';
import '../data/consumer_repository.dart';
import '../models/consumer_product.dart';

class ConsumerAvatar extends StatelessWidget {
  const ConsumerAvatar({
    super.key,
    required this.profile,
    this.size = 64,
    this.showEditButton = false,
  });

  final ConsumerProfile profile;
  final double size;
  final bool showEditButton;

  @override
  Widget build(BuildContext context) {
    final path = profile.avatarPath;
    final hasPhoto = path != null && path.isNotEmpty;
    final avatar = hasPhoto ? _photoAvatar(path, size) : _initialAvatar(size);

    if (!showEditButton) return avatar;
    return Stack(
      children: [
        avatar,
        Positioned(
          right: 0,
          bottom: 0,
          child: GestureDetector(
            onTap: () => _pickAvatar(context, hasPhoto),
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

  Widget _initialAvatar(double size) {
    final source = profile.fullName.trim();
    final initial = source.isEmpty ? 'K' : source[0].toUpperCase();
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

  static Widget _photoAvatar(String path, double size) {
    final image = kIsWeb
        ? Image.network(path, fit: BoxFit.cover)
        : Image.file(File(path), fit: BoxFit.cover);
    return ClipOval(
      child: SizedBox(width: size, height: size, child: image),
    );
  }

  Future<void> _pickAvatar(BuildContext context, bool hasPhoto) async {
    final action = await showModalBottomSheet<_AvatarAction>(
      context: context,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(
                Icons.photo_camera_outlined,
                color: AppColors.primary,
              ),
              title: const Text('Ambil dari Kamera'),
              onTap: () => Navigator.pop(sheetContext, _AvatarAction.camera),
            ),
            ListTile(
              leading: const Icon(
                Icons.photo_library_outlined,
                color: AppColors.primary,
              ),
              title: const Text('Pilih dari Galeri'),
              onTap: () => Navigator.pop(sheetContext, _AvatarAction.gallery),
            ),
            if (hasPhoto)
              ListTile(
                leading: const Icon(
                  Icons.delete_outline,
                  color: Color(0xFFDC2626),
                ),
                title: const Text(
                  'Hapus Foto Profil',
                  style: TextStyle(color: Color(0xFFDC2626)),
                ),
                onTap: () => Navigator.pop(sheetContext, _AvatarAction.remove),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (action == null) return;
    if (action == _AvatarAction.remove) {
      ConsumerRepository.instance.updateAvatar(null);
      return;
    }

    try {
      final file = await ImagePicker().pickImage(
        source: action == _AvatarAction.camera
            ? ImageSource.camera
            : ImageSource.gallery,
        maxWidth: 512,
        imageQuality: 85,
      );
      if (file != null) ConsumerRepository.instance.updateAvatar(file.path);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal mengambil foto profil.')),
        );
      }
    }
  }
}

enum _AvatarAction { camera, gallery, remove }
