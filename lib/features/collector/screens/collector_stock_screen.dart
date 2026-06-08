import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_top_bar.dart';
import '../../farmer/models/harvest_batch.dart';
import '../data/collector_repository.dart';
import '../models/collector_stock_summary.dart';

// [FE - Component Rendering] Screen ini menampilkan stok durian pengepul
// yang berasal dari batch petani setelah berhasil diverifikasi.
class CollectorStockScreen extends StatefulWidget {
  const CollectorStockScreen({super.key});

  @override
  State<CollectorStockScreen> createState() => _CollectorStockScreenState();
}

class _CollectorStockScreenState extends State<CollectorStockScreen> {
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
    final stocks = _repo.stockBatches;
    final overview = _repo.stockOverview;

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            const AppTopBar(title: 'Stok Saya'),
            Expanded(
              child: stocks.isEmpty
                  ? const _EmptyStock()
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                      children: [
                        _StockOverviewPanel(overview: overview),
                        const SizedBox(height: 18),
                        const _SectionHeader(title: 'Batch Aktif'),
                        const SizedBox(height: 10),
                        ...stocks.map(
                          (batch) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _StockCard(batch: batch),
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

class _EmptyStock extends StatelessWidget {
  const _EmptyStock();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 58,
              color: AppColors.placeholder.withValues(alpha: 0.45),
            ),
            const SizedBox(height: 14),
            const Text(
              'Belum ada stok terverifikasi',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: AppColors.black,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Batch yang sudah diverifikasi pengepul akan muncul di sini.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: AppColors.placeholder,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// [FE - Component Rendering] Panel ini menampilkan inventory overview dari
// repository sebagai dashboard gudang pengepul.
class _StockOverviewPanel extends StatelessWidget {
  const _StockOverviewPanel({required this.overview});

  final CollectorStockOverview overview;

  String _formatWeight(double value) {
    final text =
        value % 1 == 0 ? value.toStringAsFixed(0) : value.toStringAsFixed(2);
    return '$text kg';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(title: 'Ringkasan Gudang'),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _SummaryMetricTile(
                icon: Icons.scale_outlined,
                label: 'Total Berat',
                value: _formatWeight(overview.totalWeightKg),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _SummaryMetricTile(
                icon: Icons.inventory_2_outlined,
                label: 'Total Butir',
                value: '${overview.totalFruitCount}',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _SummaryMetricTile(
                icon: Icons.qr_code_2_rounded,
                label: 'Batch Aktif',
                value: '${overview.activeBatchCount}',
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _StockBreakdownSection(
          title: 'Stok per Grade',
          items: overview.gradeBreakdown,
        ),
        const SizedBox(height: 14),
        _StockBreakdownSection(
          title: 'Stok per Varietas',
          items: overview.varietyBreakdown,
        ),
      ],
    );
  }
}

// [FE - Component Rendering] Tile metrik cepat ini membantu pengepul melihat
// kapasitas gudang tanpa membuka setiap batch.
class _SummaryMetricTile extends StatelessWidget {
  const _SummaryMetricTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 92,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const Spacer(),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: AppColors.black,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 10,
              height: 1.15,
              color: AppColors.placeholder,
            ),
          ),
        ],
      ),
    );
  }
}

// [FE - Component Rendering] Section breakdown ini memecah stok berdasarkan
// dimensi operasional seperti grade dan varietas.
class _StockBreakdownSection extends StatelessWidget {
  const _StockBreakdownSection({
    required this.title,
    required this.items,
  });

  final String title;
  final List<CollectorStockBreakdown> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(title: title),
        const SizedBox(height: 8),
        ...items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _StockBreakdownRow(item: item),
          ),
        ),
      ],
    );
  }
}

// [FE - Component Rendering] Row breakdown ini menampilkan agregasi kg, butir,
// dan jumlah batch untuk satu grade/varietas.
class _StockBreakdownRow extends StatelessWidget {
  const _StockBreakdownRow({required this.item});

  final CollectorStockBreakdown item;

