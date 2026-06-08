import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_top_bar.dart';

// [FE - Component Rendering] Screen ini menampilkan informasi aplikasi untuk
// role pengepul dan konteks traceability yang sedang diprototipekan.
class CollectorAboutScreen extends StatelessWidget {
  const CollectorAboutScreen({super.key});

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
                children: const [
                  SizedBox(height: 8),
                  _AppHeader(),
                  SizedBox(height: 28),
                  _DescriptionBox(),
                  SizedBox(height: 24),
                  _AboutRow(
                    icon: Icons.qr_code_scanner_rounded,
                    label: 'Pengepul',
                    value: 'Scan QR & verifikasi batch',
                  ),
                  SizedBox(height: 14),
                  _AboutRow(
                    icon: Icons.inventory_2_outlined,
                    label: 'Stok',
                    value: 'Batch terverifikasi masuk Stok Saya',
                  ),
                  SizedBox(height: 14),
                  _AboutRow(
                    icon: Icons.info_outline_rounded,
                    label: 'Versi',
                    value: CollectorAboutScreen._appVersion,
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

class _AppHeader extends StatelessWidget {
  const _AppHeader();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: AppColors.primaryContainer.withValues(alpha: 0.12),
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
        ],
      ),
    );
  }
}

class _DescriptionBox extends StatelessWidget {
  const _DescriptionBox();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: const Text(
        'DurianTrace membantu pengepul memverifikasi batch panen durian, '
        'mencatat hasil sortir, menerima stok terverifikasi, dan menjaga '
        'alur traceability dari petani ke rantai pasok berikutnya.',
        style: TextStyle(
          fontSize: 14,
          color: AppColors.subtitle,
          height: 1.5,
        ),
      ),
    );
  }
}

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
