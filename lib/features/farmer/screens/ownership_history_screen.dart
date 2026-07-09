import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_top_bar.dart';
import '../data/farmer_repository.dart';
import '../farmer_routes.dart';
import '../models/batch_event.dart';
import '../models/harvest_batch.dart';
import 'batch_detail_screen.dart';
import 'batch_trace_screen.dart';

const _pageBackground = Color(0xFFF4F6F3);
const _borderColor = Color(0xFFE1E6DF);

// [FE - Component Rendering] Screen ini menjadi audit trail global petani
// untuk melihat semua keputusan serah terima batch tanpa menampilkan harga.
class OwnershipHistoryScreen extends StatefulWidget {
  const OwnershipHistoryScreen({super.key});

  @override
  State<OwnershipHistoryScreen> createState() => _OwnershipHistoryScreenState();
}

class _OwnershipHistoryScreenState extends State<OwnershipHistoryScreen> {
  final _repo = FarmerRepository.instance;

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

  // [FE - State Management] Listener ini membuat halaman riwayat ikut berubah
  // saat batch diverifikasi, ditolak, atau bergerak ke role berikutnya.
  void _onRepoChanged() {
    if (mounted) setState(() {});
  }

  // [FE - State Management] Getter ini membentuk daftar riwayat dari event
  // per batch agar halaman global memakai sumber data yang sama dengan detail.
  List<_OwnershipHistoryItem> get _historyItems {
    final items = <_OwnershipHistoryItem>[];

    for (final batch in _repo.batches) {
      final handoverEvents = _repo.eventsFor(batch.code).where((event) {
        return event.status != BatchStatus.created &&
            event.status != BatchStatus.draft;
      });

      for (final event in handoverEvents) {
        items.add(_OwnershipHistoryItem(batch: batch, event: event));
      }
    }

    items.sort((a, b) => b.event.timestamp.compareTo(a.event.timestamp));
    return items;
  }

  // [FE - Event Handler] Membuka detail batch dari kartu riwayat tanpa
  // membuat route baru khusus, sehingga konteks audit tetap bisa ditelusuri.
  Future<void> _openBatch(String code) async {
    await FarmerRoutes.push(context, BatchDetailScreen(batchCode: code));
  }

  // [FE - Event Handler] Membuka visual journey agar petani bisa melihat
  // keterlacakan batch sebagai alur node, bukan hanya daftar audit.
  Future<void> _openTrace(String code) async {
    await FarmerRoutes.push(context, BatchTraceScreen(batchCode: code));
  }

