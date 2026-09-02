import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_top_bar.dart';
import '../../../shared/widgets/top_notification_banner.dart';
import '../data/distributor_repository.dart';
import '../models/distributor_warehouse.dart';

const _pageBackground = Color(0xFFF4F6F3);
const _borderColor = Color(0xFFE1E6DF);

class DistributorWarehousesScreen extends StatefulWidget {
  const DistributorWarehousesScreen({super.key});

  @override
  State<DistributorWarehousesScreen> createState() =>
      _DistributorWarehousesScreenState();
}

class _DistributorWarehousesScreenState
    extends State<DistributorWarehousesScreen> {
  final _repo = DistributorRepository.instance;
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

  Future<void> _openWarehouseForm([DistributorWarehouse? warehouse]) async {
    final result = await showModalBottomSheet<_WarehouseFormResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) => _WarehouseFormSheet(warehouse: warehouse),
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

  Future<void> _deleteWarehouse(DistributorWarehouse warehouse) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.white,
          title: const Text('Hapus Gudang?'),
          content: Text(
            'Gudang ${warehouse.name} akan dihapus dari daftar distributor.',
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
          : 'Gudang tidak bisa dihapus karena masih dipakai transfer atau tersisa satu.',
      isError: !ok,
    );
  }

  Future<void> _openTransferForm() async {
    final warehouses = _repo.warehouses;
    if (warehouses.length < 2) {
      _notification.show(
        context,
        'Minimal dua gudang diperlukan untuk transfer internal.',
        isError: true,
      );
      return;
    }

    final result = await showModalBottomSheet<_TransferFormResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) => _TransferFormSheet(warehouses: warehouses),
    );
    if (result == null) return;

    final transfer = _repo.createWarehouseTransfer(
      fromWarehouseId: result.fromWarehouseId,
      toWarehouseId: result.toWarehouseId,
      itemCode: result.itemCode,
      weightKg: result.weightKg,
      fruitCount: result.fruitCount,
      note: result.note,
    );
    if (!mounted) return;
    _notification.show(
      context,
      transfer == null
          ? 'Transfer gagal disimpan. Periksa gudang dan jumlah.'
          : 'Transfer ${transfer.id} berhasil disimpan.',
      isError: transfer == null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final warehouses = _repo.warehouses;
    final transfers = _repo.warehouseTransfers;

    return Scaffold(
      backgroundColor: _pageBackground,
      body: SafeArea(
        child: Column(
          children: [
            AppTopBar(
              title: 'Manajemen Gudang',
              actions: [
                IconButton(
                  onPressed: _openTransferForm,
                  tooltip: 'Transfer antar gudang',
                  icon: const Icon(
                    Icons.compare_arrows_rounded,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
                children: [
                  _SummaryPanel(
                    warehouseCount: warehouses.length,
                    transferCount: transfers.length,
                    onTransfer: _openTransferForm,
                  ),
                  const SizedBox(height: 16),
                  _SectionHeader(
                    title: 'Daftar Gudang',
                    count: warehouses.length,
                  ),
                  const SizedBox(height: 8),
                  ...warehouses.map(
                    (warehouse) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _WarehouseCard(
                        warehouse: warehouse,
                        onEdit: () => _openWarehouseForm(warehouse),
                        onDelete: () => _deleteWarehouse(warehouse),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _SectionHeader(
                    title: 'Riwayat Transfer',
                    count: transfers.length,
                  ),
                  const SizedBox(height: 8),
                  if (transfers.isEmpty)
                    const _EmptyTransferState()
                  else
                    ...transfers
                        .take(10)
                        .map(
                          (transfer) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _TransferCard(
                              transfer: transfer,
                              repo: _repo,
                            ),
                          ),
                        ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openWarehouseForm(),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Gudang'),
      ),
    );
  }
}

class _SummaryPanel extends StatelessWidget {
  const _SummaryPanel({
    required this.warehouseCount,
    required this.transferCount,
    required this.onTransfer,
  });

  final int warehouseCount;
  final int transferCount;
  final VoidCallback onTransfer;

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
            child: _SummaryMetric(label: 'Gudang', value: '$warehouseCount'),
          ),
          Container(width: 1, height: 38, color: const Color(0xFF8BCB70)),
          Expanded(
            child: _SummaryMetric(label: 'Transfer', value: '$transferCount'),
          ),
          const SizedBox(width: 10),
          IconButton(
            onPressed: onTransfer,
            tooltip: 'Transfer antar gudang',
            style: IconButton.styleFrom(
              backgroundColor: AppColors.white.withValues(alpha: 0.16),
              foregroundColor: AppColors.white,
            ),
            icon: const Icon(Icons.compare_arrows_rounded),
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
              fontSize: 23,
              fontWeight: FontWeight.w900,
              color: AppColors.white,
            ),
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: Color(0xFFEAF7E5)),
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

class _WarehouseCard extends StatelessWidget {
  const _WarehouseCard({
    required this.warehouse,
    required this.onEdit,
    required this.onDelete,
  });

  final DistributorWarehouse warehouse;
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
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.warehouse_outlined,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      warehouse.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: AppColors.black,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      warehouse.location,
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
              if (warehouse.isDefault) const _Badge(label: 'Default'),
            ],
          ),
          if (warehouse.note?.trim().isNotEmpty == true) ...[
            const SizedBox(height: 9),
            Text(
              warehouse.note!.trim(),
              style: const TextStyle(
                fontSize: 11,
                height: 1.4,
                color: AppColors.subtitle,
              ),
            ),
          ],
          const SizedBox(height: 10),
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

class _TransferCard extends StatelessWidget {
  const _TransferCard({required this.transfer, required this.repo});

  final DistributorWarehouseTransfer transfer;
  final DistributorRepository repo;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFF1D6FA4).withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.compare_arrows_rounded,
              color: Color(0xFF1D6FA4),
              size: 21,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transfer.id,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${repo.warehouseLabel(transfer.fromWarehouseId)} -> ${repo.warehouseLabel(transfer.toWarehouseId)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.black,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${transfer.itemCode} / ${_formatWeight(transfer.weightKg)} / ${transfer.fruitCount} butir',
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

class _Badge extends StatelessWidget {
  const _Badge({required this.label});

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

class _EmptyTransferState extends StatelessWidget {
  const _EmptyTransferState();

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
      child: const Text(
        'Belum ada transfer internal antar gudang.',
        style: TextStyle(fontSize: 12, color: AppColors.placeholder),
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

  final DistributorWarehouse? warehouse;

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
              hint: 'Contoh: Gudang Hub Surabaya',
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

class _TransferFormResult {
  const _TransferFormResult({
    required this.fromWarehouseId,
    required this.toWarehouseId,
    required this.itemCode,
    required this.weightKg,
    required this.fruitCount,
    required this.note,
  });

  final String fromWarehouseId;
  final String toWarehouseId;
  final String itemCode;
  final double weightKg;
  final int fruitCount;
  final String? note;
}

class _TransferFormSheet extends StatefulWidget {
  const _TransferFormSheet({required this.warehouses});

  final List<DistributorWarehouse> warehouses;

  @override
  State<_TransferFormSheet> createState() => _TransferFormSheetState();
}

class _TransferFormSheetState extends State<_TransferFormSheet> {
  late String _fromWarehouseId;
  late String _toWarehouseId;
  final _itemCodeCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  final _fruitCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fromWarehouseId = widget.warehouses.first.id;
    _toWarehouseId = widget.warehouses.length > 1
        ? widget.warehouses[1].id
        : widget.warehouses.first.id;
  }

  @override
  void dispose() {
    _itemCodeCtrl.dispose();
    _weightCtrl.dispose();
    _fruitCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final itemCode = _itemCodeCtrl.text.trim();
    final weight = double.tryParse(
      _weightCtrl.text.trim().replaceAll(',', '.'),
    );
    final fruit = int.tryParse(_fruitCtrl.text.trim());
    if (_fromWarehouseId == _toWarehouseId ||
        itemCode.isEmpty ||
        weight == null ||
        weight <= 0 ||
        fruit == null ||
        fruit <= 0) {
      return;
    }

    Navigator.pop(
      context,
      _TransferFormResult(
        fromWarehouseId: _fromWarehouseId,
        toWarehouseId: _toWarehouseId,
        itemCode: itemCode,
        weightKg: weight,
        fruitCount: fruit,
        note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
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
            const Text(
              'Transfer Antar Gudang',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: AppColors.black,
              ),
            ),
            const SizedBox(height: 14),
            _WarehouseDropdown(
              label: 'Gudang Asal',
              value: _fromWarehouseId,
              warehouses: widget.warehouses,
              onChanged: (value) {
                if (value != null) setState(() => _fromWarehouseId = value);
              },
            ),
            const SizedBox(height: 10),
            _WarehouseDropdown(
              label: 'Gudang Tujuan',
              value: _toWarehouseId,
              warehouses: widget.warehouses,
              onChanged: (value) {
                if (value != null) setState(() => _toWarehouseId = value);
              },
            ),
            const SizedBox(height: 10),
            _SheetTextField(
              controller: _itemCodeCtrl,
              label: 'Kode Stok/Manifest',
              hint: 'Contoh: PGL-2026-000901',
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _SheetTextField(
                    controller: _weightCtrl,
                    label: 'Berat',
                    hint: 'kg',
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'^\d+\.?\d{0,2}'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _SheetTextField(
                    controller: _fruitCtrl,
                    label: 'Jumlah',
                    hint: 'butir',
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _SheetTextField(
              controller: _noteCtrl,
              label: 'Catatan',
              hint: 'Opsional',
              maxLines: 2,
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _submit,
                icon: const Icon(Icons.compare_arrows_rounded),
                label: const Text('SIMPAN TRANSFER'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryContainer,
                  foregroundColor: AppColors.white,
                  elevation: 0,
                  shape: const StadiumBorder(),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  textStyle: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WarehouseDropdown extends StatelessWidget {
  const _WarehouseDropdown({
    required this.label,
    required this.value,
    required this.warehouses,
    required this.onChanged,
  });

  final String label;
  final String value;
  final List<DistributorWarehouse> warehouses;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      items: warehouses.map((warehouse) {
        return DropdownMenuItem(
          value: warehouse.id,
          child: Text(
            warehouse.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
    this.keyboardType,
    this.inputFormatters,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final int maxLines;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
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

String _formatWeight(double value) {
  final text = value % 1 == 0
      ? value.toStringAsFixed(0)
      : value.toStringAsFixed(2);
  return '$text kg';
}
