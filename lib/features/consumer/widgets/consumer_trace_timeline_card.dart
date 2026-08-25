import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../farmer/data/farmer_repository.dart';
import '../../farmer/models/batch_event.dart';
import '../../trace/screens/public_trace_screen.dart';
import '../../traceability/data/traceability_repository.dart';
import '../../traceability/models/traceability_models.dart';
import '../consumer_routes.dart';

class ConsumerTraceTimelineCard extends StatelessWidget {
  const ConsumerTraceTimelineCard({
    super.key,
    required this.traceCode,
    this.title = 'Tracking Asal Usul Durian',
    this.maxVisibleItems = 5,
  });

  final String? traceCode;
  final String title;
  final int maxVisibleItems;

  @override
  Widget build(BuildContext context) {
    final cleanCode = _cleanTraceCode(traceCode);
    final steps = _buildSteps(cleanCode);
    final visibleSteps = steps.take(maxVisibleItems).toList();
    final hiddenCount = steps.length - visibleSteps.length;

    return Container(
      width: double.infinity,
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
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.timeline_rounded,
                  color: AppColors.primary,
                  size: 19,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: AppColors.black,
                      ),
                    ),
                    if (cleanCode != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Kode trace: $cleanCode',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.placeholder,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (visibleSteps.isEmpty)
            const _EmptyTraceState()
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(10, 2, 10, 0),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  for (var i = 0; i < visibleSteps.length; i++)
                    _TraceTimelineItem(
                      step: visibleSteps[i],
                      isFirst: i == 0,
                      isLast: i == visibleSteps.length - 1,
                    ),
                ],
              ),
            ),
          if (hiddenCount > 0) ...[
            const SizedBox(height: 8),
            Text(
              '+ $hiddenCount event lain tersedia di trace lengkap.',
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.placeholder,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          if (cleanCode != null) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () {
                ConsumerRoutes.push(
                  context,
                  PublicTraceScreen(batchCode: cleanCode),
                );
              },
              icon: const Icon(Icons.account_tree_outlined, size: 18),
              label: const Text('LIHAT TRACE LENGKAP'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(44),
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
                textStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String? _cleanTraceCode(String? raw) {
    final text = raw?.trim();
    if (text == null || text.isEmpty) return null;
    final match = RegExp(
      r'(UMKM-P-\d+|DRN-\d{4}-\d{6}|PGL-\d{3,4}-\d{3,6}|JDL-DST-\d{4}-\d{6})',
      caseSensitive: false,
    ).firstMatch(text);
    return (match?.group(0) ?? text).trim().toUpperCase();
  }

  List<_ConsumerTraceStep> _buildSteps(String? cleanCode) {
    if (cleanCode == null) return const [];
    final steps = <_ConsumerTraceStep>[];
    final seen = <String>{};

    void addStep(_ConsumerTraceStep step) {
      final key =
          '${step.title}|${step.actorLabel}|${step.timestamp.toIso8601String()}';
      if (seen.contains(key)) return;
      seen.add(key);
      steps.add(step);
    }

    final traceRepo = TraceabilityRepository.instance;
    final farmerRepo = FarmerRepository.instance;
    final lineageCodes = _lineageCodesFor(cleanCode, traceRepo);

    for (final code in lineageCodes) {
      final farmerBatch = farmerRepo.findPublicBatch(code);
      if (farmerBatch != null) {
        final events = farmerRepo.publicEventsFor(code);
        final createdEvent = events.firstWhere(
          (event) => event.type == BatchEventType.batchCreated,
          orElse: () => BatchEvent(
            title: 'Batch dibuat',
            actorLabel: 'Petani',
            timestamp: farmerBatch.createdAt ?? farmerBatch.harvestDate,
            status: farmerBatch.status,
            description: 'Batch panen dicatat oleh petani.',
            locationLabel: farmerBatch.farmName,
          ),
        );
        addStep(
          _ConsumerTraceStep(
            title: 'Batch dibuat',
            actorLabel: createdEvent.actorLabel,
            locationLabel: _publicLocation(createdEvent.locationLabel),
            timestamp: createdEvent.timestamp,
            description:
                createdEvent.description ??
                'Batch panen dicatat dan QR trace diterbitkan.',
          ),
        );

        for (final event in events.where(_isUsefulFarmerEvent)) {
          addStep(
            _ConsumerTraceStep(
              title: _publicFarmerTitle(event),
              actorLabel: event.actorLabel,
              locationLabel: _publicLocation(event.locationLabel),
              timestamp: event.timestamp,
              description: event.description ?? event.title,
            ),
          );
        }
      }

      final traceBatch = traceRepo.findBatch(code);
      final traceEvents = traceRepo
          .eventsForBatch(code)
          .where(_isUsefulTraceEvent);
      if (traceBatch != null && traceEvents.isEmpty && farmerBatch == null) {
        addStep(
          _ConsumerTraceStep(
            title: _titleForTraceBatch(traceBatch),
            actorLabel:
                '${traceBatch.currentHolderRole.label} - ${traceBatch.currentHolderName}',
            locationLabel: _publicLocation(
              traceBatch.publicLocationLabel ?? traceBatch.locationLabel,
            ),
            timestamp: traceBatch.createdAt,
            description: '${traceBatch.productName} tercatat di traceability.',
          ),
        );
      }

      for (final event in traceEvents) {
        addStep(
          _ConsumerTraceStep(
            title: _titleForTraceEvent(event),
            actorLabel: '${event.actorRole.label} - ${event.actorName}',
            locationLabel: _publicLocation(event.locationLabel),
            timestamp: event.occurredAt,
            description: _descriptionForTraceEvent(event),
          ),
        );
      }
    }

    steps.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return List.unmodifiable(steps);
  }

  List<String> _lineageCodesFor(
    String cleanCode,
    TraceabilityRepository traceRepo,
  ) {
    final result = <String>[];
    final visited = <String>{};

    void visit(String code) {
      final current = code.trim().toUpperCase();
      if (current.isEmpty || visited.contains(current)) return;
      visited.add(current);

      for (final relation in traceRepo.parentsOf(current)) {
        visit(relation.sourceBatchCode);
      }
      result.add(current);
    }

    visit(cleanCode);
    return result;
  }

  bool _isUsefulFarmerEvent(BatchEvent event) {
    return switch (event.type) {
      BatchEventType.qrScanned ||
      BatchEventType.batchVerified ||
      BatchEventType.batchGraded ||
      BatchEventType.batchRejected ||
      BatchEventType.batchSent ||
      BatchEventType.batchReceived ||
      BatchEventType.batchProcessed ||
      BatchEventType.batchSold ||
      BatchEventType.batchTransferred => true,
      _ => false,
    };
  }

  bool _isUsefulTraceEvent(TraceBatchEvent event) {
    return switch (event.type) {
      TraceEventType.harvestCreated ||
      TraceEventType.handoverDispatched ||
      TraceEventType.handoverReceived ||
      TraceEventType.receiptDisputed ||
      TraceEventType.gradingRecorded ||
      TraceEventType.splitCreated ||
      TraceEventType.consolidated ||
      TraceEventType.processed ||
      TraceEventType.consumerReleased ||
      TraceEventType.warehouseTransferred => true,
      _ => false,
    };
  }

  String _publicFarmerTitle(BatchEvent event) {
    return switch (event.type) {
      BatchEventType.qrScanned => 'QR discan penerima',
      BatchEventType.batchVerified => 'Diterima dan divalidasi',
      BatchEventType.batchGraded => 'Grading dicatat',
      BatchEventType.batchRejected => 'Ditolak penerima',
      BatchEventType.batchSent => 'Dikirim ke tujuan',
      BatchEventType.batchReceived => 'Diterima tujuan',
      BatchEventType.batchProcessed => 'Diolah UMKM',
      BatchEventType.batchSold => 'Dijual',
      BatchEventType.batchTransferred => 'Dipindahkan',
      _ => event.title,
    };
  }

  String _titleForTraceBatch(TraceBatch batch) {
    if (batch.productForm == 'processed_product') return 'Produk UMKM dibuat';
    return batch.currentHolderRole.label;
  }

  String _titleForTraceEvent(TraceBatchEvent event) {
    return switch (event.type) {
      TraceEventType.harvestCreated => 'Batch panen dicatat',
      TraceEventType.handoverDispatched => 'Dikirim ke tujuan',
      TraceEventType.handoverReceived => 'Diterima dan divalidasi',
      TraceEventType.receiptDisputed => 'Diterima dengan selisih',
      TraceEventType.gradingRecorded => 'Grading dicatat',
      TraceEventType.splitCreated => 'Sub-batch dibuat',
      TraceEventType.consolidated => 'Batch digabung',
      TraceEventType.processed => 'Produk UMKM dibuat',
      TraceEventType.consumerReleased => 'Dilepas ke konsumen',
      TraceEventType.warehouseTransferred => 'Transfer gudang',
      _ => event.type.label,
    };
  }

  String _descriptionForTraceEvent(TraceBatchEvent event) {
    if (event.description.trim().isNotEmpty) return event.description;
    return event.type.label;
  }

  String _publicLocation(String? location) {
    final parts = (location ?? '')
        .split(',')
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .where(
          (part) =>
              !part.toLowerCase().startsWith('jl ') &&
              !part.toLowerCase().startsWith('jalan ') &&
              !RegExp(r'^rt\b|^rw\b', caseSensitive: false).hasMatch(part),
        )
        .toList();
    if (parts.isEmpty) return 'Wilayah belum dicatat';
    final visible = parts.length <= 3 ? parts : parts.sublist(parts.length - 3);
    return visible.join(', ');
  }
}

class _TraceTimelineItem extends StatelessWidget {
  const _TraceTimelineItem({
    required this.step,
    required this.isFirst,
    required this.isLast,
  });

  final _ConsumerTraceStep step;
  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final accentColor = isFirst
        ? AppColors.primary
        : isLast
        ? const Color(0xFFE85D32)
        : const Color(0xFF94A3B8);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 48,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const SizedBox(height: 13),
                Text(
                  _formatDate(step.timestamp),
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 10,
                    height: 1.1,
                    fontWeight: FontWeight.w800,
                    color: AppColors.black,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _formatTime(step.timestamp),
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 10,
                    height: 1.1,
                    fontWeight: FontWeight.w600,
                    color: AppColors.placeholder,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 18,
            child: Column(
              children: [
                const SizedBox(height: 14),
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: accentColor,
                    shape: BoxShape.circle,
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 3),
                      color: const Color(0xFFD8E0D5),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(top: 10, bottom: isLast ? 12 : 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    step.title,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: AppColors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    step.actorLabel,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.subtitle,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.place_outlined,
                        size: 13,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          step.locationLabel,
                          style: const TextStyle(
                            fontSize: 10,
                            height: 1.25,
                            color: AppColors.placeholder,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    step.description,
                    style: const TextStyle(
                      fontSize: 11,
                      height: 1.35,
                      color: AppColors.placeholder,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
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
    return '${dt.day} ${months[dt.month - 1]}';
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

class _EmptyTraceState extends StatelessWidget {
  const _EmptyTraceState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Text(
        'Timeline asal-usul belum tersedia untuk produk ini.',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 12,
          height: 1.35,
          color: AppColors.placeholder,
        ),
      ),
    );
  }
}

class _ConsumerTraceStep {
  const _ConsumerTraceStep({
    required this.title,
    required this.actorLabel,
    required this.locationLabel,
    required this.timestamp,
    required this.description,
  });

  final String title;
  final String actorLabel;
  final String locationLabel;
  final DateTime timestamp;
  final String description;
}
