import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_top_bar.dart';
import '../../../shared/widgets/mobile_scanner_feedback.dart';
import '../../../shared/widgets/primary_pill_button.dart';
import '../../../shared/widgets/top_notification_banner.dart';
import '../../collector/models/collector_shipment_batch.dart';
import '../../trace/screens/public_trace_screen.dart';
import '../consumer_routes.dart';
import '../data/consumer_repository.dart';
import '../models/consumer_product.dart';
import 'consumer_product_detail_screen.dart';
import 'consumer_shipment_receive_screen.dart';

/// Screen scan QR untuk konsumen.
///
/// Layout dibuat sejajar dengan scan QR collector, tetapi targetnya produk
/// UMKM yang siap dibeli.
class ConsumerScanQrScreen extends StatefulWidget {
  const ConsumerScanQrScreen({super.key});

  @override
  State<ConsumerScanQrScreen> createState() => _ConsumerScanQrScreenState();
}

class _ConsumerScanQrScreenState extends State<ConsumerScanQrScreen> {
  final _repo = ConsumerRepository.instance;
  final _codeCtrl = TextEditingController();
  final _notification = TopNotification();
  final _scannerController = MobileScannerController();

  bool _isCameraMode = true;
  bool _isHandlingScan = false;

  @override
  void dispose() {
    _notification.dispose();
    _codeCtrl.dispose();
    _scannerController.dispose();
    super.dispose();
  }

  String _extractProductCode(String raw) {
    final text = raw.trim();
    final match = RegExp(
      r'(UMKM-P-\d+|UMKM-\d{3})',
      caseSensitive: false,
    ).firstMatch(text);
    return (match?.group(0) ?? text).toUpperCase();
  }

  String? _extractPglCode(String raw) {
    final text = raw.trim();
    final match = RegExp(
      r'PGL-\d{4}-\d{6}',
      caseSensitive: false,
    ).firstMatch(text);
    return match?.group(0)?.toUpperCase();
  }

  Future<void> _handleScanSubmit() async {
    FocusScope.of(context).unfocus();

    final raw = _codeCtrl.text;
    final pglCode = _extractPglCode(raw);
    final productCode = _extractProductCode(raw);
    if ((pglCode == null || pglCode.isEmpty) && productCode.isEmpty) {
      _notification.show(
        context,
        'Masukkan kode QR terlebih dahulu.',
        isError: true,
      );
      return;
    }

    if (pglCode != null) {
      final shipment = _repo.scanCollectorShipment(pglCode);
      if (shipment == null) {
        _notification.show(
          context,
          'PGL tidak tersedia atau bukan tujuan konsumen ini.',
          isError: true,
        );
        return;
      }
      if (shipment.status == CollectorShipmentStatus.completed ||
          shipment.status == CollectorShipmentStatus.rejected) {
        _notification.show(context, 'PGL ini sudah ${shipment.status.label}.');
        return;
      }
      await _openShipmentReceipt(pglCode);
      return;
    }

    final product = _repo.findProduct(productCode);
    if (product == null) {
      if (productCode.startsWith('UMKM-P-')) {
        await _openPublicTrace(productCode);
        return;
      }
      _notification.show(
        context,
        'QR tidak valid atau produk belum tersedia.',
        isError: true,
      );
      return;
    }

    await _openProductDetail(product);
  }

