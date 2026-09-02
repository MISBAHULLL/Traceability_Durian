import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_top_bar.dart';
import '../../../shared/widgets/primary_pill_button.dart';
import '../../../shared/widgets/top_notification_banner.dart';
import '../../farmer/models/harvest_batch.dart';
import '../data/distributor_repository.dart';
import '../models/distributor_acquisition_transaction.dart';
import '../models/distributor_receipt.dart';

const _pageBackground = Color(0xFFF4F6F3);
const _borderColor = Color(0xFFE1E6DF);

class DistributorAcquisitionVerifyScreen extends StatefulWidget {
  const DistributorAcquisitionVerifyScreen({
    super.key,
    required this.transactionId,
  });

  final String transactionId;

  @override
  State<DistributorAcquisitionVerifyScreen> createState() =>
      _DistributorAcquisitionVerifyScreenState();
}

class _DistributorAcquisitionVerifyScreenState
    extends State<DistributorAcquisitionVerifyScreen> {
  static const _grades = ['A', 'B', 'C'];

  final _repo = DistributorRepository.instance;
  final _notification = TopNotification();
  final _weightCtrl = TextEditingController();
  final _fruitCtrl = TextEditingController();
  final _destinationCtrl = TextEditingController();
  final _discrepancyCtrl = TextEditingController();
  final _qualityCtrl = TextEditingController();
  final _gradeWeightCtrls = {
    for (final grade in _grades) grade: TextEditingController(),
  };
  final _gradeFruitCtrls = {
    for (final grade in _grades) grade: TextEditingController(),
  };

  DistributorReceiptCondition? _condition;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final transaction = _repo.findAcquisitionTransaction(widget.transactionId);
    if (transaction != null) {
      _weightCtrl.text = _formatNumber(transaction.expectedWeightKg);
      _destinationCtrl.text =
          _repo.defaultWarehouse?.name ?? _repo.profile.location;
      if (transaction.expectedFruitCount > 0) {
        _fruitCtrl.text = transaction.expectedFruitCount.toString();
      }
      if (transaction.source == DistributorAcquisitionSource.farmer) {
        _gradeWeightCtrls['A']!.text = _formatNumber(
          transaction.expectedWeightKg,
        );
        if (transaction.expectedFruitCount > 0) {
          _gradeFruitCtrls['A']!.text = transaction.expectedFruitCount
              .toString();
        }
      }
    }
    _weightCtrl.addListener(_refresh);
    _fruitCtrl.addListener(_refresh);
  }

  @override
  void dispose() {
    _weightCtrl.removeListener(_refresh);
    _fruitCtrl.removeListener(_refresh);
    _weightCtrl.dispose();
    _fruitCtrl.dispose();
    _destinationCtrl.dispose();
    _discrepancyCtrl.dispose();
    _qualityCtrl.dispose();
    for (final controller in _gradeWeightCtrls.values) {
      controller.dispose();
    }
    for (final controller in _gradeFruitCtrls.values) {
      controller.dispose();
    }
    _notification.dispose();
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  double? get _receivedWeight =>
      double.tryParse(_weightCtrl.text.trim().replaceAll(',', '.'));

  int? get _receivedFruit => int.tryParse(_fruitCtrl.text.trim());

  bool _hasDiscrepancy(DistributorAcquisitionTransaction transaction) {
    final weight = _receivedWeight;
    final fruit = _receivedFruit;
    if (weight == null || fruit == null) return false;
    return (weight - transaction.expectedWeightKg).abs() > 0.01 ||
        fruit != transaction.expectedFruitCount;
  }

  List<BatchGradeBreakdown> _buildGradeBreakdown() {
    return _grades.map((grade) {
      return BatchGradeBreakdown(
        grade: grade,
        weightKg:
            double.tryParse(
              _gradeWeightCtrls[grade]!.text.trim().replaceAll(',', '.'),
            ) ??
            0,
        fruitCount: int.tryParse(_gradeFruitCtrls[grade]!.text.trim()) ?? 0,
      );
    }).toList();
  }

  Future<void> _submit(DistributorAcquisitionTransaction transaction) async {
    final weight = _receivedWeight;
    final fruit = _receivedFruit;
    if (weight == null || weight <= 0) {
      _notification.show(context, 'Berat diterima tidak valid.', isError: true);
      return;
    }
    if (fruit == null || fruit <= 0) {
      _notification.show(context, 'Jumlah buah tidak valid.', isError: true);
      return;
    }
    if (_destinationCtrl.text.trim().isEmpty) {
      _notification.show(
        context,
        'Lokasi tujuan penerimaan wajib diisi.',
        isError: true,
      );
      return;
    }
    final condition = _condition;
    if (condition == null) {
      _notification.show(context, 'Pilih kondisi fisik.', isError: true);
      return;
    }

    setState(() => _isSubmitting = true);
    await Future.delayed(const Duration(milliseconds: 450));
    if (!mounted) return;

    var success = false;
    if (transaction.source == DistributorAcquisitionSource.collector) {
      if (_hasDiscrepancy(transaction) &&
          _discrepancyCtrl.text.trim().isEmpty) {
        setState(() => _isSubmitting = false);
        _notification.show(
          context,
          'Jelaskan penyebab selisih manifest.',
          isError: true,
        );
        return;
      }

      success =
          _repo.completeCollectorAcquisition(
            transactionId: transaction.id,
            receivedWeightKg: weight,
            receivedFruitCount: fruit,
            condition: condition,
            destinationLocation: _destinationCtrl.text,
            discrepancyNote: _discrepancyCtrl.text,
            qualityNote: _qualityNoteWithCondition(condition),
          ) !=
          null;
    } else {
      final grades = _buildGradeBreakdown();
      final cleanGrades = grades.where((item) => item.hasValue).toList();
      final totalWeight = cleanGrades.fold<double>(
        0,
        (sum, item) => sum + item.weightKg,
      );
      final totalFruit = cleanGrades.fold<int>(
        0,
        (sum, item) => sum + item.fruitCount,
      );
      final invalidGrade = cleanGrades.any(
        (item) => item.weightKg <= 0 || item.fruitCount <= 0,
      );
      if (cleanGrades.isEmpty ||
          invalidGrade ||
          (totalWeight - weight).abs() > 0.01 ||
          totalFruit != fruit) {
        setState(() => _isSubmitting = false);
        _notification.show(
          context,
          'Komposisi Grade A/B/C harus sama dengan hasil diterima.',
          isError: true,
        );
        return;
      }

      success = _repo.completeFarmerAcquisition(
        transactionId: transaction.id,
        receivedWeightKg: weight,
        receivedFruitCount: fruit,
        gradeBreakdown: grades,
        destinationLocation: _destinationCtrl.text,
        qualityNote: _qualityNoteWithCondition(condition),
      );
    }

    setState(() => _isSubmitting = false);
    if (!success) {
      _notification.show(
        context,
        'Validasi gagal disimpan. Periksa status sumber stok.',
        isError: true,
      );
      return;
    }

    _notification.show(context, '${transaction.itemCode} selesai divalidasi.');
    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final transaction = _repo.findAcquisitionTransaction(widget.transactionId);
    final traceBatches = transaction == null
        ? <HarvestBatch>[]
        : _traceBatchesFor(transaction);
    final traceCodes = transaction == null
        ? <String>[]
        : _traceCodesFor(transaction);

    return Scaffold(
      backgroundColor: _pageBackground,
      body: SafeArea(
        child: Column(
          children: [
            const ColoredBox(
              color: AppColors.white,
              child: AppTopBar(title: 'Validasi Penerimaan'),
            ),
            Expanded(
              child: transaction == null
                  ? const _UnavailableState(
                      message: 'Transaksi tidak ditemukan.',
                    )
                  : transaction.status != DistributorAcquisitionStatus.initiated
                  ? const _UnavailableState(
                      message: 'Transaksi ini sudah selesai.',
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                      children: [
                        _TransactionSummary(transaction: transaction),
                        const SizedBox(height: 16),
                        _TracePanel(
                          transaction: transaction,
                          batches: traceBatches,
                          sourceCodes: traceCodes,
                        ),
                        const SizedBox(height: 16),
                        const _SectionTitle(title: 'Hasil Terima Aktual'),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: _NumberField(
                                controller: _weightCtrl,
                                label: 'Berat',
                                suffix: 'kg',
                                decimal: true,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _NumberField(
                                controller: _fruitCtrl,
                                label: 'Jumlah',
                                suffix: 'butir',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        _DifferencePanel(
                          transaction: transaction,
                          receivedWeight: _receivedWeight,
                          receivedFruit: _receivedFruit,
                        ),
                        const SizedBox(height: 16),
                        const _SectionTitle(title: 'Asal dan Gudang Tujuan'),
                        const SizedBox(height: 8),
                        _TextField(
                          controller: _destinationCtrl,
                          label: 'Gudang Tujuan Penerimaan',
                          hint: 'Contoh: Gudang Hub Surabaya',
                          required: true,
                        ),
                        if (transaction.source ==
                            DistributorAcquisitionSource.collector) ...[
                          if (_hasDiscrepancy(transaction)) ...[
                            const SizedBox(height: 12),
                            _TextArea(
                              controller: _discrepancyCtrl,
                              label: 'Alasan Selisih *',
                              hint:
                                  'Contoh: susut perjalanan atau timbang ulang',
                            ),
                          ],
                        ] else ...[
                          const SizedBox(height: 16),
                          const _SectionTitle(title: 'Komposisi Grade'),
                          const SizedBox(height: 8),
                          _GradeCompositionInput(
                            grades: _grades,
                            weightControllers: _gradeWeightCtrls,
                            fruitControllers: _gradeFruitCtrls,
                          ),
                        ],
                        const SizedBox(height: 16),
                        const _SectionTitle(title: 'Kondisi Fisik'),
                        const SizedBox(height: 8),
                        _ConditionSelector(
                          selected: _condition,
                          onChanged: (value) {
                            setState(() => _condition = value);
                          },
                        ),
                        const SizedBox(height: 14),
                        _TextArea(
                          controller: _qualityCtrl,
                          label: 'Catatan Pemeriksaan',
                          hint: 'Contoh: kemasan utuh, aroma normal',
                        ),
                        const SizedBox(height: 20),
                        PrimaryPillButton(
                          label: 'SIMPAN VALIDASI',
                          onPressed: _isSubmitting
                              ? null
                              : () => _submit(transaction),
                          isLoading: _isSubmitting,
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  List<HarvestBatch> _traceBatchesFor(
    DistributorAcquisitionTransaction transaction,
  ) {
    if (transaction.source == DistributorAcquisitionSource.collector) {
      final shipment = _repo.findShipment(transaction.itemCode);
      if (shipment == null) return const [];
      return _repo.sourceBatchesForShipment(shipment);
    }

    final batch = _repo.findFarmerAcquisitionBatch(transaction.itemCode);
    return batch == null ? const [] : [batch];
  }

  List<String> _traceCodesFor(DistributorAcquisitionTransaction transaction) {
    if (transaction.source == DistributorAcquisitionSource.collector) {
      final shipment = _repo.findShipment(transaction.itemCode);
      return shipment?.sourceBatchCodes ?? const [];
    }
    return [transaction.itemCode];
  }

  String? _qualityNoteWithCondition(DistributorReceiptCondition condition) {
    final note = _qualityCtrl.text.trim();
    final conditionText = 'Kondisi fisik: ${condition.label}';
    return note.isEmpty ? conditionText : '$conditionText. $note';
  }
}

class _TransactionSummary extends StatelessWidget {
  const _TransactionSummary({required this.transaction});

  final DistributorAcquisitionTransaction transaction;

  @override
  Widget build(BuildContext context) {
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
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.fact_check_outlined,
                  color: AppColors.primary,
                  size: 21,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transaction.id,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${transaction.source.label} - ${transaction.itemCode}',
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
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: _borderColor),
          const SizedBox(height: 10),
          _InfoRow(label: 'Item', value: transaction.itemName),
          _InfoRow(label: 'Asal', value: transaction.originLabel),
          _InfoRow(label: 'Supplier', value: transaction.supplierLabel),
          _InfoRow(
            label: 'Manifest',
            value:
                '${_formatNumber(transaction.expectedWeightKg)} kg / ${transaction.expectedFruitCount} butir',
          ),
        ],
      ),
    );
  }
}

class _TracePanel extends StatelessWidget {
  const _TracePanel({
    required this.transaction,
    required this.batches,
    required this.sourceCodes,
  });

  final DistributorAcquisitionTransaction transaction;
  final List<HarvestBatch> batches;
  final List<String> sourceCodes;

  @override
  Widget build(BuildContext context) {
    final routeLabel = transaction.source == DistributorAcquisitionSource.farmer
        ? 'Petani -> Distributor'
        : 'Petani -> Pengepul -> Distributor';
    final foundCodes = batches.map((batch) => batch.code).toSet();
    final missingCodes = sourceCodes
        .where((code) => !foundCodes.contains(code))
        .toList();

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
                Icons.account_tree_outlined,
                size: 18,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Trace Sumber Durian',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: AppColors.black,
                  ),
                ),
              ),
              _SourceBadge(label: transaction.source.label),
            ],
          ),
          const SizedBox(height: 10),
          _InfoRow(label: 'Alur', value: routeLabel),
          _InfoRow(label: 'Kode', value: transaction.itemCode),
          const Divider(height: 18, color: _borderColor),
          if (batches.isEmpty && sourceCodes.isEmpty)
            const Text(
              'Detail batch sumber belum tersedia di data lokal.',
              style: TextStyle(fontSize: 11, color: AppColors.placeholder),
            )
          else ...[
            ...batches.map(
              (batch) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _TraceBatchRow(batch: batch),
              ),
            ),
            ...missingCodes.map(
              (code) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _TraceCodeRow(code: code),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SourceBadge extends StatelessWidget {
  const _SourceBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.primaryContainer.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w900,
          color: AppColors.primary,
        ),
      ),
    );
  }
}

class _TraceBatchRow extends StatelessWidget {
  const _TraceBatchRow({required this.batch});

  final HarvestBatch batch;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: _pageBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  batch.code,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primary,
                  ),
                ),
              ),
              Text(
                batch.status.label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: batch.status.color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            '${batch.farmName} / Petani ${batch.farmerId}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.subtitle,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Durian ${batch.variety} / Grade ${batch.grade} / '
            '${_formatNumber(batch.quantity)} ${batch.unit} / '
            '${batch.fruitCount ?? 0} butir / ${_formatDate(batch.harvestDate)}',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 10,
              height: 1.35,
              color: AppColors.placeholder,
            ),
          ),
        ],
      ),
    );
  }
}

