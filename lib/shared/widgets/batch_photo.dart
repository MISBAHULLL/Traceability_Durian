import 'dart:io' show File;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

// [UTIL - Helper Function] BatchPhoto menampilkan foto durian batch secara
// lintas platform: di web memakai Image.network (blob URL dari image_picker),
// di mobile/desktop memakai Image.file. Bila path kosong, menampilkan
// placeholder ikon durian.
/// Widget penampil foto durian sebuah batch (lintas platform).
class BatchPhoto extends StatelessWidget {
  const BatchPhoto({
    super.key,
    required this.path,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
  });

  /// Path file lokal (mobile/desktop) atau blob URL (web). `null`/kosong →
  /// placeholder.
  final String? path;

  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(10);
    final hasPhoto = path != null && path!.isNotEmpty;

    Widget child;
    if (!hasPhoto) {
      child = _placeholder();
    } else if (kIsWeb) {
      // Di web, image_picker mengembalikan blob URL yang dibaca via network.
      child = Image.network(
        path!,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, _, _) => _placeholder(),
      );
    } else {
      // Di mobile/desktop, path adalah file lokal.
      child = Image.file(
        File(path!),
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, _, _) => _placeholder(),
      );
    }

    return ClipRRect(borderRadius: radius, child: child);
  }

  Widget _placeholder() {
    return Container(
      width: width,
      height: height,
      color: AppColors.surface,
      alignment: Alignment.center,
      child: const Icon(Icons.eco_outlined, color: AppColors.primary, size: 28),
    );
  }
}
