import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_top_bar.dart';
import '../../collector/models/collector_shipment_batch.dart';
import '../../collector/models/collector_stock_summary.dart';
import '../../farmer/models/harvest_batch.dart';
import '../data/distributor_repository.dart';
import '../distributor_routes.dart';
import '../models/distributor_receipt.dart';
import 'distributor_receipt_screen.dart';

// [FE - Component Rendering] Screen ini menampilkan detail batch pengiriman
// distributor, termasuk data agregat dan provenance tree dari batch petani.
class DistributorShipmentDetailScreen extends StatefulWidget {
  const DistributorShipmentDetailScreen({
    super.key,
    required this.shipmentCode,
  });

  final String shipmentCode;

  @override
  State<DistributorShipmentDetailScreen> createState() =>
      _DistributorShipmentDetailScreenState();
}

class _DistributorShipmentDetailScreenState
    extends State<DistributorShipmentDetailScreen> {
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
    if (mounted) {
      setState(() {});
    }
  }

  // [FE - Event Handler] Navigasi ini membuka pemeriksaan kuantitas dan
  // kondisi sebelum distributor boleh menyelesaikan penerimaan shipment.
  Future<void> _openReceipt(CollectorShipmentBatch shipment) async {
    await DistributorRoutes.push<bool>(
      context,
      DistributorReceiptScreen(shipmentCode: shipment.code),
    );
  }

  @override
  Widget build(BuildContext context) {
    final shipment = _repo.findShipment(widget.shipmentCode);
    final receipt = _repo.receiptForShipment(widget.shipmentCode);

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            const AppTopBar(title: 'Detail Pengiriman'),
            Expanded(
              child: shipment == null
                  ? const _MissingShipment()
                  : _ShipmentDetailContent(
                      shipment: shipment,
                      receipt: receipt,
                      sourceBatches: _repo.sourceBatchesForShipment(shipment),
                      onConfirmArrived:
                          shipment.status == CollectorShipmentStatus.sent
                          ? () => _openReceipt(shipment)
                          : null,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// [FE - Component Rendering] Konten utama ini menyusun section detail agar
// build method screen tetap tipis dan mudah dipindah ke API response nanti.
class _ShipmentDetailContent extends StatelessWidget {
  const _ShipmentDetailContent({
    required this.shipment,
    required this.receipt,
    required this.sourceBatches,
    required this.onConfirmArrived,
  });

  final CollectorShipmentBatch shipment;
  final DistributorReceipt? receipt;
  final List<HarvestBatch> sourceBatches;
  final VoidCallback? onConfirmArrived;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      children: [
        _HeaderPanel(shipment: shipment),
        const SizedBox(height: 16),
        _SummaryGrid(shipment: shipment),
        if (receipt != null) ...[
          const SizedBox(height: 20),
          const _SectionTitle(
            icon: Icons.fact_check_outlined,
            title: 'Hasil Penerimaan Distributor',
          ),
          const SizedBox(height: 10),
          _ReceiptPanel(receipt: receipt!),
        ],
        const SizedBox(height: 20),
        _SectionTitle(
          icon: Icons.stacked_bar_chart_rounded,
          title: 'Komposisi Pengiriman',
        ),
        const SizedBox(height: 10),
        _BreakdownList(
          title: 'Grade/Mutu',
          items: shipment.gradeBreakdown,
          emptyText: 'Belum ada breakdown grade.',
        ),
        const SizedBox(height: 10),
        _BreakdownList(
          title: 'Varietas',
          items: shipment.varietyBreakdown,
          emptyText: 'Belum ada breakdown varietas.',
        ),
        const SizedBox(height: 20),
        _SectionTitle(
          icon: Icons.account_tree_outlined,
          title: 'Provenance Tree',
        ),
        const SizedBox(height: 10),
        _ProvenanceList(shipment: shipment, sourceBatches: sourceBatches),
        const SizedBox(height: 20),
        _SectionTitle(icon: Icons.timeline_rounded, title: 'Timeline'),
        const SizedBox(height: 10),
        _TimelinePanel(shipment: shipment),
        if (shipment.warehouseNote != null &&
            shipment.warehouseNote!.trim().isNotEmpty) ...[
          const SizedBox(height: 20),
          _SectionTitle(icon: Icons.notes_rounded, title: 'Catatan Gudang'),
          const SizedBox(height: 10),
          _NotePanel(note: shipment.warehouseNote!),
        ],
        if (onConfirmArrived != null) ...[
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: onConfirmArrived,
              icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
              label: const Text(
                'VERIFIKASI PENERIMAAN',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _HeaderPanel extends StatelessWidget {
  const _HeaderPanel({required this.shipment});

  final CollectorShipmentBatch shipment;

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(shipment.status);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.local_shipping_outlined,
              color: statusColor,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  shipment.code,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: AppColors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${shipment.sourceBatchCodes.length} batch petani digabung',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.subtitle,
                  ),
                ),
                const SizedBox(height: 8),
                _StatusPill(status: shipment.status),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryGrid extends StatelessWidget {
  const _SummaryGrid({required this.shipment});

  final CollectorShipmentBatch shipment;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _SummaryTile(
          icon: Icons.scale_outlined,
          label: 'Total Berat',
          value: _formatWeight(shipment.totalWeightKg),
        ),
        _SummaryTile(
          icon: Icons.eco_outlined,
          label: 'Total Butir',
          value: '${shipment.totalFruitCount}',
        ),
        _SummaryTile(
          icon: Icons.inventory_2_outlined,
          label: 'Source Batch',
          value: '${shipment.sourceBatchCodes.length}',
        ),
        _SummaryTile(
          icon: Icons.event_available_outlined,
          label: 'Dikemas',
          value: _formatShortDate(shipment.packagedAt),
        ),
      ],
    );
  }
}

// [FE - Component Rendering] Panel receipt membandingkan manifest pengepul
// dengan hasil aktual distributor sebagai bukti rekonsiliasi penerimaan.
class _ReceiptPanel extends StatelessWidget {
  const _ReceiptPanel({required this.receipt});

  final DistributorReceipt receipt;

  @override
  Widget build(BuildContext context) {
    final differenceColor = receipt.hasDiscrepancy
        ? const Color(0xFF9A6700)
        : AppColors.primary;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Icon(
                  receipt.hasDiscrepancy
                      ? Icons.warning_amber_rounded
                      : Icons.verified_outlined,
                  size: 22,
                  color: differenceColor,
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        receipt.hasDiscrepancy
                            ? 'Diterima dengan selisih'
                            : 'Sesuai dengan manifest',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: differenceColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _formatDateTime(receipt.receivedAt),
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.placeholder,
                        ),
                      ),
                    ],
                  ),
                ),
                _ConditionBadge(condition: receipt.condition),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE5E7EB)),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                _ReceiptComparisonRow(
                  label: 'Berat',
                  expected: _formatWeight(receipt.expectedWeightKg),
                  received: _formatWeight(receipt.receivedWeightKg),
                  difference: '${_signedDouble(receipt.weightDifferenceKg)} kg',
                  hasDifference: receipt.weightDifferenceKg.abs() > 0.01,
                ),
                const SizedBox(height: 12),
                _ReceiptComparisonRow(
                  label: 'Jumlah',
                  expected: '${receipt.expectedFruitCount} butir',
                  received: '${receipt.receivedFruitCount} butir',
                  difference: '${_signedInt(receipt.fruitDifference)} butir',
                  hasDifference: receipt.fruitDifference != 0,
                ),
                const SizedBox(height: 12),
                _ReceiptMetaRow(
                  icon: Icons.location_on_outlined,
                  label: 'Lokasi Terima',
                  value: receipt.destinationLocation,
                ),
                if (receipt.temperatureCelsius != null) ...[
                  const SizedBox(height: 8),
                  _ReceiptMetaRow(
                    icon: Icons.thermostat_outlined,
                    label: 'Suhu Terima',
                    value:
                        '${_formatTemperature(receipt.temperatureCelsius!)} C',
                  ),
                ],
              ],
            ),
          ),
          if (receipt.discrepancyNote?.isNotEmpty == true)
            _ReceiptNote(
              label: 'Alasan Selisih',
              text: receipt.discrepancyNote!,
              color: const Color(0xFF9A6700),
            ),
          if (receipt.qualityNote?.isNotEmpty == true)
            _ReceiptNote(
              label: 'Catatan Pemeriksaan',
              text: receipt.qualityNote!,
              color: AppColors.subtitle,
            ),
        ],
      ),
    );
  }
}

