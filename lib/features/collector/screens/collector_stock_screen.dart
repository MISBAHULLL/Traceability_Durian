import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_top_bar.dart';
import '../../farmer/models/harvest_batch.dart';
import '../collector_routes.dart';
import '../data/collector_repository.dart';
import '../models/collector_stock_summary.dart';
import 'advanced_grading_screen.dart';
import 'create_shipment_batch_screen.dart';
import 'collector_shipments_screen.dart';

const _pageBackground = Color(0xFFF4F6F3);
const _borderColor = Color(0xFFE1E6DF);
const _mutedSurface = Color(0xFFF8F9F7);

enum _BatchAllocationFilter { semua, siap, dialokasikan, hampirKedaluwarsa }

extension _BatchAllocationFilterX on _BatchAllocationFilter {
  String get label {
    switch (this) {
      case _BatchAllocationFilter.semua:
        return 'Semua';
      case _BatchAllocationFilter.siap:
        return 'Siap';
      case _BatchAllocationFilter.dialokasikan:
        return 'Dialokasikan';
      case _BatchAllocationFilter.hampirKedaluwarsa:
        return 'Hampir ED';
    }
  }
}

enum _BatchSort { terbaru, terlama, beratTerbesar, grade, kedaluwarsa }

extension _BatchSortX on _BatchSort {
  String get label {
    switch (this) {
      case _BatchSort.terbaru:
        return 'Terbaru';
      case _BatchSort.terlama:
        return 'Terlama';
      case _BatchSort.beratTerbesar:
        return 'Berat terbesar';
      case _BatchSort.grade:
        return 'Grade';
      case _BatchSort.kedaluwarsa:
        return 'Mendekati ED';
    }
  }
}

String _subBatchCode(String code) {
  final clean = code.replaceAll(RegExp(r'[^A-Za-z0-9]'), '');
  final suffix = clean.length <= 6 ? clean : clean.substring(clean.length - 6);
  return 'SB-$suffix';
}

// [FE - Component Rendering] Screen ini menyusun stok pengepul sebagai
// dashboard inventori: ringkasan, breakdown, daftar batch, dan aksi pengiriman.
class CollectorStockScreen extends StatefulWidget {
  const CollectorStockScreen({super.key});

  @override
  State<CollectorStockScreen> createState() => _CollectorStockScreenState();
}

class _CollectorStockScreenState extends State<CollectorStockScreen> {
  final _repo = CollectorRepository.instance;
  _BatchAllocationFilter _activeFilter = _BatchAllocationFilter.semua;
  _BatchSort _activeSort = _BatchSort.terbaru;

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

  // [FE - State Management] Listener ini menyegarkan dashboard saat stok atau
  // status alokasi batch berubah di repository pengepul.
  void _onRepoChanged() {
    if (mounted) setState(() {});
  }

  List<_StockTrendPoint> _buildTrendPoints(List<HarvestBatch> batches) {
    final today = DateTime.now();
    final days = List.generate(7, (index) {
      final date = today.subtract(Duration(days: 6 - index));
      return DateTime(date.year, date.month, date.day);
    });
    final buckets = {
      for (final day in days) _dateKey(day): _MutableTrendBucket(date: day),
    };

    for (final batch in batches) {
      final verifiedAt = batch.verifiedAt;
      if (verifiedAt == null) continue;

      final day = DateTime(verifiedAt.year, verifiedAt.month, verifiedAt.day);
      final key = _dateKey(day);
      final bucket = buckets[key];
      if (bucket == null) continue;

      bucket.totalWeightKg += batch.receivedQuantity ?? batch.quantity;
      bucket.totalFruitCount +=
          batch.receivedFruitCount ?? batch.fruitCount ?? 0;
      bucket.batchCount++;
    }

    return days.map((day) => buckets[_dateKey(day)]!.toPoint()).toList();
  }

  String _dateKey(DateTime date) {
    return '${date.year}-${date.month}-${date.day}';
  }

