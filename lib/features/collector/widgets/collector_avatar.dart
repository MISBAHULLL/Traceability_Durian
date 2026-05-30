import 'dart:io' show File;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_colors.dart';
import '../data/collector_repository.dart';
import '../models/collector_product.dart';

// [FE - Component Rendering] CollectorAvatar menampilkan foto profil pengepul
// (atau inisial bila belum ada foto) secara lintas platform. Bila
// [showEditButton] aktif, menampilkan overlay kamera untuk mengganti foto.
// Pola identik dengan FarmerAvatar agar konsisten di seluruh aplikasi.
/// Avatar profil pengepul — foto atau inisial, dengan opsi edit.
class CollectorAvatar extends StatelessWidget {
  const CollectorAvatar({
    super.key,
    required this.profile,
    this.size = 64,
    this.showEditButton = false,
    this.onAvatarChanged,
  });

  /// Profil yang berisi nama (untuk inisial) dan avatarPath.
  final CollectorProfile profile;

  /// Diameter avatar dalam logical pixel.
  final double size;

  /// Bila true, tampilkan ikon kamera kecil di pojok kanan bawah.
  final bool showEditButton;

  /// Dipanggil setelah foto baru dipilih (path baru atau null bila dihapus).
  final void Function(String? path)? onAvatarChanged;

  @override
  Widget build(BuildContext context) {
    final fullName = profile.fullName;
    final avatarPath = profile.avatarPath;
    final hasPhoto = avatarPath != null && avatarPath.isNotEmpty;

    final avatar =
        hasPhoto ? _photoAvatar(avatarPath, size) : _initialsAvatar(fullName, size);

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

  // [FE - Event Handler] _pickAvatar membuka bottom sheet pilihan sumber foto,
  // lalu menyimpan path ke repository via updateAvatar.
  Future<void> _pickAvatar(BuildContext context, bool hasPhoto) async {
    final source = await showModalBottomSheet<_AvatarAction>(
      context: context,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetCtx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined,
                  color: AppColors.primary),
              title: const Text('Ambil dari Kamera'),
              onTap: () => Navigator.pop(sheetCtx, _AvatarAction.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined,
                  color: AppColors.primary),
              title: const Text('Pilih dari Galeri'),
              onTap: () => Navigator.pop(sheetCtx, _AvatarAction.gallery),
            ),
            if (hasPhoto)
              ListTile(
                leading: const Icon(Icons.delete_outline,
                    color: Color(0xFFDC2626)),
                title: const Text(
                  'Hapus Foto Profil',
                  style: TextStyle(color: Color(0xFFDC2626)),
                ),
                onTap: () => Navigator.pop(sheetCtx, _AvatarAction.remove),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (source == null) return;

    if (source == _AvatarAction.remove) {
      CollectorRepository.instance.updateAvatar(null);
      onAvatarChanged?.call(null);
      return;
    }

    final imageSource = source == _AvatarAction.camera
        ? ImageSource.camera
        : ImageSource.gallery;

    try {
      final picker = ImagePicker();
      final file = await picker.pickImage(
        source: imageSource,
        maxWidth: 512,
        imageQuality: 85,
      );
      if (file != null) {
        CollectorRepository.instance.updateAvatar(file.path);
        onAvatarChanged?.call(file.path);
      }
    } catch (_) {
      // Gagal ambil foto — biarkan avatar tidak berubah.
    }
  }

  static Widget _photoAvatar(String path, double size) {
    Widget img;
    if (kIsWeb) {
      img = Image.network(path,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => const SizedBox.shrink());
    } else {
      img = Image.file(File(path),
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => const SizedBox.shrink());
    }
    return ClipOval(child: SizedBox(width: size, height: size, child: img));
  }

  static Widget _initialsAvatar(String name, double size) {
    final parts = name.trim().split(RegExp(r'\s+'));
    String initials;
    if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
      initials = '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else {
      initials = name.isNotEmpty ? name[0].toUpperCase() : '?';
    }
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: AppColors.primaryContainer,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: TextStyle(
          fontSize: size * 0.34,
          fontWeight: FontWeight.w800,
          color: AppColors.white,
          letterSpacing: 1,
        ),
      ),
    );
  }
}

enum _AvatarAction { camera, gallery, remove }
