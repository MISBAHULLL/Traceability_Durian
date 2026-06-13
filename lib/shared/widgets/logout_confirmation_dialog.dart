import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Menampilkan dialog konfirmasi logout yang seragam untuk semua role.
///
/// Mengikuti gaya pada screenshot: sudut membulat, judul tebal, tombol
/// "Batal" abu-abu dan "Keluar" merah.
Future<bool> showLogoutConfirmationDialog(BuildContext context) async {
  final confirmed = await showDialog<bool>(
    context: context,
    barrierDismissible: true,
    builder: (dialogCtx) {
      return AlertDialog(
        backgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
        contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
        actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
        title: const Text(
          'Keluar dari akun?',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppColors.black,
          ),
        ),
        content: const Text(
          'Anda akan keluar dari sesi ini dan kembali ke halaman masuk.',
          style: TextStyle(
            fontSize: 14,
            height: 1.45,
            color: AppColors.black,
          ),
        ),
        actionsAlignment: MainAxisAlignment.end,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF6B7280),
              textStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            child: const Text('Batal'),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, true),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFEF4444),
              textStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            child: const Text('Keluar'),
          ),
        ],
      );
    },
  );

  return confirmed == true;
}