class _ConditionBadge extends StatelessWidget {
  const _ConditionBadge({required this.condition});

  final DistributorReceiptCondition condition;

  @override
  Widget build(BuildContext context) {
    final color = switch (condition) {
      DistributorReceiptCondition.good => AppColors.primary,
      DistributorReceiptCondition.minorDamage => const Color(0xFF9A6700),
      DistributorReceiptCondition.damaged => const Color(0xFFC83B3B),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        condition.label,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
}

class _ReceiptComparisonRow extends StatelessWidget {
  const _ReceiptComparisonRow({
    required this.label,
    required this.expected,
    required this.received,
    required this.difference,
    required this.hasDifference,
  });

  final String label;
  final String expected;
  final String received;
  final String difference;
  final bool hasDifference;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 56,
          child: Text(
            label,
            style: const TextStyle(fontSize: 11, color: AppColors.placeholder),
          ),
        ),
        Expanded(
          child: _ComparisonValue(label: 'Manifest', value: expected),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _ComparisonValue(label: 'Diterima', value: received),
        ),
        const SizedBox(width: 8),
        Text(
          difference,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: hasDifference ? const Color(0xFF9A6700) : AppColors.primary,
          ),
        ),
      ],
    );
  }
}

class _ReceiptMetaRow extends StatelessWidget {
  const _ReceiptMetaRow({
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
        Icon(icon, size: 17, color: AppColors.primary),
        const SizedBox(width: 8),
        SizedBox(
          width: 92,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: AppColors.placeholder,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: AppColors.subtitle,
            ),
          ),
        ),
      ],
    );
  }
}