  @override
  Widget build(BuildContext context) {
    final items = _historyItems;

    return Scaffold(
      backgroundColor: _pageBackground,
      body: SafeArea(
        child: Column(
          children: [
            const ColoredBox(
              color: AppColors.homeHeaderSurface,
              child: AppTopBar(title: 'Riwayat Perpindahan'),
            ),
            Expanded(
              child: items.isEmpty
                  ? const _EmptyHistory()
                  : ListView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                      children: [
                        _HistorySummary(items: items),
                        const SizedBox(height: 18),
                        const _SectionTitle(),
                        const SizedBox(height: 12),
                        ...List.generate(items.length, (index) {
                          return _OwnershipTimelineItem(
                            item: items[index],
                            isLast: index == items.length - 1,
                            onOpenBatch: () => _openBatch(items[index].code),
                            onOpenTrace: () => _openTrace(items[index].code),
                          );
                        }),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// [FE - State Management] Model view lokal ini memperkaya BatchEvent dengan
// data batch agar kartu riwayat punya konteks jumlah, varietas, dan penerima.
class _OwnershipHistoryItem {
  const _OwnershipHistoryItem({required this.batch, required this.event});

  final HarvestBatch batch;
  final BatchEvent event;

  String get code => batch.code;
  BatchStatus get status => event.status;
  DateTime get timestamp => event.timestamp;

  String get title {
    switch (status) {
      case BatchStatus.verifiedByCollector:
        return 'Diterima oleh Pengepul';
      case BatchStatus.inDistribution:
        return 'Masuk Pengiriman';
      case BatchStatus.receivedByUmkm:
        return 'Diterima oleh UMKM';
      case BatchStatus.processed:
        return 'Diproses UMKM';
      case BatchStatus.sold:
        return 'Selesai Terjual';
      case BatchStatus.rejected:
        return 'Ditolak oleh Pengepul';
      case BatchStatus.draft:
      case BatchStatus.created:
        return event.title;
    }
  }

  String get fromLabel {
    switch (status) {
      case BatchStatus.verifiedByCollector:
      case BatchStatus.rejected:
        return 'Petani';
      case BatchStatus.inDistribution:
        return batch.verifiedBy ?? 'Pengepul';
      case BatchStatus.receivedByUmkm:
        return 'Pengepul/Distributor';
      case BatchStatus.processed:
      case BatchStatus.sold:
        return 'UMKM';
      case BatchStatus.draft:
      case BatchStatus.created:
        return 'Petani';
    }
  }

  String get toLabel {
    switch (status) {
      case BatchStatus.verifiedByCollector:
        return batch.verifiedBy ?? event.actorLabel;
      case BatchStatus.inDistribution:
        return 'Distributor/UMKM';
      case BatchStatus.receivedByUmkm:
        return event.actorLabel;
      case BatchStatus.processed:
        return 'Proses produksi UMKM';
      case BatchStatus.sold:
        return 'Konsumen akhir';
      case BatchStatus.rejected:
        return 'Tidak berpindah';
      case BatchStatus.draft:
      case BatchStatus.created:
        return event.actorLabel;
    }
  }

  String get approvalLabel {
    switch (status) {
      case BatchStatus.verifiedByCollector:
        return 'Disetujui - kepemilikan berpindah ke pengepul';
      case BatchStatus.rejected:
        return 'Ditolak - kepemilikan tetap di petani';
      case BatchStatus.inDistribution:
        return 'Disiapkan untuk serah terima berikutnya';
      case BatchStatus.receivedByUmkm:
        return 'Dikonfirmasi oleh penerima';
      case BatchStatus.processed:
      case BatchStatus.sold:
        return 'Tercatat dalam rantai pasok';
      case BatchStatus.draft:
      case BatchStatus.created:
        return 'Belum ada persetujuan perpindahan';
    }
  }

  String get conditionNotes {
    final note = status == BatchStatus.rejected
        ? batch.rejectionReason
        : batch.qualityNotes;
    return _cleanText(note) ?? 'Belum ada catatan kondisi dari penerima.';
  }

  String get receivedAmount {
    if (status == BatchStatus.rejected) return 'Tidak diterima';

    final kg = batch.receivedQuantity ?? batch.quantity;
    final fruit = batch.receivedFruitCount ?? batch.fruitCount;
    return '${_formatNumber(kg)} ${batch.unit}${fruit == null ? '' : ' / $fruit butir'}';
  }

  String get initialAmount {
    return '${_formatNumber(batch.quantity)} ${batch.unit}${batch.fruitCount == null ? '' : ' / ${batch.fruitCount} butir'}';
  }

  String get gradeInfo {
    final verified = _cleanText(batch.verifiedGrade);
    if (verified == null) return 'Awal ${batch.grade}';
    return 'Awal ${batch.grade} -> Riil $verified';
  }
}

class _HistorySummary extends StatelessWidget {
  const _HistorySummary({required this.items});

  final List<_OwnershipHistoryItem> items;

  @override
  Widget build(BuildContext context) {
    final accepted = items
        .where((item) => item.status == BatchStatus.verifiedByCollector)
        .length;
    final rejected = items
        .where((item) => item.status == BatchStatus.rejected)
        .length;

    // [FE - Component Rendering] Ringkasan ini memberi konteks cepat sebelum
    // user membaca timeline detail satu per satu.
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _borderColor),
      ),
      child: Row(
        children: [
          Expanded(
            child: _SummaryCell(
              icon: Icons.timeline_rounded,
              label: 'Aktivitas',
              value: '${items.length}',
            ),
          ),
          const _SummaryDivider(),
          Expanded(
            child: _SummaryCell(
              icon: Icons.verified_outlined,
              label: 'Diterima',
              value: '$accepted',
            ),
          ),
          const _SummaryDivider(),
          Expanded(
            child: _SummaryCell(
              icon: Icons.block_rounded,
              label: 'Ditolak',
              value: '$rejected',
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCell extends StatelessWidget {
  const _SummaryCell({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: AppColors.black,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11, color: AppColors.placeholder),
          ),
        ],
      ),
    );
  }
}

class _SummaryDivider extends StatelessWidget {
  const _SummaryDivider();

  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 58, color: _borderColor);
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Icon(Icons.route_rounded, size: 18, color: AppColors.primary),
        SizedBox(width: 8),
        Expanded(
          child: Text(
            'Timeline Serah Terima',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: AppColors.black,
            ),
          ),
        ),
        Text(
          'Terbaru di atas',
          style: TextStyle(fontSize: 11, color: AppColors.placeholder),
        ),
      ],
    );
  }
}

class _OwnershipTimelineItem extends StatefulWidget {
  const _OwnershipTimelineItem({
    required this.item,
    required this.isLast,
    required this.onOpenBatch,
    required this.onOpenTrace,
  });

  final _OwnershipHistoryItem item;
  final bool isLast;
  final VoidCallback onOpenBatch;
  final VoidCallback onOpenTrace;

  @override
  State<_OwnershipTimelineItem> createState() => _OwnershipTimelineItemState();
}

class _OwnershipTimelineItemState extends State<_OwnershipTimelineItem> {
  bool _expanded = false;

  // [FE - Event Handler] Toggle ini membuka detail audit hanya saat diminta,
  // sehingga timeline tetap padat untuk penggunaan harian.
  void _toggleExpanded() {
    setState(() => _expanded = !_expanded);
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _TimelineRail(status: item.status, isLast: widget.isLast),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: widget.isLast ? 0 : 12),
              child: Material(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  onTap: _toggleExpanded,
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: _borderColor),
                    ),
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _HistoryCardHeader(item: item, expanded: _expanded),
                        AnimatedSize(
                          duration: const Duration(milliseconds: 180),
                          curve: Curves.easeOutCubic,
                          alignment: Alignment.topCenter,
                          child: _expanded
                              ? _HistoryExpandedDetails(
                                  item: item,
                                  onOpenBatch: widget.onOpenBatch,
                                  onOpenTrace: widget.onOpenTrace,
                                )
                              : const SizedBox.shrink(),
                        ),
                      ],
                    ),
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

class _TimelineRail extends StatelessWidget {
  const _TimelineRail({required this.status, required this.isLast});