  List<HarvestBatch> _visibleStockBatches(List<HarvestBatch> stocks) {
    final filtered = stocks.where(_matchesActiveFilter).toList();
    filtered.sort(_compareStockBatch);
    return filtered;
  }

  bool _matchesActiveFilter(HarvestBatch batch) {
    final isAllocated = _repo.shipmentForSourceBatch(batch.code) != null;
    final expiry = _ExpiryInfo.fromBatch(batch);

    switch (_activeFilter) {
      case _BatchAllocationFilter.semua:
        return true;
      case _BatchAllocationFilter.siap:
        return !isAllocated;
      case _BatchAllocationFilter.dialokasikan:
        return isAllocated;
      case _BatchAllocationFilter.hampirKedaluwarsa:
        return expiry.isPriority;
    }
  }

  int _compareStockBatch(HarvestBatch a, HarvestBatch b) {
    switch (_activeSort) {
      case _BatchSort.terbaru:
        return _stockDate(b).compareTo(_stockDate(a));
      case _BatchSort.terlama:
        return _stockDate(a).compareTo(_stockDate(b));
      case _BatchSort.beratTerbesar:
        return _stockWeight(b).compareTo(_stockWeight(a));
      case _BatchSort.grade:
        return _stockGrade(a).compareTo(_stockGrade(b));
      case _BatchSort.kedaluwarsa:
        return _ExpiryInfo.fromBatch(
          a,
        ).sortValue.compareTo(_ExpiryInfo.fromBatch(b).sortValue);
    }
  }

  DateTime _stockDate(HarvestBatch batch) {
    return batch.verifiedAt ?? batch.createdAt ?? batch.harvestDate;
  }

  double _stockWeight(HarvestBatch batch) {
    return batch.receivedQuantity ?? batch.quantity;
  }

  String _stockGrade(HarvestBatch batch) {
    return (batch.verifiedGrade?.isNotEmpty == true
            ? batch.verifiedGrade!
            : batch.grade)
        .toUpperCase();
  }

  // [FE - Event Handler] Aksi utama langsung membuka form agregasi ketika
  // stok tersedia; daftar pengiriman hanya dibuka saat tidak ada stok bebas.
  Future<void> _openShipmentAction() async {
    if (_repo.availableStockBatches.isNotEmpty) {
      await CollectorRoutes.push<bool>(
        context,
        const CreateShipmentBatchScreen(),
      );
      return;
    }

    await CollectorRoutes.push(context, const CollectorShipmentsScreen());
  }

  Future<void> _openAdvancedGrading(HarvestBatch batch) async {
    await CollectorRoutes.push<bool>(
      context,
      AdvancedGradingScreen(batch: batch),
    );
  }

