import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_top_bar.dart';

// [FE - Component Rendering] Screen ini menampilkan informasi tentang
// aplikasi (deskripsi + versi) — diakses dari navigation drawer Beranda.
/// Layar "Tentang DurianTrace".
///
/// Menampilkan logo, nama aplikasi, deskripsi singkat, dan nomor versi.
/// Nomor versi saat ini bersifat statis; dapat dibaca dari package_info
/// di masa depan agar selalu sinkron dengan pubspec.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  /// Versi aplikasi — selaraskan dengan `version` di pubspec.yaml.
  static const String _appVersion = '1.0.0';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            const AppTopBar(title: 'Tentang'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                children: [
                  const SizedBox(height: 8),

                  // ── Logo + nama ──────────────────────────────────────────
                  Center(
                    child: Column(
                      children: [
                        Container(
                          width: 88,
                          height: 88,
                          decoration: BoxDecoration(
                            color: AppColors.primaryContainer.withValues(
                              alpha: 0.12,
                            ),
                            borderRadius: BorderRadius.circular(22),
                          ),
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.eco_rounded,
                            size: 48,
                            color: AppColors.primaryContainer,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'DurianTrace',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: AppColors.black,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Versi $_appVersion',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.placeholder,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // ── Deskripsi ────────────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: const Text(
                      'DurianTrace adalah aplikasi ketertelusuran rantai '
                      'pasok durian Jawa Timur. Aplikasi ini membantu petani '
                      'mencatat hasil panen, menghasilkan QR Code, dan '
                      'memantau perjalanan setiap batch durian dari kebun '
                      'hingga ke tangan konsumen.',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.subtitle,
                        height: 1.5,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── Info baris ───────────────────────────────────────────
                  const _AboutRow(
                    icon: Icons.verified_user_outlined,
                    label: 'Ketertelusuran',
                    value: 'Berbasis QR Code',
                  ),
                  const SizedBox(height: 14),
                  const _AboutRow(
                    icon: Icons.location_on_outlined,
                    label: 'Wilayah',
                    value: 'Jawa Timur, Indonesia',
                  ),
                  const SizedBox(height: 14),
                  const _AboutRow(
                    icon: Icons.copyright_outlined,
                    label: 'Hak Cipta',
                    value: '© 2026 DurianTrace',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Satu baris informasi (ikon + label + nilai) pada layar Tentang.
class _AboutRow extends StatelessWidget {
  const _AboutRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Icon(icon, size: 18, color: AppColors.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.placeholder,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.black,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