  final BatchStatus status;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 22,
      child: Column(
        children: [
          Container(
            width: 14,
            height: 14,
            margin: const EdgeInsets.only(top: 18),
            decoration: BoxDecoration(
              color: status.color,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: status.color.withValues(alpha: 0.25),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
          if (!isLast)
            Expanded(
              child: Container(
                width: 2,
                margin: const EdgeInsets.symmetric(vertical: 4),
                color: _borderColor,
              ),
            ),
        ],
      ),
    );
  }
}

class _HistoryCardHeader extends StatelessWidget {
  const _HistoryCardHeader({required this.item, required this.expanded});

  final _OwnershipHistoryItem item;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: AppColors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${item.code} - ${item.batch.variety}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            _StatusBadge(status: item.status),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            _MetaChip(
              icon: Icons.scale_outlined,
              label: item.initialAmount,
            ),
            _MetaChip(
              icon: Icons.person_pin_circle_outlined,
              label: item.toLabel,
            ),
            _MetaChip(
              icon: Icons.schedule_rounded,
              label: _formatShortDate(item.timestamp),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: Text(
                '${item.fromLabel} -> ${item.toLabel}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.placeholder,
                ),
              ),
            ),
            Icon(
              expanded
                  ? Icons.keyboard_arrow_up_rounded
                  : Icons.keyboard_arrow_down_rounded,
              color: AppColors.placeholder,
            ),
          ],
        ),
      ],
    );
  }
}

class _HistoryExpandedDetails extends StatelessWidget {
  const _HistoryExpandedDetails({
    required this.item,
    required this.onOpenBatch,
    required this.onOpenTrace,
  });

  final _OwnershipHistoryItem item;
  final VoidCallback onOpenBatch;
  final VoidCallback onOpenTrace;

  @override
  Widget build(BuildContext context) {
    // [FE - Component Rendering] Detail expand menampilkan data audit krusial
    // tanpa memenuhi kartu utama saat halaman pertama kali dibuka.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 14),
        const Divider(height: 1, color: _borderColor),
        const SizedBox(height: 12),
        _DetailRow(label: 'Tanggal & Waktu', value: _formatDateTime(item.timestamp)),
        _DetailRow(label: 'Kebun', value: item.batch.farmName),
        _DetailRow(label: 'Jumlah Awal', value: item.initialAmount),
        _DetailRow(label: 'Jumlah Diterima', value: item.receivedAmount),
        _DetailRow(label: 'Grade', value: item.gradeInfo),
        _DetailRow(label: 'Persetujuan', value: item.approvalLabel),
        _DetailRow(label: 'Kondisi Fisik', value: item.conditionNotes),
        const _DetailRow(
          label: 'Foto Penerimaan',
          value: 'Belum ada foto penerimaan',
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onOpenTrace,
                icon: const Icon(Icons.route_rounded, size: 17),
                label: const Text('Trace'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primaryContainer),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 11),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onOpenBatch,
                icon: const Icon(Icons.open_in_new_rounded, size: 17),
                label: const Text('Detail'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.placeholder,
                  side: const BorderSide(color: _borderColor),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 11),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

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
            width: 112,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
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
                color: AppColors.subtitle,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: _pageBackground,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.placeholder),
          const SizedBox(width: 5),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 170),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.placeholder,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final BatchStatus status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: status.background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w900,
          color: status.color,
        ),
      ),
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(
                Icons.timeline_rounded,
                size: 34,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Belum ada perpindahan',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: AppColors.black,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Batch yang diterima, ditolak, atau berpindah ke role berikutnya akan tercatat di sini.',
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

String? _cleanText(String? value) {
  final text = value?.trim();
  if (text == null || text.isEmpty) return null;
  return text;
}

String _formatNumber(num value) {
  if (value % 1 == 0) return value.toInt().toString();
  return value.toStringAsFixed(1);
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
  final hour = date.hour.toString().padLeft(2, '0');
  final minute = date.minute.toString().padLeft(2, '0');
  return '${_formatShortDate(date)} ${date.year}, $hour:$minute';
}
