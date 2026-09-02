import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_top_bar.dart';
import '../../../shared/widgets/top_notification_banner.dart';
import '../../farmer/models/harvest_batch.dart';
import '../data/collector_repository.dart';
import '../models/collector_warehouse.dart';
import '../models/collector_warehouse_transfer.dart';

const _pageBackground = Color(0xFFF4F6F3);
const _borderColor = Color(0xFFE1E6DF);

String _formatKg(double value) {
  if (value == value.roundToDouble()) return value.toStringAsFixed(0);
  return value.toStringAsFixed(1);
}

String _formatTransferTime(DateTime value) {
  return DateFormat('dd/MM/yyyy HH:mm').format(value);
}

// [FE - Component Rendering] CRUD gudang ringan untuk pengepul. Modul ini
// hanya mencatat lokasi penyimpanan yang dipilih saat menerima batch.
class CollectorWarehousesScreen extends StatefulWidget {
  const CollectorWarehousesScreen({super.key});

  @override
  State<CollectorWarehousesScreen> createState() =>
      _CollectorWarehousesScreenState();
}

class _CollectorWarehousesScreenState extends State<CollectorWarehousesScreen> {
  final _repo = CollectorRepository.instance;
  final _notification = TopNotification();

  @override
  void initState() {
    super.initState();
    _repo.addListener(_onRepoChanged);
  }

  @override
  void dispose() {
    _repo.removeListener(_onRepoChanged);
    _notification.dispose();
    super.dispose();
  }

  void _onRepoChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _openForm([CollectorWarehouse? warehouse]) async {
    final result = await showModalBottomSheet<_WarehouseFormResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (sheetContext) {
        return _WarehouseFormSheet(warehouse: warehouse);
      },
    );
    if (result == null) return;

    if (warehouse == null) {
      _repo.createWarehouse(
        name: result.name,
        location: result.location,
        note: result.note,
        setAsDefault: result.isDefault,
      );
      if (!mounted) return;
      _notification.show(context, 'Gudang berhasil ditambahkan.');
      return;
    }

