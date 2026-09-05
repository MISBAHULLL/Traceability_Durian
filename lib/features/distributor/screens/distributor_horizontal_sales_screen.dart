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
                        child: _SaleCard(sale: sale),
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
  const _SaleCard({required this.sale});

  final DistributorHorizontalSale sale;

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
                if (isPending) ...[
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(11),
                    decoration: BoxDecoration(
                      color: const Color(0xFF9A6700).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFF9A6700).withValues(alpha: 0.22),
                      ),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.qr_code_scanner_rounded,
                          size: 18,
                          color: Color(0xFF9A6700),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Menunggu distributor penerima scan QR dan menyimpan validasi T2.',
                            style: TextStyle(
                              fontSize: 11,
                              height: 1.35,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF9A6700),
                            ),
                          ),
                        ),
                      ],
                    ),
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
  String? _partnerId;
  late final _itemCtrl = TextEditingController(text: widget.defaultItemCode);
  final _weightCtrl = TextEditingController();
  final _fruitCtrl = TextEditingController();
  final _destinationCtrl = TextEditingController();
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

  Future<void> _openPartnerPicker() async {
    final partner = await showModalBottomSheet<DistributorPartner>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _DistributorPickerSheet(
        partners: widget.partners,
        selectedId: _partnerId,
      ),
    );
    if (partner == null) return;
    setState(() {
      _partnerId = partner.id;
      _destinationCtrl.text = partner.address;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final selectedPartner = _partnerFor(_partnerId);

    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(20, 10, 20, bottom + 20),
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
            _SheetTitle(
              title: 'Buat T1 Jual Distributor',
              subtitle: 'Pilih stok dan akun distributor penerima.',
              onClose: () => Navigator.pop(context),
            ),
            const SizedBox(height: 18),
            const _FormLabel(label: 'Gudang asal'),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              initialValue: _warehouseId,
              isExpanded: true,
              decoration: _inputDecoration(),
              items: widget.warehouses
                  .map(
                    (warehouse) => DropdownMenuItem(
                      value: warehouse.id,
                      child: Text(
                        warehouse.name,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (value) => setState(() => _warehouseId = value),
            ),
            const SizedBox(height: 12),
            const _FormLabel(label: 'Distributor tujuan'),
            const SizedBox(height: 6),
            _PartnerPickerField(
              partner: selectedPartner,
              onTap: _openPartnerPicker,
            ),
            const SizedBox(height: 10),
            _DestinationAddress(partner: selectedPartner),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Divider(height: 1, color: _borderColor),
            ),
            _TextField(
              controller: _itemCtrl,
              label: 'Kode Stok / Batch',
              hint: 'Contoh: PGL-2026-000903',
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
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
            const SizedBox(height: 12),
            _TextArea(
              controller: _noteCtrl,
              label: 'Catatan Penjualan',
              hint: 'Contoh: pemerataan stok lintas kota',
            ),
            const SizedBox(height: 16),
            PrimaryPillButton(
              label: 'SIMPAN T1',
              onPressed: selectedPartner == null ? null : _submit,
            ),
          ],
        ),
      ),
    );
  }
}

class _SheetTitle extends StatelessWidget {
  const _SheetTitle({
    required this.title,
    required this.subtitle,
    required this.onClose,
  });

  final String title;
  final String subtitle;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.primaryContainer.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.swap_horiz_rounded,
            size: 22,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  color: AppColors.black,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.placeholder,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: onClose,
          tooltip: 'Tutup',
          icon: const Icon(Icons.close_rounded),
        ),
      ],
    );
  }
}

class _FormLabel extends StatelessWidget {
  const _FormLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: AppColors.subtitle,
      ),
    );
  }
}

class _PartnerPickerField extends StatelessWidget {
  const _PartnerPickerField({required this.partner, required this.onTap});

  final DistributorPartner? partner;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF8FAF7),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          constraints: const BoxConstraints(minHeight: 62),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: partner == null
                  ? _borderColor
                  : AppColors.primaryContainer,
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.business_outlined,
                size: 21,
                color: partner == null
                    ? AppColors.placeholder
                    : AppColors.primary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      partner?.name ?? 'Pilih akun distributor',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: partner == null
                            ? AppColors.subtitle
                            : AppColors.black,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      partner == null
                          ? 'Cari menggunakan ID, nama, atau kota'
                          : 'ID ${partner!.id}  |  ${partner!.city}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: partner == null
                            ? FontWeight.w400
                            : FontWeight.w700,
                        color: partner == null
                            ? AppColors.placeholder
                            : AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: AppColors.placeholder,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DestinationAddress extends StatelessWidget {
  const _DestinationAddress({required this.partner});

  final DistributorPartner? partner;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAF7),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.location_on_outlined,
            size: 19,
            color: AppColors.placeholder,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Alamat akun terdaftar',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.placeholder,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  partner?.address ?? 'Alamat tampil setelah akun dipilih',
                  style: TextStyle(
                    fontSize: 11,
                    height: 1.4,
                    fontWeight: partner == null
                        ? FontWeight.w400
                        : FontWeight.w600,
                    color: partner == null
                        ? AppColors.placeholder
                        : AppColors.subtitle,
                  ),
                ),
              ],
            ),
          ),
          if (partner != null)
            const Icon(
              Icons.lock_outline_rounded,
              size: 15,
              color: AppColors.placeholder,
            ),
        ],
      ),
    );
  }
}

