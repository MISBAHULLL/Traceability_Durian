import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_top_bar.dart';
import '../../../shared/widgets/primary_pill_button.dart';
import '../../../shared/widgets/top_notification_banner.dart';
import '../../collector/models/collector_shipment_batch.dart';
import '../../farmer/models/harvest_batch.dart';
import '../data/distributor_repository.dart';
import '../distributor_routes.dart';
import '../models/distributor_acquisition_transaction.dart';
import 'distributor_acquisition_verify_screen.dart';

const _pageBackground = Color(0xFFF4F6F3);
const _borderColor = Color(0xFFE1E6DF);

class DistributorAcquisitionScreen extends StatefulWidget {
  const DistributorAcquisitionScreen({super.key});

  @override
  State<DistributorAcquisitionScreen> createState() =>
      _DistributorAcquisitionScreenState();
}

class _DistributorAcquisitionScreenState
    extends State<DistributorAcquisitionScreen> {
  final _repo = DistributorRepository.instance;
  final _notification = TopNotification();
  final _codeCtrl = TextEditingController();

  DistributorAcquisitionSource _source = DistributorAcquisitionSource.collector;
  bool _isStarting = false;

  @override
  void initState() {
    super.initState();
    _repo.addListener(_onRepoChanged);
  }

  @override
  void dispose() {
    _repo.removeListener(_onRepoChanged);
    _notification.dispose();
    _codeCtrl.dispose();
    super.dispose();
  }

  void _onRepoChanged() {
    if (mounted) setState(() {});
  }

  String _extractCode(String raw) {
    final text = raw.trim();
    final pattern = _source == DistributorAcquisitionSource.farmer
        ? r'DRN-\d{4}-\d{6}'
        : r'(?:BATCH-)?PGL-\d{3,4}-\d{3,6}';
    final match = RegExp(pattern, caseSensitive: false).firstMatch(text);
    return (match?.group(0) ?? text).toUpperCase();
  }

  Future<void> _startFromInput() async {
    FocusScope.of(context).unfocus();
    final code = _extractCode(_codeCtrl.text);
    if (code.isEmpty) {
      _notification.show(
        context,
        'Masukkan kode sumber dahulu.',
        isError: true,
      );
      return;
    }
    await _startAcquisition(code);
  }

  Future<void> _startAcquisition(String code) async {
    setState(() => _isStarting = true);
    await Future.delayed(const Duration(milliseconds: 250));
    if (!mounted) return;

    final transaction = _source == DistributorAcquisitionSource.collector
        ? _repo.initiateCollectorAcquisition(code)
        : _repo.initiateFarmerAcquisition(code);
    setState(() => _isStarting = false);

    if (transaction == null) {
      _notification.show(
        context,
        _source == DistributorAcquisitionSource.collector
            ? 'Manifest PGL tidak tersedia untuk akuisisi.'
            : 'Batch DRN tidak tersedia untuk akuisisi langsung.',
        isError: true,
      );
      return;
    }

    await _openT2(transaction);
  }

  Future<void> _openT2(DistributorAcquisitionTransaction transaction) async {
    final completed = await DistributorRoutes.push<bool>(
      context,
      DistributorAcquisitionVerifyScreen(transactionId: transaction.id),
    );
    if (!mounted) return;
    if (completed == true) {
      _codeCtrl.clear();
      _notification.show(context, '${transaction.id} berhasil selesai.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final pending = _repo.pendingAcquisitionTransactions;
    final collectorShipments = _repo.availableCollectorAcquisitionShipments;
    final farmerBatches = _repo.availableFarmerAcquisitionBatches;

    return Scaffold(
      backgroundColor: _pageBackground,
      body: SafeArea(
        child: Column(
          children: [
            const ColoredBox(
              color: AppColors.white,
              child: AppTopBar(title: 'Akuisisi'),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
                children: [
                  _SummaryPanel(
                    collectorCount: collectorShipments.length,
                    farmerCount: farmerBatches.length,
                    pendingCount: pending.length,
                  ),
                  const SizedBox(height: 14),
                  _SourceToggle(
                    source: _source,
                    onChanged: (source) {
                      setState(() {
                        _source = source;
                        _codeCtrl.clear();
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  _ManualCodePanel(
                    source: _source,
                    controller: _codeCtrl,
                    isLoading: _isStarting,
                    onSubmit: _startFromInput,
                  ),
                  if (pending.isNotEmpty) ...[
                    const SizedBox(height: 18),
                    _SectionHeader(
                      title: 'T1 Menunggu T2',
                      count: pending.length,
                    ),
                    const SizedBox(height: 8),
                    ...pending.map(
                      (transaction) => Padding(
                        padding: const EdgeInsets.only(bottom: 9),
                        child: _PendingTransactionTile(
                          transaction: transaction,
                          onTap: () => _openT2(transaction),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 18),
                  _SectionHeader(
                    title: _source == DistributorAcquisitionSource.collector
                        ? 'Manifest Pengepul Tersedia'
                        : 'Batch Petani Tersedia',
                    count: _source == DistributorAcquisitionSource.collector
                        ? collectorShipments.length
                        : farmerBatches.length,
                  ),
                  const SizedBox(height: 8),
                  if (_source == DistributorAcquisitionSource.collector)
                    if (collectorShipments.isEmpty)
                      const _EmptyState(
                        message: 'Belum ada manifest PGL siap dibeli.',
                      )
                    else
                      ...collectorShipments.map(
                        (shipment) => Padding(
                          padding: const EdgeInsets.only(bottom: 9),
                          child: _CollectorShipmentTile(
                            shipment: shipment,
                            onTap: () => _startAcquisition(shipment.code),
                          ),
                        ),
                      )
                  else if (farmerBatches.isEmpty)
                    const _EmptyState(
                      message: 'Belum ada batch DRN dari petani.',
                    )
                  else
                    ...farmerBatches.map(
                      (batch) => Padding(
                        padding: const EdgeInsets.only(bottom: 9),
                        child: _FarmerBatchTile(
                          batch: batch,
                          onTap: () => _startAcquisition(batch.code),
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

class _SummaryPanel extends StatelessWidget {
  const _SummaryPanel({
    required this.collectorCount,
    required this.farmerCount,
    required this.pendingCount,
  });

  final int collectorCount;
  final int farmerCount;
  final int pendingCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 88, 168, 53),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: _SummaryMetric(label: 'PGL', value: '$collectorCount'),
          ),
          Container(width: 1, height: 38, color: const Color(0xFF8BCB70)),
          Expanded(
            child: _SummaryMetric(label: 'DRN', value: '$farmerCount'),
          ),
          Container(width: 1, height: 38, color: const Color(0xFF8BCB70)),
          Expanded(
            child: _SummaryMetric(label: 'Pending T2', value: '$pendingCount'),
          ),
        ],
      ),
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  const _SummaryMetric({required this.label, required this.value});

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
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: AppColors.white,
            ),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11, color: Color(0xFFEAF7E5)),
          ),
        ],
      ),
    );
  }
}

class _SourceToggle extends StatelessWidget {
  const _SourceToggle({required this.source, required this.onChanged});

  final DistributorAcquisitionSource source;
  final ValueChanged<DistributorAcquisitionSource> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _borderColor),
      ),
      child: Row(
        children: [
          Expanded(
            child: _SourceButton(
              icon: Icons.storefront_outlined,
              label: 'Pengepul',
              selected: source == DistributorAcquisitionSource.collector,
              onTap: () => onChanged(DistributorAcquisitionSource.collector),
            ),
          ),
          Expanded(
            child: _SourceButton(
              icon: Icons.agriculture_outlined,
              label: 'Petani',
              selected: source == DistributorAcquisitionSource.farmer,
              onTap: () => onChanged(DistributorAcquisitionSource.farmer),
            ),
          ),
        ],
      ),
    );
  }
}

class _SourceButton extends StatelessWidget {
  const _SourceButton({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryContainer : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 17,
              color: selected ? AppColors.white : AppColors.placeholder,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: selected ? AppColors.white : AppColors.placeholder,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ManualCodePanel extends StatelessWidget {
  const _ManualCodePanel({
    required this.source,
    required this.controller,
    required this.isLoading,
    required this.onSubmit,
  });

  final DistributorAcquisitionSource source;
  final TextEditingController controller;
  final bool isLoading;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final hint = source == DistributorAcquisitionSource.collector
        ? 'Contoh: PGL-2026-000901'
        : 'Contoh: DRN-2026-000128';

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
          const Text(
            'Input Kode QR',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: AppColors.black,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(
              hintText: hint,
              prefixIcon: const Icon(Icons.qr_code_2_rounded),
              filled: true,
              fillColor: _pageBackground,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: _borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(
                  color: AppColors.primaryContainer,
                  width: 2,
                ),
              ),
            ),
            onSubmitted: (_) => onSubmit(),
          ),
          const SizedBox(height: 12),
          PrimaryPillButton(
            label: 'BUAT T1',
            onPressed: isLoading ? null : onSubmit,
            isLoading: isLoading,
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.count});

  final String title;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: AppColors.black,
            ),
          ),
        ),
        Text(
          '$count data',
          style: const TextStyle(fontSize: 11, color: AppColors.placeholder),
        ),
      ],
    );
  }
}

