import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_top_bar.dart';
import '../../../shared/widgets/primary_pill_button.dart';
import '../../../shared/widgets/top_notification_banner.dart';
import '../../farmer/models/harvest_batch.dart';
import '../data/collector_repository.dart';
import '../models/collector_shipment_batch.dart';
import '../models/shipment_recipient.dart';

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
  ShipmentDestinationType? _destinationType;
  ShipmentRecipient? _selectedRecipient;
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
  void _toggleBatch(HarvestBatch batch) {
    setState(() {
      if (_selectedCodes.contains(batch.code)) {
        _selectedCodes.remove(batch.code);
      } else {
        _selectedCodes.add(batch.code);
      }
    });
  }

  // [FE - Event Handler] Submit ini membuat batch agregat FE-only dan
  // menyimpan mapping source batch untuk mencegah alokasi ganda.
  Future<void> _handleSubmit() async {
    if (_selectedCodes.isEmpty) {
      _notification.show(
        context,
        'Pilih minimal satu batch stok untuk dikirim.',
        isError: true,
      );
      return;
    }

    final destinationType = _destinationType;
    if (destinationType == null) {
      _notification.show(context, 'Pilih tujuan pengiriman.', isError: true);
      return;
    }
    final recipient = _selectedRecipient;
    if (recipient == null) {
      _notification.show(
        context,
        'Pilih akun penerima yang sudah terdaftar.',
        isError: true,
      );
      return;
    }

    setState(() => _isSubmitting = true);
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;

    final shipment = _repo.createShipmentBatch(
      sourceBatchCodes: _selectedCodes.toList(),
      destinationType: destinationType,
      destinationUserId: recipient.userId,
      destinationName: recipient.name,
      destinationLocation: recipient.address,
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
                              onTap: () => _toggleBatch(batch),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        const _SectionTitle(title: 'Tujuan Pengiriman'),
                        const SizedBox(height: 8),
                        // [FE - Component Rendering] Tujuan dipilih eksplisit
                        // karena jumlah batch tidak menentukan jenis penerima.
                        _DestinationSelector(
                          selected: _destinationType,
                          onChanged: (value) {
                            setState(() {
                              _destinationType = value;
                              _selectedRecipient = null;
                            });
                          },
                        ),
                        const SizedBox(height: 18),
                        const _SectionTitle(title: 'Detail Tujuan'),
                        const SizedBox(height: 8),
                        _DestinationDetailPanel(
                          destinationType: _destinationType,
                          selected: _selectedRecipient,
                          onChanged: (recipient) {
                            setState(() => _selectedRecipient = recipient);
                          },
                        ),
                        const SizedBox(height: 18),
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
          'Belum ada batch stok yang tersedia untuk dibuatkan pengiriman.',
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

class _DestinationDetailPanel extends StatelessWidget {
  const _DestinationDetailPanel({
    required this.destinationType,
    required this.selected,
    required this.onChanged,
  });

  final ShipmentDestinationType? destinationType;
  final ShipmentRecipient? selected;
  final ValueChanged<ShipmentRecipient?> onChanged;

  Future<void> _selectRecipient(BuildContext context) async {
    final type = destinationType;
    if (type == null) return;
    final recipients = ShipmentRecipientDirectory.forDestination(type);
    final result = await showModalBottomSheet<ShipmentRecipient>(
      context: context,
      backgroundColor: AppColors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _RecipientPickerSheet(
        destinationType: type,
        recipients: recipients,
        selected: selected,
      ),
    );
    if (result != null) onChanged(result);
  }

  @override
  Widget build(BuildContext context) {
    final type = destinationType;
    if (type == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F8F6),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: const Row(
          children: [
            _DestinationIcon(
              icon: Icons.person_search_outlined,
              isActive: false,
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Belum ada jenis tujuan',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.subtitle,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'Pilih tujuan pengiriman di atas',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.placeholder,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: selected == null
              ? const Color(0xFFDDE2DB)
              : AppColors.primaryContainer.withValues(alpha: 0.55),
        ),
      ),
      child: Column(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _selectRecipient(context),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(8),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    _DestinationIcon(
                      icon: Icons.account_circle_outlined,
                      isActive: selected != null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Akun ${type.label}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.placeholder,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            selected?.name ?? 'Pilih akun penerima',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: selected == null
                                  ? AppColors.subtitle
                                  : AppColors.black,
                            ),
                          ),
                          if (selected != null) ...[
                            const SizedBox(height: 3),
                            Text(
                              'ID ${selected!.userId}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: AppColors.placeholder,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE5E7EB)),
          _RecipientAddressRow(recipient: selected),
        ],
      ),
    );
  }
}

class _DestinationIcon extends StatelessWidget {
  const _DestinationIcon({required this.icon, required this.isActive});

  final IconData icon;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: isActive
            ? AppColors.primaryContainer.withValues(alpha: 0.12)
            : const Color(0xFFEEF1ED),
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.center,
      child: Icon(
        icon,
        size: 21,
        color: isActive ? AppColors.primary : AppColors.placeholder,
      ),
    );
  }
}

