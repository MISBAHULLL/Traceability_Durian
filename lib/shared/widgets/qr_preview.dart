import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/theme/app_colors.dart';

// [FE - Component Rendering] Widget QR ini menjadi komponen lintas role untuk
// menampilkan kode QR yang responsif di web dan mobile.
/// Lightweight QR preview used across the app.
class QrPreview extends StatelessWidget {
  const QrPreview({
    super.key,
    required this.data,
    this.size = 180,
    this.showLabel = true,
  });

  final String data;
  final double size;
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : size;
        final effectiveSize = size > maxWidth ? maxWidth : size;
        final qrSize = showLabel ? effectiveSize * 0.68 : effectiveSize * 0.82;

        return Container(
          width: effectiveSize,
          constraints: BoxConstraints(minHeight: effectiveSize),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          padding: const EdgeInsets.all(10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              QrImageView(
                data: data,
                version: QrVersions.auto,
                size: qrSize,
                backgroundColor: AppColors.white,
                gapless: false,
              ),
              if (showLabel) ...[
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
            ],
          ),
        );
      },
    );
  }
}

// [FE - Component Rendering] Widget ini khusus QR tanpa label tambahan untuk
// layar yang sudah punya teks kode sendiri di bawah QR.
class ResponsiveQrCode extends StatelessWidget {
  const ResponsiveQrCode({super.key, required this.data, this.size = 220});

  final String data;
  final double size;

  @override
  Widget build(BuildContext context) {
    return QrPreview(data: data, size: size, showLabel: false);
  }
}