class _ComparisonValue extends StatelessWidget {
  const _ComparisonValue({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 9, color: AppColors.placeholder),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: AppColors.subtitle,
          ),
        ),
      ],
    );
  }
}

class _ReceiptNote extends StatelessWidget {
  const _ReceiptNote({
    required this.label,
    required this.text,
    required this.color,
  });

  final String label;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
      decoration: const BoxDecoration(
        color: Color(0xFFF8F9F7),
        border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            text,
            style: const TextStyle(
              fontSize: 11,
              height: 1.4,
              color: AppColors.subtitle,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final width = (MediaQuery.sizeOf(context).width - 50) / 2;
    return SizedBox(
      width: width,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: AppColors.primary),
            const SizedBox(height: 8),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: AppColors.black,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.placeholder,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BreakdownList extends StatelessWidget {
  const _BreakdownList({
    required this.title,
    required this.items,
    required this.emptyText,
  });

  final String title;
  final List<CollectorStockBreakdown> items;
  final String emptyText;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: AppColors.black,
            ),
          ),
          const SizedBox(height: 10),
          if (items.isEmpty)
            Text(
              emptyText,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.placeholder,
              ),
            )
          else
            ...items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _BreakdownRow(item: item),
              ),
            ),
        ],
      ),
    );
  }
}

class _BreakdownRow extends StatelessWidget {
  const _BreakdownRow({required this.item});

