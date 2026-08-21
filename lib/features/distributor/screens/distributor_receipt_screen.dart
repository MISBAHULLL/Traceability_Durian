import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_top_bar.dart';
import '../../../shared/widgets/primary_pill_button.dart';
import '../../../shared/widgets/top_notification_banner.dart';
import '../../collector/models/collector_shipment_batch.dart';
import '../data/distributor_repository.dart';
import '../models/distributor_receipt.dart';

const _pageBackground = Color(0xFFF4F6F3);
const _borderColor = Color(0xFFE1E6DF);

// [FE - Component Rendering] Screen ini menjadi form serah-terima distributor
// untuk mencatat kuantitas dan kondisi aktual tanpa mengubah manifest asal.
class DistributorReceiptScreen extends StatefulWidget {
  const DistributorReceiptScreen({super.key, required this.shipmentCode});

  final String shipmentCode;

  @override
  State<DistributorReceiptScreen> createState() =>
      _DistributorReceiptScreenState();
}

class _DistributorReceiptScreenState extends State<DistributorReceiptScreen> {
  final _repo = DistributorRepository.instance;
  final _notification = TopNotification();
  final _weightCtrl = TextEditingController();
  final _fruitCtrl = TextEditingController();
  final _destinationCtrl = TextEditingController();
  final _discrepancyCtrl = TextEditingController();
  final _qualityCtrl = TextEditingController();

