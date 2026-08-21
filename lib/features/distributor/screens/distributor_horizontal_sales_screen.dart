import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_top_bar.dart';
import '../../../shared/widgets/primary_pill_button.dart';
import '../../../shared/widgets/top_notification_banner.dart';
import '../data/distributor_repository.dart';
import '../models/distributor_horizontal_sale.dart';
import '../models/distributor_receipt.dart';
import '../models/distributor_warehouse.dart';

const _pageBackground = Color(0xFFF4F6F3);
const _borderColor = Color(0xFFE1E6DF);

class DistributorHorizontalSalesScreen extends StatefulWidget {
  const DistributorHorizontalSalesScreen({super.key});

  @override
  State<DistributorHorizontalSalesScreen> createState() =>
      _DistributorHorizontalSalesScreenState();
}

class _DistributorHorizontalSalesScreenState
    extends State<DistributorHorizontalSalesScreen> {
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

  Future<void> _openCreateForm() async {
    final result = await showModalBottomSheet<_SaleFormResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) => _SaleFormSheet(
        warehouses: _repo.warehouses,
        partners: _repo.distributorPartners,
        defaultItemCode: _defaultItemCode(),
      ),
    );
    if (result == null) return;

    final sale = _repo.initiateHorizontalSale(
      buyerDistributorId: result.buyerDistributorId,
      sourceWarehouseId: result.sourceWarehouseId,
      itemCode: result.itemCode,
      expectedWeightKg: result.expectedWeightKg,
      expectedFruitCount: result.expectedFruitCount,
      destinationLocation: result.destinationLocation,
      qualityNote: result.note,
    );
    if (!mounted) return;
    _notification.show(
      context,
      sale == null
          ? 'T1 jual distributor gagal dibuat. Periksa data wajib.'
          : 'T1 ${sale.id} berhasil dibuat.',
      isError: sale == null,
    );
  }

  Future<void> _openVerifyForm(DistributorHorizontalSale sale) async {
    final result = await showModalBottomSheet<_VerifySaleResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) => _VerifySaleSheet(sale: sale),
    );
    if (result == null) return;

    final ok = _repo.verifyHorizontalSale(
      saleId: sale.id,
      receivedWeightKg: result.receivedWeightKg,
      receivedFruitCount: result.receivedFruitCount,
      condition: result.condition,
      discrepancyNote: result.discrepancyNote,
      qualityNote: result.qualityNote,
    );
    if (!mounted) return;
    _notification.show(
      context,
      ok
          ? 'T2 ${sale.id} berhasil diverifikasi.'
          : 'T2 gagal disimpan. Periksa selisih dan catatan.',
      isError: !ok,
    );
  }

  Future<void> _openRejectForm(DistributorHorizontalSale sale) async {
    final note = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) => const _RejectSaleSheet(),
    );
    if (note == null) return;

    final ok = _repo.rejectHorizontalSale(saleId: sale.id, note: note);
    if (!mounted) return;
    _notification.show(
      context,
      ok ? '${sale.id} ditolak.' : 'Penolakan gagal disimpan.',
      isError: !ok,
    );
  }

  String _defaultItemCode() {
    final receipts = _repo.receiptHistory;
    if (receipts.isNotEmpty) return receipts.first.shipmentCode;
    final transfers = _repo.warehouseTransfers;
    if (transfers.isNotEmpty) return transfers.first.itemCode;
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final sales = _repo.horizontalSales;
    final pending = sales
        .where(
          (sale) => sale.status == DistributorHorizontalSaleStatus.initiated,
        )
        .toList();
    final finished = sales
        .where(
          (sale) => sale.status != DistributorHorizontalSaleStatus.initiated,
        )
        .toList();

    return Scaffold(
      backgroundColor: _pageBackground,
      body: SafeArea(
        child: Column(
          children: [
            AppTopBar(
              title: 'Jual ke Distributor Lain',
              actions: [
                IconButton(
                  onPressed: _openCreateForm,
                  tooltip: 'Buat T1 penjualan',
                  icon: const Icon(Icons.add_rounded, color: AppColors.primary),
                ),
              ],
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
                children: [
                  _SummaryPanel(
                    pendingCount: pending.length,
                    finishedCount: finished.length,
                    onCreate: _openCreateForm,
                  ),
                  const SizedBox(height: 16),
                  _SectionHeader(
                    title: 'T1 Menunggu Validasi',
                    count: pending.length,
                  ),
                  const SizedBox(height: 8),
                  if (pending.isEmpty)
                    const _EmptyState(
                      message:
                          'Belum ada transaksi horizontal yang menunggu T2.',
                    )
                  else
                    ...pending.map(
                      (sale) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _SaleCard(
                          sale: sale,
                          onVerify: () => _openVerifyForm(sale),
                          onReject: () => _openRejectForm(sale),
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  _SectionHeader(
                    title: 'Riwayat Penjualan',
                    count: finished.length,
                  ),
                  const SizedBox(height: 8),
                  if (finished.isEmpty)
                    const _EmptyState(
                      message:
                          'Penjualan yang terverifikasi atau ditolak akan tampil di sini.',
                    )
                  else
                    ...finished.map(
                      (sale) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _SaleCard(sale: sale),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreateForm,
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('T1 Jual'),
      ),
    );
  }
}

class _SummaryPanel extends StatelessWidget {
  const _SummaryPanel({
    required this.pendingCount,
    required this.finishedCount,
    required this.onCreate,
  });

  final int pendingCount;
  final int finishedCount;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 88, 168, 53),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _Metric(label: 'Menunggu T2', value: '$pendingCount'),
              ),
              Container(width: 1, height: 38, color: const Color(0xFF8BCB70)),
              Expanded(
                child: _Metric(label: 'Selesai', value: '$finishedCount'),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 42,
            child: OutlinedButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.add_business_outlined, size: 18),
              label: const Text('BUAT T1 PENJUALAN'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.white,
                side: const BorderSide(color: AppColors.white),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                textStyle: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
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

class _SaleCard extends StatelessWidget {
  const _SaleCard({required this.sale, this.onVerify, this.onReject});

  final DistributorHorizontalSale sale;
  final VoidCallback? onVerify;
  final VoidCallback? onReject;

  @override
  Widget build(BuildContext context) {
    final isPending = sale.status == DistributorHorizontalSaleStatus.initiated;
    final statusColor = switch (sale.status) {
      DistributorHorizontalSaleStatus.initiated => const Color(0xFF9A6700),
      DistributorHorizontalSaleStatus.verified => AppColors.primary,
      DistributorHorizontalSaleStatus.rejected => const Color(0xFFD64545),
    };

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _borderColor),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.local_shipping_outlined,
                    size: 22,
                    color: statusColor,
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sale.id,
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
                        '${sale.itemCode} / ${sale.buyerName}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: AppColors.black,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${sale.sourceWarehouseName} -> ${sale.destinationLocation}',
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
                _StatusBadge(label: sale.status.label, color: statusColor),
              ],
            ),
          ),
          const Divider(height: 1, color: _borderColor),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
            child: Column(
              children: [
                _InfoRow(
                  label: 'Manifest',
                  value:
                      '${_formatWeight(sale.expectedWeightKg)} / ${sale.expectedFruitCount} butir',
                ),
                if (sale.receivedWeightKg != null &&
                    sale.receivedFruitCount != null)
                  _InfoRow(
                    label: 'Diterima',
                    value:
                        '${_formatWeight(sale.receivedWeightKg!)} / ${sale.receivedFruitCount} butir',
                  ),
                if (sale.condition != null)
                  _InfoRow(label: 'Kondisi', value: sale.condition!.label),
                _InfoRow(
                  label: 'Tanggal',
                  value: _formatDateTime(sale.initiatedAt),
                ),
                if (isPending && onVerify != null && onReject != null) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: onReject,
                          icon: const Icon(Icons.close_rounded, size: 16),
                          label: const Text('Tolak'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFD64545),
                            side: const BorderSide(color: Color(0xFFD64545)),
                            minimumSize: const Size.fromHeight(38),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          onPressed: onVerify,
                          icon: const Icon(Icons.fact_check_outlined, size: 16),
                          label: const Text('Validasi T2'),
                          style: ElevatedButton.styleFrom(
                            elevation: 0,
                            backgroundColor: const Color.fromARGB(
                              255,
                              88,
                              168,
                              53,
                            ),
                            foregroundColor: AppColors.white,
                            minimumSize: const Size.fromHeight(38),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w900,
          color: color,
        ),
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
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 74,
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
                fontWeight: FontWeight.w800,
                color: AppColors.subtitle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SaleFormSheet extends StatefulWidget {
  const _SaleFormSheet({
    required this.warehouses,
    required this.partners,
    required this.defaultItemCode,
  });

  final List<DistributorWarehouse> warehouses;
  final List<DistributorPartner> partners;
  final String defaultItemCode;

  @override
  State<_SaleFormSheet> createState() => _SaleFormSheetState();
}

class _SaleFormSheetState extends State<_SaleFormSheet> {
  late String? _warehouseId = widget.warehouses.isEmpty
      ? null
      : widget.warehouses.first.id;
  late String? _partnerId = widget.partners.isEmpty
      ? null
      : widget.partners.first.id;
  late final _itemCtrl = TextEditingController(text: widget.defaultItemCode);
  final _weightCtrl = TextEditingController();
  final _fruitCtrl = TextEditingController();
  late final _destinationCtrl = TextEditingController(
    text: widget.partners.isEmpty ? '' : widget.partners.first.address,
  );
  final _noteCtrl = TextEditingController();

  @override
  void dispose() {
    _itemCtrl.dispose();
    _weightCtrl.dispose();
    _fruitCtrl.dispose();
    _destinationCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final weight = double.tryParse(
      _weightCtrl.text.trim().replaceAll(',', '.'),
    );
    final fruit = int.tryParse(_fruitCtrl.text.trim());
    if (_warehouseId == null ||
        _partnerId == null ||
        _itemCtrl.text.trim().isEmpty ||
        _destinationCtrl.text.trim().isEmpty ||
        weight == null ||
        weight <= 0 ||
        fruit == null ||
        fruit <= 0) {
      return;
    }

    Navigator.pop(
      context,
      _SaleFormResult(
        buyerDistributorId: _partnerId!,
        sourceWarehouseId: _warehouseId!,
        itemCode: _itemCtrl.text,
        expectedWeightKg: weight,
        expectedFruitCount: fruit,
        destinationLocation: _destinationCtrl.text,
        note: _noteCtrl.text,
      ),
    );
  }

  DistributorPartner? _partnerFor(String? id) {
    if (id == null) return null;
    for (final partner in widget.partners) {
      if (partner.id == id) return partner;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, bottom + 18),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SheetTitle(
              title: 'Buat T1 Jual Distributor',
              subtitle: 'Pilih stok, gudang asal, dan distributor tujuan.',
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              initialValue: _warehouseId,
              isExpanded: true,
              decoration: _inputDecoration('Gudang Asal'),
              items: widget.warehouses
                  .map(
                    (warehouse) => DropdownMenuItem(
                      value: warehouse.id,
                      child: Text(warehouse.name),
                    ),
                  )
                  .toList(),
              onChanged: (value) => setState(() => _warehouseId = value),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              initialValue: _partnerId,
              isExpanded: true,
              decoration: _inputDecoration('Distributor Tujuan'),
              items: widget.partners
                  .map(
                    (partner) => DropdownMenuItem(
                      value: partner.id,
                      child: Text('${partner.name} - ${partner.city}'),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _partnerId = value;
                  final partner = _partnerFor(value);
                  if (partner != null) _destinationCtrl.text = partner.address;
                });
              },
            ),
            const SizedBox(height: 10),
            _TextField(
              controller: _itemCtrl,
              label: 'Kode Stok / Batch',
              hint: 'Contoh: PGL-2026-000903',
            ),
            const SizedBox(height: 10),
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
            _TextField(
              controller: _destinationCtrl,
              label: 'Lokasi Tujuan',
              hint: 'Alamat/gudang distributor tujuan',
            ),
            const SizedBox(height: 10),
            _TextArea(
              controller: _noteCtrl,
              label: 'Catatan Penjualan',
              hint: 'Contoh: pemerataan stok lintas kota',
            ),
            const SizedBox(height: 16),
            PrimaryPillButton(label: 'SIMPAN T1', onPressed: _submit),
          ],
        ),
      ),
    );
  }
}

class _VerifySaleSheet extends StatefulWidget {
  const _VerifySaleSheet({required this.sale});

  final DistributorHorizontalSale sale;

  @override
  State<_VerifySaleSheet> createState() => _VerifySaleSheetState();
}

class _VerifySaleSheetState extends State<_VerifySaleSheet> {
  late final _weightCtrl = TextEditingController(
    text: _formatNumber(widget.sale.expectedWeightKg),
  );
  late final _fruitCtrl = TextEditingController(
    text: widget.sale.expectedFruitCount.toString(),
  );
  final _discrepancyCtrl = TextEditingController();
  final _qualityCtrl = TextEditingController();
  DistributorReceiptCondition? _condition;

  @override
  void dispose() {
    _weightCtrl.dispose();
    _fruitCtrl.dispose();
    _discrepancyCtrl.dispose();
    _qualityCtrl.dispose();
    super.dispose();
  }

  bool get _hasDiscrepancy {
    final weight = double.tryParse(
      _weightCtrl.text.trim().replaceAll(',', '.'),
    );
    final fruit = int.tryParse(_fruitCtrl.text.trim());
    if (weight == null || fruit == null) return false;
    return (weight - widget.sale.expectedWeightKg).abs() > 0.01 ||
        fruit != widget.sale.expectedFruitCount;
  }

  void _submit() {
    final weight = double.tryParse(
      _weightCtrl.text.trim().replaceAll(',', '.'),
    );
    final fruit = int.tryParse(_fruitCtrl.text.trim());
    final condition = _condition;
    if (weight == null ||
        weight <= 0 ||
        fruit == null ||
        fruit <= 0 ||
        condition == null ||
        (_hasDiscrepancy && _discrepancyCtrl.text.trim().isEmpty)) {
      return;
    }

    Navigator.pop(
      context,
      _VerifySaleResult(
        receivedWeightKg: weight,
        receivedFruitCount: fruit,
        condition: condition,
        discrepancyNote: _discrepancyCtrl.text,
        qualityNote: _qualityCtrl.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, bottom + 18),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SheetTitle(
              title: 'Validasi T2',
              subtitle:
                  '${widget.sale.itemCode} diterima oleh ${widget.sale.buyerName}.',
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _NumberField(
                    controller: _weightCtrl,
                    label: 'Berat Diterima',
                    suffix: 'kg',
                    decimal: true,
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _NumberField(
                    controller: _fruitCtrl,
                    label: 'Jumlah',
                    suffix: 'butir',
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ],
            ),
            if (_hasDiscrepancy) ...[
              const SizedBox(height: 10),
              _TextArea(
                controller: _discrepancyCtrl,
                label: 'Alasan Selisih',
                hint: 'Contoh: susut timbang atau selisih hitung penerima',
              ),
            ],
            const SizedBox(height: 12),
            const Text(
              'Kondisi Fisik',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: AppColors.black,
              ),
            ),
            const SizedBox(height: 8),
            _ConditionSelector(
              selected: _condition,
              onChanged: (condition) => setState(() => _condition = condition),
            ),
            const SizedBox(height: 10),
            _TextArea(
              controller: _qualityCtrl,
              label: 'Catatan Pemeriksaan',
              hint: 'Contoh: diterima baik di gudang tujuan',
            ),
            const SizedBox(height: 16),
            PrimaryPillButton(label: 'SIMPAN T2', onPressed: _submit),
          ],
        ),
      ),
    );
  }
}