  @override
  Widget build(BuildContext context) {
    final stocks = _repo.stockBatches;
    final visibleStocks = _visibleStockBatches(stocks);
    final overview = _repo.stockOverview;
    final readyCount = _repo.availableStockBatches.length;
    final visibleReadyCount = visibleStocks
        .where((batch) => _repo.shipmentForSourceBatch(batch.code) == null)
        .length;
    final trendPoints = _buildTrendPoints(_repo.historyBatches);

    return Scaffold(
      backgroundColor: _pageBackground,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const ColoredBox(
              color: AppColors.white,
              child: AppTopBar(title: 'Stok Saya'),
            ),
            Expanded(
              child: stocks.isEmpty
                  ? const _EmptyStock()
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                      children: [
                        _WarehouseSummary(overview: overview),
                        const SizedBox(height: 16),
                        _StockTrendPanel(points: trendPoints),
                        const SizedBox(height: 12),
                        _BreakdownPanel(
                          title: 'Stok per Grade',
                          icon: Icons.workspace_premium_outlined,
                          items: overview.gradeBreakdown,
                        ),
                        const SizedBox(height: 12),
                        _BreakdownPanel(
                          title: 'Stok per Varietas',
                          icon: Icons.eco_outlined,
                          items: overview.varietyBreakdown,
                        ),
                        const SizedBox(height: 22),
                        _BatchSectionHeader(
                          totalCount: stocks.length,
                          displayedCount: visibleStocks.length,
                          readyCount: visibleReadyCount,
                        ),
                        const SizedBox(height: 10),
                        _BatchControls(
                          activeFilter: _activeFilter,
                          activeSort: _activeSort,
                          onFilterChanged: (value) {
                            setState(() => _activeFilter = value);
                          },
                          onSortChanged: (value) {
                            setState(() => _activeSort = value);
                          },
                        ),
                        const SizedBox(height: 12),
                        if (visibleStocks.isEmpty)
                          const _EmptyFilteredBatches()
                        else
                          ...visibleStocks.map(
                            (batch) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _StockCard(
                                batch: batch,
                                warehouseName: _repo.warehouseLabel(
                                  batch.warehouseId,
                                ),
                                shipmentCode: _repo
                                    .shipmentForSourceBatch(batch.code)
                                    ?.code,
                                onAdvancedGrading: () {
                                  _openAdvancedGrading(batch);
                                },
                              ),
                            ),
                          ),
                      ],
                    ),
            ),
          ],
        ),
      ),
      // [FE - Component Rendering] Action bar tetap menjaga perintah membuat
      // pengiriman terpisah jelas dari konten inventori yang dapat digulir.
      bottomNavigationBar: stocks.isEmpty
          ? null
          : _ShipmentActionBar(
              readyCount: readyCount,
              onPressed: _openShipmentAction,
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
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.primaryContainer.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.inventory_2_outlined,
                size: 34,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Belum ada stok terverifikasi',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.black,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Batch yang selesai diterima dan diverifikasi akan tersimpan di gudang ini.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                height: 1.45,
                color: AppColors.placeholder,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// [FE - Component Rendering] Panel utama menonjolkan total berat sebagai
// metrik primer, sedangkan jumlah butir dan batch menjadi konteks sekunder.
class _WarehouseSummary extends StatelessWidget {
  const _WarehouseSummary({required this.overview});

  final CollectorStockOverview overview;

  String _formatWeight(double value) {
    return value % 1 == 0 ? value.toStringAsFixed(0) : value.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 88, 168, 53),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.warehouse_outlined,
                size: 20,
                color: Color(0xFFDDF2D4),
              ),
              SizedBox(width: 8),
              Text(
                'Ringkasan Gudang',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFDDF2D4),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            '${_formatWeight(overview.totalWeightKg)} kg',
            style: const TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w900,
              color: AppColors.white,
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'Total stok diterima',
            style: TextStyle(fontSize: 12, color: Color(0xFFDDF2D4)),
          ),
          const SizedBox(height: 18),
          Container(height: 1, color: const Color(0xFF4A8236)),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _SummaryValue(
                  label: 'Jumlah buah',
                  value: '${overview.totalFruitCount} butir',
                ),
              ),
              Container(width: 1, height: 38, color: const Color(0xFF4A8236)),
              Expanded(
                child: _SummaryValue(
                  label: 'Batch aktif',
                  value: '${overview.activeBatchCount} batch',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryValue extends StatelessWidget {
  const _SummaryValue({required this.label, required this.value});

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
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.white,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: Color(0xFFDDF2D4)),
          ),
        ],
      ),
    );
  }
}

enum _ExpiryLevel { unknown, fresh, monitor, priority, expired }

class _ExpiryInfo {
  const _ExpiryInfo({
    required this.level,
    required this.label,
    required this.sortValue,
  });

  final _ExpiryLevel level;
  final String label;
  final int sortValue;

  bool get isPriority {
    return level == _ExpiryLevel.priority || level == _ExpiryLevel.expired;
  }

