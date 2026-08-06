import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_top_bar.dart';
import '../../../shared/widgets/mobile_scanner_feedback.dart';
import '../../../shared/widgets/primary_pill_button.dart';
import '../../../shared/widgets/top_notification_banner.dart';
import '../../collector/models/collector_shipment_batch.dart';
import '../data/distributor_repository.dart';
import '../distributor_routes.dart';
import 'distributor_receipt_screen.dart';

const _borderColor = Color(0xFFE1E6DF);

// [FE - Component Rendering] Screen ini membaca QR manifest pengepul melalui
// kamera atau kode manual sebelum membuka verifikasi penerimaan distributor.
class DistributorScanQrScreen extends StatefulWidget {
  const DistributorScanQrScreen({super.key});

  @override
  State<DistributorScanQrScreen> createState() =>
      _DistributorScanQrScreenState();
}

class _DistributorScanQrScreenState extends State<DistributorScanQrScreen> {
  final _repo = DistributorRepository.instance;
  final _codeCtrl = TextEditingController();
  final _notification = TopNotification();
  final _scannerController = MobileScannerController();

  bool _isCameraMode = true;
  bool _isHandlingScan = false;

  @override
  void initState() {
    super.initState();
    _repo.addListener(_onRepoChanged);
  }

  @override
  void dispose() {
    _repo.removeListener(_onRepoChanged);
    _codeCtrl.dispose();
    _notification.dispose();
    _scannerController.dispose();
    super.dispose();
  }

  void _onRepoChanged() {
    if (mounted) setState(() {});
  }

  // [UTIL - Helper Function] Parser menerima kode PGL langsung maupun URL QR
  // agar payload FE saat ini tetap kompatibel dengan endpoint backend nanti.
  String _extractShipmentCode(String raw) {
    final text = raw.trim();
    final match = RegExp(
      r'(?:BATCH-)?PGL-\d{4}-\d{3,6}',
      caseSensitive: false,
    ).firstMatch(text);
    return (match?.group(0) ?? text).toUpperCase();
  }

  // [FE - Event Handler] Input manual memakai validator dan transisi yang
  // sama dengan kamera agar tidak terbentuk dua alur penerimaan berbeda.
  Future<void> _handleManualSubmit() async {
    FocusScope.of(context).unfocus();
    final code = _extractShipmentCode(_codeCtrl.text);
    if (code.isEmpty) {
      _notification.show(
        context,
        'Masukkan kode pengiriman terlebih dahulu.',
        isError: true,
      );
      return;
    }
    await _processShipment(code);
  }

  // [FE - Event Handler] Kamera menghentikan stream setelah QR terbaca untuk
  // mencegah manifest yang sama diproses berkali-kali.
  Future<void> _handleCameraDetect(BarcodeCapture capture) async {
    if (_isHandlingScan) return;
    final rawValue = capture.barcodes
        .map((barcode) => barcode.rawValue)
        .whereType<String>()
        .firstWhere((value) => value.trim().isNotEmpty, orElse: () => '');
    if (rawValue.isEmpty) return;

    setState(() => _isHandlingScan = true);
    await _scannerController.stop();
    await _processShipment(_extractShipmentCode(rawValue));
  }

  // [FE - Event Handler] Processor ini mengambil handover yang masih ready,
  // lalu membuka form receipt; shipment transit dapat dilanjutkan langsung.
  Future<void> _processShipment(String code) async {
    final shipment = _repo.findShipment(code);
    if (shipment == null) {
      await _showScanError('QR tidak valid atau bukan tujuan distributor.');
      return;
    }
    if (shipment.status == CollectorShipmentStatus.completed) {
      await _showScanError('Pengiriman $code sudah selesai diterima.');
      return;
    }

    if (shipment.status == CollectorShipmentStatus.readyToShip) {
      final taken = _repo.takeShipment(code);
      if (!taken) {
        await _showScanError('Pengiriman gagal diambil. Coba muat ulang data.');
        return;
      }
    }

    if (!mounted) return;
    await DistributorRoutes.push<bool>(
      context,
      DistributorReceiptScreen(shipmentCode: code),
    );
    if (!mounted) return;
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

  @override
  Widget build(BuildContext context) {
    final readyShipments = _repo.readyToPickShipments;

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            const AppTopBar(title: 'Scan QR Pengiriman'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
                children: [
                  _ScanModeToggle(
                    isCameraMode: _isCameraMode,
                    onChanged: (cameraMode) async {
                      setState(() {
                        _isCameraMode = cameraMode;
                        _isHandlingScan = false;
                      });
                      if (cameraMode) {
                        await _scannerController.start();
                      } else {
                        await _scannerController.stop();
                      }
                    },
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
                      controller: _codeCtrl,
                      textCapitalization: TextCapitalization.characters,
                      decoration: InputDecoration(
                        labelText: 'Kode / URL QR Pengiriman',
                        hintText: 'Contoh: PGL-2026-000901',
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
                      label: 'CEK PENGIRIMAN',
                      onPressed: _handleManualSubmit,
                    ),
                  ],
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Data Simulasi Tersedia',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: AppColors.black,
                          ),
                        ),
                      ),
                      Text(
                        '${readyShipments.length} pengiriman',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.placeholder,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 9),
                  if (readyShipments.isEmpty)
                    const _EmptyReadyShipment()
                  else
                    ...readyShipments.map(
                      (shipment) => Padding(
                        padding: const EdgeInsets.only(bottom: 9),
                        child: _ReadyShipmentTile(
                          shipment: shipment,
                          onTap: () => _processShipment(shipment.code),
                        ),
                      ),
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
          // [FE - Component Rendering] Frame scan dibuat kompak di area kamera
          // penuh agar tidak memanjang sampai caption instruksi.
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
                    ? 'QR terbaca, memeriksa pengiriman...'
                    : 'Arahkan kamera ke QR pengiriman pengepul.',
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

class _ReadyShipmentTile extends StatelessWidget {
  const _ReadyShipmentTile({required this.shipment, required this.onTap});

  final CollectorShipmentBatch shipment;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _borderColor),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primaryContainer.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.qr_code_2_rounded,
                size: 21,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    shipment.code,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${_formatWeight(shipment.totalWeightKg)} kg · '
                    '${shipment.totalFruitCount} butir · '
                    '${shipment.sourceBatchCodes.length} sumber',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.placeholder,
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

class _EmptyReadyShipment extends StatelessWidget {
  const _EmptyReadyShipment();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _borderColor),
      ),
      child: const Text(
        'Tidak ada pengiriman baru yang menunggu penerimaan.',
        style: TextStyle(fontSize: 12, color: AppColors.placeholder),
      ),
    );
  }
}

String _formatWeight(double value) {
  return value % 1 == 0 ? value.toStringAsFixed(0) : value.toStringAsFixed(2);
}
