import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_top_bar.dart';
import '../../farmer/models/harvest_batch.dart';
import '../data/collector_repository.dart';

// [FE - Component Rendering] Screen ini menampilkan riwayat aksi pengepul
// berupa batch yang sudah diverifikasi atau ditolak pada fase mock FE.
class CollectorHistoryScreen extends StatefulWidget {
  const CollectorHistoryScreen({super.key});

  @override
  State<CollectorHistoryScreen> createState() => _CollectorHistoryScreenState();
}

class _CollectorHistoryScreenState extends State<CollectorHistoryScreen> {
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
    final histories = _repo.historyBatches;

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            const AppTopBar(title: 'Riwayat Transaksi'),
            Expanded(
              child: histories.isEmpty
                  ? const _EmptyHistory()
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                      itemBuilder: (context, index) {
                        return _HistoryCard(batch: histories[index]);
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
          'Belum ada riwayat verifikasi atau penolakan batch.',
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

// [FE - Component Rendering] Kartu riwayat membedakan hasil verifikasi dan
// penolakan agar audit pengepul mudah dipindai.
class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.batch});

  final HarvestBatch batch;

  bool get _isRejected => batch.status == BatchStatus.rejected;

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
    final h = d.hour.toString().padLeft(2, '0');
    final m = d.minute.toString().padLeft(2, '0');
    return '${d.day} ${months[d.month - 1]} ${d.year}, $h:$m';
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _isRejected
        ? const Color(0xFFD64545)
        : AppColors.primary;
    final statusLabel = _isRejected ? 'Ditolak' : 'Terverifikasi';
    final eventAt =
        batch.rejectedAt ??
        batch.verifiedAt ??
        batch.createdAt ??
        batch.harvestDate;
    final note = _isRejected ? batch.rejectionReason : batch.qualityNotes;

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
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  batch.code,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
              ),
              Text(
                statusLabel,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: statusColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Durian ${batch.variety}',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.black,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _formatDate(eventAt),
            style: const TextStyle(fontSize: 12, color: AppColors.placeholder),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MiniInfo(
                label: 'Berat',
                value:
                    '${(batch.receivedQuantity ?? batch.quantity).toStringAsFixed(0)} ${batch.unit}',
              ),
              _MiniInfo(
                label: 'Butir',
                value: (batch.receivedFruitCount ?? batch.fruitCount) == null
                    ? '-'
                    : '${batch.receivedFruitCount ?? batch.fruitCount}',
              ),
              _MiniInfo(
                label: 'Grade Dominan',
                value: 'Grade ${batch.verifiedGrade ?? batch.grade}',
              ),
            ],
          ),
          if (note != null && note.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              note,
              style: const TextStyle(
                fontSize: 12,
                height: 1.35,
                color: AppColors.subtitle,
              ),
            ),
          ],
        ],
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