  Color get color {
    switch (level) {
      case _ExpiryLevel.unknown:
        return AppColors.placeholder;
      case _ExpiryLevel.fresh:
        return AppColors.primary;
      case _ExpiryLevel.monitor:
        return const Color(0xFF8A5A00);
      case _ExpiryLevel.priority:
      case _ExpiryLevel.expired:
        return const Color(0xFFC2410C);
    }
  }

  Color get background {
    switch (level) {
      case _ExpiryLevel.unknown:
        return const Color(0xFFE5E7EB);
      case _ExpiryLevel.fresh:
        return const Color(0xFFEAF4E6);
      case _ExpiryLevel.monitor:
        return const Color(0xFFFFF3D8);
      case _ExpiryLevel.priority:
      case _ExpiryLevel.expired:
        return const Color(0xFFFFEDD5);
    }
  }

  IconData get icon {
    switch (level) {
      case _ExpiryLevel.unknown:
        return Icons.help_outline_rounded;
      case _ExpiryLevel.fresh:
        return Icons.check_circle_outline_rounded;
      case _ExpiryLevel.monitor:
        return Icons.schedule_rounded;
      case _ExpiryLevel.priority:
      case _ExpiryLevel.expired:
        return Icons.priority_high_rounded;
    }
  }

  static _ExpiryInfo fromBatch(HarvestBatch batch) {
    final shelfLifeDays = _shelfLifeDays(batch.shelfLifeEstimate);
    if (shelfLifeDays == null) {
      return const _ExpiryInfo(
        level: _ExpiryLevel.unknown,
        label: 'Masa simpan -',
        sortValue: 9999,
      );
    }

    final startDate = _dateOnly(batch.verifiedAt ?? batch.harvestDate);
    final today = _dateOnly(DateTime.now());
    final expiresAt = startDate.add(Duration(days: shelfLifeDays));
    final remainingDays = expiresAt.difference(today).inDays;

    if (remainingDays < 0) {
      return _ExpiryInfo(
        level: _ExpiryLevel.expired,
        label: 'Lewat ${remainingDays.abs()} hari',
        sortValue: remainingDays,
      );
    }
    if (remainingDays <= 1) {
      return _ExpiryInfo(
        level: _ExpiryLevel.priority,
        label: remainingDays == 0 ? 'ED hari ini' : '1 hari lagi',
        sortValue: remainingDays,
      );
    }
    if (remainingDays <= 3) {
      return _ExpiryInfo(
        level: _ExpiryLevel.monitor,
        label: '$remainingDays hari lagi',
        sortValue: remainingDays,
      );
    }
    return _ExpiryInfo(
      level: _ExpiryLevel.fresh,
      label: '$remainingDays hari lagi',
      sortValue: remainingDays,
    );
  }

  static int? _shelfLifeDays(String? text) {
    final value = text?.trim();
    if (value == null || value.isEmpty) return null;

    final matches = RegExp(r'\d+').allMatches(value).toList();
    if (matches.isEmpty) return null;

    return matches
        .map((match) => int.tryParse(match.group(0) ?? '') ?? 0)
        .reduce((max, value) => value > max ? value : max);
  }

  static DateTime _dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }
}

class _StockTrendPoint {
  const _StockTrendPoint({
    required this.date,
    required this.totalWeightKg,
    required this.totalFruitCount,
    required this.batchCount,
  });

  final DateTime date;
  final double totalWeightKg;
  final int totalFruitCount;
  final int batchCount;
}

class _MutableTrendBucket {
  _MutableTrendBucket({required this.date});

  final DateTime date;
  double totalWeightKg = 0;
  int totalFruitCount = 0;
  int batchCount = 0;

  _StockTrendPoint toPoint() {
    return _StockTrendPoint(
      date: date,
      totalWeightKg: totalWeightKg,
      totalFruitCount: totalFruitCount,
      batchCount: batchCount,
    );
  }
}

class _StockTrendPanel extends StatelessWidget {
  const _StockTrendPanel({required this.points});

