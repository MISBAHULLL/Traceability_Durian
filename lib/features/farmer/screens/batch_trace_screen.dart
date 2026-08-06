import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_top_bar.dart';
import '../data/farmer_repository.dart';
import '../models/batch_event.dart';
import '../models/harvest_batch.dart';

const _pageBackground = Color(0xFFF4F6F3);
const _borderColor = Color(0xFFE1E6DF);

// [FE - Component Rendering] Screen ini menampilkan visual trace perjalanan
// satu batch sebagai node dinamis, bukan peta geografis yang kaku.
class BatchTraceScreen extends StatefulWidget {
  const BatchTraceScreen({super.key, required this.batchCode});

  final String batchCode;

  @override
  State<BatchTraceScreen> createState() => _BatchTraceScreenState();
}

class _BatchTraceScreenState extends State<BatchTraceScreen> {
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

  // [FE - State Management] Listener ini menjaga visual trace tetap sinkron
  // saat status batch berubah dari role lain pada fase mock/local data.
  void _onRepoChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final batch = _repo.findBatch(widget.batchCode);

    return Scaffold(
      backgroundColor: _pageBackground,
      body: SafeArea(
        child: Column(
          children: [
            const ColoredBox(
              color: AppColors.homeHeaderSurface,
              child: AppTopBar(title: 'Trace Journey'),
            ),
            Expanded(
              child: batch == null
                  ? _TraceNotFound(batchCode: widget.batchCode)
                  : _TraceContent(
                      batch: batch,
                      profileName: _repo.profile.fullName,
                      events: _repo.eventsFor(batch.code),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TraceContent extends StatelessWidget {
  const _TraceContent({
    required this.batch,
    required this.profileName,
    required this.events,
  });

  final HarvestBatch batch;
  final String profileName;
  final List<BatchEvent> events;

  @override
  Widget build(BuildContext context) {
    final steps = _TraceStepFactory.build(
      batch: batch,
      farmerName: profileName,
      events: events,
    );

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      children: [
        _TraceHeader(batch: batch),
        const SizedBox(height: 14),
        _JourneyMap(steps: steps),
        const SizedBox(height: 14),
        _TraceFacts(batch: batch),
        const SizedBox(height: 14),
        _EvidenceList(steps: steps),
      ],
    );
  }
}

class _TraceHeader extends StatelessWidget {
  const _TraceHeader({required this.batch});

  final HarvestBatch batch;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.route_rounded,
              color: AppColors.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  batch.code,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${batch.variety} - ${batch.farmName}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.placeholder,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          _TraceStatusBadge(status: batch.status),
        ],
      ),
    );
  }
}

class _JourneyMap extends StatelessWidget {
  const _JourneyMap({required this.steps});

  final List<_TraceStep> steps;

  @override
  Widget build(BuildContext context) {
    // [FE - Component Rendering] Journey map ini merender node role secara
    // dinamis dari event batch, sehingga jalur tidak dipaksa selalu linear.
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.route_rounded, color: AppColors.primary),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Visual Trace',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: AppColors.black,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List.generate(steps.length, (index) {
                final step = steps[index];
                final isLast = index == steps.length - 1;

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _JourneyNode(step: step, isCurrent: isLast),
                    if (!isLast)
                      _JourneyConnector(color: steps[index + 1].color),
                  ],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _JourneyNode extends StatelessWidget {
  const _JourneyNode({required this.step, required this.isCurrent});

  final _TraceStep step;
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 104,
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: step.color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
              border: Border.all(
                color: isCurrent
                    ? step.color
                    : step.color.withValues(alpha: 0.35),
                width: isCurrent ? 2 : 1,
              ),
            ),
            child: Icon(step.icon, color: step.color, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            step.roleLabel,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              height: 1.2,
              fontWeight: FontWeight.w900,
              color: AppColors.black,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            step.actionLabel,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 10.5,
              height: 1.2,
              color: AppColors.placeholder,
            ),
          ),
        ],
      ),
    );
  }
}