  final CollectorStockBreakdown item;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            item.label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.subtitle,
            ),
          ),
        ),
        Text(
          '${_formatWeight(item.totalWeightKg)} • ${item.totalFruitCount} butir',
          style: const TextStyle(fontSize: 12, color: AppColors.placeholder),
        ),
      ],
    );
  }
}

class _ProvenanceList extends StatelessWidget {
  const _ProvenanceList({required this.shipment, required this.sourceBatches});

  final CollectorShipmentBatch shipment;
  final List<HarvestBatch> sourceBatches;

  @override
  Widget build(BuildContext context) {
    final sourceByCode = {for (final batch in sourceBatches) batch.code: batch};
    return Column(
      children: shipment.sourceBatchCodes.map((code) {
        final batch = sourceByCode[code];
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _ProvenanceItem(code: code, batch: batch),
        );
      }).toList(),
    );
  }
}

class _ProvenanceItem extends StatelessWidget {
  const _ProvenanceItem({required this.code, required this.batch});

  final String code;
  final HarvestBatch? batch;

  @override
  Widget build(BuildContext context) {
    // [FE - State Management] Local variable ini membuat nullable source batch
    // aman dibaca setelah pengecekan null di blok rendering.
    final resolvedBatch = batch;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.spa_outlined,
              color: AppColors.primary,
              size: 19,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: resolvedBatch == null
                ? Text(
                    '$code\nData batch sumber belum ditemukan di mock store.',
                    style: const TextStyle(
                      fontSize: 12,
                      height: 1.4,
                      color: AppColors.placeholder,
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        resolvedBatch.code,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: AppColors.black,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Durian ${resolvedBatch.variety} • ${resolvedBatch.farmName}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.subtitle,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_formatWeight(resolvedBatch.receivedQuantity ?? resolvedBatch.quantity)} • ${resolvedBatch.receivedFruitCount ?? resolvedBatch.fruitCount ?? 0} butir • ${resolvedBatch.status.label}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.placeholder,
                        ),
                      ),
                      const SizedBox(height: 12),
                      // [FE - Component Rendering] Detail provenance ini
                      // menampilkan warisan data dari petani dan validasi
                      // pengepul di dalam satu source batch DRN.
                      _SourceTraceDetails(batch: resolvedBatch),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _SourceTraceDetails extends StatelessWidget {
  const _SourceTraceDetails({required this.batch});

  final HarvestBatch batch;

  @override
  Widget build(BuildContext context) {
    // [FE - Component Rendering] Expansion ini menjaga provenance tetap
    // ringkas; detail lintas role dibuka hanya ketika distributor membutuhkannya.
    // [FE - Component Rendering] Material lokal menjadi surface ListTile
    // internal ExpansionTile agar ink splash tidak tertutup card provenance.
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 10),
          childrenPadding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
          backgroundColor: const Color(0xFFF7FAF5),
          collapsedBackgroundColor: const Color(0xFFF7FAF5),
          iconColor: AppColors.primary,
          collapsedIconColor: AppColors.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: const BorderSide(color: Color(0xFFDCE8D7)),
          ),
          collapsedShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: const BorderSide(color: Color(0xFFDCE8D7)),
          ),
          leading: const Icon(
            Icons.account_tree_outlined,
            size: 18,
            color: AppColors.primary,
          ),
          title: const Text(
            'Data asal & verifikasi',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
            ),
          ),
          children: [
            // [FE - Component Rendering] Blok ini adalah data asal dari petani
            // yang diwariskan ke distributor melalui provenance source batch.
            _TraceDetailBlock(
              title: 'Data dari Petani',
              icon: Icons.agriculture_outlined,
              children: [
                _TraceDetailLine(label: 'Varietas', value: batch.variety),
                _TraceDetailLine(label: 'Kebun', value: batch.farmName),
                _TraceDetailLine(
                  label: 'Tanggal Panen',
                  value: _formatShortDate(batch.harvestDate),
                ),
                _TraceDetailLine(
                  label: 'Jumlah Awal',
                  value:
                      '${_formatWeight(batch.quantity)} • ${batch.fruitCount ?? 0} butir',
                ),
                _TraceDetailLine(
                  label: 'Grade Awal',
                  value: 'Grade ${batch.grade}',
                ),
                _TraceDetailLine(
                  label: 'Metode Panen',
                  value: _valueOrDash(batch.harvestMethod),
                ),
                _TraceDetailLine(
                  label: 'Pupuk',
                  value: _valueOrDash(batch.fertilizer),
                ),
                _TraceDetailLine(
                  label: 'Kematangan',
                  value: _valueOrDash(batch.maturityLevel),
                ),
                _TraceDetailLine(
                  label: 'Estimasi Simpan',
                  value: _valueOrDash(batch.shelfLifeEstimate),
                ),
                _TraceDetailLine(
                  label: 'Foto Durian',
                  value: batch.photoPath == null ? 'Tidak ada' : 'Tersimpan',
                ),
                if (batch.notes != null && batch.notes!.trim().isNotEmpty)
                  _TraceDetailLine(label: 'Catatan', value: batch.notes!),
              ],
            ),
            const SizedBox(height: 10),
            // [FE - Component Rendering] Blok ini adalah hasil validasi pengepul
            // sehingga distributor tahu data mana yang sudah dikoreksi secara fisik.
            _TraceDetailBlock(
              title: 'Verifikasi Pengepul',
              icon: Icons.fact_check_outlined,
              children: [
                _TraceDetailLine(
                  label: 'Berat Diterima',
                  value: batch.receivedQuantity == null
                      ? '-'
                      : _formatWeight(batch.receivedQuantity!),
                ),
                _TraceDetailLine(
                  label: 'Butir Diterima',
                  value: batch.receivedFruitCount == null
                      ? '-'
                      : '${batch.receivedFruitCount} butir',
                ),
                _TraceDetailLine(
                  label: 'Grade Riil',
                  value: batch.verifiedGrade == null
                      ? '-'
                      : 'Grade ${batch.verifiedGrade}',
                ),
                _TraceDetailLine(
                  label: 'Diverifikasi Oleh',
                  value: _valueOrDash(batch.verifiedBy),
                ),
                _TraceDetailLine(
                  label: 'Waktu Verifikasi',
                  value: batch.verifiedAt == null
                      ? '-'
                      : _formatDateTime(batch.verifiedAt!),
                ),
                if (batch.gradeBreakdown.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  const Text(
                    'Breakdown Grade',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: AppColors.placeholder,
                    ),
                  ),
                  const SizedBox(height: 6),
                  ...batch.gradeBreakdown.map(
                    (item) => _TraceGradeLine(item: item),
                  ),
                ],
                if (batch.qualityNotes != null &&
                    batch.qualityNotes!.trim().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _TraceNotice(text: batch.qualityNotes!),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TraceDetailBlock extends StatelessWidget {
  const _TraceDetailBlock({
    required this.title,
    required this.icon,
    required this.children,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 17, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: AppColors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }
}

class _TraceDetailLine extends StatelessWidget {
  const _TraceDetailLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 112,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.placeholder,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                height: 1.35,
                color: AppColors.subtitle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TraceGradeLine extends StatelessWidget {
  const _TraceGradeLine({required this.item});

  final BatchGradeBreakdown item;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Grade ${item.grade}',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: AppColors.subtitle,
              ),
            ),
          ),
          Text(
            '${_formatWeight(item.weightKg)} • ${item.fruitCount} butir',
            style: const TextStyle(fontSize: 12, color: AppColors.placeholder),
          ),
        ],
      ),
    );
  }
}

