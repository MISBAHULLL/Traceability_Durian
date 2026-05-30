import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_top_bar.dart';
import '../data/farmer_repository.dart';
import '../farmer_routes.dart';
import 'farmer_home_screen.dart';

/// Layar QR Code untuk satu batch panen.
///
/// Menampilkan QR Code yang merepresentasikan [batchCode], teks kode batch,
/// dan URL telusur publik (Req 4.1–4.3).
///
/// Bila [openedAfterCreate] bernilai `true`, tombol back akan mengarahkan
/// pengguna kembali ke Beranda Petani (bukan ke form Tambah Batch) — Req 4.6.
///
/// Implementasi penuh (qr_flutter widget) akan ditambahkan pada Task 9.
class BatchQrScreen extends StatelessWidget {
  const BatchQrScreen({
    super.key,
    required this.batchCode,
    this.openedAfterCreate = false,
  });

  /// Kode batch yang akan ditampilkan QR-nya.
  final String batchCode;

  /// Bila `true`, tombol back kembali ke Beranda (bukan pop biasa).
  final bool openedAfterCreate;

  @override
  Widget build(BuildContext context) {
    final repo = FarmerRepository.instance;
    final traceUrl = repo.publicTraceUrl(batchCode);

    return PopScope(
      // Intercept back bila dibuka setelah create (Req 4.6)
      canPop: !openedAfterCreate,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && openedAfterCreate) {
          FarmerRoutes.replaceAll(context, const FarmerHomeScreen());
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.white,
        body: SafeArea(
          child: Column(
            children: [
              AppTopBar(
                title: 'QR Batch',
                onBack: openedAfterCreate
                    ? () => FarmerRoutes.replaceAll(
                          context,
                          const FarmerHomeScreen(),
                        )
                    : null,
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                  child: Column(
                    children: [
                      // Placeholder QR — akan diganti qr_flutter pada Task 9
                      Container(
                        width: 220,
                        height: 220,
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.qr_code_2_rounded,
                            size: 120,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Kode batch (Req 4.2)
                      Text(
                        batchCode,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // URL telusur publik (Req 4.3)
                      Text(
                        traceUrl,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.placeholder,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