class _RejectSaleSheet extends StatefulWidget {
  const _RejectSaleSheet();

  @override
  State<_RejectSaleSheet> createState() => _RejectSaleSheetState();
}

class _RejectSaleSheetState extends State<_RejectSaleSheet> {
  final _noteCtrl = TextEditingController();

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final note = _noteCtrl.text.trim();
    if (note.isEmpty) return;
    Navigator.pop(context, note);
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, bottom + 18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SheetTitle(
            title: 'Tolak Penjualan',
            subtitle: 'Catat alasan agar audit trail tetap lengkap.',
          ),
          const SizedBox(height: 14),
          _TextArea(
            controller: _noteCtrl,
            label: 'Alasan Penolakan',
            hint: 'Contoh: pembeli membatalkan kebutuhan stok',
          ),
          const SizedBox(height: 16),
          PrimaryPillButton(label: 'SIMPAN PENOLAKAN', onPressed: _submit),
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

class _SheetTitle extends StatelessWidget {
  const _SheetTitle({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: AppColors.black,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 12,
            height: 1.35,
            color: AppColors.placeholder,
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
  });

  final TextEditingController controller;
  final String label;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      textCapitalization: TextCapitalization.characters,
      decoration: _inputDecoration(label).copyWith(hintText: hint),
    );
  }
}

