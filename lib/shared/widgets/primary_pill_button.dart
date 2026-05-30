import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Tombol aksi utama berbentuk pill yang dipakai di seluruh layar petani.
///
/// Mengekstrak pola `ElevatedButton` + `StadiumBorder` yang berulang di
/// layar auth agar konsisten dengan Req 8.2.
///
/// Contoh penggunaan:
/// ```dart
/// PrimaryPillButton(
///   label: 'KIRIM',
///   onPressed: _handleSubmit,
///   isLoading: _isSubmitting,
/// )
/// ```
class PrimaryPillButton extends StatelessWidget {
  const PrimaryPillButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
  });

  /// Teks yang ditampilkan pada tombol.
  final String label;

  /// Callback saat tombol ditekan. Jika `null`, tombol dalam state disabled.
  final VoidCallback? onPressed;

  /// Jika `true`, tombol menampilkan spinner dan dinonaktifkan.
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final bool isDisabled = onPressed == null || isLoading;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isDisabled ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryContainer,
          disabledBackgroundColor:
              AppColors.primaryContainer.withValues(alpha: 0.55),
          foregroundColor: AppColors.white,
          disabledForegroundColor: AppColors.white.withValues(alpha: 0.7),
          elevation: 0,
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
                ),
              )
            : Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                  color: AppColors.white,
                ),
              ),
      ),
    );
  }
}