  final List<_StockTrendPoint> points;

  String _formatWeight(double value) {
    return value % 1 == 0 ? value.toStringAsFixed(0) : value.toStringAsFixed(1);
  }

  String _dayLabel(DateTime date) {
    const days = ['Min', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab'];
    return days[date.weekday % 7];
  }

  @override
  Widget build(BuildContext context) {
    final maxWeight = points.fold<double>(
      0,
      (max, point) => point.totalWeightKg > max ? point.totalWeightKg : max,
    );
    final totalWeight = points.fold<double>(
      0,
      (sum, point) => sum + point.totalWeightKg,
    );
    final totalBatch = points.fold<int>(
      0,
      (sum, point) => sum + point.batchCount,
    );

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.trending_up_rounded,
                size: 18,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Tren Penerimaan 7 Hari',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.black,
                  ),
                ),
              ),
              Text(
                '${_formatWeight(totalWeight)} kg',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '$totalBatch batch diterima dalam 7 hari terakhir',
            style: const TextStyle(fontSize: 11, color: AppColors.placeholder),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 116,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: points.map((point) {
                return Expanded(
                  child: _TrendBar(
                    point: point,
                    maxWeight: maxWeight,
                    label: _dayLabel(point.date),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _TrendBar extends StatelessWidget {
  const _TrendBar({
    required this.point,
    required this.maxWeight,
    required this.label,
  });

  final _StockTrendPoint point;
  final double maxWeight;
  final String label;

  String _formatWeight(double value) {
    return value % 1 == 0 ? value.toStringAsFixed(0) : value.toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    final ratio = maxWeight <= 0 ? 0.0 : point.totalWeightKg / maxWeight;
    final barHeight = 16 + (ratio * 58);
    final isEmpty = point.totalWeightKg <= 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          SizedBox(
            height: 22,
            child: Text(
              isEmpty ? '-' : _formatWeight(point.totalWeightKg),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w800,
                color: isEmpty ? AppColors.placeholder : AppColors.subtitle,
              ),
            ),
          ),
          Tooltip(
            message:
                '${_formatWeight(point.totalWeightKg)} kg, '
                '${point.totalFruitCount} butir, '
                '${point.batchCount} batch',
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: double.infinity,
              height: barHeight,
              constraints: const BoxConstraints(minHeight: 16),
              decoration: BoxDecoration(
                color: isEmpty
                    ? const Color(0xFFE5E7EB)
                    : AppColors.primaryContainer,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
          const SizedBox(height: 7),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.placeholder,
            ),
          ),
        ],
      ),
    );
  }
}

// [FE - Component Rendering] Panel breakdown memberi batas section yang jelas
// dan memakai divider agar setiap grade atau varietas mudah dibandingkan.
class _BreakdownPanel extends StatelessWidget {
  const _BreakdownPanel({
    required this.title,
    required this.icon,
    required this.items,
  });

  final String title;
  final IconData icon;
  final List<CollectorStockBreakdown> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _borderColor),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 13, 14, 11),
            child: Row(
              children: [
                Icon(icon, size: 18, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.black,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: _borderColor),
          ...List.generate(items.length, (index) {
            return Column(
              children: [
                _BreakdownRow(item: items[index]),
                if (index < items.length - 1)
                  const Divider(height: 1, indent: 14, endIndent: 14),
              ],
            );
          }),
        ],
      ),
    );
  }
}

class _BreakdownRow extends StatelessWidget {
  const _BreakdownRow({required this.item});

  final CollectorStockBreakdown item;