class _TraceNotice extends StatelessWidget {
  const _TraceNotice({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          height: 1.4,
          color: AppColors.subtitle,
        ),
      ),
    );
  }
}

class _TimelinePanel extends StatelessWidget {
  const _TimelinePanel({required this.shipment});

  final CollectorShipmentBatch shipment;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: [
          _TimelineItem(
            title: 'Dikemas Pengepul',
            subtitle: _formatDateTime(shipment.packagedAt),
            isDone: true,
          ),
          _TimelineItem(
            title: 'Diambil Distributor',
            subtitle: shipment.sentAt == null
                ? 'Menunggu scan QR distributor'
                : _formatDateTime(shipment.sentAt!),
            isDone: shipment.sentAt != null,
          ),
          _TimelineItem(
            title: 'Tiba di Gudang Distributor',
            subtitle: shipment.completedAt == null
                ? 'Menunggu konfirmasi tiba'
                : _formatDateTime(shipment.completedAt!),
            isDone: shipment.completedAt != null,
            isLast: true,
          ),
        ],
      ),
    );
  }
}

class _TimelineItem extends StatelessWidget {
  const _TimelineItem({
    required this.title,
    required this.subtitle,
    required this.isDone,
    this.isLast = false,
  });

  final String title;
  final String subtitle;
  final bool isDone;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final color = isDone ? AppColors.primary : const Color(0xFFCBD5E1);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              child: Icon(
                isDone ? Icons.check_rounded : Icons.circle_outlined,
                size: 14,
                color: AppColors.white,
              ),
            ),
            if (!isLast)
              Container(width: 2, height: 36, color: const Color(0xFFE5E7EB)),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: AppColors.black,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.placeholder,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _NotePanel extends StatelessWidget {
  const _NotePanel({required this.note});

  final String note;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Text(
        note,
        style: const TextStyle(
          fontSize: 13,
          height: 1.45,
          color: AppColors.subtitle,
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w900,
            color: AppColors.black,
          ),
        ),
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final CollectorShipmentStatus status;

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w900,
          color: color,
        ),
      ),
    );
  }
}

