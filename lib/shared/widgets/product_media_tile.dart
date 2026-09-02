import 'dart:io' show File;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

// [FE - Component Rendering] Media tile ini menjadi standar visual gambar
// produk lintas role agar card horizontal tetap compact dan proporsional.
class ProductMediaTile extends StatelessWidget {
  const ProductMediaTile({
    super.key,
    this.imagePath,
    this.fallbackAsset = 'assets/images/durian.png',
    this.width = 128,
    this.height = 128,
    this.imageSize = 104,
  });

  final String? imagePath;
  final String fallbackAsset;
  final double width;
  final double height;
  final double imageSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
      ),
      alignment: Alignment.center,
      child: Center(child: _buildImage()),
    );
  }

  Widget _buildImage() {
    final path = (imagePath == null || imagePath!.isEmpty)
        ? fallbackAsset
        : imagePath!;

    // [FE - Component Rendering] Resolver gambar ini mendukung asset seed,
    // path file mobile, dan blob/network path dari web image picker.
    if (path.startsWith('assets/')) {
      return Image.asset(
        path,
        width: imageSize,
        height: imageSize,
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) => const _ProductImageFallback(),
      );
    }

    if (kIsWeb) {
      return Image.network(
        path,
        width: imageSize,
        height: imageSize,
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) => const _ProductImageFallback(),
      );
    }

    return Image.file(
      File(path),
      width: imageSize,
      height: imageSize,
      fit: BoxFit.contain,
      errorBuilder: (_, _, _) => const _ProductImageFallback(),
    );
  }
}

class _ProductImageFallback extends StatelessWidget {
  const _ProductImageFallback();

  @override
  Widget build(BuildContext context) {
    return const Icon(
      Icons.image_outlined,
      color: AppColors.placeholder,
      size: 30,
    );
  }
}