class _NumberField extends StatelessWidget {
  const _NumberField({
    required this.controller,
    required this.label,
    required this.suffix,
    this.decimal = false,
    this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final String suffix;
  final bool decimal;
  final ValueChanged<String>? onChanged;

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
      onChanged: onChanged,
      decoration: _inputDecoration(label).copyWith(suffixText: suffix),
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
    return TextField(
      controller: controller,
      maxLines: 3,
      decoration: _inputDecoration(label).copyWith(hintText: hint),
    );
  }
}

InputDecoration _inputDecoration(String label) {
  return InputDecoration(
    labelText: label,
    filled: true,
    fillColor: _pageBackground,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: _borderColor),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: AppColors.primaryContainer, width: 2),
    ),
  );
}

class _SaleFormResult {
  const _SaleFormResult({
    required this.buyerDistributorId,
    required this.sourceWarehouseId,
    required this.itemCode,
    required this.expectedWeightKg,
    required this.expectedFruitCount,
    required this.destinationLocation,
    required this.note,
  });

  final String buyerDistributorId;
  final String sourceWarehouseId;
  final String itemCode;
  final double expectedWeightKg;
  final int expectedFruitCount;
  final String destinationLocation;
  final String note;
}

class _VerifySaleResult {
  const _VerifySaleResult({
    required this.receivedWeightKg,
    required this.receivedFruitCount,
    required this.condition,
    required this.discrepancyNote,
    required this.qualityNote,
  });

  final double receivedWeightKg;
  final int receivedFruitCount;
  final DistributorReceiptCondition condition;
  final String discrepancyNote;
  final String qualityNote;
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
  return value % 1 == 0
      ? '${value.toStringAsFixed(0)} kg'
      : '${value.toStringAsFixed(2)} kg';
}

String _formatNumber(double value) {
  return value % 1 == 0 ? value.toStringAsFixed(0) : value.toStringAsFixed(2);
}

String _formatDateTime(DateTime date) {
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
  final hour = date.hour.toString().padLeft(2, '0');
  final minute = date.minute.toString().padLeft(2, '0');
  return '${date.day} ${months[date.month - 1]} ${date.year}, $hour:$minute';
}