    final ok = _repo.updateWarehouse(
      warehouse.id,
      name: result.name,
      location: result.location,
      note: result.note,
      setAsDefault: result.isDefault,
    );
    if (!mounted) return;
    _notification.show(
      context,
      ok ? 'Gudang berhasil diperbarui.' : 'Gudang gagal diperbarui.',
      isError: !ok,
    );
  }

  Future<void> _deleteWarehouse(CollectorWarehouse warehouse) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.white,
          title: const Text('Hapus Gudang?'),
          content: Text(
            'Gudang ${warehouse.name} akan dihapus dari daftar penyimpanan.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text(
                'Hapus',
                style: TextStyle(
                  color: Color(0xFFD64545),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        );
      },
    );
    if (confirmed != true) return;

    final ok = _repo.deleteWarehouse(warehouse.id);
    if (!mounted) return;
    _notification.show(
      context,
      ok
          ? 'Gudang berhasil dihapus.'
          : 'Gudang tidak bisa dihapus karena masih dipakai atau tersisa satu.',
      isError: !ok,
    );
  }

  Future<void> _openTransferForm() async {
    final result = await showModalBottomSheet<_TransferFormResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (sheetContext) {
        return _TransferFormSheet(
          repo: _repo,
          batches: _repo.transferableWarehouseBatches,
          warehouses: _repo.warehouses,
        );
      },
    );
    if (result == null) return;

    final transfer = _repo.transferWarehouseStock(
      batchCode: result.batchCode,
      fromWarehouseId: result.fromWarehouseId,
      toWarehouseId: result.toWarehouseId,
      reason: result.reason,
    );
    if (!mounted) return;
    _notification.show(
      context,
      transfer == null
          ? 'Transfer gagal. Pastikan stok masih tersedia di gudang asal.'
          : 'Stok berhasil dipindahkan ke ${transfer.toWarehouseName}.',
      isError: transfer == null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final warehouses = _repo.warehouses;
    final transferableBatches = _repo.transferableWarehouseBatches;
    final transfers = _repo.warehouseTransfers;

    return Scaffold(
      backgroundColor: _pageBackground,
      body: SafeArea(
        child: Column(
          children: [
            const AppTopBar(title: 'Kelola Gudang'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                children: [
                  _SummaryCard(count: warehouses.length),
                  const SizedBox(height: 12),
                  _TransferActionCard(
                    enabled:
                        warehouses.length > 1 && transferableBatches.isNotEmpty,
                    availableBatchCount: transferableBatches.length,
                    onTap: _openTransferForm,
                  ),
                  const SizedBox(height: 16),
                  const _SectionTitle(title: 'Daftar Gudang'),
                  const SizedBox(height: 8),
                  ...warehouses.map((warehouse) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _WarehouseCard(
                        warehouse: warehouse,
                        onEdit: () => _openForm(warehouse),
                        onDelete: () => _deleteWarehouse(warehouse),
                      ),
                    );
                  }),
                  if (transfers.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const _SectionTitle(title: 'Riwayat Transfer'),
                    const SizedBox(height: 8),
                    ...transfers.take(8).map((transfer) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _TransferHistoryCard(transfer: transfer),
                      );
                    }),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Gudang'),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.count});

  final int count;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
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
              color: const Color(0xFFEAF4E6),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.warehouse_outlined,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Lokasi Penyimpanan',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: AppColors.black,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '$count gudang tercatat',
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
    );
  }
}

class _WarehouseCard extends StatelessWidget {
  const _WarehouseCard({
    required this.warehouse,
    required this.onEdit,
    required this.onDelete,
  });

  final CollectorWarehouse warehouse;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

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
              Expanded(
                child: Text(
                  warehouse.name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: AppColors.black,
                  ),
                ),
              ),
              if (warehouse.isDefault)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF4E6),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'Default',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            warehouse.location,
            style: const TextStyle(
              fontSize: 12,
              height: 1.4,
              color: AppColors.subtitle,
            ),
          ),
          if (warehouse.note?.trim().isNotEmpty == true) ...[
            const SizedBox(height: 5),
            Text(
              warehouse.note!.trim(),
              style: const TextStyle(
                fontSize: 11,
                height: 1.4,
                color: AppColors.placeholder,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              TextButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined, size: 16),
                label: const Text('Edit'),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline_rounded, size: 16),
                label: const Text('Hapus'),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFFD64545),
                ),
              ),
            ],
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

class _TransferActionCard extends StatelessWidget {
  const _TransferActionCard({
    required this.enabled,
    required this.availableBatchCount,
    required this.onTap,
  });

  final bool enabled;
  final int availableBatchCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
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
              color: const Color(0xFFEAF4E6),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.move_down_rounded,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Transfer Antar Gudang',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: AppColors.black,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  enabled
                      ? '$availableBatchCount batch siap dipindah'
                      : 'Butuh minimal dua gudang dan stok tersedia',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.placeholder,
                  ),
                ),
              ],
            ),
          ),
          FilledButton.icon(
            onPressed: enabled ? onTap : null,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primaryContainer,
              foregroundColor: AppColors.white,
              disabledBackgroundColor: const Color(0xFFE3E8E0),
              disabledForegroundColor: AppColors.placeholder,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            icon: const Icon(Icons.swap_horiz_rounded, size: 18),
            label: const Text('Transfer'),
          ),
        ],
      ),
    );
  }
}

class _TransferHistoryCard extends StatelessWidget {
  const _TransferHistoryCard({required this.transfer});

  final CollectorWarehouseTransfer transfer;

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
              Expanded(
                child: Text(
                  transfer.batchCode,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primary,
                  ),
                ),
              ),
              Text(
                _formatTransferTime(transfer.transferredAt),
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.placeholder,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.warehouse_outlined,
                size: 16,
                color: AppColors.subtitle,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${transfer.fromWarehouseName} -> ${transfer.toWarehouseName}',
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.35,
                    fontWeight: FontWeight.w800,
                    color: AppColors.black,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${_formatKg(transfer.weightKg)} kg / ${transfer.fruitCount} butir',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.subtitle,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            transfer.reason,
            style: const TextStyle(
              fontSize: 12,
              height: 1.4,
              color: AppColors.placeholder,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Aktor: ${transfer.actorName}',
            style: const TextStyle(fontSize: 11, color: AppColors.placeholder),
          ),
        ],
      ),
    );
  }
}

