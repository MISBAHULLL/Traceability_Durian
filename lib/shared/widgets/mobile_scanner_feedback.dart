import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../core/theme/app_colors.dart';

// [FE - Component Rendering] Widget ini menjadi fallback visual shared untuk
// scanner kamera ketika permission belum diberikan atau kamera belum siap.
class MobileScannerFeedback extends StatelessWidget {
  const MobileScannerFeedback({super.key, this.error});

  final MobileScannerException? error;

  @override
  Widget build(BuildContext context) {
    final isPermissionDenied =
        error?.errorCode == MobileScannerErrorCode.permissionDenied;
    final message = isPermissionDenied
        ? 'Izin kamera belum diberikan. Aktifkan izin kamera atau gunakan input kode.'
        : 'Kamera belum siap. Coba lagi atau gunakan input kode manual.';

    return Container(
      color: AppColors.black,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.no_photography_outlined,
            size: 38,
            color: AppColors.white,
          ),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              height: 1.4,
              fontWeight: FontWeight.w700,
              color: AppColors.white,
            ),
          ),
        ],
      ),
    );
  }
}

// [FE - Component Rendering] Placeholder ini menjaga box kamera tetap stabil
// saat stream kamera mobile sedang mulai.
class MobileScannerLoading extends StatelessWidget {
  const MobileScannerLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: AppColors.black,
      child: Center(
        child: CircularProgressIndicator(
          strokeWidth: 2.6,
          color: AppColors.white,
        ),
      ),
    );
  }
}
