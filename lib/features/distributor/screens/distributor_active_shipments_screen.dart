import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_top_bar.dart';
import '../../collector/models/collector_shipment_batch.dart';
import '../../farmer/models/harvest_batch.dart';
import '../data/distributor_repository.dart';
import '../distributor_routes.dart';
import '../models/distributor_acquisition_transaction.dart';
import 'distributor_acquisition_verify_screen.dart';
import 'distributor_receipt_screen.dart';
import 'distributor_stock_receipt_screen.dart';
import 'distributor_shipment_detail_screen.dart';

const _pageBackground = Color(0xFFF4F6F3);
const _borderColor = Color(0xFFE1E6DF);

enum _ShipmentStatusFilter { all, ready, transit }

// [FE - Component Rendering] Screen ini menjadi work queue stok masuk:
// distributor scan PGL/DRN, melihat trace, lalu memvalidasi kondisi aktual.
class DistributorActiveShipmentsScreen extends StatefulWidget {
  const DistributorActiveShipmentsScreen({super.key});

  @override
  State<DistributorActiveShipmentsScreen> createState() =>
      _DistributorActiveShipmentsScreenState();
}

class _DistributorActiveShipmentsScreenState
    extends State<DistributorActiveShipmentsScreen> {
  final _repo = DistributorRepository.instance;
  _ShipmentStatusFilter _statusFilter = _ShipmentStatusFilter.all;

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

  // [FE - Event Handler] Scanner mengidentifikasi stok PGL/DRN lalu membuka
  // validasi penerimaan tanpa memaknai scan sebagai proses jemput barang.
  Future<void> _openScanner() async {
    await DistributorRoutes.push(
      context,
      const DistributorStockReceiptScreen(),
    );
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

  Future<void> _openCollectorValidation(CollectorShipmentBatch shipment) async {
    final transaction = _repo.initiateCollectorAcquisition(shipment.code);
    if (transaction == null) {
      await _openDetail(shipment);
      return;
    }

    await DistributorRoutes.push<bool>(
      context,
      DistributorAcquisitionVerifyScreen(transactionId: transaction.id),
    );
  }

  Future<void> _openFarmerValidation(HarvestBatch batch) async {
    final transaction = _repo.initiateFarmerAcquisition(batch.code);
    if (transaction == null) {
      return;
    }

    await DistributorRoutes.push<bool>(
      context,
      DistributorAcquisitionVerifyScreen(transactionId: transaction.id),
    );
  }

  Future<void> _openPendingValidation(
    DistributorAcquisitionTransaction transaction,
  ) async {
    await DistributorRoutes.push<bool>(
      context,
      DistributorAcquisitionVerifyScreen(transactionId: transaction.id),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pending = _repo.pendingAcquisitionTransactions;
    final pendingCodes = pending.map((item) => item.itemCode).toSet();
    final pendingCollector = pending
        .where((item) => item.source == DistributorAcquisitionSource.collector)
        .toList();
    final pendingFarmer = pending
        .where((item) => item.source == DistributorAcquisitionSource.farmer)
        .toList();
    final ready = _repo.readyToPickShipments
        .where((shipment) => !pendingCodes.contains(shipment.code))
        .toList();
    final transit = _repo.activeShipments;
    final farmerBatches = _repo.availableFarmerAcquisitionBatches
        .where((batch) => !pendingCodes.contains(batch.code))
        .toList();
    final showReady =
        _statusFilter == _ShipmentStatusFilter.all ||
        _statusFilter == _ShipmentStatusFilter.ready;
    final showTransit =
        _statusFilter == _ShipmentStatusFilter.all ||
        _statusFilter == _ShipmentStatusFilter.transit;
    final hasVisibleShipments =
        (showReady &&
            (ready.isNotEmpty ||
                farmerBatches.isNotEmpty ||
                pendingCollector.isNotEmpty ||
                pendingFarmer.isNotEmpty)) ||
        (showTransit && transit.isNotEmpty);
    final totalReadyCount =
        ready.length +
        farmerBatches.length +
        pendingCollector.length +
        pendingFarmer.length;
    final totalActiveCount = totalReadyCount + transit.length;

    return Scaffold(
      backgroundColor: _pageBackground,
      body: SafeArea(
        child: Column(
          children: [
            AppTopBar(
              title: 'Stok Masuk Aktif',
              actions: [
                IconButton(
                  onPressed: _openScanner,
                  tooltip: 'Scan stok masuk',
                  icon: const Icon(
                    Icons.qr_code_scanner_rounded,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            Expanded(
              child: totalActiveCount == 0
                  ? _EmptyActiveShipment(onScan: _openScanner)
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
                      children: [
                        _QueueSummary(
                          readyCount: totalReadyCount,
                          transitCount: transit.length,
                          onScan: _openScanner,
                        ),
                        const SizedBox(height: 14),
                        _StatusFilterBar(
                          selected: _statusFilter,
                          readyCount: totalReadyCount,
                          transitCount: transit.length,
                          onChanged: (filter) =>
                              setState(() => _statusFilter = filter),
                        ),
                        if (!hasVisibleShipments) ...[
                          const SizedBox(height: 18),
                          _FilteredEmptyState(filter: _statusFilter),
                        ],
                        if (showReady && pending.isNotEmpty) ...[
                          const SizedBox(height: 20),
                          _SectionHeader(
                            title: 'T1 Menunggu T2',
                            count: pending.length,
                          ),
                          const SizedBox(height: 9),
                          ...pending.map(
                            (transaction) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _PendingAcquisitionCard(
                                transaction: transaction,
                                onPrimaryAction: () =>
                                    _openPendingValidation(transaction),
                              ),
                            ),
                          ),
                        ],
                        if (showReady && ready.isNotEmpty) ...[
                          const SizedBox(height: 20),
                          _SectionHeader(
                            title: 'PGL Siap Divalidasi',
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
                                onPrimaryAction: () =>
                                    _openCollectorValidation(shipment),
                              ),
                            ),
                          ),
                        ],
                        if (showReady && farmerBatches.isNotEmpty) ...[
                          const SizedBox(height: 20),
                          _SectionHeader(
                            title: 'DRN Petani Siap Divalidasi',
                            count: farmerBatches.length,
                          ),
                          const SizedBox(height: 9),
                          ...farmerBatches.map(
                            (batch) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _FarmerBatchCard(
                                batch: batch,
                                onPrimaryAction: () =>
                                    _openFarmerValidation(batch),
                              ),
                            ),
                          ),
                        ],
                        if (showTransit && transit.isNotEmpty) ...[
                          const SizedBox(height: 20),
                          _SectionHeader(
                            title: 'PGL Perlu Receipt',
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
                child: _QueueMetric(label: 'Siap T2', value: '$readyCount'),
              ),
              Container(width: 1, height: 38, color: const Color(0xFF8BCB70)),
              Expanded(
                child: _QueueMetric(label: 'Receipt', value: '$transitCount'),
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
              label: const Text('SCAN STOK MASUK'),
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

class _StatusFilterBar extends StatelessWidget {
  const _StatusFilterBar({
    required this.selected,
    required this.readyCount,
    required this.transitCount,
    required this.onChanged,
  });

  final _ShipmentStatusFilter selected;
  final int readyCount;
  final int transitCount;
  final ValueChanged<_ShipmentStatusFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _borderColor),
      ),
      child: Row(
        children: [
          _StatusFilterButton(
            label: 'Semua',
            count: readyCount + transitCount,
            selected: selected == _ShipmentStatusFilter.all,
            onTap: () => onChanged(_ShipmentStatusFilter.all),
          ),
          _StatusFilterButton(
            label: 'Siap T2',
            count: readyCount,
            selected: selected == _ShipmentStatusFilter.ready,
            onTap: () => onChanged(_ShipmentStatusFilter.ready),
          ),
          _StatusFilterButton(
            label: 'Receipt',
            count: transitCount,
            selected: selected == _ShipmentStatusFilter.transit,
            onTap: () => onChanged(_ShipmentStatusFilter.transit),
          ),
        ],
      ),
    );
  }
}

class _StatusFilterButton extends StatelessWidget {
  const _StatusFilterButton({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFE9F5E4) : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            '$label ($count)',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: selected ? AppColors.primary : AppColors.placeholder,
            ),
          ),
        ),
      ),
    );
  }
}

class _PendingAcquisitionCard extends StatelessWidget {
  const _PendingAcquisitionCard({
    required this.transaction,
    required this.onPrimaryAction,
  });

  final DistributorAcquisitionTransaction transaction;
  final VoidCallback onPrimaryAction;

  @override
  Widget build(BuildContext context) {
    final isFarmer = transaction.source == DistributorAcquisitionSource.farmer;
    final statusColor = const Color(0xFF9A6700);

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
                    isFarmer
                        ? Icons.agriculture_outlined
                        : Icons.inventory_2_outlined,
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
                        transaction.itemCode,
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
                        '${transaction.source.label} / ${transaction.supplierLabel} / '
                        '${_formatWeight(transaction.expectedWeightKg)} / '
                        '${transaction.expectedFruitCount} butir',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.placeholder,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _StateBadge(label: 'T1 aktif', color: statusColor),
              ],
            ),
          ),
          const Divider(height: 1, color: _borderColor),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 9, 12, 11),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onPrimaryAction,
                icon: const Icon(Icons.fact_check_outlined, size: 15),
                label: const Text('Lanjut Validasi T2'),
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  backgroundColor: const Color.fromARGB(255, 88, 168, 53),
                  foregroundColor: AppColors.white,
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
          ),
        ],
      ),
    );
  }
}

