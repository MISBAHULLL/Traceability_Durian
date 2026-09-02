import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_top_bar.dart';
import '../../../shared/widgets/primary_pill_button.dart';
import '../../../shared/widgets/top_notification_banner.dart';
import '../data/collector_repository.dart';
import '../models/collector_incoming_receipt.dart';
import '../models/collector_shipment_batch.dart';
import '../models/collector_warehouse.dart';

const _pageBackground = Color(0xFFF4F6F3);
const _borderColor = Color(0xFFE1E6DF);

String _formatNumber(double value) {
  if (value == value.roundToDouble()) return value.toStringAsFixed(0);
  return value.toStringAsFixed(1);
}

// [FE - Component Rendering] Form T2 untuk pengepul yang menerima PGL dari
// pengepul lain. Form ini mencatat hasil timbang aktual, kondisi, gudang tujuan,
// dan catatan audit selisih.
class CollectorIncomingReceiptScreen extends StatefulWidget {
  const CollectorIncomingReceiptScreen({super.key, required this.shipmentCode});

  final String shipmentCode;

  @override
  State<CollectorIncomingReceiptScreen> createState() =>
      _CollectorIncomingReceiptScreenState();
}

class _CollectorIncomingReceiptScreenState
    extends State<CollectorIncomingReceiptScreen> {
  final _repo = CollectorRepository.instance;
  final _notification = TopNotification();
  final _weightCtrl = TextEditingController();
  final _fruitCtrl = TextEditingController();
  final _discrepancyCtrl = TextEditingController();
  final _qualityCtrl = TextEditingController();

  String? _warehouseId;
  CollectorIncomingReceiptCondition? _condition;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final shipment = _repo.findIncomingCollectorShipment(widget.shipmentCode);
    if (shipment != null) {
      _weightCtrl.text = _formatNumber(shipment.totalWeightKg);
      _fruitCtrl.text = shipment.totalFruitCount.toString();
    }
    _warehouseId = _repo.defaultWarehouse?.id;
    _weightCtrl.addListener(_refreshDifference);
    _fruitCtrl.addListener(_refreshDifference);
  }

  @override
  void dispose() {
    _weightCtrl.removeListener(_refreshDifference);
    _fruitCtrl.removeListener(_refreshDifference);
    _weightCtrl.dispose();
    _fruitCtrl.dispose();
    _discrepancyCtrl.dispose();
    _qualityCtrl.dispose();
    _notification.dispose();
    super.dispose();
  }

  void _refreshDifference() {
    if (mounted) setState(() {});
  }

  double? get _receivedWeight =>
      double.tryParse(_weightCtrl.text.trim().replaceAll(',', '.'));

  int? get _receivedFruit => int.tryParse(_fruitCtrl.text.trim());

  bool _hasDiscrepancy(CollectorShipmentBatch shipment) {
    final weight = _receivedWeight;
    final fruit = _receivedFruit;
    if (weight == null || fruit == null) return false;
    return (weight - shipment.totalWeightKg).abs() > 0.01 ||
        fruit != shipment.totalFruitCount;
  }

  Future<void> _submit(CollectorShipmentBatch shipment) async {
    final weight = _receivedWeight;
    final fruit = _receivedFruit;
    if (weight == null || weight <= 0) {
      _notification.show(
        context,
        'Masukkan berat diterima yang valid.',
        isError: true,
      );
      return;
    }
    if (fruit == null || fruit <= 0) {
      _notification.show(
        context,
        'Masukkan jumlah buah diterima yang valid.',
        isError: true,
      );
      return;
    }
    final warehouseId = _warehouseId;
    if (warehouseId == null || warehouseId.trim().isEmpty) {
      _notification.show(
        context,
        'Pilih gudang tujuan penerimaan.',
        isError: true,
      );
      return;
    }
    final condition = _condition;
    if (condition == null) {
      _notification.show(context, 'Pilih kondisi fisik durian.', isError: true);
      return;
    }
    if (_hasDiscrepancy(shipment) && _discrepancyCtrl.text.trim().isEmpty) {
      _notification.show(
        context,
        'Jelaskan penyebab selisih berat atau jumlah buah.',
        isError: true,
      );
      return;
    }

    setState(() => _isSubmitting = true);
    await Future.delayed(const Duration(milliseconds: 350));
    if (!mounted) return;

    final receipt = _repo.receiveIncomingCollectorShipment(
      code: shipment.code,
      receivedWeightKg: weight,
      receivedFruitCount: fruit,
      condition: condition,
      destinationWarehouseId: warehouseId,
      discrepancyNote: _discrepancyCtrl.text,
      qualityNote: _qualityCtrl.text,
    );
    setState(() => _isSubmitting = false);

    if (receipt == null) {
      _notification.show(
        context,
        'Penerimaan PGL gagal disimpan. Periksa status dan data pengiriman.',
        isError: true,
      );
      return;
    }

    _notification.show(context, '${shipment.code} berhasil diterima.');
    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final shipment = _repo.findIncomingCollectorShipment(widget.shipmentCode);
    final existingReceipt = _repo.incomingReceiptForShipment(
      widget.shipmentCode,
    );
    final warehouses = _repo.warehouses;

    return Scaffold(
      backgroundColor: _pageBackground,
      body: SafeArea(
        child: Column(
          children: [
            const ColoredBox(
              color: AppColors.white,
              child: AppTopBar(title: 'Terima PGL Pengepul'),
            ),
            Expanded(
              child: shipment == null
                  ? const _UnavailableState(message: 'PGL tidak ditemukan.')
                  : existingReceipt != null
                  ? const _UnavailableState(message: 'PGL ini sudah diterima.')
                  : shipment.status != CollectorShipmentStatus.sent
                  ? const _UnavailableState(
                      message: 'PGL harus discan terlebih dahulu.',
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                      children: [
                        _ManifestSummary(shipment: shipment),
                        const SizedBox(height: 18),
                        const _SectionTitle(title: 'Hasil Timbang Aktual'),
                        const SizedBox(height: 9),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _NumberField(
                                controller: _weightCtrl,
                                label: 'Berat Diterima',
                                suffix: 'kg',
                                decimal: true,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _NumberField(
                                controller: _fruitCtrl,
                                label: 'Jumlah Diterima',
                                suffix: 'butir',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _DifferencePanel(
                          expectedWeight: shipment.totalWeightKg,
                          expectedFruit: shipment.totalFruitCount,
                          receivedWeight: _receivedWeight,
                          receivedFruit: _receivedFruit,
                        ),
                        if (_hasDiscrepancy(shipment)) ...[
                          const SizedBox(height: 12),
                          _TextArea(
                            controller: _discrepancyCtrl,
                            label: 'Alasan Selisih',
                            hint:
                                'Contoh: susut perjalanan atau hasil timbang ulang',
                            required: true,
                          ),
                        ],
                        const SizedBox(height: 18),
                        const _SectionTitle(title: 'Gudang Tujuan'),
                        const SizedBox(height: 9),
                        DropdownButtonFormField<String>(
                          initialValue: _warehouseId,
                          items: warehouses.map((warehouse) {
                            return DropdownMenuItem(
                              value: warehouse.id,
                              child: Text(warehouse.name),
                            );
                          }).toList(),
                          onChanged: (value) =>
                              setState(() => _warehouseId = value),
                          decoration: InputDecoration(
                            labelText: 'Gudang tujuan penerimaan',
                            filled: true,
                            fillColor: AppColors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        if (_warehouseId != null) ...[
                          const SizedBox(height: 8),
                          _WarehouseLocation(
                            warehouse: _repo.findWarehouse(_warehouseId),
                          ),
                        ],
                        const SizedBox(height: 18),
                        const _SectionTitle(title: 'Kondisi Fisik'),
                        const SizedBox(height: 9),
                        _ConditionSelector(
                          selected: _condition,
                          onChanged: (value) =>
                              setState(() => _condition = value),
                        ),
                        const SizedBox(height: 14),
                        _TextArea(
                          controller: _qualityCtrl,
                          label: 'Catatan Pemeriksaan',
                          hint:
                              'Contoh: kemasan utuh, aroma normal, tidak ada buah pecah',
                        ),
                        const SizedBox(height: 22),
                        PrimaryPillButton(
                          label: _isSubmitting
                              ? 'MENYIMPAN...'
                              : 'SIMPAN PENERIMAAN',
                          onPressed: _isSubmitting
                              ? null
                              : () => _submit(shipment),
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

class _ManifestSummary extends StatelessWidget {
  const _ManifestSummary({required this.shipment});

  final CollectorShipmentBatch shipment;

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
                  color: const Color(0xFFEAF4E6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.inventory_2_outlined,
                  color: AppColors.primary,
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
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Dari ${shipment.collectorId} -> ${shipment.destinationName ?? shipment.destinationType.label}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.subtitle,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _InfoRow(
            label: 'Manifest',
            value:
                '${_formatNumber(shipment.totalWeightKg)} kg / ${shipment.totalFruitCount} butir',
          ),
          _InfoRow(
            label: 'Batch sumber',
            value: shipment.sourceBatchCodes.join(', '),
          ),
          if (shipment.destinationLocation?.trim().isNotEmpty == true)
            _InfoRow(
              label: 'Tujuan manifest',
              value: shipment.destinationLocation!.trim(),
            ),
          if (shipment.warehouseNote?.trim().isNotEmpty == true)
            _InfoRow(
              label: 'Catatan pengirim',
              value: shipment.warehouseNote!.trim(),
            ),
        ],
      ),
    );
  }
}

class _WarehouseLocation extends StatelessWidget {
  const _WarehouseLocation({required this.warehouse});

  final CollectorWarehouse? warehouse;

  @override
  Widget build(BuildContext context) {
    final location = warehouse?.location.trim();
    if (location == null || location.isEmpty) return const SizedBox.shrink();
    return Text(
      location,
      style: const TextStyle(fontSize: 12, color: AppColors.placeholder),
    );
  }
}

class _DifferencePanel extends StatelessWidget {
  const _DifferencePanel({
    required this.expectedWeight,
    required this.expectedFruit,
    required this.receivedWeight,
    required this.receivedFruit,
  });

  final double expectedWeight;
  final int expectedFruit;
  final double? receivedWeight;
  final int? receivedFruit;

  @override
  Widget build(BuildContext context) {
    final weightDiff = receivedWeight == null
        ? null
        : receivedWeight! - expectedWeight;
    final fruitDiff = receivedFruit == null
        ? null
        : receivedFruit! - expectedFruit;
    final hasDiff = (weightDiff?.abs() ?? 0) > 0.01 || (fruitDiff ?? 0) != 0;
    final color = hasDiff ? const Color(0xFFB45309) : AppColors.primary;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: hasDiff ? const Color(0xFFFFF7ED) : const Color(0xFFEAF4E6),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            hasDiff
                ? 'Ada selisih dengan manifest'
                : 'Sesuai manifest sementara',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          _InfoRow(
            label: 'Selisih berat',
            value: weightDiff == null
                ? '-'
                : '${weightDiff >= 0 ? '+' : ''}${_formatNumber(weightDiff)} kg',
          ),
          _InfoRow(
            label: 'Selisih jumlah',
            value: fruitDiff == null
                ? '-'
                : '${fruitDiff >= 0 ? '+' : ''}$fruitDiff butir',
          ),
        ],
      ),
    );
  }
}

class _ConditionSelector extends StatelessWidget {
  const _ConditionSelector({required this.selected, required this.onChanged});

  final CollectorIncomingReceiptCondition? selected;
  final ValueChanged<CollectorIncomingReceiptCondition> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: CollectorIncomingReceiptCondition.values.map((condition) {
        final active = condition == selected;
        return ChoiceChip(
          selected: active,
          label: Text(condition.label),
          onSelected: (_) => onChanged(condition),
          selectedColor: const Color(0xFFEAF4E6),
          labelStyle: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: active ? AppColors.primary : AppColors.subtitle,
          ),
          side: BorderSide(color: active ? AppColors.primary : _borderColor),
          backgroundColor: AppColors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        );
      }).toList(),
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
      decoration: InputDecoration(
        labelText: label,
        suffixText: suffix,
        filled: true,
        fillColor: AppColors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

class _TextArea extends StatelessWidget {
  const _TextArea({
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
    return TextField(
      controller: controller,
      minLines: 2,
      maxLines: 3,
      decoration: InputDecoration(
        labelText: required ? '$label *' : label,
        hintText: hint,
        filled: true,
        fillColor: AppColors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
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
      padding: const EdgeInsets.only(top: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 104,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.placeholder,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                height: 1.35,
                fontWeight: FontWeight.w800,
                color: AppColors.black,
              ),
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

class _UnavailableState extends StatelessWidget {
  const _UnavailableState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 13, color: AppColors.placeholder),
        ),
      ),
    );
  }
}