class _TraceCodeRow extends StatelessWidget {
  const _TraceCodeRow({required this.code});

  final String code;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: _pageBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _borderColor),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.qr_code_2_rounded,
            size: 17,
            color: AppColors.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              code,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: AppColors.primary,
              ),
            ),
          ),
          const Text(
            'Kode sumber',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: AppColors.placeholder,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

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

class _NumberField extends StatelessWidget {
  const _NumberField({
    required this.controller,
    required this.label,
    required this.suffix,
    this.decimal = false,
  });

  final TextEditingController controller;
  final String label;
  final String suffix;
  final bool decimal;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.numberWithOptions(decimal: decimal),
      inputFormatters: [
        if (decimal)
          FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))
        else
          FilteringTextInputFormatter.digitsOnly,
      ],
      decoration: InputDecoration(
        labelText: label,
        suffixText: suffix,
        filled: true,
        fillColor: AppColors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
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
    );
  }
}

class _DifferencePanel extends StatelessWidget {
  const _DifferencePanel({
    required this.transaction,
    required this.receivedWeight,
    required this.receivedFruit,
  });

  final DistributorAcquisitionTransaction transaction;
  final double? receivedWeight;
  final int? receivedFruit;

  @override
  Widget build(BuildContext context) {
    final weightDiff = receivedWeight == null
        ? null
        : receivedWeight! - transaction.expectedWeightKg;
    final fruitDiff = receivedFruit == null
        ? null
        : receivedFruit! - transaction.expectedFruitCount;
    final hasDiff = (weightDiff?.abs() ?? 0) > 0.01 || (fruitDiff ?? 0) != 0;
    final color = hasDiff ? const Color(0xFF9A6700) : AppColors.primary;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: [
          Icon(
            hasDiff ? Icons.warning_amber_rounded : Icons.check_circle_outline,
            size: 20,
            color: color,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              receivedWeight == null || receivedFruit == null
                  ? 'Masukkan hasil timbang dan hitung aktual.'
                  : hasDiff
                  ? 'Selisih ${_signedNumber(weightDiff!)} kg dan ${_signedInt(fruitDiff!)} butir.'
                  : 'Kuantitas aktual sesuai dengan manifest T1.',
              style: TextStyle(
                fontSize: 11,
                height: 1.35,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConditionSelector extends StatelessWidget {
  const _ConditionSelector({required this.selected, required this.onChanged});

  final DistributorReceiptCondition? selected;
  final ValueChanged<DistributorReceiptCondition> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: DistributorReceiptCondition.values.map((condition) {
        final isSelected = selected == condition;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: InkWell(
            onTap: () => onChanged(condition),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primaryContainer.withValues(alpha: 0.08)
                    : AppColors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected ? AppColors.primaryContainer : _borderColor,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isSelected
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked_rounded,
                    size: 21,
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.placeholder,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      condition.label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.subtitle,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _GradeCompositionInput extends StatelessWidget {
  const _GradeCompositionInput({
    required this.grades,
    required this.weightControllers,
    required this.fruitControllers,
  });

  final List<String> grades;
  final Map<String, TextEditingController> weightControllers;
  final Map<String, TextEditingController> fruitControllers;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: grades.map((grade) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _borderColor),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 60,
                  child: Text(
                    'Grade $grade',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: AppColors.black,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _NumberField(
                    controller: weightControllers[grade]!,
                    label: 'Kg',
                    suffix: 'kg',
                    decimal: true,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _NumberField(
                    controller: fruitControllers[grade]!,
                    label: 'Butir',
                    suffix: 'bt',
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _TextArea extends StatelessWidget {
  const _TextArea({
    required this.controller,
    required this.label,
    required this.hint,
  });

  final TextEditingController controller;
  final String label;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: AppColors.subtitle,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: AppColors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
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
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 76,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.placeholder,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.subtitle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TextField extends StatelessWidget {
  const _TextField({
    required this.controller,
    required this.label,
    required this.hint,
    this.required = false,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final bool required;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          required ? '$label *' : label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: AppColors.subtitle,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: AppColors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
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
        ),
      ],
    );
  }
}

class _UnavailableState extends StatelessWidget {
  const _UnavailableState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 13,
            height: 1.4,
            color: AppColors.placeholder,
          ),
        ),
      ),
    );
  }
}

String _formatNumber(double value) {
  return value % 1 == 0 ? value.toStringAsFixed(0) : value.toStringAsFixed(2);
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

String _signedNumber(double value) {
  final prefix = value > 0 ? '+' : '';
  return '$prefix${_formatNumber(value)}';
}

String _signedInt(int value) {
  return value > 0 ? '+$value' : '$value';
}
