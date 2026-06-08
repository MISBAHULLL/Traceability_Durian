import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_top_bar.dart';
import '../../../shared/widgets/primary_pill_button.dart';
import '../../../shared/widgets/top_notification_banner.dart';
import '../collector_routes.dart';
import '../data/collector_repository.dart';
import '../models/collector_product.dart';
import 'add_transaction_screen.dart';
import 'collector_stock_screen.dart';

// [FE - Component Rendering] Screen ini menjadi pintu masuk pengepul untuk
// membaca QR batch petani sebelum masuk ke alur verifikasi.
class CollectorScanQrScreen extends StatefulWidget {
  const CollectorScanQrScreen({super.key});

  @override
  State<CollectorScanQrScreen> createState() => _CollectorScanQrScreenState();
}

class _CollectorScanQrScreenState extends State<CollectorScanQrScreen> {
  final _repo = CollectorRepository.instance;
  final _codeCtrl = TextEditingController();
  final _notification = TopNotification();
  final _scannerController = MobileScannerController();

  // [FE - State Management] State ini mengatur mode scan kamera/manual dan
  // mencegah hasil kamera diproses berkali-kali saat QR masih terlihat.
  bool _isCameraMode = true;
  bool _isHandlingScan = false;

  @override
  void dispose() {
    _notification.dispose();
    _codeCtrl.dispose();
    _scannerController.dispose();
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

  // [FE - Event Handler] Handler ini memvalidasi input kode manual dan membuka
  // form verifikasi bila batch masih tersedia untuk pengepul.
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

  // [FE - Event Handler] Handler kamera membaca rawValue dari QR lalu memakai
  // validator yang sama dengan input manual.
  Future<void> _handleCameraDetect(BarcodeCapture capture) async {
    if (_isHandlingScan) return;

    final rawValue = capture.barcodes
        .map((barcode) => barcode.rawValue)
        .whereType<String>()
        .firstWhere((value) => value.trim().isNotEmpty, orElse: () => '');

    if (rawValue.isEmpty) return;

    setState(() => _isHandlingScan = true);
    await _scannerController.stop();

    final code = _extractBatchCode(rawValue);
    final product = _repo.findProduct(code);
    if (product == null || product.category != ProductCategory.durianSegar) {
      if (!mounted) return;
      _notification.show(
        context,
        'QR tidak valid atau batch sudah tidak tersedia untuk diverifikasi.',
        isError: true,
      );
      await Future.delayed(const Duration(milliseconds: 900));
      if (!mounted) return;
      setState(() => _isHandlingScan = false);
      await _scannerController.start();
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
    if (!mounted) return;

    setState(() => _isHandlingScan = false);
    if (completed == true) {
      await CollectorRoutes.push(context, const CollectorStockScreen());
      return;
    }
    if (_isCameraMode) {
      await _scannerController.start();
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
                    // [FE - Component Rendering] Panel ini menjelaskan konteks
                    // scan dan tetap menyediakan fallback input manual.
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
                            'Gunakan kamera atau input kode batch secara manual.',
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
                    _ScanModeToggle(
                      isCameraMode: _isCameraMode,
                      onChanged: (value) async {
                        setState(() {
                          _isCameraMode = value;
                          _isHandlingScan = false;
                        });
                        if (value) {
                          await _scannerController.start();
                        } else {
                          await _scannerController.stop();
                        }
                      },
                    ),
                    const SizedBox(height: 14),
                    if (_isCameraMode) ...[
                      _CameraScannerBox(
                        controller: _scannerController,
                        isHandlingScan: _isHandlingScan,
                        onDetect: (capture) {
                          _handleCameraDetect(capture);
                        },
                      ),
                    ] else ...[
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
                    ],
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

// [FE - Component Rendering] Toggle ini memisahkan scan kamera dan input kode
// supaya FE tetap bisa dites di device maupun browser.
class _ScanModeToggle extends StatelessWidget {
  const _ScanModeToggle({
    required this.isCameraMode,
    required this.onChanged,
  });

  final bool isCameraMode;
  final Future<void> Function(bool value) onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ModeButton(
              icon: Icons.photo_camera_outlined,
              label: 'Kamera',
              isActive: isCameraMode,
              onTap: () {
                onChanged(true);
              },
            ),
          ),
          Expanded(
            child: _ModeButton(
              icon: Icons.keyboard_alt_outlined,
              label: 'Input Kode',
              isActive: !isCameraMode,
              onTap: () {
                onChanged(false);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  const _ModeButton({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = isActive ? AppColors.white : AppColors.placeholder;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primaryContainer : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 17, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// [FE - Component Rendering] Kamera scanner membaca QR fisik dan meneruskan
// hasilnya ke event handler validasi batch pengepul.
class _CameraScannerBox extends StatelessWidget {
  const _CameraScannerBox({
    required this.controller,
    required this.isHandlingScan,
    required this.onDetect,
  });

  final MobileScannerController controller;
  final bool isHandlingScan;
  final void Function(BarcodeCapture capture) onDetect;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 280,
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.black,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            controller: controller,
            onDetect: onDetect,
          ),
          Center(
            child: Container(
              width: 210,
              height: 210,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: AppColors.white.withValues(alpha: 0.85),
                  width: 2,
                ),
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.black.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                isHandlingScan
                    ? 'QR terbaca, membuka verifikasi...'
                    : 'Arahkan kamera ke QR batch petani.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.white,
                ),
              ),
            ),
          ),
        ],
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

// [FE - Component Rendering] Tile ini menjadi fallback pilih batch langsung
// saat pengepul perlu verifikasi tanpa memindai QR fisik.
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