class _JourneyConnector extends StatelessWidget {
  const _JourneyConnector({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 52,
      alignment: Alignment.center,
      child: Container(
        height: 2,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }
}

class _TraceFacts extends StatelessWidget {
  const _TraceFacts({required this.batch});

  final HarvestBatch batch;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ringkasan Batch',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: AppColors.black,
            ),
          ),
          const SizedBox(height: 12),
          _FactRow(label: 'Jumlah Awal', value: _initialAmount(batch)),
          _FactRow(label: 'Jumlah Diterima', value: _receivedAmount(batch)),
          _FactRow(label: 'Grade', value: _gradeInfo(batch)),
          _FactRow(
            label: 'Tanggal Panen',
            value: _formatDate(batch.harvestDate),
          ),
        ],
      ),
    );
  }
}

class _EvidenceList extends StatelessWidget {
  const _EvidenceList({required this.steps});

  final List<_TraceStep> steps;

  @override
  Widget build(BuildContext context) {
    // [FE - Component Rendering] Panel bukti menurunkan visual node menjadi
    // daftar audit detail untuk kebutuhan validasi traceability.
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Bukti Perjalanan',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: AppColors.black,
            ),
          ),
          const SizedBox(height: 12),
          ...List.generate(steps.length, (index) {
            final step = steps[index];
            return _EvidenceItem(step: step, isLast: index == steps.length - 1);
          }),
        ],
      ),
    );
  }
}

class _EvidenceItem extends StatelessWidget {
  const _EvidenceItem({required this.step, required this.isLast});

