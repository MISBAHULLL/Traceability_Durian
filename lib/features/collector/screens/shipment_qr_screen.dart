import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_top_bar.dart';
import '../../../shared/widgets/primary_pill_button.dart';
import '../../../shared/widgets/qr_preview.dart';
import '../../../shared/widgets/top_notification_banner.dart';
import '../data/collector_repository.dart';
import '../models/collector_shipment_batch.dart';

// [FE - Component Rendering] Screen ini menampilkan QR batch pengiriman PGL
// dan simulasi konfirmasi distributor pada fase FE-only.
class ShipmentQrScreen extends StatefulWidget {
  const ShipmentQrScreen({super.key, required this.shipmentCode});

  final String shipmentCode;

  @override
  State<ShipmentQrScreen> createState() => _ShipmentQrScreenState();
}

class _ShipmentQrScreenState extends State<ShipmentQrScreen> {
  final _repo = CollectorRepository.instance;
  final _notification = TopNotification();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _repo.addListener(_onRepoChanged);
  }

  @override
  void dispose() {
    _repo.removeListener(_onRepoChanged);
    _notification.dispose();
    super.dispose();
  }

  void _onRepoChanged() {
    if (mounted) setState(() {});
  }

  // [FE - Event Handler] Handler ini mensimulasikan pihak tujuan berhasil
  // scan QR lalu mengonfirmasi pengiriman mulai berjalan.
  Future<void> _markSent() async {
    setState(() => _isSubmitting = true);
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;

    final ok = _repo.markShipmentSent(widget.shipmentCode);
    setState(() => _isSubmitting = false);
    final shipment = _repo.findShipmentBatch(widget.shipmentCode);
    final receiver = shipment?.destinationType.label ?? 'Penerima';
    _notification.show(
      context,
      ok
          ? '$receiver mengonfirmasi batch dikirim.'
          : 'Status batch tidak bisa diubah.',
      isError: !ok,
    );
  }

  // [FE - Event Handler] Handler ini mensimulasikan konfirmasi akhir dari
  // distributor bahwa batch pengiriman selesai diterima.
  Future<void> _completeShipment() async {
    setState(() => _isSubmitting = true);
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;

    final ok = _repo.completeShipment(widget.shipmentCode);
    setState(() => _isSubmitting = false);
    _notification.show(
      context,
      ok
          ? 'Pengiriman selesai dikonfirmasi.'
          : 'Status batch tidak bisa diubah.',
      isError: !ok,
    );
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
                        if (shipment.status ==
                            CollectorShipmentStatus.readyToShip)
                          PrimaryPillButton(
                            label:
                                'SIMULASI ${shipment.destinationType.label.toUpperCase()} KONFIRMASI',
                            onPressed: _isSubmitting ? null : _markSent,
                            isLoading: _isSubmitting,
                          )
                        else if (shipment.status ==
                            CollectorShipmentStatus.sent)
                          PrimaryPillButton(
                            label: 'TANDAI SELESAI',
                            onPressed: _isSubmitting ? null : _completeShipment,
                            isLoading: _isSubmitting,
                          )
                        else
                          const _CompletedNotice(),
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
          _InfoRow(
            label: 'Source Batch',
            value: shipment.sourceBatchCodes.join(', '),
          ),
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

class _CompletedNotice extends StatelessWidget {
  const _CompletedNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primaryContainer.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Text(
        'Batch pengiriman sudah selesai.',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w800,
          color: AppColors.primary,
        ),
      ),
    );
  }
}
