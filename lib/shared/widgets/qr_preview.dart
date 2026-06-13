import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/theme/app_colors.dart';

/// Lightweight QR preview used across the app.
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
      padding: const EdgeInsets.all(8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          QrImageView(
            data: data,
            version: QrVersions.auto,
            size: size * 0.62,
            backgroundColor: AppColors.white,
            gapless: false,
          ),
          const SizedBox(height: 8),
          Text(
            data,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.subtitle,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}
