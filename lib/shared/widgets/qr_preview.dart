import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Lightweight QR preview placeholder used when package API differs.
/// Shows a bordered box with the code text. Replace with real QR widget
/// when package API is aligned.
class QrPreview extends StatelessWidget {
  const QrPreview({super.key, required this.data, this.size = 180});

  final String data;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      alignment: Alignment.center,
      padding: const EdgeInsets.all(8),
      child: Text(
        data,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 12, color: AppColors.subtitle),
      ),
    );
  }
}