  String _formatWeight(double value) {
    return value % 1 == 0 ? value.toStringAsFixed(0) : value.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.black,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${item.batchCount} batch sumber',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.placeholder,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '${_formatWeight(item.totalWeightKg)} kg',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: AppColors.subtitle,
            ),
          ),
          const SizedBox(width: 10),
          Container(width: 1, height: 24, color: _borderColor),
          const SizedBox(width: 10),
          SizedBox(
            width: 54,
            child: Text(
              '${item.totalFruitCount} butir',
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.placeholder,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BatchSectionHeader extends StatelessWidget {
  const _BatchSectionHeader({
    required this.totalCount,
    required this.displayedCount,
    required this.readyCount,
  });

  final int totalCount;
  final int displayedCount;
  final int readyCount;

  @override
  Widget build(BuildContext context) {
    final summary = displayedCount == totalCount
        ? '$readyCount siap dari $totalCount'
        : '$displayedCount tampil - $readyCount siap';

    return Row(
      children: [
        const Expanded(
          child: Text(
            'Batch Aktif',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: AppColors.black,
            ),
          ),
        ),
        Text(
          summary,
          style: const TextStyle(fontSize: 11, color: AppColors.placeholder),
        ),
      ],
    );
  }
}

class _BatchControls extends StatefulWidget {
  const _BatchControls({
    required this.activeFilter,
    required this.activeSort,
    required this.onFilterChanged,
    required this.onSortChanged,
  });

  final _BatchAllocationFilter activeFilter;
  final _BatchSort activeSort;
  final ValueChanged<_BatchAllocationFilter> onFilterChanged;
  final ValueChanged<_BatchSort> onSortChanged;

  @override
  State<_BatchControls> createState() => _BatchControlsState();
}

class _BatchControlsState extends State<_BatchControls> {
  bool _sortMenuOpen = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _borderColor),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(
                Icons.filter_list_rounded,
                size: 17,
                color: AppColors.placeholder,
              ),
              const SizedBox(width: 8),
              const Text(
                'Filter',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.subtitle,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _BatchAllocationFilter.values.map((filter) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _FilterPill(
                          label: filter.label,
                          selected: widget.activeFilter == filter,
                          onTap: () => widget.onFilterChanged(filter),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(
                Icons.sort_rounded,
                size: 17,
                color: AppColors.placeholder,
              ),
              const SizedBox(width: 8),
              const Text(
                'Urutkan',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.subtitle,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: _SortDropdownButton(
                    label: widget.activeSort.label,
                    expanded: _sortMenuOpen,
                    onTap: () {
                      setState(() => _sortMenuOpen = !_sortMenuOpen);
                    },
                  ),
                ),
              ),
            ],
          ),
          if (_sortMenuOpen) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(left: 33),
              child: _SortDropdownMenu(
                activeSort: widget.activeSort,
                onChanged: (sort) {
                  setState(() => _sortMenuOpen = false);
                  widget.onSortChanged(sort);
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SortDropdownButton extends StatelessWidget {
  const _SortDropdownButton({
    required this.label,
    required this.expanded,
    required this.onTap,
  });

  final String label;
  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.primary),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: AppColors.white,
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              expanded
                  ? Icons.keyboard_arrow_up_rounded
                  : Icons.keyboard_arrow_down_rounded,
              size: 16,
              color: AppColors.white,
            ),
          ],
        ),
      ),
    );
  }
}

class _SortDropdownMenu extends StatelessWidget {
  const _SortDropdownMenu({required this.activeSort, required this.onChanged});

  final _BatchSort activeSort;
  final ValueChanged<_BatchSort> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _borderColor),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: _BatchSort.values.map((sort) {
          final selected = sort == activeSort;
          return InkWell(
            onTap: () => onChanged(sort),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.primary.withValues(alpha: 0.10)
                    : AppColors.white,
                borderRadius: BorderRadius.circular(7),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      sort.label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: selected
                            ? FontWeight.w900
                            : FontWeight.w700,
                        color: selected
                            ? AppColors.primary
                            : AppColors.subtitle,
                      ),
                    ),
                  ),
                  if (selected)
                    const Icon(
                      Icons.check_rounded,
                      size: 16,
                      color: AppColors.primary,
                    ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  const _FilterPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : _mutedSurface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? AppColors.primary : _borderColor,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: selected ? AppColors.white : AppColors.subtitle,
          ),
        ),
      ),
    );
  }
}

