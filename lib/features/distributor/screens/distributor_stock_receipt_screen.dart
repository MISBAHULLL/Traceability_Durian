import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_top_bar.dart';
import '../../../shared/widgets/mobile_scanner_feedback.dart';
import '../../../shared/widgets/primary_pill_button.dart';
import '../../../shared/widgets/top_notification_banner.dart';
import '../data/distributor_repository.dart';
import '../distributor_routes.dart';
import '../models/distributor_acquisition_transaction.dart';
import 'distributor_acquisition_verify_screen.dart';

const _borderColor = Color(0xFFE1E6DF);

class DistributorStockReceiptScreen extends StatefulWidget {
  const DistributorStockReceiptScreen({super.key});

  @override
  State<DistributorStockReceiptScreen> createState() =>
      _DistributorStockReceiptScreenState();
}

class _DistributorStockReceiptScreenState
    extends State<DistributorStockReceiptScreen> {
  final _repository = DistributorRepository.instance;
  final _codeController = TextEditingController();
  final _notification = TopNotification();
  final _scannerController = MobileScannerController();

  bool _isCameraMode = true;
  bool _isHandlingScan = false;

  @override
  void dispose() {
    _codeController.dispose();
    _notification.dispose();
    _scannerController.dispose();
    super.dispose();
  }

  _ReceiptCode _extractCode(String raw) {
    final text = raw.trim();
    final pgl = RegExp(
      r'(?:BATCH-)?PGL-\d{3,4}-\d{3,6}',
      caseSensitive: false,
    ).firstMatch(text);
    if (pgl != null) {
      return _ReceiptCode(
        source: DistributorAcquisitionSource.collector,
        value: pgl.group(0)!.toUpperCase(),
      );
    }

    final drn = RegExp(
      r'DRN-\d{4}-\d{6}',
      caseSensitive: false,
    ).firstMatch(text);
    if (drn != null) {
      return _ReceiptCode(
        source: DistributorAcquisitionSource.farmer,
        value: drn.group(0)!.toUpperCase(),
      );
    }

    final upper = text.toUpperCase();
    return _ReceiptCode(
      source: upper.startsWith('DRN-')
          ? DistributorAcquisitionSource.farmer
          : DistributorAcquisitionSource.collector,
      value: upper,
    );
  }

  Future<void> _handleManualSubmit() async {
    FocusScope.of(context).unfocus();
    final code = _extractCode(_codeController.text);
    if (code.value.isEmpty) {
      _notification.show(
        context,
        'Masukkan kode PGL atau DRN terlebih dahulu.',
        isError: true,
      );
      return;
    }
    await _processCode(code);
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
    await _processCode(_extractCode(rawValue));
  }

  Future<void> _processCode(_ReceiptCode code) async {
    final transaction = code.source == DistributorAcquisitionSource.collector
        ? _repository.initiateCollectorAcquisition(code.value)
        : _repository.initiateFarmerAcquisition(code.value);

    if (transaction == null) {
      await _showScanError(
        code.source == DistributorAcquisitionSource.collector
            ? 'PGL tidak valid atau sudah selesai diterima.'
            : 'DRN tidak valid atau belum tersedia dari petani.',
      );
      return;
    }

    if (!mounted) return;
    final completed = await DistributorRoutes.push<bool>(
      context,
      DistributorAcquisitionVerifyScreen(transactionId: transaction.id),
    );
    if (!mounted) return;

    if (completed == true) {
      _codeController.clear();
      _notification.show(context, '${transaction.itemCode} berhasil diterima.');
    }
    setState(() => _isHandlingScan = false);
    if (_isCameraMode) await _scannerController.start();
  }

  Future<void> _showScanError(String message) async {
    if (!mounted) return;
    _notification.show(context, message, isError: true);
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    setState(() => _isHandlingScan = false);
    if (_isCameraMode) await _scannerController.start();
  }

  Future<void> _changeMode(bool cameraMode) async {
    setState(() {
      _isCameraMode = cameraMode;
      _isHandlingScan = false;
    });
    if (cameraMode) {
      await _scannerController.start();
    } else {
      await _scannerController.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            const AppTopBar(title: 'Scan Stok Masuk'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
                children: [
                  _ScanModeToggle(
                    isCameraMode: _isCameraMode,
                    onChanged: _changeMode,
                  ),
                  const SizedBox(height: 12),
                  if (_isCameraMode)
                    _CameraScanner(
                      controller: _scannerController,
                      isHandlingScan: _isHandlingScan,
                      onDetect: _handleCameraDetect,
                    )
                  else ...[
                    TextField(
                      controller: _codeController,
                      textCapitalization: TextCapitalization.characters,
                      decoration: InputDecoration(
                        labelText: 'Kode atau URL QR',
                        hintText: 'PGL-2026-000901 atau DRN-2026-000128',
                        prefixIcon: const Icon(Icons.qr_code_2_rounded),
                        filled: true,
                        fillColor: AppColors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: _borderColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: AppColors.primaryContainer,
                            width: 2,
                          ),
                        ),
                      ),
                      onSubmitted: (_) => _handleManualSubmit(),
                    ),
                    const SizedBox(height: 12),
                    PrimaryPillButton(
                      label: 'LANJUT VALIDASI',
                      onPressed: _handleManualSubmit,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReceiptCode {
  const _ReceiptCode({required this.source, required this.value});

  final DistributorAcquisitionSource source;
  final String value;
}

class _ScanModeToggle extends StatelessWidget {
  const _ScanModeToggle({required this.isCameraMode, required this.onChanged});

  final bool isCameraMode;
  final Future<void> Function(bool) onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _borderColor),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ModeButton(
              icon: Icons.photo_camera_outlined,
              label: 'Kamera',
              selected: isCameraMode,
              onTap: () => onChanged(true),
            ),
          ),
          Expanded(
            child: _ModeButton(
              icon: Icons.keyboard_alt_outlined,
              label: 'Input Kode',
              selected: !isCameraMode,
              onTap: () => onChanged(false),
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
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryContainer : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 17,
              color: selected ? AppColors.white : AppColors.placeholder,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: selected ? AppColors.white : AppColors.placeholder,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CameraScanner extends StatelessWidget {
  const _CameraScanner({
    required this.controller,
    required this.isHandlingScan,
    required this.onDetect,
  });

  final MobileScannerController controller;
  final bool isHandlingScan;
  final ValueChanged<BarcodeCapture> onDetect;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 330,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.black,
        borderRadius: BorderRadius.circular(8),
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
          Positioned(
            top: 28,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 240,
                height: 240,
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
                    ? 'QR terbaca, menyiapkan validasi...'
                    : 'Arahkan kamera ke QR PGL atau DRN.',
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
      constraints: const BoxConstraints(maxWidth: 280),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.black.withValues(alpha: 0.58),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: AppColors.white,
        ),
      ),
    );
  }
}