class _PendingTransactionTile extends StatelessWidget {
  const _PendingTransactionTile({
    required this.transaction,
    required this.onTap,
  });

  final DistributorAcquisitionTransaction transaction;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _BaseTile(
      icon: Icons.pending_actions_outlined,
      code: transaction.id,
      title: '${transaction.source.label} - ${transaction.itemCode}',
      subtitle:
          '${transaction.itemName} / ${_formatWeight(transaction.expectedWeightKg)}',
      badge: transaction.status.label,
      onTap: onTap,
    );
  }
}

class _CollectorShipmentTile extends StatelessWidget {
  const _CollectorShipmentTile({required this.shipment, required this.onTap});

  final CollectorShipmentBatch shipment;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _BaseTile(
      icon: Icons.inventory_2_outlined,
      code: shipment.code,
      title:
          '${_formatWeight(shipment.totalWeightKg)} / ${shipment.totalFruitCount} butir',
      subtitle: '${shipment.sourceBatchCodes.length} batch sumber pengepul',
      badge: 'Buat T1',
      onTap: onTap,
    );
  }
}

class _FarmerBatchTile extends StatelessWidget {
  const _FarmerBatchTile({required this.batch, required this.onTap});

  final HarvestBatch batch;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _BaseTile(
      icon: Icons.agriculture_outlined,
      code: batch.code,
      title:
          'Durian ${batch.variety} / ${_formatWeight(batch.quantity)} / ${batch.fruitCount ?? 0} butir',
      subtitle: batch.farmName,
      badge: 'Buat T1',
      onTap: onTap,
    );
  }
}

class _BaseTile extends StatelessWidget {
  const _BaseTile({
    required this.icon,
    required this.code,
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.onTap,
  });

  final IconData icon;
  final String code;
  final String title;
  final String subtitle;
  final String badge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _borderColor),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primaryContainer.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 21, color: AppColors.primary),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    code,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.black,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.placeholder,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.primaryContainer.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                badge,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _borderColor),
      ),
      child: Text(
        message,
        style: const TextStyle(fontSize: 12, color: AppColors.placeholder),
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
