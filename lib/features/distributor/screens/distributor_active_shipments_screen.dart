import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_top_bar.dart';
import '../../collector/models/collector_shipment_batch.dart';
import '../data/distributor_repository.dart';
import '../distributor_routes.dart';
import 'distributor_receipt_screen.dart';
import 'distributor_scan_qr_screen.dart';
import 'distributor_shipment_detail_screen.dart';

const _pageBackground = Color(0xFFF4F6F3);
const _borderColor = Color(0xFFE1E6DF);

// [FE - Component Rendering] Screen ini menjadi work queue distributor untuk
// shipment yang menunggu scan dan shipment transit yang menunggu penerimaan.
class DistributorActiveShipmentsScreen extends StatefulWidget {
  const DistributorActiveShipmentsScreen({super.key});

  @override
  State<DistributorActiveShipmentsScreen> createState() =>
      _DistributorActiveShipmentsScreenState();
}

class _DistributorActiveShipmentsScreenState
    extends State<DistributorActiveShipmentsScreen> {
  final _repo = DistributorRepository.instance;

  @override
  void initState() {
    super.initState();
    _repo.addListener(_onRepoChanged);
  }

  @override
  void dispose() {
    _repo.removeListener(_onRepoChanged);
    super.dispose();
  }

  void _onRepoChanged() {
    if (mounted) setState(() {});
  }

  // [FE - Event Handler] Scanner menjadi satu-satunya aksi mengambil
  // manifest ready agar handover pengepul ke distributor tetap eksplisit.
  Future<void> _openScanner() async {
    await DistributorRoutes.push(context, const DistributorScanQrScreen());
  }

  Future<void> _openDetail(CollectorShipmentBatch shipment) async {
    await DistributorRoutes.push(
      context,
      DistributorShipmentDetailScreen(shipmentCode: shipment.code),
    );
  }

  Future<void> _openReceipt(CollectorShipmentBatch shipment) async {
    await DistributorRoutes.push<bool>(
      context,
      DistributorReceiptScreen(shipmentCode: shipment.code),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ready = _repo.readyToPickShipments;
    final transit = _repo.activeShipments;

    return Scaffold(
      backgroundColor: _pageBackground,
      body: SafeArea(
        child: Column(
          children: [
            AppTopBar(
              title: 'Pengiriman Aktif',
              actions: [
                IconButton(
                  onPressed: _openScanner,
                  tooltip: 'Scan QR pengiriman',
                  icon: const Icon(
                    Icons.qr_code_scanner_rounded,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            Expanded(
              child: ready.isEmpty && transit.isEmpty
                  ? _EmptyActiveShipment(onScan: _openScanner)
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
                      children: [
                        _QueueSummary(
                          readyCount: ready.length,
                          transitCount: transit.length,
                          onScan: _openScanner,
                        ),
                        if (ready.isNotEmpty) ...[
                          const SizedBox(height: 20),
                          _SectionHeader(
                            title: 'Menunggu Diambil',
                            count: ready.length,
                          ),
                          const SizedBox(height: 9),
                          ...ready.map(
                            (shipment) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _ActiveShipmentCard(
                                shipment: shipment,
                                state: _ActiveShipmentState.ready,
                                onDetail: () => _openDetail(shipment),
                                onPrimaryAction: _openScanner,
                              ),
                            ),
                          ),
                        ],
                        if (transit.isNotEmpty) ...[
                          const SizedBox(height: 20),
                          _SectionHeader(
                            title: 'Dalam Perjalanan',
                            count: transit.length,
                          ),
                          const SizedBox(height: 9),
                          ...transit.map(
                            (shipment) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _ActiveShipmentCard(
                                shipment: shipment,
                                state: _ActiveShipmentState.transit,
                                onDetail: () => _openDetail(shipment),
                                onPrimaryAction: () => _openReceipt(shipment),
                              ),
                            ),
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

class _QueueSummary extends StatelessWidget {
  const _QueueSummary({
    required this.readyCount,
    required this.transitCount,
    required this.onScan,
  });

  final int readyCount;
  final int transitCount;
  final VoidCallback onScan;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 88, 168, 53),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _QueueMetric(
                  label: 'Menunggu scan',
                  value: '$readyCount',
                ),
              ),
              Container(width: 1, height: 38, color: const Color(0xFF8BCB70)),
              Expanded(
                child: _QueueMetric(label: 'Transit', value: '$transitCount'),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 42,
            child: OutlinedButton.icon(
              onPressed: onScan,
              icon: const Icon(Icons.qr_code_scanner_rounded, size: 18),
              label: const Text('SCAN QR PENGIRIMAN'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.white,
                side: const BorderSide(color: AppColors.white),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                textStyle: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QueueMetric extends StatelessWidget {
  const _QueueMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 23,
              fontWeight: FontWeight.w900,
              color: AppColors.white,
            ),
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: Color(0xFFEAF7E5)),
          ),
        ],
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
          '$count pengiriman',
          style: const TextStyle(fontSize: 11, color: AppColors.placeholder),
        ),
      ],
    );
  }
}

enum _ActiveShipmentState { ready, transit }

// [FE - Component Rendering] Kartu aktif mempertahankan aksi sesuai state:
// ready harus melalui scan, sedangkan transit masuk verifikasi penerimaan.
class _ActiveShipmentCard extends StatelessWidget {
  const _ActiveShipmentCard({
    required this.shipment,
    required this.state,
    required this.onDetail,
    required this.onPrimaryAction,
  });

  final CollectorShipmentBatch shipment;
  final _ActiveShipmentState state;
  final VoidCallback onDetail;
  final VoidCallback onPrimaryAction;

  @override
  Widget build(BuildContext context) {
    final isReady = state == _ActiveShipmentState.ready;
    final statusColor = isReady
        ? const Color(0xFF9A6700)
        : const Color(0xFF1D6FA4);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _borderColor),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    isReady
                        ? Icons.qr_code_2_rounded
                        : Icons.local_shipping_outlined,
                    size: 21,
                    color: statusColor,
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        shipment.code,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_formatWeight(shipment.totalWeightKg)} · '
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
                const SizedBox(width: 8),
                _StateBadge(
                  label: isReady ? 'Menunggu scan' : 'Transit',
                  color: statusColor,
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: _borderColor),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 9, 12, 11),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onDetail,
                    icon: const Icon(Icons.visibility_outlined, size: 15),
                    label: const Text('Detail'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      minimumSize: const Size.fromHeight(38),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: onPrimaryAction,
                    icon: Icon(
                      isReady
                          ? Icons.qr_code_scanner_rounded
                          : Icons.fact_check_outlined,
                      size: 15,
                    ),
                    label: Text(
                      isReady ? 'Scan untuk Ambil' : 'Verifikasi Terima',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: const Color.fromARGB(255, 88, 168, 53),
                      foregroundColor: AppColors.white,
                      minimumSize: const Size.fromHeight(38),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StateBadge extends StatelessWidget {
  const _StateBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
}

class _EmptyActiveShipment extends StatelessWidget {
  const _EmptyActiveShipment({required this.onScan});

  final VoidCallback onScan;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.local_shipping_outlined,
              size: 50,
              color: AppColors.placeholder,
            ),
            const SizedBox(height: 14),
            const Text(
              'Tidak ada pengiriman aktif',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: AppColors.black,
              ),
            ),
            const SizedBox(height: 14),
            ElevatedButton.icon(
              onPressed: onScan,
              icon: const Icon(Icons.qr_code_scanner_rounded, size: 18),
              label: const Text('Scan QR Pengiriman'),
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor: const Color.fromARGB(255, 88, 168, 53),
                foregroundColor: AppColors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatWeight(double value) {
  return value % 1 == 0
      ? '${value.toStringAsFixed(0)} kg'
      : '${value.toStringAsFixed(2)} kg';
}