  String _formatWeight(double value) {
    final text =
        value % 1 == 0 ? value.toStringAsFixed(0) : value.toStringAsFixed(2);
    return '$text kg';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              item.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: AppColors.black,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '${_formatWeight(item.totalWeightKg)} / '
            '${item.totalFruitCount} butir',
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: AppColors.subtitle,
            ),
          ),
          const SizedBox(width: 8),
          _TinyCountPill(label: '${item.batchCount} batch'),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w900,
        color: AppColors.black,
      ),
    );
  }
}

class _TinyCountPill extends StatelessWidget {
  const _TinyCountPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.primaryContainer.withValues(alpha: 0.1),
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

// [FE - Component Rendering] Kartu stok menggabungkan data panen awal dan
// metadata verifikasi pengepul sebagai ringkasan operasional.
class _StockCard extends StatelessWidget {
  const _StockCard({required this.batch});

  final HarvestBatch batch;

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

  // [UTIL - Helper Function] Formatter ini mengubah grade breakdown menjadi
  // ringkasan stok yang mudah dibaca di kartu pengepul.
  String _formatGradeBreakdown(HarvestBatch batch) {
    if (batch.gradeBreakdown.isEmpty) return '';
    return batch.gradeBreakdown.map((item) {
      final weight = item.weightKg % 1 == 0
          ? item.weightKg.toStringAsFixed(0)
          : item.weightKg.toStringAsFixed(2);
      return 'Grade ${item.grade}: $weight kg / ${item.fruitCount} butir';
    }).join('\n');
  }

  @override
  Widget build(BuildContext context) {
    final receivedQty = batch.receivedQuantity ?? batch.quantity;
    final receivedFruitCount = batch.receivedFruitCount ?? batch.fruitCount;
    final verifiedGrade = batch.verifiedGrade?.isNotEmpty == true
        ? batch.verifiedGrade!
        : batch.grade;
    final gradeBreakdownText = _formatGradeBreakdown(batch);

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
                  Icons.inventory_2_outlined,
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
                      batch.code,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Durian ${batch.variety}',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.black,
                      ),
                    ),
                  ],
                ),
              ),
              _StatusPill(label: 'Siap Distribusi'),
            ],
          ),
          const SizedBox(height: 14),
          _InfoGrid(
            items: [
              _InfoData(
                label: 'Berat Diterima',
                value: '${receivedQty.toStringAsFixed(0)} ${batch.unit}',
              ),
              _InfoData(
                label: 'Grade Pengepul',
                value: 'Dominan Grade $verifiedGrade',
              ),
              _InfoData(
                label: 'Jumlah Diterima',
                value: receivedFruitCount == null
                    ? '-'
                    : '$receivedFruitCount butir',
              ),
              _InfoData(
                label: 'Tanggal Verifikasi',
                value: batch.verifiedAt == null
                    ? '-'
                    : _formatDate(batch.verifiedAt!),
              ),
            ],
          ),
          if (gradeBreakdownText.isNotEmpty) ...[
            const SizedBox(height: 12),
            _GradeBreakdownBox(text: gradeBreakdownText),
          ],
          if (batch.qualityNotes != null && batch.qualityNotes!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                batch.qualityNotes!,
                style: const TextStyle(
                  fontSize: 12,
                  height: 1.35,
                  color: AppColors.subtitle,
                ),
              ),
            ),
          ],
        ],
      ),
    );
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

// [FE - Component Rendering] Box ini menampilkan komposisi grade riil hasil
// sortir agar stok gudang bisa dilihat per mutu.
class _GradeBreakdownBox extends StatelessWidget {
  const _GradeBreakdownBox({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primaryContainer.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          height: 1.45,
          fontWeight: FontWeight.w700,
          color: AppColors.subtitle,
        ),
      ),
    );
  }
}

class _InfoData {
  const _InfoData({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;
}

class _InfoGrid extends StatelessWidget {
  const _InfoGrid({required this.items});

  final List<_InfoData> items;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: items.map((item) {
        return SizedBox(
          width: (MediaQuery.of(context).size.width - 62) / 2,
          child: _InfoTile(data: item),
        );
      }).toList(),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.data});

  final _InfoData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            data.label,
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.placeholder,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            data.value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: AppColors.black,
            ),
          ),
        ],
      ),
    );
  }
}
