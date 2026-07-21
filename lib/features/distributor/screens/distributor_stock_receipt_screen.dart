import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_top_bar.dart';
import '../../../shared/widgets/mobile_scanner_feedback.dart';
import '../../../shared/widgets/primary_pill_button.dart';
import '../../../shared/widgets/top_notification_banner.dart';
import '../../collector/models/collector_shipment_batch.dart';
import '../../farmer/models/harvest_batch.dart';
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
    if (upper.startsWith('DRN-')) {
      return _ReceiptCode(
        source: DistributorAcquisitionSource.farmer,
        value: upper,
      );
    }
    return _ReceiptCode(
      source: DistributorAcquisitionSource.collector,
      value: upper,
    );
  }

  Future<void> _handleManualSubmit() async {
    FocusScope.of(context).unfocus();
    final code = _extractCode(_codeCtrl.text);
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
    DistributorAcquisitionTransaction? transaction;
    if (code.source == DistributorAcquisitionSource.collector) {
      transaction = _repo.initiateCollectorAcquisition(code.value);
    } else {
      transaction = _repo.initiateFarmerAcquisition(code.value);
    }

    if (transaction == null) {
      await _showScanError(
        code.source == DistributorAcquisitionSource.collector
            ? 'Manifest PGL tidak valid atau sudah selesai diterima.'
            : 'Batch DRN tidak valid atau belum tersedia dari petani.',
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
      _codeCtrl.clear();
      _notification.show(context, '${transaction.id} berhasil diterima.');
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

  @override
  Widget build(BuildContext context) {
    final pending = _repo.pendingAcquisitionTransactions;
    final readyShipments = _repo.availableCollectorAcquisitionShipments;
    final farmerBatches = _repo.availableFarmerAcquisitionBatches;

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            const AppTopBar(title: 'Terima Stok'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
                children: [
                  _ReceiptSummary(
                    collectorCount: readyShipments.length,
                    farmerCount: farmerBatches.length,
                    pendingCount: pending.length,
                  ),
                  const SizedBox(height: 14),
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
                        labelText: 'Kode / URL QR Stok',
                        hintText:
                            'Contoh: PGL-2026-000901 atau DRN-2026-000128',
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
                      label: 'CEK STOK',
                      onPressed: _handleManualSubmit,
                    ),
                  ],
                  if (pending.isNotEmpty) ...[
                    const SizedBox(height: 22),
                    _SectionHeader(
                      title: 'T1 Menunggu T2',
                      count: pending.length,
                    ),
                    const SizedBox(height: 9),
                    ...pending.map(
                      (transaction) => Padding(
                        padding: const EdgeInsets.only(bottom: 9),
                        child: _PendingTile(
                          transaction: transaction,
                          onTap: () => _processCode(
                            _ReceiptCode(
                              source: transaction.source,
                              value: transaction.itemCode,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 22),
                  _SectionHeader(
                    title: 'Dari Pengepul',
                    count: readyShipments.length,
                  ),
                  const SizedBox(height: 9),
                  if (readyShipments.isEmpty)
                    const _EmptyTile(
                      message: 'Belum ada manifest PGL siap terima.',
                    )
                  else
                    ...readyShipments.map(
                      (shipment) => Padding(
                        padding: const EdgeInsets.only(bottom: 9),
                        child: _ShipmentTile(
                          shipment: shipment,
                          onTap: () => _processCode(
                            _ReceiptCode(
                              source: DistributorAcquisitionSource.collector,
                              value: shipment.code,
                            ),
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 14),
                  _SectionHeader(
                    title: 'Dari Petani',
                    count: farmerBatches.length,
                  ),
                  const SizedBox(height: 9),
                  if (farmerBatches.isEmpty)
                    const _EmptyTile(
                      message: 'Belum ada batch DRN siap terima.',
                    )
                  else
                    ...farmerBatches.map(
                      (batch) => Padding(
                        padding: const EdgeInsets.only(bottom: 9),
                        child: _FarmerBatchTile(
                          batch: batch,
                          onTap: () => _processCode(
                            _ReceiptCode(
                              source: DistributorAcquisitionSource.farmer,
                              value: batch.code,
                            ),
                          ),
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

class _ReceiptCode {
  const _ReceiptCode({required this.source, required this.value});

  final DistributorAcquisitionSource source;
  final String value;
}

class _ReceiptSummary extends StatelessWidget {
  const _ReceiptSummary({
    required this.collectorCount,
    required this.farmerCount,
    required this.pendingCount,
  });

  final int collectorCount;
  final int farmerCount;
  final int pendingCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 88, 168, 53),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: _Metric(label: 'PGL', value: '$collectorCount'),
          ),
          Container(width: 1, height: 38, color: const Color(0xFF8BCB70)),
          Expanded(
            child: _Metric(label: 'DRN', value: '$farmerCount'),
          ),
          Container(width: 1, height: 38, color: const Color(0xFF8BCB70)),
          Expanded(
            child: _Metric(label: 'Pending T2', value: '$pendingCount'),
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: AppColors.white,
            ),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11, color: Color(0xFFEAF7E5)),
          ),
        ],
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
                    ? 'QR terbaca, menyiapkan T2...'
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

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.count});

  final String title;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: AppColors.black,
            ),
          ),
        ),
        Text(
          '$count data',
          style: const TextStyle(fontSize: 11, color: AppColors.placeholder),
        ),
      ],
    );
  }
}

class _PendingTile extends StatelessWidget {
  const _PendingTile({required this.transaction, required this.onTap});

  final DistributorAcquisitionTransaction transaction;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _BaseTile(
      icon: Icons.pending_actions_outlined,
      code: transaction.id,
      title: '${transaction.source.label} - ${transaction.itemCode}',
      subtitle:
          '${transaction.itemName} / ${_formatWeight(transaction.expectedWeightKg)} / ${transaction.expectedFruitCount} butir',
      badge: 'Lanjut T2',
      onTap: onTap,
    );
  }
}

class _ShipmentTile extends StatelessWidget {
  const _ShipmentTile({required this.shipment, required this.onTap});

  final CollectorShipmentBatch shipment;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _BaseTile(
      icon: Icons.inventory_2_outlined,
      code: shipment.code,
      title:
          '${_formatWeight(shipment.totalWeightKg)} / ${shipment.totalFruitCount} butir',
      subtitle: '${shipment.sourceBatchCodes.length} batch sumber pengepul',
      badge: 'Terima',
      onTap: onTap,
    );
  }
}

class _FarmerBatchTile extends StatelessWidget {
  const _FarmerBatchTile({required this.batch, required this.onTap});

  final HarvestBatch batch;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _BaseTile(
      icon: Icons.agriculture_outlined,
      code: batch.code,
      title:
          'Durian ${batch.variety} / ${_formatWeight(batch.quantity)} / ${batch.fruitCount ?? 0} butir',
      subtitle: batch.farmName,
      badge: 'Terima',
      onTap: onTap,
    );
  }
}

class _BaseTile extends StatelessWidget {
  const _BaseTile({
    required this.icon,
    required this.code,
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.onTap,
  });

  final IconData icon;
  final String code;
  final String title;
  final String subtitle;
  final String badge;
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
              child: Icon(icon, size: 21, color: AppColors.primary),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    code,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.black,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.placeholder,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.primaryContainer.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                badge,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyTile extends StatelessWidget {
  const _EmptyTile({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _borderColor),
      ),
      child: Text(
        message,
        style: const TextStyle(fontSize: 12, color: AppColors.placeholder),
      ),
    );
  }
}

String _formatWeight(double value) {
  final text = value % 1 == 0
      ? value.toStringAsFixed(0)
      : value.toStringAsFixed(2);
  return '$text kg';
}