class _FarmerBatchCard extends StatelessWidget {
  const _FarmerBatchCard({required this.batch, required this.onPrimaryAction});

  final HarvestBatch batch;
  final VoidCallback onPrimaryAction;

  @override
  Widget build(BuildContext context) {
    final statusColor = batch.status.color;

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
                    Icons.agriculture_outlined,
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
                        batch.code,
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
                        'Dari petani ${batch.farmerId} / ${batch.farmName} / '
                        'Durian ${batch.variety} / ${_formatWeight(batch.quantity)} / '
                        '${batch.fruitCount ?? 0} butir',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.placeholder,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _StateBadge(label: 'DRN siap', color: statusColor),
              ],
            ),
          ),
          const Divider(height: 1, color: _borderColor),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 9, 12, 11),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onPrimaryAction,
                icon: const Icon(Icons.qr_code_scanner_rounded, size: 15),
                label: const Text('Validasi Terima'),
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  backgroundColor: const Color.fromARGB(255, 88, 168, 53),
                  foregroundColor: AppColors.white,
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
          '$count data',
          style: const TextStyle(fontSize: 11, color: AppColors.placeholder),
        ),
      ],
    );
  }
}

class _FilteredEmptyState extends StatelessWidget {
  const _FilteredEmptyState({required this.filter});