class _EmptyFilteredBatches extends StatelessWidget {
  const _EmptyFilteredBatches();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 22),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _borderColor),
      ),
      child: const Text(
        'Tidak ada batch yang cocok dengan filter ini.',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 12,
          height: 1.4,
          color: AppColors.placeholder,
        ),
      ),
    );
  }
}

// [FE - Component Rendering] Kartu stok menyajikan identitas batch, metrik
// penerimaan, dan hasil grading dalam urutan baca operasional pengepul.
class _StockCard extends StatelessWidget {
  const _StockCard({
    required this.batch,
    required this.warehouseName,
    required this.onAdvancedGrading,
    this.shipmentCode,
  });

  final HarvestBatch batch;
  final String warehouseName;
  final String? shipmentCode;
  final VoidCallback onAdvancedGrading;

  String _formatDate(DateTime date) {
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
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _formatWeight(double value) {
    return value % 1 == 0 ? value.toStringAsFixed(0) : value.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    final receivedWeight = batch.receivedQuantity ?? batch.quantity;
    final receivedFruit = batch.receivedFruitCount ?? batch.fruitCount;
    final verifiedGrade = batch.verifiedGrade?.isNotEmpty == true
        ? batch.verifiedGrade!
        : batch.grade;
    final isAllocated = shipmentCode != null;
    final expiry = _ExpiryInfo.fromBatch(batch);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
                    color: isAllocated
                        ? const Color(0xFFFFF3D8)
                        : const Color(0xFFEAF4E6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    isAllocated
                        ? Icons.local_shipping_outlined
                        : Icons.inventory_2_outlined,
                    size: 21,
                    color: isAllocated
                        ? const Color(0xFF9A6700)
                        : AppColors.primary,
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
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Durian ${batch.variety}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.black,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          _InfoPill(
                            icon: Icons.inventory_2_outlined,
                            label: _subBatchCode(batch.code),
                          ),
                          _InfoPill(
                            icon: Icons.event_available_outlined,
                            label: batch.verifiedAt == null
                                ? 'Belum verifikasi'
                                : _formatDate(batch.verifiedAt!),
                          ),
                          _ExpiryBadge(info: expiry),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _StatusBadge(
                  isAllocated: isAllocated,
                  label: isAllocated ? 'Dialokasikan' : 'Siap digabung',
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: _borderColor),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _BatchMetric(
                    label: 'Berat',
                    value: '${_formatWeight(receivedWeight)} kg',
                  ),
                ),
                const _MetricDivider(),
                Expanded(
                  child: _BatchMetric(
                    label: 'Jumlah',
                    value: receivedFruit == null ? '-' : '$receivedFruit butir',
                  ),
                ),
                const _MetricDivider(),
                Expanded(
                  child: _BatchMetric(label: 'Gudang', value: warehouseName),
                ),
              ],
            ),
          ),
          _GradeSummary(
            dominantGrade: verifiedGrade,
            breakdown: batch.gradeBreakdown,
          ),
          if (!isAllocated)
            _StockActionStrip(onAdvancedGrading: onAdvancedGrading),
          if (isAllocated) _AllocationNotice(code: shipmentCode!),
          if (batch.qualityNotes?.trim().isNotEmpty == true)
            _QualityNote(note: batch.qualityNotes!.trim()),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.isAllocated, required this.label});

  final bool isAllocated;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: isAllocated ? const Color(0xFFFFF3D8) : const Color(0xFFEAF4E6),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: isAllocated ? const Color(0xFF8A5A00) : AppColors.primary,
        ),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: _mutedSurface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: _borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.placeholder),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: AppColors.subtitle,
            ),
          ),
        ],
      ),
    );
  }
}

class _ExpiryBadge extends StatelessWidget {
  const _ExpiryBadge({required this.info});

