import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_top_bar.dart';
import '../../../shared/widgets/batch_photo.dart';
import '../../farmer/data/farmer_repository.dart';
import '../../farmer/models/harvest_batch.dart';

// [FE - Component Rendering] Screen ini menjadi halaman trace publik yang
// dibuka dari QR batch; konsumen hanya membaca data tanpa aksi edit/verifikasi.
class PublicTraceScreen extends StatefulWidget {
  const PublicTraceScreen({super.key, required this.batchCode});

  final String batchCode;

  @override
  State<PublicTraceScreen> createState() => _PublicTraceScreenState();
}

class _PublicTraceScreenState extends State<PublicTraceScreen> {
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

  void _onRepoChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final batch = _repo.findPublicBatch(widget.batchCode);

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            const AppTopBar(title: 'Trace Durian'),
            Expanded(
              child: batch == null
                  ? _TraceNotFound(batchCode: widget.batchCode)
                  : _TraceContent(batch: batch),
            ),
          ],
        ),
      ),
    );
  }
}

class _TraceContent extends StatelessWidget {
  const _TraceContent({required this.batch});

  final HarvestBatch batch;

  String _formatDate(DateTime d) {
    const months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  String _formatDateTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '${_formatDate(dt)}, $h:$m';
  }

  @override
  Widget build(BuildContext context) {
    final hasPhoto = batch.photoPath != null && batch.photoPath!.isNotEmpty;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _TraceStatusHeader(batch: batch),
          const SizedBox(height: 16),
          if (hasPhoto) ...[
            BatchPhoto(
              path: batch.photoPath,
              width: double.infinity,
              height: 190,
              borderRadius: BorderRadius.circular(10),
            ),
            const SizedBox(height: 16),
          ],
          _TraceSection(
            title: 'Informasi Durian',
            children: [
              _TraceInfoRow(label: 'Kode Batch', value: batch.code),
              _TraceInfoRow(label: 'Varietas', value: batch.variety),
              _TraceInfoRow(
                label: 'Total Berat',
                value: '${batch.quantity.toStringAsFixed(0)} ${batch.unit}',
              ),
              if (batch.fruitCount != null)
                _TraceInfoRow(
                  label: 'Jumlah Buah',
                  value: '${batch.fruitCount} butir',
                ),
              _TraceInfoRow(
                label: 'Grade Awal Petani',
                value: 'Grade ${batch.grade}',
              ),
              // [FE - Component Rendering] Data sortir pengepul ditampilkan
              // sebagai hasil verifikasi, bukan pengganti data awal petani.
              if (batch.verifiedGrade != null &&
                  batch.verifiedGrade!.isNotEmpty)
                _TraceInfoRow(
                  label: 'Grade Pengepul',
                  value: 'Grade ${batch.verifiedGrade}',
                ),
              if (batch.receivedQuantity != null)
                _TraceInfoRow(
                  label: 'Berat Diterima',
                  value:
                      '${batch.receivedQuantity!.toStringAsFixed(0)} ${batch.unit}',
                ),
              if (batch.verifiedBy != null && batch.verifiedBy!.isNotEmpty)
                _TraceInfoRow(
                  label: 'Diverifikasi Oleh',
                  value: batch.verifiedBy!,
                ),
              if (batch.verifiedAt != null)
                _TraceInfoRow(
                  label: 'Waktu Verifikasi',
                  value: _formatDateTime(batch.verifiedAt!),
                ),
              _TraceInfoRow(
                label: 'Tanggal Panen',
                value: _formatDate(batch.harvestDate),
              ),
              _TraceInfoRow(label: 'Asal Kebun', value: batch.farmName),
              if (batch.maturityLevel != null &&
                  batch.maturityLevel!.isNotEmpty)
                _TraceInfoRow(label: 'Kematangan', value: batch.maturityLevel!),
              if (batch.shelfLifeEstimate != null &&
                  batch.shelfLifeEstimate!.isNotEmpty)
                _TraceInfoRow(
                  label: 'Masa Simpan',
                  value: batch.shelfLifeEstimate!,
                ),
              if (batch.harvestMethod != null &&
                  batch.harvestMethod!.isNotEmpty)
                _TraceInfoRow(
                  label: 'Metode Panen',
                  value: batch.harvestMethod!,
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (_hasHandlingInfo(batch)) ...[
            _TraceSection(
              title: 'Catatan Kualitas',
              children: [
                if (batch.storageSuggestion != null &&
                    batch.storageSuggestion!.isNotEmpty)
                  _TraceInfoRow(
                    label: 'Saran Simpan',
                    value: batch.storageSuggestion!,
                  ),
                if (batch.notes != null && batch.notes!.isNotEmpty)
                  _TraceInfoRow(label: 'Catatan', value: batch.notes!),
                if (batch.qualityNotes != null &&
                    batch.qualityNotes!.isNotEmpty)
                  _TraceInfoRow(
                    label: 'Catatan Sortir',
                    value: batch.qualityNotes!,
                  ),
              ],
            ),
            const SizedBox(height: 16),
          ],
          _TraceTimeline(status: batch.status),
        ],
      ),
    );
  }

  bool _hasHandlingInfo(HarvestBatch batch) {
    return (batch.storageSuggestion != null &&
            batch.storageSuggestion!.isNotEmpty) ||
        (batch.notes != null && batch.notes!.isNotEmpty) ||
        (batch.qualityNotes != null && batch.qualityNotes!.isNotEmpty);
  }
}

