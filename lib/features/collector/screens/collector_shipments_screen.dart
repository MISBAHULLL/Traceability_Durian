import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_top_bar.dart';
import '../../../shared/widgets/primary_pill_button.dart';
import '../collector_routes.dart';
import '../data/collector_repository.dart';
import '../models/collector_shipment_batch.dart';
import '../models/collector_stock_summary.dart';
import 'create_shipment_batch_screen.dart';
import 'shipment_qr_screen.dart';

// [FE - Component Rendering] Screen ini menampilkan batch pengiriman agregat
// milik pengepul sebagai tahap sebelum generate QR pengiriman.
class CollectorShipmentsScreen extends StatefulWidget {
  const CollectorShipmentsScreen({super.key});

  @override
  State<CollectorShipmentsScreen> createState() =>
      _CollectorShipmentsScreenState();
}

class _CollectorShipmentsScreenState extends State<CollectorShipmentsScreen> {
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

  // [FE - Event Handler] Navigasi ini membuka form pembuatan batch agregat
  // dan merefresh list saat form berhasil menyimpan data baru.
  Future<void> _openCreateShipment() async {
    final created = await CollectorRoutes.push<bool>(
      context,
      const CreateShipmentBatchScreen(),
    );
    if (mounted && created == true) setState(() {});
  }

  // [FE - Event Handler] Navigasi ini membuka QR handover untuk batch PGL
  // yang akan discan dan dikonfirmasi oleh distributor.
  Future<void> _openShipmentQr(String code) async {
    await CollectorRoutes.push(context, ShipmentQrScreen(shipmentCode: code));
  }

  @override
  Widget build(BuildContext context) {
    final shipments = _repo.shipmentBatches;

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            const AppTopBar(title: 'Batch Pengiriman'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                children: [
                  PrimaryPillButton(
                    label: 'BUAT BATCH PENGIRIMAN',
                    onPressed: _openCreateShipment,
                  ),
                  const SizedBox(height: 18),
                  if (shipments.isEmpty)
                    const _EmptyShipment()
                  else
                    ...shipments.map(
                      (shipment) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _ShipmentCard(
                          shipment: shipment,
                          onQr: () => _openShipmentQr(shipment.code),
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

class _EmptyShipment extends StatelessWidget {
  const _EmptyShipment();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: const Text(
        'Belum ada batch pengiriman. Buat batch dari stok terverifikasi untuk menyiapkan pengiriman ke distributor.',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 13,
          height: 1.4,
          color: AppColors.placeholder,
        ),
      ),
    );
  }
}

// [FE - Component Rendering] Kartu ini menampilkan satu batch agregat beserta
// provenance tree sederhana berupa daftar kode batch petani asal.
class _ShipmentCard extends StatelessWidget {
  const _ShipmentCard({
    required this.shipment,
    required this.onQr,
  });

  final CollectorShipmentBatch shipment;
  final VoidCallback onQr;

  String _formatWeight(double value) {
    final text =
        value % 1 == 0 ? value.toStringAsFixed(0) : value.toStringAsFixed(2);
    return '$text kg';
  }

  String _formatDate(DateTime d) {
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
    return '${d.day} ${months[d.month - 1]} ${d.year}';
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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.local_shipping_outlined,
                  color: AppColors.primary,
                  size: 23,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      shipment.code,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${shipment.sourceBatchCodes.length} batch sumber',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.subtitle,
                      ),
                    ),
                  ],
                ),
              ),
              _StatusPill(label: shipment.status.label),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MiniInfo(
                label: 'Berat',
                value: _formatWeight(shipment.totalWeightKg),
              ),
              _MiniInfo(
                label: 'Butir',
                value: '${shipment.totalFruitCount}',
              ),
              _MiniInfo(
                label: 'Dikemas',
                value: _formatDate(shipment.packagedAt),
              ),
              if (shipment.sentAt != null)
                _MiniInfo(
                  label: 'Dikirim',
                  value: _formatDate(shipment.sentAt!),
                ),
              if (shipment.completedAt != null)
                _MiniInfo(
                  label: 'Selesai',
                  value: _formatDate(shipment.completedAt!),
                ),
            ],
          ),
          const SizedBox(height: 12),
          _BreakdownText(
            title: 'Source Batch',
            text: shipment.sourceBatchCodes.join(', '),
          ),
          if (shipment.gradeBreakdown.isNotEmpty) ...[
            const SizedBox(height: 10),
            _BreakdownText(
              title: 'Grade',
              text: _formatBreakdown(shipment.gradeBreakdown),
            ),
          ],
          if (shipment.varietyBreakdown.isNotEmpty) ...[
            const SizedBox(height: 10),
            _BreakdownText(
              title: 'Varietas',
              text: _formatBreakdown(shipment.varietyBreakdown),
            ),
          ],
          if (shipment.warehouseNote != null &&
              shipment.warehouseNote!.isNotEmpty) ...[
            const SizedBox(height: 10),
            _BreakdownText(
              title: 'Catatan Gudang',
              text: shipment.warehouseNote!,
            ),
          ],
          const SizedBox(height: 12),
          // [FE - Component Rendering] Tombol ini membuka QR pengiriman yang
          // menjadi media handover data dari pengepul ke distributor.
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onQr,
              icon: const Icon(Icons.qr_code_2_rounded),
              label: const Text('QR PENGIRIMAN'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primaryContainer),
                shape: const StadiumBorder(),
                padding: const EdgeInsets.symmetric(vertical: 13),
                textStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatBreakdown(List<CollectorStockBreakdown> items) {
    return items.map((item) {
      return '${item.label}: ${_formatWeight(item.totalWeightKg)} / '
          '${item.totalFruitCount} butir';
    }).join('\n');
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.primaryContainer.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: AppColors.primary,
        ),
      ),
    );
  }
}

class _MiniInfo extends StatelessWidget {
  const _MiniInfo({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$label: $value',
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppColors.subtitle,
        ),
      ),
    );
  }
}

class _BreakdownText extends StatelessWidget {
  const _BreakdownText({
    required this.title,
    required this.text,
  });

  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: AppColors.placeholder,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              height: 1.35,
              fontWeight: FontWeight.w700,
              color: AppColors.subtitle,
            ),
          ),
        ],
      ),
    );
  }
}
