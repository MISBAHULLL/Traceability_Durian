import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_top_bar.dart';
import '../../../shared/widgets/primary_pill_button.dart';
import '../../../shared/widgets/top_notification_banner.dart';
import '../../farmer/models/harvest_batch.dart';
import '../data/collector_repository.dart';

// [FE - Component Rendering] Screen ini menjadi form agregasi stok pengepul
// menjadi batch pengiriman baru tanpa menyentuh backend/blockchain.
class CreateShipmentBatchScreen extends StatefulWidget {
  const CreateShipmentBatchScreen({super.key});

  @override
  State<CreateShipmentBatchScreen> createState() =>
      _CreateShipmentBatchScreenState();
}

class _CreateShipmentBatchScreenState extends State<CreateShipmentBatchScreen> {
  final _repo = CollectorRepository.instance;
  final _noteCtrl = TextEditingController();
  final _notification = TopNotification();
  final Set<String> _selectedCodes = {};
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _repo.addListener(_onRepoChanged);
  }

  @override
  void dispose() {
    _repo.removeListener(_onRepoChanged);
    _notification.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  void _onRepoChanged() {
    if (mounted) setState(() {});
  }

  // [FE - Event Handler] Handler ini memilih/melepas source batch yang akan
  // masuk ke provenance tree batch pengiriman.
  void _toggleBatch(String code) {
    setState(() {
      if (_selectedCodes.contains(code)) {
        _selectedCodes.remove(code);
      } else {
        _selectedCodes.add(code);
      }
    });
  }

  // [FE - Event Handler] Submit ini membuat batch agregat FE-only dan
  // menyimpan mapping source batch untuk mencegah alokasi ganda.
  Future<void> _handleSubmit() async {
    if (_selectedCodes.length < 2) {
      _notification.show(
        context,
        'Pilih minimal dua batch stok untuk digabungkan.',
        isError: true,
      );
      return;
    }

    setState(() => _isSubmitting = true);
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;

    final shipment = _repo.createShipmentBatch(
      sourceBatchCodes: _selectedCodes.toList(),
      warehouseNote: _noteCtrl.text,
    );

    setState(() => _isSubmitting = false);
    if (shipment == null) {
      _notification.show(
        context,
        'Batch gagal dibuat. Pastikan batch belum masuk pengiriman lain.',
        isError: true,
      );
      return;
    }

    _notification.show(context, 'Batch ${shipment.code} berhasil dibuat.');
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final batches = _repo.availableStockBatches;

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            const AppTopBar(title: 'Buat Batch Pengiriman'),
            Expanded(
              child: batches.isEmpty
                  ? const _EmptyAvailableBatch()
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                      children: [
                        const _SectionTitle(title: 'Pilih Batch Stok'),
                        const SizedBox(height: 10),
                        ...batches.map(
                          (batch) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _SelectableBatchTile(
                              batch: batch,
                              selected: _selectedCodes.contains(batch.code),
                              onTap: () => _toggleBatch(batch.code),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const _SectionTitle(title: 'Catatan Kondisi Gudang'),
                        const SizedBox(height: 8),
                        // [FE - Component Rendering] Catatan gudang menjadi
                        // metadata operasional opsional untuk batch agregat.
                        TextField(
                          controller: _noteCtrl,
                          maxLines: 3,
                          decoration: InputDecoration(
                            hintText: 'Contoh: suhu ruang stabil, siap angkut',
                            filled: true,
                            fillColor: AppColors.surface,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFFE5E7EB),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFFE5E7EB),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: AppColors.primaryContainer,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 22),
                        PrimaryPillButton(
                          label: 'BUAT BATCH PENGIRIMAN',
                          onPressed: _isSubmitting ? null : _handleSubmit,
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

class _EmptyAvailableBatch extends StatelessWidget {
  const _EmptyAvailableBatch();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(28),
        child: Text(
          'Belum ada minimal dua batch stok yang tersedia untuk digabungkan.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            height: 1.4,
            color: AppColors.placeholder,
          ),
        ),
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

// [FE - Component Rendering] Tile ini menampilkan satu batch stok yang bisa
// dipilih sebagai source batch pengiriman.
class _SelectableBatchTile extends StatelessWidget {
  const _SelectableBatchTile({
    required this.batch,
    required this.selected,
    required this.onTap,
  });

  final HarvestBatch batch;
  final bool selected;
  final VoidCallback onTap;

  String _formatWeight(double value) {
    final text = value % 1 == 0
        ? value.toStringAsFixed(0)
        : value.toStringAsFixed(2);
    return '$text kg';
  }

  @override
  Widget build(BuildContext context) {
    final receivedWeight = batch.receivedQuantity ?? batch.quantity;
    final receivedFruit = batch.receivedFruitCount ?? batch.fruitCount;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primaryContainer.withValues(alpha: 0.08)
              : AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? AppColors.primaryContainer
                : const Color(0xFFE5E7EB),
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: selected ? AppColors.primary : AppColors.placeholder,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    batch.code,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Durian ${batch.variety}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.black,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '${_formatWeight(receivedWeight)}'
                    '${receivedFruit == null ? '' : ' / $receivedFruit butir'}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.placeholder,
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