class _TraceStatusHeader extends StatelessWidget {
  const _TraceStatusHeader({required this.batch});

  final HarvestBatch batch;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: batch.status.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: batch.status.color.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.verified_outlined, color: batch.status.color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  batch.status.label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: batch.status.color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Durian ${batch.variety}',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.black,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            batch.code,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.subtitle,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }
}

// [FE - Component Rendering] Section ini mengelompokkan atribut trace agar
// konsumen dapat membaca asal, kualitas, dan handling batch secara terstruktur.
class _TraceSection extends StatelessWidget {
  const _TraceSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppColors.black,
            ),
          ),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }
}

class _TraceInfoRow extends StatelessWidget {
  const _TraceInfoRow({required this.label, required this.value});

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
            width: 118,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
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
                fontWeight: FontWeight.w700,
                color: AppColors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// [FE - Component Rendering] Timeline ini menerjemahkan status batch menjadi
// perjalanan rantai pasok yang mudah dibaca konsumen.
class _TraceTimeline extends StatelessWidget {
  const _TraceTimeline({required this.status});

  final BatchStatus status;

  @override
  Widget build(BuildContext context) {
    final steps = _stepsFor(status);

    return _TraceSection(
      title: 'Perjalanan Batch',
      children: [
        for (var i = 0; i < steps.length; i++)
          _TimelineItem(
            step: steps[i],
            isLast: i == steps.length - 1,
          ),
      ],
    );
  }

  List<_TraceStep> _stepsFor(BatchStatus status) {
    final order = [
      BatchStatus.created,
      BatchStatus.verifiedByCollector,
      BatchStatus.inDistribution,
      BatchStatus.receivedByUmkm,
      BatchStatus.processed,
      BatchStatus.sold,
    ];
    final statusIndex = order.indexOf(status);
    final currentIndex = status == BatchStatus.rejected
        ? 0
        : statusIndex < 0
            ? 0
            : statusIndex.clamp(0, order.length - 1).toInt();

    return [
      _TraceStep(
        title: 'Batch Dicatat Petani',
        description: 'Data panen dan QR batch dibuat.',
        state: _stateFor(0, currentIndex, status),
      ),
      _TraceStep(
        title: 'Diverifikasi Pengepul',
        description: 'Pengepul mengecek jumlah dan mutu durian.',
        state: _stateFor(1, currentIndex, status),
      ),
      _TraceStep(
        title: 'Distribusi',
        description: 'Batch dikirim ke tujuan berikutnya.',
        state: _stateFor(2, currentIndex, status),
      ),
      _TraceStep(
        title: 'Diterima UMKM/Retailer',
        description: 'Batch diterima untuk proses lanjutan atau penjualan.',
        state: _stateFor(3, currentIndex, status),
      ),
      _TraceStep(
        title: 'Siap Konsumsi/Jual',
        description: 'Produk berada di tahap akhir rantai pasok.',
        state: _stateFor(4, currentIndex, status),
      ),
    ];
  }

  _TraceStepState _stateFor(int index, int currentIndex, BatchStatus status) {
    if (status == BatchStatus.rejected) {
      if (index == 0) return _TraceStepState.done;
      if (index == 1) return _TraceStepState.rejected;
      return _TraceStepState.pending;
    }
    if (index < currentIndex) return _TraceStepState.done;
    if (index == currentIndex) return _TraceStepState.current;
    return _TraceStepState.pending;
  }
}

enum _TraceStepState { done, current, pending, rejected }

class _TraceStep {
  const _TraceStep({
    required this.title,
    required this.description,
    required this.state,
  });

  final String title;
  final String description;
  final _TraceStepState state;
}

class _TimelineItem extends StatelessWidget {
  const _TimelineItem({required this.step, required this.isLast});

  final _TraceStep step;
  final bool isLast;

  Color get _color {
    switch (step.state) {
      case _TraceStepState.done:
      case _TraceStepState.current:
        return AppColors.primaryContainer;
      case _TraceStepState.rejected:
        return const Color(0xFFD64545);
      case _TraceStepState.pending:
        return const Color(0xFFCBD5E1);
    }
  }

  IconData get _icon {
    switch (step.state) {
      case _TraceStepState.done:
        return Icons.check_rounded;
      case _TraceStepState.current:
        return Icons.radio_button_checked_rounded;
      case _TraceStepState.rejected:
        return Icons.close_rounded;
      case _TraceStepState.pending:
        return Icons.circle_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: _color.withValues(alpha: 0.14),
                shape: BoxShape.circle,
              ),
              child: Icon(_icon, size: 15, color: _color),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 34,
                color: _color.withValues(alpha: 0.26),
              ),
          ],
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step.title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: step.state == _TraceStepState.pending
                        ? AppColors.placeholder
                        : AppColors.black,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  step.description,
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1.35,
                    color: AppColors.placeholder,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _TraceNotFound extends StatelessWidget {
  const _TraceNotFound({required this.batchCode});

  final String batchCode;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.search_off_rounded,
            size: 64,
            color: Color(0xFFCBD5E1),
          ),
          const SizedBox(height: 16),
          const Text(
            'Batch tidak ditemukan',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            batchCode,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.placeholder,
            ),
          ),
        ],
      ),
    );
  }
}