  final _ExpiryInfo info;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: info.background,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(info.icon, size: 12, color: info.color),
          const SizedBox(width: 4),
          Text(
            info.label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: info.color,
            ),
          ),
        ],
      ),
    );
  }
}

class _StockActionStrip extends StatelessWidget {
  const _StockActionStrip({required this.onAdvancedGrading});

  final VoidCallback onAdvancedGrading;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: _borderColor)),
      ),
      child: Align(
        alignment: Alignment.centerRight,
        child: OutlinedButton.icon(
          onPressed: onAdvancedGrading,
          icon: const Icon(Icons.call_split_outlined, size: 16),
          label: const Text('Grading'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            side: const BorderSide(color: _borderColor),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            textStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
        ),
      ),
    );
  }
}

class _BatchMetric extends StatelessWidget {
  const _BatchMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: AppColors.placeholder),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 12,
            height: 1.25,
            fontWeight: FontWeight.w800,
            color: AppColors.subtitle,
          ),
        ),
      ],
    );
  }
}

class _MetricDivider extends StatelessWidget {
  const _MetricDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 40,
      margin: const EdgeInsets.symmetric(horizontal: 10),
      color: _borderColor,
    );
  }
}

// [FE - Component Rendering] Ringkasan grading mempertahankan grade dominan
// sekaligus rincian hasil sortir sebagai data traceability pengepul.
class _GradeSummary extends StatelessWidget {
  const _GradeSummary({required this.dominantGrade, required this.breakdown});

  final String dominantGrade;
  final List<BatchGradeBreakdown> breakdown;

  String _formatWeight(double value) {
    return value % 1 == 0 ? value.toStringAsFixed(0) : value.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: _mutedSurface,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 13),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.fact_check_outlined,
                size: 17,
                color: AppColors.primary,
              ),
              const SizedBox(width: 7),
              Text(
                'Hasil sortir · Dominan Grade $dominantGrade',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppColors.subtitle,
                ),
              ),
            ],
          ),
          if (breakdown.isNotEmpty) ...[
            const SizedBox(height: 9),
            Wrap(
              spacing: 8,
              runSpacing: 7,
              children: breakdown.map((item) {
                return Text(
                  'Grade ${item.grade}: ${_formatWeight(item.weightKg)} kg / '
                  '${item.fruitCount} butir',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.placeholder,
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _AllocationNotice extends StatelessWidget {
  const _AllocationNotice({required this.code});

  final String code;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: const BoxDecoration(
        color: Color(0xFFFFF8E8),
        border: Border(top: BorderSide(color: Color(0xFFF0D79B))),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.account_tree_outlined,
            size: 17,
            color: Color(0xFF9A6700),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Dialokasikan ke batch pengiriman $code',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Color(0xFF7A5100),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QualityNote extends StatelessWidget {
  const _QualityNote({required this.note});

  final String note;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: _borderColor)),
      ),
      child: Text(
        'Catatan: $note',
        style: const TextStyle(
          fontSize: 11,
          height: 1.4,
          color: AppColors.placeholder,
        ),
      ),
    );
  }
}

class _ShipmentActionBar extends StatelessWidget {
  const _ShipmentActionBar({required this.readyCount, required this.onPressed});

  final int readyCount;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        decoration: const BoxDecoration(
          color: AppColors.white,
          border: Border(top: BorderSide(color: _borderColor)),
        ),
        child: SizedBox(
          height: 50,
          child: ElevatedButton.icon(
            onPressed: onPressed,
            icon: const Icon(Icons.local_shipping_outlined, size: 20),
            label: Text(
              readyCount > 0
                  ? 'Buat Batch Pengiriman ($readyCount siap)'
                  : 'Kelola Batch Pengiriman',
            ),
            style: ElevatedButton.styleFrom(
              elevation: 0,
              backgroundColor: AppColors.primaryContainer,
              foregroundColor: AppColors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              textStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