class _DistributorPickerSheet extends StatefulWidget {
  const _DistributorPickerSheet({
    required this.partners,
    required this.selectedId,
  });

  final List<DistributorPartner> partners;
  final String? selectedId;

  @override
  State<_DistributorPickerSheet> createState() =>
      _DistributorPickerSheetState();
}

class _DistributorPickerSheetState extends State<_DistributorPickerSheet> {
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(_refresh);
  }

  @override
  void dispose() {
    _searchCtrl.removeListener(_refresh);
    _searchCtrl.dispose();
    super.dispose();
  }

  void _refresh() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final query = _searchCtrl.text.trim().toLowerCase();
    final visiblePartners = widget.partners.where((partner) {
      return query.isEmpty ||
          partner.id.toLowerCase().contains(query) ||
          partner.name.toLowerCase().contains(query) ||
          partner.city.toLowerCase().contains(query);
    }).toList();

    return FractionallySizedBox(
      heightFactor: 0.72,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 18),
          child: Column(
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
              const Text(
                'Pilih Distributor Tujuan',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  color: AppColors.black,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Cari akun distributor yang sudah terdaftar',
                style: TextStyle(fontSize: 11, color: AppColors.placeholder),
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: 46,
                child: TextField(
                  controller: _searchCtrl,
                  autofocus: true,
                  decoration: _inputDecoration().copyWith(
                    hintText: 'Masukkan ID, nama, atau kota',
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    suffixIcon: query.isEmpty
                        ? null
                        : IconButton(
                            onPressed: _searchCtrl.clear,
                            tooltip: 'Hapus pencarian',
                            icon: const Icon(Icons.close_rounded, size: 18),
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: visiblePartners.isEmpty
                    ? const Center(
                        child: Text(
                          'Akun distributor tidak ditemukan.',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.placeholder,
                          ),
                        ),
                      )
                    : ListView.separated(
                        itemCount: visiblePartners.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final partner = visiblePartners[index];
                          final selected = partner.id == widget.selectedId;
                          return Material(
                            color: selected
                                ? AppColors.primaryContainer.withValues(
                                    alpha: 0.08,
                                  )
                                : AppColors.white,
                            borderRadius: BorderRadius.circular(8),
                            child: InkWell(
                              onTap: () => Navigator.pop(context, partner),
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: selected
                                        ? AppColors.primaryContainer
                                        : _borderColor,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 38,
                                      height: 38,
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withValues(
                                          alpha: 0.10,
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(
                                        Icons.business_outlined,
                                        size: 20,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                    const SizedBox(width: 11),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            partner.name,
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
                                            '${partner.id}  |  ${partner.city}',
                                            style: const TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.primary,
                                            ),
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            partner.address,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 10,
                                              color: AppColors.placeholder,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Icon(
                                      selected
                                          ? Icons.check_circle_rounded
                                          : Icons.chevron_right_rounded,
                                      size: 20,
                                      color: selected
                                          ? AppColors.primary
                                          : AppColors.placeholder,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FormLabel(label: label),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          textCapitalization: TextCapitalization.characters,
          decoration: _inputDecoration().copyWith(hintText: hint),
        ),
      ],
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FormLabel(label: label),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: TextInputType.numberWithOptions(decimal: decimal),
          inputFormatters: [
            if (decimal)
              FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))
            else
              FilteringTextInputFormatter.digitsOnly,
          ],
          decoration: _inputDecoration().copyWith(suffixText: suffix),
        ),
      ],
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
        _FormLabel(label: label),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: 3,
          decoration: _inputDecoration().copyWith(hintText: hint),
        ),
      ],
    );
  }
}

InputDecoration _inputDecoration() {
  return InputDecoration(
    filled: true,
    fillColor: const Color(0xFFF8FAF7),
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
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
        width: 1.5,
      ),
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
