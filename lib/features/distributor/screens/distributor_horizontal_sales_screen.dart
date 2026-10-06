import 'package:flutter/material.dart';

import '../../../core/network/backend_api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../farmer/models/batch_recipient.dart';
import '../../farmer/models/harvest_batch.dart';
import '../../../shared/widgets/app_top_bar.dart';
import '../../../shared/widgets/primary_pill_button.dart';
import '../../../shared/widgets/top_notification_banner.dart';
import '../data/distributor_repository.dart';
import '../models/distributor_horizontal_sale.dart';
import '../models/distributor_receipt.dart';

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
        inventory: _repo.saleInventoryBatches,
        recipients: _repo.saleRecipients,
      ),
    );
    if (result == null) return;

    try {
      final sale = await _repo.createHorizontalSale(
        batchCode: result.batch.code,
        recipient: result.recipient,
        qualityNote: result.note,
      );
      if (!mounted) return;
      _notification.show(context, 'T1 ${sale.id} menunggu konfirmasi T2.');
    } on BackendApiException catch (error) {
      if (!mounted) return;
      _notification.show(context, error.message, isError: true);
    } on FormatException catch (error) {
      if (!mounted) return;
      _notification.show(context, error.message, isError: true);
    }
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
              title: 'Jual Durian',
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
                            'Menunggu akun tujuan mengonfirmasi penerimaan T2.',
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
  const _SaleFormSheet({required this.inventory, required this.recipients});

  final List<HarvestBatch> inventory;
  final List<BatchRecipient> recipients;

  @override
  State<_SaleFormSheet> createState() => _SaleFormSheetState();
}

class _SaleFormSheetState extends State<_SaleFormSheet> {
  String? _batchCode;
  String? _recipientId;
  final _noteCtrl = TextEditingController();

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final batch = _batchFor(_batchCode);
    final recipient = _recipientFor(_recipientId);
    if (batch == null || recipient == null) return;

