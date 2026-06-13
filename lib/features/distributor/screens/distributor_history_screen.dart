import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_top_bar.dart';
import '../../collector/models/collector_shipment_batch.dart';
import '../data/distributor_repository.dart';
import '../distributor_routes.dart';
import 'distributor_shipment_detail_screen.dart';

// [FE - Component Rendering] Screen ini menampilkan riwayat shipment yang
// sudah selesai agar distributor punya audit pengiriman yang pernah diterima.
class DistributorHistoryScreen extends StatefulWidget {
  const DistributorHistoryScreen({super.key});

  @override
  State<DistributorHistoryScreen> createState() =>
      _DistributorHistoryScreenState();
}

class _DistributorHistoryScreenState extends State<DistributorHistoryScreen> {
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

  // [FE - Event Handler] Navigasi ini membuka detail B1 dari item riwayat
  // sehingga audit lama tetap bisa dilihat sampai provenance tree.
  Future<void> _openDetail(CollectorShipmentBatch shipment) async {
    await DistributorRoutes.push(
      context,
      DistributorShipmentDetailScreen(shipmentCode: shipment.code),
    );
  }

  @override
  Widget build(BuildContext context) {
    final histories = _repo.historyShipments;

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            const AppTopBar(title: 'Riwayat Pengiriman'),
            Expanded(
              child: histories.isEmpty
                  ? const _EmptyHistory()
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                      itemBuilder: (context, index) {
                        final shipment = histories[index];
                        return _HistoryCard(
                          shipment: shipment,
                          onDetail: () => _openDetail(shipment),
                        );
                      },
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemCount: histories.length,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(28),
        child: Text(
          'Belum ada pengiriman yang selesai diterima.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            height: 1.4,
            color: AppColors.placeholder,
          ),
        ),
      ),
    );
  }
}

// [FE - Component Rendering] Kartu riwayat dibuat read-only dengan tombol
// detail eksplisit agar tidak bercampur dengan aksi konfirmasi pengiriman.
class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.shipment, required this.onDetail});

  final CollectorShipmentBatch shipment;
  final VoidCallback onDetail;

  @override
  Widget build(BuildContext context) {
    final completedAt = shipment.completedAt ?? shipment.packagedAt;
    final sentAt = shipment.sentAt;

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
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFF1D6FA4).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Icon(
                  Icons.task_alt_rounded,
                  size: 20,
                  color: Color(0xFF1D6FA4),
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
                        color: AppColors.black,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Selesai ${_formatDateTime(completedAt)}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.placeholder,
                      ),
                    ),
                  ],
                ),
              ),
              const _StatusPill(),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MiniInfo(
                label: 'Berat',
                value: _formatWeight(shipment.totalWeightKg),
              ),
              _MiniInfo(label: 'Butir', value: '${shipment.totalFruitCount}'),
              _MiniInfo(
                label: 'Source',
                value: '${shipment.sourceBatchCodes.length} batch',
              ),
              if (sentAt != null)
                _MiniInfo(label: 'Diambil', value: _formatShortDate(sentAt)),
            ],
          ),
          if (shipment.warehouseNote != null &&
              shipment.warehouseNote!.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              shipment.warehouseNote!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                height: 1.35,
                color: AppColors.subtitle,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                minimumSize: const Size(0, 34),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              onPressed: onDetail,
              icon: const Icon(Icons.visibility_outlined, size: 15),
              label: const Text(
                'Detail',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF1D6FA4).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(99),
      ),
      child: const Text(
        'Selesai',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w900,
          color: Color(0xFF1D6FA4),
        ),
      ),
    );
  }
}

class _MiniInfo extends StatelessWidget {
  const _MiniInfo({required this.label, required this.value});

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

String _formatWeight(double value) {
  final text = value % 1 == 0
      ? value.toStringAsFixed(0)
      : value.toStringAsFixed(2);
  return '$text kg';
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