class _TransferFormResult {
  const _TransferFormResult({
    required this.batchCode,
    required this.fromWarehouseId,
    required this.toWarehouseId,
    required this.reason,
  });

  final String batchCode;
  final String fromWarehouseId;
  final String toWarehouseId;
  final String reason;
}

class _TransferFormSheet extends StatefulWidget {
  const _TransferFormSheet({
    required this.repo,
    required this.batches,
    required this.warehouses,
  });

  final CollectorRepository repo;
  final List<HarvestBatch> batches;
  final List<CollectorWarehouse> warehouses;

  @override
  State<_TransferFormSheet> createState() => _TransferFormSheetState();
}

class _TransferFormSheetState extends State<_TransferFormSheet> {
  late final TextEditingController _reasonCtrl;
  String? _selectedBatchCode;
  String? _selectedToWarehouseId;

  HarvestBatch? get _selectedBatch {
    final code = _selectedBatchCode;
    if (code == null) return null;
    try {
      return widget.batches.firstWhere((batch) => batch.code == code);
    } catch (_) {
      return null;
    }
  }

  CollectorWarehouse? get _fromWarehouse {
    return widget.repo.findWarehouse(_selectedBatch?.warehouseId);
  }

  List<CollectorWarehouse> get _destinationWarehouses {
    final fromId = _fromWarehouse?.id;
    if (fromId == null) return const [];
    return widget.warehouses
        .where((warehouse) => warehouse.id != fromId)
        .toList();
  }

  @override
  void initState() {
    super.initState();
    _reasonCtrl = TextEditingController();
    if (widget.batches.isNotEmpty) {
      _selectedBatchCode = widget.batches.first.code;
    }
    final destinations = _destinationWarehouses;
    if (destinations.isNotEmpty) {
      _selectedToWarehouseId = destinations.first.id;
    }
  }

  @override
  void dispose() {
    _reasonCtrl.dispose();
    super.dispose();
  }

  void _selectBatch(String? code) {
    setState(() {
      _selectedBatchCode = code;
      final destinations = _destinationWarehouses;
      _selectedToWarehouseId = destinations.isEmpty
          ? null
          : destinations.first.id;
    });
  }

  void _submit() {
    final batch = _selectedBatch;
    final fromWarehouse = _fromWarehouse;
    final toWarehouseId = _selectedToWarehouseId;
    final reason = _reasonCtrl.text.trim();
    if (batch == null ||
        fromWarehouse == null ||
        toWarehouseId == null ||
        reason.isEmpty) {
      return;
    }

    Navigator.pop(
      context,
      _TransferFormResult(
        batchCode: batch.code,
        fromWarehouseId: fromWarehouse.id,
        toWarehouseId: toWarehouseId,
        reason: reason,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final batch = _selectedBatch;
    final fromWarehouse = _fromWarehouse;
    final destinations = _destinationWarehouses;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, bottom + 16),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Transfer Stok Gudang',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: AppColors.black,
              ),
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              initialValue: _selectedBatchCode,
              items: widget.batches.map((batch) {
                final warehouse = widget.repo.findWarehouse(batch.warehouseId);
                return DropdownMenuItem(
                  value: batch.code,
                  child: Text('${batch.code} - ${warehouse?.name ?? 'Gudang'}'),
                );
              }).toList(),
              onChanged: widget.batches.isEmpty ? null : _selectBatch,
              decoration: InputDecoration(
                labelText: 'Batch stok',
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 10),
            _ReadOnlyInfoRow(
              label: 'Gudang asal',
              value: fromWarehouse?.name ?? '-',
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              initialValue: _selectedToWarehouseId,
              items: destinations.map((warehouse) {
                return DropdownMenuItem(
                  value: warehouse.id,
                  child: Text(warehouse.name),
                );
              }).toList(),
              onChanged: destinations.isEmpty
                  ? null
                  : (value) => setState(() => _selectedToWarehouseId = value),
              decoration: InputDecoration(
                labelText: 'Gudang tujuan',
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 10),
            _ReadOnlyInfoRow(
              label: 'Jumlah dipindah',
              value: batch == null
                  ? '-'
                  : '${_formatKg(batch.receivedQuantity ?? batch.quantity)} kg / ${batch.receivedFruitCount ?? batch.fruitCount ?? 0} butir',
            ),
            const SizedBox(height: 10),
            _SheetTextField(
              controller: _reasonCtrl,
              label: 'Alasan transfer',
              hint: 'Contoh: pemerataan stok atau persiapan pengiriman',
              maxLines: 2,
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryContainer,
                  foregroundColor: AppColors.white,
                  elevation: 0,
                  shape: const StadiumBorder(),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text(
                  'SIMPAN TRANSFER',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReadOnlyInfoRow extends StatelessWidget {
  const _ReadOnlyInfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: AppColors.placeholder),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: AppColors.black,
            ),
          ),
        ],
      ),
    );
  }
}