    Navigator.pop(
      context,
      _SaleFormResult(batch: batch, recipient: recipient, note: _noteCtrl.text),
    );
  }

  HarvestBatch? _batchFor(String? code) {
    if (code == null) return null;
    for (final batch in widget.inventory) {
      if (batch.code == code) return batch;
    }
    return null;
  }

  BatchRecipient? _recipientFor(String? id) {
    if (id == null) return null;
    for (final recipient in widget.recipients) {
      if (recipient.userId.toString() == id) return recipient;
    }
    return null;
  }

  Future<void> _openRecipientPicker() async {
    final recipient = await showModalBottomSheet<BatchRecipient>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _SaleRecipientPickerSheet(
        recipients: widget.recipients,
        selectedUserId: _recipientId,
      ),
    );
    if (recipient == null) return;
    setState(() => _recipientId = recipient.userId.toString());
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final selectedRecipient = _recipientFor(_recipientId);
    final selectedBatch = _batchFor(_batchCode);

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
              title: 'Buat T1 Jual Durian',
              subtitle: 'Pilih stok terverifikasi dan akun penerima.',
              onClose: () => Navigator.pop(context),
            ),
            const SizedBox(height: 18),
            const _FormLabel(label: 'Stok durian tersedia'),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              initialValue: _batchCode,
              isExpanded: true,
              decoration: _inputDecoration(),
              items: widget.inventory
                  .map(
                    (batch) => DropdownMenuItem(
                      value: batch.code,
                      child: Text(
                        '${batch.code} • ${batch.variety}',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (value) => setState(() => _batchCode = value),
            ),
            if (widget.inventory.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 6),
                child: Text(
                  'Belum ada batch yang sudah diterima sebagai stok distributor.',
                  style: TextStyle(fontSize: 11, color: AppColors.placeholder),
                ),
              ),
            if (selectedBatch != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '${selectedBatch.receivedQuantity ?? selectedBatch.quantity} kg • '
                  '${selectedBatch.receivedFruitCount ?? selectedBatch.fruitCount ?? 0} butir • '
                  '${selectedBatch.farmName}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.subtitle,
                  ),
                ),
              ),
            const SizedBox(height: 12),
            const _FormLabel(label: 'Akun penerima'),
            const SizedBox(height: 6),
            _PartnerPickerField(
              recipient: selectedRecipient,
              onTap: _openRecipientPicker,
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Divider(height: 1, color: _borderColor),
            ),
            _TextArea(
              controller: _noteCtrl,
              label: 'Catatan Penjualan',
              hint: 'Catatan kondisi atau pengiriman (opsional)',
            ),
            const SizedBox(height: 16),
            PrimaryPillButton(
              label: 'SIMPAN T1',
              onPressed: selectedRecipient == null || selectedBatch == null
                  ? null
                  : _submit,
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
  const _PartnerPickerField({required this.recipient, required this.onTap});

  final BatchRecipient? recipient;
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
              color: recipient == null
                  ? _borderColor
                  : AppColors.primaryContainer,
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.business_outlined,
                size: 21,
                color: recipient == null
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
                      recipient?.fullName ?? 'Pilih akun tujuan',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: recipient == null
                            ? AppColors.subtitle
                            : AppColors.black,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      recipient == null
                          ? 'Cari menggunakan nama atau ID akun'
                          : 'ID ${recipient!.accountId}  |  ${recipient!.role.label}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: recipient == null
                            ? FontWeight.w400
                            : FontWeight.w700,
                        color: recipient == null
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

class _SaleRecipientPickerSheet extends StatefulWidget {
  const _SaleRecipientPickerSheet({
    required this.recipients,
    required this.selectedUserId,
  });

  final List<BatchRecipient> recipients;
  final String? selectedUserId;

  @override
  State<_SaleRecipientPickerSheet> createState() =>
      _SaleRecipientPickerSheetState();
}

class _SaleRecipientPickerSheetState extends State<_SaleRecipientPickerSheet> {
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
    final visibleRecipients = widget.recipients.where((recipient) {
      return query.isEmpty ||
          recipient.accountId.toLowerCase().contains(query) ||
          recipient.userId.toString().contains(query) ||
          recipient.fullName.toLowerCase().contains(query) ||
          recipient.role.label.toLowerCase().contains(query);
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
                'Pilih Akun Tujuan',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  color: AppColors.black,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Tujuan dapat berupa pengepul, distributor, atau UMKM.',
                style: TextStyle(fontSize: 11, color: AppColors.placeholder),
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: 46,
                child: TextField(
                  controller: _searchCtrl,
                  autofocus: true,
                  decoration: _inputDecoration().copyWith(
                    hintText: 'Masukkan ID akun atau nama',
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
                child: visibleRecipients.isEmpty
                    ? const Center(
                        child: Text(
                          'Akun tujuan tidak ditemukan.',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.placeholder,
                          ),
                        ),
                      )
                    : ListView.separated(
                        itemCount: visibleRecipients.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final recipient = visibleRecipients[index];
                          final selected =
                              recipient.userId.toString() ==
                              widget.selectedUserId;
                          return Material(
                            color: selected
                                ? AppColors.primaryContainer.withValues(
                                    alpha: 0.08,
                                  )
                                : AppColors.white,
                            borderRadius: BorderRadius.circular(8),
                            child: InkWell(
                              onTap: () => Navigator.pop(context, recipient),
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
                                            recipient.fullName,
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
                                            'ID ${recipient.accountId}  |  ${recipient.role.label}',
                                            style: const TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.primary,
                                            ),
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            recipient.address.isEmpty
                                                ? 'Alamat belum tersedia'
                                                : recipient.address,
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
    required this.batch,
    required this.recipient,
    required this.note,
  });

  final HarvestBatch batch;
  final BatchRecipient recipient;
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
