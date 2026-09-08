import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_top_bar.dart';
import '../../../shared/widgets/qr_preview.dart';
import '../../traceability/data/traceability_repository.dart';
import '../data/collector_repository.dart';
import '../models/collector_shipment_batch.dart';

// [FE - Component Rendering] Screen ini menampilkan QR batch pengiriman PGL
// untuk discan role penerima saat handover fisik.
class ShipmentQrScreen extends StatefulWidget {
  const ShipmentQrScreen({super.key, required this.shipmentCode});

  final String shipmentCode;

  @override
  State<ShipmentQrScreen> createState() => _ShipmentQrScreenState();
}

class _ShipmentQrScreenState extends State<ShipmentQrScreen> {
  final _repo = CollectorRepository.instance;

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

  @override
  Widget build(BuildContext context) {
    final shipment = _repo.findShipmentBatch(widget.shipmentCode);
    final payload = _repo.shipmentQrPayload(widget.shipmentCode);

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            const AppTopBar(title: 'QR Pengiriman'),
            Expanded(
              child: shipment == null
                  ? const _MissingShipment()
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
                      children: [
                        _ShipmentQrCard(shipment: shipment, payload: payload),
                        const SizedBox(height: 16),
                        _ShipmentInfoCard(shipment: shipment),
                        const SizedBox(height: 20),
                        _ShipmentStatusNotice(shipment: shipment),
                      ],
                    ),
            ),
          ],
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
        padding: EdgeInsets.all(28),
        child: Text(
          'Batch pengiriman tidak ditemukan.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: AppColors.placeholder),
        ),
      ),
    );
  }
}

// [FE - Component Rendering] Card ini menjadi representasi QR yang akan
// discan distributor saat handover fisik.
class _ShipmentQrCard extends StatelessWidget {
  const _ShipmentQrCard({required this.shipment, required this.payload});

  final CollectorShipmentBatch shipment;
  final String payload;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: [
          Text(
            shipment.code,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: ResponsiveQrCode(data: payload, size: 210),
          ),
          const SizedBox(height: 12),
          Text(
            payload,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              height: 1.35,
              color: AppColors.placeholder,
            ),
          ),
        ],
      ),
    );
  }
}

// [FE - Component Rendering] Card ini menampilkan isi batch pengiriman agar
// pengepul mengecek data sebelum QR diberikan ke distributor.
class _ShipmentInfoCard extends StatelessWidget {
  const _ShipmentInfoCard({required this.shipment});

  final CollectorShipmentBatch shipment;

  String _formatWeight(double value) {
    final text = value % 1 == 0
        ? value.toStringAsFixed(0)
        : value.toStringAsFixed(2);
    return '$text kg';
  }

  String _formatLineage() {
    final relations = TraceabilityRepository.instance.parentsOf(shipment.code);
    if (relations.isEmpty) return shipment.sourceBatchCodes.join(', ');
    return relations
        .map((relation) {
          final weight = relation.quantity % 1 == 0
              ? relation.quantity.toStringAsFixed(0)
              : relation.quantity.toStringAsFixed(2);
          final fruit = relation.fruitCount == null
              ? ''
              : ' / ${relation.fruitCount} butir';
          return '${relation.sourceBatchCode}: $weight ${relation.unit}$fruit';
        })
        .join('\n');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InfoRow(label: 'Status', value: shipment.status.label),
          _InfoRow(
            label: 'Tujuan',
            value: shipment.destinationName?.trim().isNotEmpty == true
                ? '${shipment.destinationType.label} - '
                      '${shipment.destinationName!.trim()}'
                : shipment.destinationType.label,
          ),
          if (shipment.destinationUserId?.trim().isNotEmpty == true)
            _InfoRow(
              label: 'ID Penerima',
              value: shipment.destinationUserId!.trim(),
            ),
          if (shipment.destinationLocation?.trim().isNotEmpty == true)
            _InfoRow(
              label: 'Lokasi',
              value: shipment.destinationLocation!.trim(),
            ),
          _InfoRow(
            label: 'Total Berat',
            value: _formatWeight(shipment.totalWeightKg),
          ),
          _InfoRow(label: 'Total Butir', value: '${shipment.totalFruitCount}'),
          _InfoRow(label: 'Komposisi Sumber', value: _formatLineage()),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 92,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.placeholder,
              ),
            ),
          ),
          const Text(
            ': ',
            style: TextStyle(fontSize: 12, color: AppColors.placeholder),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: AppColors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ShipmentStatusNotice extends StatelessWidget {
  const _ShipmentStatusNotice({required this.shipment});

  final CollectorShipmentBatch shipment;

  Color get _color {
    switch (shipment.status) {
      case CollectorShipmentStatus.readyToShip:
        return AppColors.primary;
      case CollectorShipmentStatus.sent:
        return const Color(0xFFB45309);
      case CollectorShipmentStatus.completed:
        return const Color(0xFF1D6FA4);
      case CollectorShipmentStatus.rejected:
        return const Color(0xFFD64545);
    }
  }

  IconData get _icon {
    switch (shipment.status) {
      case CollectorShipmentStatus.readyToShip:
        return Icons.qr_code_scanner_rounded;
      case CollectorShipmentStatus.sent:
        return Icons.local_shipping_outlined;
      case CollectorShipmentStatus.completed:
        return Icons.verified_rounded;
      case CollectorShipmentStatus.rejected:
        return Icons.cancel_rounded;
    }
  }

  String get _message {
    switch (shipment.status) {
      case CollectorShipmentStatus.readyToShip:
        return 'Menunggu QR discan oleh ${shipment.destinationType.label}. Status berikutnya berubah dari aksi penerima.';
      case CollectorShipmentStatus.sent:
        return 'PGL sedang menunggu validasi penerima. Pengepul tidak dapat menandai selesai sendiri.';
      case CollectorShipmentStatus.completed:
        return 'PGL sudah diterima dan divalidasi oleh penerima.';
      case CollectorShipmentStatus.rejected:
        return 'PGL ditolak saat validasi penerimaan.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _color.withValues(alpha: 0.22)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(_icon, size: 20, color: _color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _message,
              style: TextStyle(
                fontSize: 13,
                height: 1.35,
                fontWeight: FontWeight.w800,
                color: _color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