class _RecipientAddressRow extends StatelessWidget {
  const _RecipientAddressRow({required this.recipient});

  final ShipmentRecipient? recipient;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.location_on_outlined,
            size: 20,
            color: AppColors.placeholder,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Alamat terdaftar',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.placeholder,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  recipient?.address ?? 'Alamat tampil setelah akun dipilih',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.45,
                    fontWeight: recipient == null
                        ? FontWeight.w400
                        : FontWeight.w600,
                    color: recipient == null
                        ? AppColors.placeholder
                        : AppColors.subtitle,
                  ),
                ),
              ],
            ),
          ),
          if (recipient != null) ...[
            const SizedBox(width: 8),
            const Icon(
              Icons.lock_outline_rounded,
              size: 16,
              color: AppColors.placeholder,
            ),
          ],
        ],
      ),
    );
  }
}

class _RecipientPickerSheet extends StatelessWidget {
  const _RecipientPickerSheet({
    required this.destinationType,
    required this.recipients,
    required this.selected,
  });

  final ShipmentDestinationType destinationType;
  final List<ShipmentRecipient> recipients;
  final ShipmentRecipient? selected;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFD1D5DB),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Pilih Akun ${destinationType.label}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: AppColors.black,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Akun terdaftar sebagai penerima pengiriman',
              style: TextStyle(fontSize: 12, color: AppColors.placeholder),
            ),
            const SizedBox(height: 16),
            ...recipients.map(
              (recipient) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _RecipientOption(
                  recipient: recipient,
                  selected: selected?.userId == recipient.userId,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecipientOption extends StatelessWidget {
  const _RecipientOption({required this.recipient, required this.selected});

  final ShipmentRecipient recipient;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? AppColors.primaryContainer.withValues(alpha: 0.08)
          : AppColors.white,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: () => Navigator.pop(context, recipient),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected
                  ? AppColors.primaryContainer
                  : const Color(0xFFE5E7EB),
            ),
          ),
          child: Row(
            children: [
              _DestinationIcon(
                icon: Icons.business_outlined,
                isActive: selected,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recipient.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppColors.black,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${recipient.userId}  |  ${recipient.address}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        height: 1.35,
                        color: AppColors.placeholder,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                selected
                    ? Icons.check_circle_rounded
                    : Icons.chevron_right_rounded,
                size: 21,
                color: selected ? AppColors.primary : AppColors.placeholder,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// [FE - Component Rendering] Selector ini memisahkan jalur handover langsung
// ke UMKM dan jalur skala besar melalui distributor tanpa aturan jumlah kaku.
class _DestinationSelector extends StatelessWidget {
  const _DestinationSelector({required this.selected, required this.onChanged});

  final ShipmentDestinationType? selected;
  final ValueChanged<ShipmentDestinationType> onChanged;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = (constraints.maxWidth - 10) / 2;
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: ShipmentDestinationType.values.map((type) {
            final isSelected = selected == type;
            return SizedBox(
              width: itemWidth,
              child: InkWell(
                onTap: () => onChanged(type),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primaryContainer.withValues(alpha: 0.08)
                        : AppColors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primaryContainer
                          : const Color(0xFFE5E7EB),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _destinationIcon(type),
                        size: 20,
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.placeholder,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          type.label,
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
      },
    );
  }

  IconData _destinationIcon(ShipmentDestinationType type) {
    switch (type) {
      case ShipmentDestinationType.umkm:
        return Icons.storefront_outlined;
      case ShipmentDestinationType.distributor:
        return Icons.local_shipping_outlined;
      case ShipmentDestinationType.consumer:
        return Icons.person_outline_rounded;
      case ShipmentDestinationType.collector:
        return Icons.groups_2_outlined;
    }
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
