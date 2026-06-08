import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_top_bar.dart';
import '../../../shared/widgets/primary_pill_button.dart';
import '../../../shared/widgets/top_notification_banner.dart';
import '../collector_routes.dart';
import '../data/collector_repository.dart';
import '../models/collector_product.dart';
import 'add_transaction_screen.dart';
import 'collector_stock_screen.dart';

// [FE - Component Rendering] Screen ini mensimulasikan scan QR batch untuk
// pengepul sebelum integrasi kamera/mobile_scanner ditambahkan.
class CollectorScanQrScreen extends StatefulWidget {
  const CollectorScanQrScreen({super.key});

  @override
  State<CollectorScanQrScreen> createState() => _CollectorScanQrScreenState();
}

class _CollectorScanQrScreenState extends State<CollectorScanQrScreen> {
  final _repo = CollectorRepository.instance;
  final _codeCtrl = TextEditingController();
  final _notification = TopNotification();

  @override
  void dispose() {
    _notification.dispose();
    _codeCtrl.dispose();
    super.dispose();
  }

  // [UTIL - Helper Function] Parser ini menerima kode batch langsung atau URL
  // trace publik, lalu mengambil kode DRN-YYYY-NNNNNN untuk validasi FE.
  String _extractBatchCode(String raw) {
    final text = raw.trim();
    final match = RegExp(r'DRN-\d{4}-\d{6}', caseSensitive: false)
        .firstMatch(text);
    return (match?.group(0) ?? text).toUpperCase();
  }

  // [FE - Event Handler] Handler ini memvalidasi hasil scan simulasi dan
  // membuka form verifikasi bila batch masih tersedia untuk pengepul.
  Future<void> _handleScanSubmit() async {
    FocusScope.of(context).unfocus();

    final code = _extractBatchCode(_codeCtrl.text);
    if (code.isEmpty) {
      _notification.show(context, 'Masukkan kode batch terlebih dahulu.',
          isError: true);
      return;
    }

    final product = _repo.findProduct(code);
    if (product == null || product.category != ProductCategory.durianSegar) {
      _notification.show(
        context,
        'QR tidak valid atau batch sudah tidak tersedia untuk diverifikasi.',
        isError: true,
      );
      return;
    }

    await _openVerification(code);
  }

  // [FE - Event Handler] Navigasi ini membawa kode hasil scan ke form
  // verifikasi sehingga produk terpilih otomatis.
  Future<void> _openVerification(String code) async {
    final completed = await CollectorRoutes.push<bool>(
      context,
      AddTransactionScreen(initialBatchCode: code),
    );
    if (mounted) setState(() {});
    if (mounted && completed == true) {
      await CollectorRoutes.push(context, const CollectorStockScreen());
    }
  }

  @override
  Widget build(BuildContext context) {
    final products = _repo.products
        .where((p) => p.category == ProductCategory.durianSegar)
        .toList();

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            const AppTopBar(title: 'Scan QR Batch'),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // [FE - Component Rendering] Panel ini menggantikan kamera
                    // sementara dengan input kode untuk prototype FE.
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: AppColors.primaryContainer,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.qr_code_scanner_rounded,
                            size: 34,
                            color: AppColors.white,
                          ),
                          SizedBox(height: 14),
                          Text(
                            'Scan QR Batch',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: AppColors.white,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Simulasi scan: masukkan kode batch atau URL QR.',
                            style: TextStyle(
                              fontSize: 12,
                              height: 1.35,
                              color: Color(0xFFEAF7E5),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    const _FieldLabel(label: 'Kode / URL QR Batch'),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _codeCtrl,
                      textCapitalization: TextCapitalization.characters,
                      decoration: InputDecoration(
                        hintText: 'Contoh: DRN-2026-000128',
                        filled: true,
                        fillColor: AppColors.white,
                        prefixIcon: const Icon(
                          Icons.qr_code_2_rounded,
                          color: AppColors.placeholder,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: Color(0xFFE5E7EB)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: Color(0xFFE5E7EB)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppColors.primaryContainer,
                            width: 2,
                          ),
                        ),
                      ),
                      onSubmitted: (_) => _handleScanSubmit(),
                    ),
                    const SizedBox(height: 18),
                    PrimaryPillButton(
                      label: 'LANJUT VERIFIKASI',
                      onPressed: _handleScanSubmit,
                    ),
                    const SizedBox(height: 26),
                    const _SectionTitle(title: 'Batch Tersedia'),
                    const SizedBox(height: 10),
                    if (products.isEmpty)
                      const _EmptyBatchHint()
                    else
                      ...products.map(
                        (product) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _AvailableBatchTile(
                            product: product,
                            onTap: () => _openVerification(product.code),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: AppColors.subtitle,
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w800,
        color: AppColors.black,
      ),
    );
  }
}

// [FE - Component Rendering] Tile ini menjadi shortcut mock untuk memilih
// batch tanpa kamera saat testing FE di emulator/web.
class _AvailableBatchTile extends StatelessWidget {
  const _AvailableBatchTile({
    required this.product,
    required this.onTap,
  });

  final CollectorProduct product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.primaryContainer.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.qr_code_2_rounded,
                color: AppColors.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.code,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${product.name} - ${product.weightRange}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.black,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.placeholder,
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyBatchHint extends StatelessWidget {
  const _EmptyBatchHint();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: const Text(
        'Belum ada batch petani yang menunggu verifikasi.',
        style: TextStyle(
          fontSize: 13,
          color: AppColors.placeholder,
        ),
      ),
    );
  }
}