  final _ShipmentStatusFilter filter;

  @override
  Widget build(BuildContext context) {
    final message = switch (filter) {
      _ShipmentStatusFilter.ready => 'Tidak ada stok yang perlu divalidasi.',
      _ShipmentStatusFilter.transit => 'Tidak ada PGL yang perlu receipt.',
      _ShipmentStatusFilter.all => 'Tidak ada stok masuk aktif.',
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _borderColor),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.filter_alt_off_outlined,
            size: 32,
            color: AppColors.placeholder,
          ),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: AppColors.subtitle,
            ),
          ),
        ],
      ),
    );
  }
}

enum _ActiveShipmentState { ready, transit }

// [FE - Component Rendering] Kartu aktif mempertahankan aksi sesuai state:
// PGL baru masuk validasi T2, sedangkan data sent lama tetap bisa receipt.
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
                        'Dari pengepul ${shipment.collectorId} / '
                        '${_formatWeight(shipment.totalWeightKg)} / '
                        '${shipment.totalFruitCount} butir / '
                        '${shipment.sourceBatchCodes.length} batch sumber',
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
                  label: isReady ? 'Siap validasi' : 'Perlu receipt',
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
                      isReady ? 'Validasi Terima' : 'Verifikasi Terima',
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
              'Tidak ada stok masuk aktif',
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
              label: const Text('Scan Stok Masuk'),
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