  Future<void> _handleCameraDetect(BarcodeCapture capture) async {
    if (_isHandlingScan) return;

    final rawValue = capture.barcodes
        .map((barcode) => barcode.rawValue)
        .whereType<String>()
        .firstWhere((value) => value.trim().isNotEmpty, orElse: () => '');

    if (rawValue.isEmpty) return;

    setState(() => _isHandlingScan = true);
    await _scannerController.stop();

    final pglCode = _extractPglCode(rawValue);
    if (pglCode != null) {
      final shipment = _repo.scanCollectorShipment(pglCode);
      if (shipment == null) {
        if (!mounted) return;
        _notification.show(
          context,
          'PGL tidak tersedia atau bukan tujuan konsumen ini.',
          isError: true,
        );
        await Future.delayed(const Duration(milliseconds: 900));
        if (!mounted) return;
        setState(() => _isHandlingScan = false);
        await _scannerController.start();
        return;
      }
      if (shipment.status == CollectorShipmentStatus.completed ||
          shipment.status == CollectorShipmentStatus.rejected) {
        if (!mounted) return;
        _notification.show(context, 'PGL ini sudah ${shipment.status.label}.');
        await Future.delayed(const Duration(milliseconds: 900));
        if (!mounted) return;
        setState(() => _isHandlingScan = false);
        await _scannerController.start();
        return;
      }
      await _openShipmentReceipt(pglCode);
      return;
    }

    final code = _extractProductCode(rawValue);
    final product = _repo.findProduct(code);
    if (product == null) {
      if (code.startsWith('UMKM-P-')) {
        await _openPublicTrace(code);
        return;
      }
      if (!mounted) return;
      _notification.show(
        context,
        'QR tidak valid atau produk belum tersedia.',
        isError: true,
      );
      await Future.delayed(const Duration(milliseconds: 900));
      if (!mounted) return;
      setState(() => _isHandlingScan = false);
      await _scannerController.start();
      return;
    }

    await _openProductDetail(product);
  }

  Future<void> _openPublicTrace(String batchCode) async {
    await ConsumerRoutes.push(context, PublicTraceScreen(batchCode: batchCode));

    if (!mounted) return;
    setState(() => _isHandlingScan = false);
    if (_isCameraMode) {
      await _scannerController.start();
    }
  }

  Future<void> _openProductDetail(ConsumerProduct product) async {
    await ConsumerRoutes.push(
      context,
      ConsumerProductDetailScreen(product: product),
    );

    if (!mounted) return;
    setState(() => _isHandlingScan = false);
    if (_isCameraMode) {
      await _scannerController.start();
    }
  }

  Future<void> _openShipmentReceipt(String shipmentCode) async {
    await ConsumerRoutes.push(
      context,
      ConsumerShipmentReceiveScreen(shipmentCode: shipmentCode),
    );

    if (!mounted) return;
    setState(() => _isHandlingScan = false);
    if (_isCameraMode) {
      await _scannerController.start();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            const AppTopBar(title: 'Scan QR Produk / PGL'),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                            'Scan QR Produk / PGL',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: AppColors.white,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Gunakan kamera atau input kode produk maupun PGL.',
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
                        onDetect: _handleCameraDetect,
                      ),
                    ] else ...[
                      const _FieldLabel(label: 'Kode / URL QR'),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _codeCtrl,
                        textCapitalization: TextCapitalization.characters,
                        decoration: InputDecoration(
                          hintText: 'Contoh: UMKM-001 atau PGL-2026-000906',
                          hintStyle: const TextStyle(
                            color: Color(0xFFB8B8B8),
                            fontSize: 14,
                          ),
                          filled: true,
                          fillColor: AppColors.white,
                          prefixIcon: const Icon(
                            Icons.qr_code_2_rounded,
                            color: AppColors.placeholder,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFFE5E7EB),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFFE5E7EB),
                            ),
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
                        label: 'LANJUT',
                        onPressed: _handleScanSubmit,
                      ),
                    ],
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

class _ScanModeToggle extends StatelessWidget {
  const _ScanModeToggle({required this.isCameraMode, required this.onChanged});

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

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
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
      height: 320,
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
            errorBuilder: (context, error) =>
                MobileScannerFeedback(error: error),
            placeholderBuilder: (context) => const MobileScannerLoading(),
          ),
          // [FE - Component Rendering] Frame scan dibuat kompak di area kamera
          // penuh agar tidak memanjang sampai caption instruksi.
          Positioned(
            top: 28,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 230,
                height: 230,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: AppColors.white.withValues(alpha: 0.9),
                    width: 2,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: 18,
            child: Center(
              child: _ScannerCaption(
                text: isHandlingScan
                    ? 'QR terbaca, membuka detail produk...'
                    : 'Arahkan kamera ke QR produk.',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScannerCaption extends StatelessWidget {
  const _ScannerCaption({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 260),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.black.withValues(alpha: 0.58),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: AppColors.white,
        ),
      ),
    );
  }
}