class _WarehouseFormResult {
  const _WarehouseFormResult({
    required this.name,
    required this.location,
    required this.note,
    required this.isDefault,
  });

  final String name;
  final String location;
  final String? note;
  final bool isDefault;
}

class _WarehouseFormSheet extends StatefulWidget {
  const _WarehouseFormSheet({this.warehouse});

  final CollectorWarehouse? warehouse;

  @override
  State<_WarehouseFormSheet> createState() => _WarehouseFormSheetState();
}

class _WarehouseFormSheetState extends State<_WarehouseFormSheet> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _locationCtrl;
  late final TextEditingController _noteCtrl;
  late bool _isDefault;

  @override
  void initState() {
    super.initState();
    final warehouse = widget.warehouse;
    _nameCtrl = TextEditingController(text: warehouse?.name ?? '');
    _locationCtrl = TextEditingController(text: warehouse?.location ?? '');
    _noteCtrl = TextEditingController(text: warehouse?.note ?? '');
    _isDefault = warehouse?.isDefault ?? false;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _locationCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nameCtrl.text.trim();
    final location = _locationCtrl.text.trim();
    if (name.isEmpty || location.isEmpty) return;

    Navigator.pop(
      context,
      _WarehouseFormResult(
        name: name,
        location: location,
        note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
        isDefault: _isDefault,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, bottom + 16),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.warehouse == null ? 'Tambah Gudang' : 'Edit Gudang',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: AppColors.black,
              ),
            ),
            const SizedBox(height: 14),
            _SheetTextField(
              controller: _nameCtrl,
              label: 'Nama gudang',
              hint: 'Contoh: Gudang Utama Pakis',
            ),
            const SizedBox(height: 10),
            _SheetTextField(
              controller: _locationCtrl,
              label: 'Lokasi',
              hint: 'Alamat/lokasi singkat',
            ),
            const SizedBox(height: 10),
            _SheetTextField(
              controller: _noteCtrl,
              label: 'Catatan',
              hint: 'Opsional',
              maxLines: 2,
            ),
            const SizedBox(height: 8),
            CheckboxListTile(
              value: _isDefault,
              onChanged: (value) {
                setState(() => _isDefault = value ?? false);
              },
              dense: true,
              contentPadding: EdgeInsets.zero,
              activeColor: AppColors.primary,
              title: const Text(
                'Jadikan gudang default',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.subtitle,
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryContainer,
                  foregroundColor: AppColors.white,
                  elevation: 0,
                  shape: const StadiumBorder(),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text(
                  'SIMPAN',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SheetTextField extends StatelessWidget {
  const _SheetTextField({
    required this.controller,
    required this.label,
    required this.hint,
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