  final _TraceStep step;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: step.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(step.icon, color: step.color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step.title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: AppColors.black,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  step.description,
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1.35,
                    color: AppColors.placeholder,
                  ),
                ),
                if (step.timestamp != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    _formatDateTime(step.timestamp!),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FactRow extends StatelessWidget {
  const _FactRow({required this.label, required this.value});

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
                height: 1.35,
                fontWeight: FontWeight.w800,
                color: AppColors.subtitle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TraceStatusBadge extends StatelessWidget {
  const _TraceStatusBadge({required this.status});

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

class _TraceNotFound extends StatelessWidget {
  const _TraceNotFound({required this.batchCode});

  final String batchCode;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.search_off_rounded,
              size: 54,
              color: AppColors.placeholder,
            ),
            const SizedBox(height: 14),
            const Text(
              'Trace tidak ditemukan',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: AppColors.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Kode $batchCode tidak tersedia untuk akun ini.',
              textAlign: TextAlign.center,
              style: const TextStyle(
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

// [FE - State Management] Factory ini menerjemahkan event status menjadi node
// visual sehingga BE nanti cukup mengganti sumber event tanpa mengubah UI.
class _TraceStepFactory {
  const _TraceStepFactory._();

  static List<_TraceStep> build({
    required HarvestBatch batch,
    required String farmerName,
    required List<BatchEvent> events,
  }) {
    final createdAt = batch.createdAt ?? batch.harvestDate;
    final steps = <_TraceStep>[
      _TraceStep(
        roleLabel: 'Petani',
        actionLabel: 'Panen dicatat',
        title: 'Batch dibuat',
        description:
            '$farmerName mencatat ${batch.variety} dari ${batch.farmName}.',
        timestamp: createdAt,
        status: BatchStatus.created,
        icon: Icons.agriculture_rounded,
      ),
    ];

    final handoverEvents = events.where((event) {
      return event.status != BatchStatus.created &&
          event.status != BatchStatus.draft;
    }).toList()..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    for (final event in handoverEvents) {
      steps.add(_TraceStep.fromEvent(event));
    }

    return steps;
  }
}

class _TraceStep {
  const _TraceStep({
    required this.roleLabel,
    required this.actionLabel,
    required this.title,
    required this.description,
    required this.timestamp,
    required this.status,
    required this.icon,
  });

  final String roleLabel;
  final String actionLabel;
  final String title;
  final String description;
  final DateTime? timestamp;
  final BatchStatus status;
  final IconData icon;

  Color get color => status.color;

  factory _TraceStep.fromEvent(BatchEvent event) {
    switch (event.status) {
      case BatchStatus.verifiedByCollector:
        return _TraceStep(
          roleLabel: _receiverRole(event),
          actionLabel: 'Menerima batch',
          title: 'Batch diterima',
          description: '${event.actorLabel} menerima dan memverifikasi batch.',
          timestamp: event.timestamp,
          status: event.status,
          icon: _receiverIcon(event),
        );
      case BatchStatus.inDistribution:
        return _TraceStep(
          roleLabel: 'Pengiriman',
          actionLabel: 'Dalam perjalanan',
          title: 'Batch dikirim',
          description:
              '${event.actorLabel} menyiapkan batch untuk penerima berikutnya.',
          timestamp: event.timestamp,
          status: event.status,
          icon: Icons.local_shipping_rounded,
        );
      case BatchStatus.receivedByUmkm:
        return _TraceStep(
          roleLabel: 'UMKM',
          actionLabel: 'Diterima',
          title: 'Batch diterima UMKM',
          description: '${event.actorLabel} mengonfirmasi penerimaan batch.',
          timestamp: event.timestamp,
          status: event.status,
          icon: Icons.storefront_rounded,
        );
      case BatchStatus.processed:
        return _TraceStep(
          roleLabel: 'UMKM',
          actionLabel: 'Diproses',
          title: 'Batch diproses',
          description: '${event.actorLabel} mengolah batch menjadi produk.',
          timestamp: event.timestamp,
          status: event.status,
          icon: Icons.settings_rounded,
        );
      case BatchStatus.sold:
        return _TraceStep(
          roleLabel: 'Konsumen',
          actionLabel: 'Terjual',
          title: 'Produk sampai konsumen',
          description: '${event.actorLabel} menyelesaikan penjualan produk.',
          timestamp: event.timestamp,
          status: event.status,
          icon: Icons.shopping_bag_rounded,
        );
      case BatchStatus.rejected:
        return _TraceStep(
          roleLabel: _receiverRole(event),
          actionLabel: 'Ditolak',
          title: 'Batch ditolak',
          description: '${event.actorLabel} menolak perpindahan batch.',
          timestamp: event.timestamp,
          status: event.status,
          icon: Icons.block_rounded,
        );
      case BatchStatus.draft:
      case BatchStatus.created:
        return _TraceStep(
          roleLabel: 'Petani',
          actionLabel: 'Dicatat',
          title: event.title,
          description: event.actorLabel,
          timestamp: event.timestamp,
          status: event.status,
          icon: Icons.agriculture_rounded,
        );
    }
  }

  static String _receiverRole(BatchEvent event) {
    final text = '${event.title} ${event.actorLabel}'.toLowerCase();
    if (text.contains('distributor')) return 'Distributor';
    if (text.contains('umkm')) return 'UMKM';
    if (text.contains('konsumen')) return 'Konsumen';
    return 'Pengepul';
  }

  static IconData _receiverIcon(BatchEvent event) {
    switch (_receiverRole(event)) {
      case 'Distributor':
        return Icons.business_rounded;
      case 'UMKM':
        return Icons.storefront_rounded;
      case 'Konsumen':
        return Icons.person_pin_circle_rounded;
      default:
        return Icons.inventory_2_rounded;
    }
  }
}

String _initialAmount(HarvestBatch batch) {
  return '${_formatNumber(batch.quantity)} ${batch.unit}${batch.fruitCount == null ? '' : ' / ${batch.fruitCount} butir'}';
}

String _receivedAmount(HarvestBatch batch) {
  if (batch.status == BatchStatus.rejected) return 'Tidak diterima';

  final kg = batch.receivedQuantity ?? batch.quantity;
  final fruit = batch.receivedFruitCount ?? batch.fruitCount;
  return '${_formatNumber(kg)} ${batch.unit}${fruit == null ? '' : ' / $fruit butir'}';
}

String _gradeInfo(HarvestBatch batch) {
  final verified = _cleanText(batch.verifiedGrade);
  if (verified == null) return 'Awal ${batch.grade}';
  return 'Awal ${batch.grade} - Riil $verified';
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

String _formatDateTime(DateTime date) {
  final hour = date.hour.toString().padLeft(2, '0');
  final minute = date.minute.toString().padLeft(2, '0');
  return '${_formatDate(date)}, $hour:$minute';
}
