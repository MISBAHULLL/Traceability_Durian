import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_top_bar.dart';
import '../../../shared/widgets/primary_pill_button.dart';
import '../../collector/models/collector_delivery_receipt.dart';
import '../../collector/models/collector_shipment_batch.dart';
import '../data/consumer_repository.dart';

class ConsumerShipmentReceiveScreen extends StatefulWidget {
  const ConsumerShipmentReceiveScreen({super.key, required this.shipmentCode});

  final String shipmentCode;

  @override
  State<ConsumerShipmentReceiveScreen> createState() =>
      _ConsumerShipmentReceiveScreenState();
}

class _ConsumerShipmentReceiveScreenState
    extends State<ConsumerShipmentReceiveScreen> {
  final _repo = ConsumerRepository.instance;
  final _weightCtrl = TextEditingController();
  final _fruitCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _discrepancyCtrl = TextEditingController();
  final _qualityCtrl = TextEditingController();
  var _condition = CollectorDeliveryReceiptCondition.good;
  var _isSaving = false;

  CollectorShipmentBatch? get _shipment =>
      _repo.findCollectorShipment(widget.shipmentCode);

  @override
  void initState() {
    super.initState();
    final shipment = _shipment;
    if (shipment != null) {
      _weightCtrl.text = _formatNumber(shipment.totalWeightKg);
      _fruitCtrl.text = '${shipment.totalFruitCount}';
      _locationCtrl.text = _repo.profile.location;
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
    _locationCtrl.dispose();
    _discrepancyCtrl.dispose();
    _qualityCtrl.dispose();
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  double? get _weight =>
      double.tryParse(_weightCtrl.text.trim().replaceAll(',', '.'));

  int? get _fruit => int.tryParse(_fruitCtrl.text.trim());

  bool _hasDiscrepancy(CollectorShipmentBatch shipment) {
    final weight = _weight;
    final fruit = _fruit;
    if (weight == null || fruit == null) return false;
    return (weight - shipment.totalWeightKg).abs() > 0.01 ||
        fruit != shipment.totalFruitCount;
  }

  Future<void> _accept(CollectorShipmentBatch shipment) async {
    final weight = _weight;
    final fruit = _fruit;
    if (weight == null || weight <= 0 || fruit == null || fruit <= 0) {
      _snack('Berat dan jumlah aktual wajib valid.');
      return;
    }
    if (_locationCtrl.text.trim().isEmpty) {
      _snack('Lokasi penerimaan wajib diisi.');
      return;
    }
    if (_hasDiscrepancy(shipment) && _discrepancyCtrl.text.trim().isEmpty) {
      _snack('Isi catatan untuk selisih stok.');
      return;
    }

    setState(() => _isSaving = true);
    await Future.delayed(const Duration(milliseconds: 350));
    final receipt = _repo.receiveCollectorShipment(
      code: shipment.code,
      receivedWeightKg: weight,
      receivedFruitCount: fruit,
      condition: _condition,
      destinationLocation: _locationCtrl.text,
      discrepancyNote: _discrepancyCtrl.text,
      qualityNote: _qualityCtrl.text,
    );
    if (!mounted) return;
    setState(() => _isSaving = false);
    if (receipt == null) {
      _snack('Penerimaan PGL gagal disimpan.');
      return;
    }
    Navigator.pop(context, true);
  }

  Future<void> _reject(CollectorShipmentBatch shipment) async {
    final reason = _qualityCtrl.text.trim();
    if (reason.isEmpty) {
      _snack('Isi catatan sebagai alasan penolakan.');
      return;
    }
    if (_locationCtrl.text.trim().isEmpty) {
      _snack('Lokasi pemeriksaan wajib diisi.');
      return;
    }

    setState(() => _isSaving = true);
    await Future.delayed(const Duration(milliseconds: 300));
    final receipt = _repo.rejectCollectorShipment(
      code: shipment.code,
      reason: reason,
      destinationLocation: _locationCtrl.text,
    );
    if (!mounted) return;
    setState(() => _isSaving = false);
    if (receipt == null) {
      _snack('Penolakan PGL gagal disimpan.');
      return;
    }
    Navigator.pop(context, true);
  }

  void _snack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final shipment = _shipment;
    final existingReceipt = _repo.deliveryReceiptForShipment(
      widget.shipmentCode,
    );
    final unavailable =
        shipment == null ||
        existingReceipt != null ||
        shipment.status == CollectorShipmentStatus.completed ||
        shipment.status == CollectorShipmentStatus.rejected;

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            const AppTopBar(title: 'Validasi PGL'),
            Expanded(
              child: unavailable
                  ? const _EmptyState()
                  : SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _InfoCard(
                            title: 'Ringkasan PGL',
                            children: [
                              _DetailLine(label: 'Kode', value: shipment.code),
                              _DetailLine(
                                label: 'Tujuan',
                                value:
                                    shipment.destinationName ??
                                    shipment.destinationType.label,
                              ),
                              _DetailLine(
                                label: 'Lokasi Tujuan',
                                value: shipment.destinationLocation ?? '-',
                              ),
                              _DetailLine(
                                label: 'Jumlah Kirim',
                                value:
                                    '${_formatNumber(shipment.totalWeightKg)} kg / ${shipment.totalFruitCount} butir',
                              ),
                              _DetailLine(
                                label: 'Sumber Batch',
                                value: shipment.sourceBatchCodes.join(', '),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _InfoCard(
                            title: 'Validasi Penerimaan',
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _weightCtrl,
                                      keyboardType: TextInputType.number,
                                      decoration: _inputDecoration(
                                        'Berat aktual kg',
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: TextField(
                                      controller: _fruitCtrl,
                                      keyboardType: TextInputType.number,
                                      decoration: _inputDecoration(
                                        'Jumlah butir',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (_hasDiscrepancy(shipment)) ...[
                                const SizedBox(height: 12),
                                TextField(
                                  controller: _discrepancyCtrl,
                                  maxLines: 2,
                                  decoration: _inputDecoration(
                                    'Catatan selisih wajib diisi',
                                  ),
                                ),
                              ],
                              const SizedBox(height: 12),
                              TextField(
                                controller: _locationCtrl,
                                decoration: _inputDecoration(
                                  'Lokasi penerimaan',
                                ),
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: CollectorDeliveryReceiptCondition
                                    .values
                                    .map(_conditionChip)
                                    .toList(),
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: _qualityCtrl,
                                maxLines: 3,
                                decoration: _inputDecoration(
                                  'Catatan kondisi atau alasan penolakan',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          PrimaryPillButton(
                            label: 'TERIMA STOK',
                            isLoading: _isSaving,
                            onPressed: _isSaving
                                ? null
                                : () => _accept(shipment),
                          ),
                          const SizedBox(height: 10),
                          OutlinedButton.icon(
                            onPressed: _isSaving
                                ? null
                                : () => _reject(shipment),
                            icon: const Icon(Icons.close_rounded, size: 18),
                            label: const Text('TOLAK STOK'),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size.fromHeight(48),
                              foregroundColor: const Color(0xFFD64545),
                              side: const BorderSide(color: Color(0xFFD64545)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(999),
                              ),
                              textStyle: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _conditionChip(CollectorDeliveryReceiptCondition condition) {
    final selected = condition == _condition;
    return ChoiceChip(
      label: Text(condition.label),
      selected: selected,
      onSelected: (_) => setState(() => _condition = condition),
      selectedColor: AppColors.primaryContainer.withValues(alpha: 0.18),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w800,
        color: selected ? AppColors.primary : AppColors.subtitle,
      ),
      side: BorderSide(
        color: selected ? AppColors.primaryContainer : const Color(0xFFE5E7EB),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: AppColors.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: AppColors.black,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _DetailLine extends StatelessWidget {
  const _DetailLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 112,
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

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(28),
        child: Text(
          'PGL ini sudah diproses atau bukan tujuan konsumen.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: AppColors.placeholder),
        ),
      ),
    );
  }
}

String _formatNumber(double value) {
  if (value % 1 == 0) return value.toStringAsFixed(0);
  return value.toStringAsFixed(1);
}