  DistributorReceiptCondition? _condition;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final shipment = _repo.findShipment(widget.shipmentCode);
    if (shipment != null) {
      _weightCtrl.text = _formatNumber(shipment.totalWeightKg);
      _fruitCtrl.text = shipment.totalFruitCount.toString();
      _destinationCtrl.text =
          _repo.defaultWarehouse?.name ?? _repo.profile.location;
    }
    _weightCtrl.addListener(_refreshDifference);
    _fruitCtrl.addListener(_refreshDifference);
  }

  @override
  void dispose() {
    _weightCtrl.removeListener(_refreshDifference);
    _fruitCtrl.removeListener(_refreshDifference);
    _weightCtrl.dispose();
    _fruitCtrl.dispose();
    _destinationCtrl.dispose();
    _discrepancyCtrl.dispose();
    _qualityCtrl.dispose();
    _notification.dispose();
    super.dispose();
  }

  // [FE - State Management] Listener ini menghitung ulang selisih manifest
  // saat distributor mengubah angka timbang atau jumlah buah aktual.
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

  // [FE - Event Handler] Submit memvalidasi hasil pemeriksaan lalu meminta
  // repository membuat receipt dan menyelesaikan handover dari pengepul.
  Future<void> _handleSubmit(CollectorShipmentBatch shipment) async {
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
    final condition = _condition;
    if (condition == null) {
      _notification.show(
        context,
        'Pilih kondisi fisik pengiriman.',
        isError: true,
      );
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
    if (_hasDiscrepancy(shipment) && _discrepancyCtrl.text.trim().isEmpty) {
      _notification.show(
        context,
        'Jelaskan penyebab selisih berat atau jumlah buah.',
        isError: true,
      );
      return;
    }

    setState(() => _isSubmitting = true);
    await Future.delayed(const Duration(milliseconds: 450));
    if (!mounted) return;

    final receipt = _repo.receiveShipment(
      code: shipment.code,
      receivedWeightKg: weight,
      receivedFruitCount: fruit,
      condition: condition,
      destinationLocation: _destinationCtrl.text,
      discrepancyNote: _discrepancyCtrl.text,
      qualityNote: _qualityCtrl.text,
    );
    setState(() => _isSubmitting = false);

    if (receipt == null) {
      _notification.show(
        context,
        'Penerimaan gagal disimpan. Periksa status dan data pengiriman.',
        isError: true,
      );
      return;
    }

    _notification.show(context, '${shipment.code} berhasil diterima.');
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final shipment = _repo.findShipment(widget.shipmentCode);
    final existingReceipt = _repo.receiptForShipment(widget.shipmentCode);

    return Scaffold(
      backgroundColor: _pageBackground,
      body: SafeArea(
        child: Column(
          children: [
            const ColoredBox(
              color: AppColors.white,
              child: AppTopBar(title: 'Penerimaan Pengiriman'),
            ),
            Expanded(
              child: shipment == null
                  ? const _UnavailableState(
                      message: 'Pengiriman tidak ditemukan.',
                    )
                  : existingReceipt != null
                  ? const _UnavailableState(
                      message: 'Pengiriman ini sudah selesai diterima.',
                    )
                  : shipment.status != CollectorShipmentStatus.sent
                  ? const _UnavailableState(
                      message:
                          'Pengiriman harus diambil atau di-scan terlebih dahulu.',
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                      children: [
                        _ManifestSummary(shipment: shipment),
                        const SizedBox(height: 18),
                        const _SectionTitle(
                          title: 'Hasil Timbang dan Hitung Aktual',
                        ),
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
                                'Contoh: susut selama perjalanan atau hasil timbang ulang',
                            required: true,
                          ),
                        ],
                        const SizedBox(height: 18),
                        const _SectionTitle(title: 'Asal dan Gudang Tujuan'),
                        const SizedBox(height: 9),
                        _TextField(
                          controller: _destinationCtrl,
                          label: 'Gudang Tujuan Penerimaan',
                          hint: 'Contoh: Gudang Hub Surabaya',
                          required: true,
                        ),
                        const SizedBox(height: 18),
                        const _SectionTitle(title: 'Kondisi Fisik'),
                        const SizedBox(height: 9),
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
                          hint:
                              'Contoh: kemasan utuh, aroma normal, tidak ada buah pecah',
                        ),
                        const SizedBox(height: 22),
                        PrimaryPillButton(
                          label: 'KONFIRMASI PENERIMAAN',
                          onPressed: _isSubmitting
                              ? null
                              : () => _handleSubmit(shipment),
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
}

class _ManifestSummary extends StatelessWidget {
  const _ManifestSummary({required this.shipment});

  final CollectorShipmentBatch shipment;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
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
                  Icons.inventory_2_outlined,
                  color: AppColors.primary,
                  size: 21,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      shipment.code,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${shipment.sourceBatchCodes.length} batch sumber pengepul',
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
          const SizedBox(height: 14),
          const Divider(height: 1, color: _borderColor),
          const SizedBox(height: 13),
          Row(
            children: [
              Expanded(
                child: _ManifestMetric(
                  label: 'Berat Manifest',
                  value: '${_formatNumber(shipment.totalWeightKg)} kg',
                ),
              ),
              Container(width: 1, height: 36, color: _borderColor),
              Expanded(
                child: _ManifestMetric(
                  label: 'Jumlah Manifest',
                  value: '${shipment.totalFruitCount} butir',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ManifestMetric extends StatelessWidget {
  const _ManifestMetric({required this.label, required this.value});

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
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: AppColors.black,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: const TextStyle(fontSize: 10, color: AppColors.placeholder),
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
      decoration: InputDecoration(
        labelText: label,
        suffixText: suffix,
        filled: true,
        fillColor: AppColors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _borderColor),
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
    final weightDifference = receivedWeight == null
        ? null
        : receivedWeight! - expectedWeight;
    final fruitDifference = receivedFruit == null
        ? null
        : receivedFruit! - expectedFruit;
    final hasDifference =
        (weightDifference?.abs() ?? 0) > 0.01 || (fruitDifference ?? 0) != 0;
    final color = hasDifference ? const Color(0xFF9A6700) : AppColors.primary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(
            hasDifference
                ? Icons.warning_amber_rounded
                : Icons.check_circle_outline_rounded,
            size: 20,
            color: color,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              receivedWeight == null || receivedFruit == null
                  ? 'Masukkan hasil pemeriksaan aktual.'
                  : hasDifference
                  ? 'Selisih ${_signedWeight(weightDifference!)} kg dan '
                        '${_signedInt(fruitDifference!)} butir dari manifest.'
                  : 'Kuantitas aktual sesuai dengan manifest pengiriman.',
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

// [FE - Component Rendering] Pilihan kondisi memakai kontrol tersegmentasi
// agar status fisik dapat dibandingkan tanpa membuka menu tambahan.
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
        const SizedBox(height: 7),
        TextField(
          controller: controller,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: AppColors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: _borderColor),
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
        ),
      ],
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
        const SizedBox(height: 7),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: AppColors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: _borderColor),
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

String _signedWeight(double value) {
  final prefix = value > 0 ? '+' : '';
  return '$prefix${_formatNumber(value)}';
}

String _signedInt(int value) {
  return value > 0 ? '+$value' : '$value';
}