class _MissingShipment extends StatelessWidget {
  const _MissingShipment();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'Data pengiriman tidak ditemukan.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: AppColors.placeholder),
        ),
      ),
    );
  }
}

Color _statusColor(CollectorShipmentStatus status) {
  switch (status) {
    case CollectorShipmentStatus.readyToShip:
      return AppColors.primary;
    case CollectorShipmentStatus.sent:
      return const Color(0xFFB45309);
    case CollectorShipmentStatus.completed:
      return const Color(0xFF1D6FA4);
  }
}

String _formatWeight(double value) {
  final text = value % 1 == 0
      ? value.toStringAsFixed(0)
      : value.toStringAsFixed(2);
  return '$text kg';
}

String _signedDouble(double value) {
  final prefix = value > 0 ? '+' : '';
  final text = value % 1 == 0
      ? value.toStringAsFixed(0)
      : value.toStringAsFixed(2);
  return '$prefix$text';
}

String _signedInt(int value) {
  return value > 0 ? '+$value' : '$value';
}

String _formatTemperature(double value) {
  return value % 1 == 0 ? value.toStringAsFixed(0) : value.toStringAsFixed(1);
}

String _valueOrDash(String? value) {
  final cleanValue = value?.trim() ?? '';
  return cleanValue.isEmpty ? '-' : cleanValue;
}

String _formatShortDate(DateTime date) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'Mei',
    'Jun',
    'Jul',
    'Agu',
    'Sep',
    'Okt',
    'Nov',
    'Des',
  ];
  return '${date.day} ${months[date.month - 1]}';
}

String _formatDateTime(DateTime date) {
  final dateText = _formatShortDate(date);
  final hour = date.hour.toString().padLeft(2, '0');
  final minute = date.minute.toString().padLeft(2, '0');
  return '$dateText ${date.year}, $hour:$minute';
}
