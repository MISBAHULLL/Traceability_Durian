import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_top_bar.dart';
import '../../../shared/widgets/primary_pill_button.dart';
import '../../../shared/widgets/qr_preview.dart';
import '../data/umkm_repository.dart';
import '../models/umkm_purchase.dart';
import '../models/umkm_stock_offer.dart';
import '../models/umkm_stock_order.dart';

class UmkmAddPurchaseScreen extends StatefulWidget {
  const UmkmAddPurchaseScreen({super.key});

  @override
  State<UmkmAddPurchaseScreen> createState() => _UmkmAddPurchaseScreenState();
}

class _UmkmAddPurchaseScreenState extends State<UmkmAddPurchaseScreen> {
  final _repo = UmkmRepository.instance;

  final _searchCtrl = TextEditingController();
  String _query = '';
  _MainTab _activeTab = _MainTab.beli;
  UmkmSupplierType? _activeSupplierFilter;
  UmkmStockOrderStatus _activeOrderStatus = UmkmStockOrderStatus.diproses;

  @override
  void initState() {
    super.initState();
    _repo.addListener(_onRepoChanged);
    _searchCtrl.addListener(() {
      setState(() => _query = _searchCtrl.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _repo.removeListener(_onRepoChanged);
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onRepoChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final offers = _repo.stockOffers.where(_matchesOffer).toList();

    final orders = _repo.stockOrders
        .where((order) => order.status == _activeOrderStatus)
        .toList();

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            const AppTopBar(title: 'Beli Stok Durian'),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Pilih durian dari pengepul, distributor, atau petani lalu buat pesanan stok.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.placeholder,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _SectionTabs(
                    active: _activeTab,
                    onChanged: (value) => setState(() => _activeTab = value),
                  ),
                ],
              ),
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: _activeTab == _MainTab.beli
                    ? _buildBeliTab(offers)
                    : _buildPesananTab(orders),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _matchesOffer(UmkmStockOffer offer) {
    try {
      final name = offer.name.toLowerCase();
      final supplierName = offer.supplierName.toLowerCase();
      final traceCode = offer.traceCode.toLowerCase();
      final matchesQuery =
          name.contains(_query) ||
          supplierName.contains(_query) ||
          traceCode.contains(_query);
      final matchesSupplier =
          _activeSupplierFilter == null ||
          offer.supplierType == _activeSupplierFilter;
      return matchesQuery && matchesSupplier;
    } catch (_) {
      return false;
    }
  }

  Widget _buildBeliTab(List<UmkmStockOffer> offers) {
    final categories = <UmkmSupplierType?>[
      null,
      UmkmSupplierType.pengepul,
      UmkmSupplierType.distributor,
      UmkmSupplierType.petani,
    ];

    return ListView(
      key: const ValueKey('beli-tab'),
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
      children: [
        TextField(
          controller: _searchCtrl,
          style: const TextStyle(fontSize: 14, color: AppColors.black),
          decoration: InputDecoration(
            hintText: 'Cari durian, pemasok, atau trace code',
            hintStyle: const TextStyle(
              fontSize: 14,
              color: AppColors.placeholder,
            ),
            prefixIcon: const Icon(
              Icons.search_rounded,
              color: AppColors.placeholder,
              size: 22,
            ),
            filled: true,
            fillColor: AppColors.surface,
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 38,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: categories.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final category = categories[index];
              final label = category?.label ?? 'Semua';
              final isActive = category == _activeSupplierFilter;
              return GestureDetector(
                onTap: () => setState(() => _activeSupplierFilter = category),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isActive ? AppColors.primary : AppColors.surface,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: isActive
                          ? AppColors.primary
                          : const Color(0xFFE5E7EB),
                    ),
                  ),
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isActive ? AppColors.white : AppColors.subtitle,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 18),
        if (offers.isEmpty)
          const _EmptyState(
            icon: Icons.storefront_outlined,
            title: 'Durian tidak ditemukan',
            subtitle: 'Coba ubah kata kunci atau filter pemasok.',
          )
        else
          ...offers.map(
            (offer) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GestureDetector(
                onTap: () => _openOfferDetail(offer),
                child: _OfferCard(offer: offer),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPesananTab(List<UmkmStockOrder> orders) {
    return ListView(
      key: const ValueKey('pesanan-tab'),
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
      children: [
        _SectionTabs(
          active: _activeOrderStatus,
          onChanged: (value) => setState(() => _activeOrderStatus = value),
          leftLabel: 'Diproses',
          rightLabel: 'Selesai',
        ),
        const SizedBox(height: 16),
        if (orders.isEmpty)
          const _EmptyState(
            icon: Icons.receipt_long_outlined,
            title: 'Belum ada pesanan',
            subtitle: 'Pesanan stok untuk tab ini belum tersedia.',
          )
        else
          ...orders.map(
            (order) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GestureDetector(
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => UmkmStockOrderDetailScreen(order: order),
                    ),
                  );
                },
                child: _StockOrderCard(order: order),
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _openOfferDetail(UmkmStockOffer offer) async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => UmkmStockOfferDetailScreen(offer: offer),
      ),
    );
    if (created == true && mounted) {
      setState(() {
        _activeTab = _MainTab.pesanan;
        _activeOrderStatus = UmkmStockOrderStatus.diproses;
      });
    }
  }
}

class UmkmStockOfferDetailScreen extends StatelessWidget {
  const UmkmStockOfferDetailScreen({super.key, required this.offer});

  final UmkmStockOffer offer;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            const AppTopBar(title: 'Detail Stok Durian'),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Image.asset(
                        offer.imagePath ?? 'assets/images/durian.png',
                        width: double.infinity,
                        height: 220,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Container(
                          height: 220,
                          color: AppColors.surface,
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.image_outlined,
                            color: AppColors.placeholder,
                            size: 32,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      offer.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.black,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [_Chip(label: offer.supplierType.label)],
                    ),
                    const SizedBox(height: 16),
                    _InfoTile(label: 'Supplier', value: offer.supplierName),
                    const SizedBox(height: 10),
                    _InfoTile(label: 'Trace Code', value: offer.traceCode),
                    const SizedBox(height: 10),
                    _InfoTile(label: 'Harga', value: offer.priceLabel),
                    const SizedBox(height: 10),
                    _InfoTile(label: 'Stok', value: offer.stockLabel),
                    const SizedBox(height: 10),
                    _InfoTile(label: 'Deskripsi', value: offer.description),
                    const SizedBox(height: 16),
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: QrPreview(data: offer.traceCode, size: 150),
                      ),
                    ),
                    const SizedBox(height: 16),
                    PrimaryPillButton(
                      label: 'Buat Pesanan',
                      onPressed: () async {
                        final created = await Navigator.push<bool>(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                UmkmCreateStockOrderScreen(offer: offer),
                          ),
                        );
                        if (created == true && context.mounted) {
                          Navigator.pop(context, true);
                        }
                      },
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
}

enum _MainTab { beli, pesanan }

class _SectionTabs extends StatelessWidget {
  const _SectionTabs({
    required this.active,
    required this.onChanged,
    this.leftLabel = 'Beli',
    this.rightLabel = 'Pesanan',
  });

  final Object active;
  final ValueChanged<dynamic> onChanged;
  final String leftLabel;
  final String rightLabel;

  @override
  Widget build(BuildContext context) {
    final isBeli = active is _MainTab
        ? active == _MainTab.beli
        : active == UmkmStockOrderStatus.diproses;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => onChanged(
                active is _MainTab
                    ? _MainTab.beli
                    : UmkmStockOrderStatus.diproses,
              ),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 10),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isBeli
                      ? AppColors.primaryContainer
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  leftLabel,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isBeli ? AppColors.white : AppColors.subtitle,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => onChanged(
                active is _MainTab
                    ? _MainTab.pesanan
                    : UmkmStockOrderStatus.selesai,
              ),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 10),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isBeli
                      ? Colors.transparent
                      : AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  rightLabel,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isBeli ? AppColors.subtitle : AppColors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OfferCard extends StatelessWidget {
  const _OfferCard({required this.offer});

  final UmkmStockOffer offer;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: 108,
              child: Container(
                color: AppColors.surface,
                child: Image.asset(
                  offer.imagePath ?? 'assets/images/durian.png',
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const _ImageFallback(),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            offer.name,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: AppColors.black,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _MiniChip(label: offer.supplierType.label),
                        _MiniChip(label: offer.traceCode),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      offer.priceLabel,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      offer.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        height: 1.4,
                        color: AppColors.placeholder,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _Bullet(text: offer.stockLabel),
                    _Bullet(text: offer.supplierName),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StockOrderCard extends StatelessWidget {
  const _StockOrderCard({required this.order});

  final UmkmStockOrder order;

  @override
  Widget build(BuildContext context) {
    final isDone = order.status == UmkmStockOrderStatus.selesai;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  order.offerName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.black,
                  ),
                ),
              ),
              _StatusBadge(label: order.status.label, isActive: !isDone),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${order.supplierType.label} • ${order.supplierName}',
            style: const TextStyle(fontSize: 12, color: AppColors.subtitle),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MiniChip(label: '${order.quantityKg} kg'),
              _MiniChip(label: order.paymentMethod.label),
              _MiniChip(label: order.traceCode),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                order.totalLabel,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
              const Spacer(),
              Text(
                isDone ? 'Selesai' : 'Diproses',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isDone ? const Color(0xFF166534) : AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class UmkmCreateStockOrderScreen extends StatefulWidget {
  const UmkmCreateStockOrderScreen({super.key, required this.offer});

  final UmkmStockOffer offer;

  @override
  State<UmkmCreateStockOrderScreen> createState() =>
      _UmkmCreateStockOrderScreenState();
}

class _UmkmCreateStockOrderScreenState
    extends State<UmkmCreateStockOrderScreen> {
  final _repo = UmkmRepository.instance;
  final _quantityCtrl = TextEditingController(text: '1');
  final _accountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  final _banks = const ['BCA', 'BNI', 'BRI', 'Mandiri', 'BTN', 'CIMB Niaga'];
  bool _isSaving = false;
  UmkmStockPaymentMethod _paymentMethod = UmkmStockPaymentMethod.cod;
  String _selectedBank = 'BCA';

  @override
  void dispose() {
    _quantityCtrl.dispose();
    _accountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  int get _quantityKg {
    final value =
        int.tryParse(_quantityCtrl.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 1;
    return value < 1 ? 1 : value;
  }

  int get _totalAmount => _quantityKg * widget.offer.pricePerKg;

  Future<void> _submit() async {
    if (_quantityKg < 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Jumlah kilogram harus lebih dari 0.')),
      );
      return;
    }

    if (_paymentMethod == UmkmStockPaymentMethod.transfer &&
        _accountCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nomor rekening wajib diisi untuk transfer.'),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    await Future.delayed(const Duration(milliseconds: 500));

    final order = UmkmStockOrder(
      id: 'SPO-${DateTime.now().millisecondsSinceEpoch}',
      offerId: widget.offer.id,
      offerName: widget.offer.name,
      supplierName: widget.offer.supplierName,
      supplierType: widget.offer.supplierType,
      traceCode: widget.offer.traceCode,
      quantityKg: _quantityKg,
      pricePerKg: widget.offer.pricePerKg,
      totalAmount: _totalAmount,
      paymentMethod: _paymentMethod,
      status: UmkmStockOrderStatus.diproses,
      createdAt: DateTime.now(),
      bankName: _paymentMethod == UmkmStockPaymentMethod.transfer
          ? _selectedBank
          : null,
      accountNumber: _paymentMethod == UmkmStockPaymentMethod.transfer
          ? _accountCtrl.text.trim()
          : null,
      note: _noteCtrl.text.trim().isEmpty
          ? 'Tidak ada catatan.'
          : _noteCtrl.text.trim(),
    );

    _repo.addStockOrder(order);
    _repo.updateStockOffer(
      widget.offer.id,
      widget.offer.copyWith(
        stockKg: (widget.offer.stockKg - _quantityKg).clamp(
          0,
          widget.offer.stockKg,
        ),
      ),
    );

    if (!mounted) return;
    setState(() => _isSaving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Pesanan stok berhasil dibuat.')),
    );
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            const AppTopBar(title: 'Buat Pesanan'),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _InfoCard(
                      title: widget.offer.name,
                      children: [
                        _DetailLine(
                          label: 'Supplier',
                          value: widget.offer.supplierName,
                        ),
                        _DetailLine(
                          label: 'Kategori',
                          value: widget.offer.supplierType.label,
                        ),
                        _DetailLine(
                          label: 'Trace Code',
                          value: widget.offer.traceCode,
                        ),
                        _DetailLine(
                          label: 'Harga',
                          value: widget.offer.priceLabel,
                        ),
                        _DetailLine(
                          label: 'Stok tersedia',
                          value: widget.offer.stockLabel,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _InfoCard(
                      title: 'Jumlah Pembelian',
                      children: [
                        Row(
                          children: [
                            _StepButton(
                              icon: Icons.remove_rounded,
                              onTap: () {
                                final next = _quantityKg - 1;
                                if (next < 1) return;
                                setState(() => _quantityCtrl.text = '$next');
                              },
                            ),
                            Expanded(
                              child: TextField(
                                controller: _quantityCtrl,
                                textAlign: TextAlign.center,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  hintText: '0',
                                ),
                                onChanged: (value) {
                                  final digits = value.replaceAll(
                                    RegExp(r'[^0-9]'),
                                    '',
                                  );
                                  if (digits.isEmpty) return;
                                  final next = int.tryParse(digits) ?? 1;
                                  if (next < 1) return;
                                  if (digits != value) {
                                    _quantityCtrl.value = TextEditingValue(
                                      text: '$next',
                                      selection: TextSelection.collapsed(
                                        offset: '$next'.length,
                                      ),
                                    );
                                  }
                                  setState(() {});
                                },
                              ),
                            ),
                            _StepButton(
                              icon: Icons.add_rounded,
                              onTap: () => setState(
                                () => _quantityCtrl.text = '${_quantityKg + 1}',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        const Center(
                          child: Text(
                            'dalam satuan KG',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.placeholder,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Center(
                          child: Text(
                            'Total estimasi ${_formatCurrency(_totalAmount)}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _InfoCard(
                      title: 'Pembayaran',
                      children: [
                        _PaymentChoice(
                          label: 'Cash on Delivery',
                          selected:
                              _paymentMethod == UmkmStockPaymentMethod.cod,
                          onTap: () => setState(
                            () => _paymentMethod = UmkmStockPaymentMethod.cod,
                          ),
                        ),
                        const SizedBox(height: 10),
                        _PaymentChoice(
                          label: 'Transfer Bank',
                          selected:
                              _paymentMethod == UmkmStockPaymentMethod.transfer,
                          onTap: () => setState(
                            () => _paymentMethod =
                                UmkmStockPaymentMethod.transfer,
                          ),
                        ),
                        if (_paymentMethod ==
                            UmkmStockPaymentMethod.transfer) ...[
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            initialValue: _selectedBank,
                            items: _banks
                                .map(
                                  (bank) => DropdownMenuItem(
                                    value: bank,
                                    child: Text(bank),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              if (value == null) return;
                              setState(() => _selectedBank = value);
                            },
                            decoration: _inputDecoration('Pilih bank'),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _accountCtrl,
                            keyboardType: TextInputType.number,
                            decoration: _inputDecoration('Nomor rekening'),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 16),
                    _InfoCard(
                      title: 'Catatan',
                      children: [
                        TextField(
                          controller: _noteCtrl,
                          maxLines: 3,
                          decoration: _inputDecoration('Catatan tambahan'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    PrimaryPillButton(
                      label: 'Buat Pesanan',
                      isLoading: _isSaving,
                      onPressed: _isSaving ? null : _submit,
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

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: AppColors.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}

class UmkmStockOrderDetailScreen extends StatefulWidget {
  const UmkmStockOrderDetailScreen({super.key, required this.order});

  final UmkmStockOrder order;

  @override
  State<UmkmStockOrderDetailScreen> createState() =>
      _UmkmStockOrderDetailScreenState();
}

class _UmkmStockOrderDetailScreenState
    extends State<UmkmStockOrderDetailScreen> {
  final _repo = UmkmRepository.instance;
  late UmkmStockOrder _order;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _order = widget.order;
  }

  Future<void> _finishOrder() async {
    setState(() => _isSaving = true);
    await Future.delayed(const Duration(milliseconds: 400));
    _order = _order.copyWith(status: UmkmStockOrderStatus.selesai);
    _repo.updateStockOrder(_order);
    _repo.addPurchase(
      UmkmPurchase(
        id: 'PUR-${DateTime.now().millisecondsSinceEpoch}',
        supplierName: _order.supplierName,
        productName: _order.offerName,
        quantity: _order.quantityKg,
        totalLabel: _order.totalLabel,
        createdAt: DateTime.now(),
        qrCodeData: _order.traceCode,
        note: '${_order.paymentMethod.label} • ${_order.supplierType.label}',
      ),
    );
    if (!mounted) return;
    setState(() => _isSaving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Pesanan stok ditandai selesai.')),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isDone = _order.status == UmkmStockOrderStatus.selesai;
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            const AppTopBar(title: 'Detail Pesanan'),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _InfoCard(
                      title: _order.offerName,
                      children: [
                        _DetailLine(
                          label: 'Supplier',
                          value: _order.supplierName,
                        ),
                        _DetailLine(
                          label: 'Kategori',
                          value: _order.supplierType.label,
                        ),
                        _DetailLine(
                          label: 'Trace Code',
                          value: _order.traceCode,
                        ),
                        _DetailLine(
                          label: 'Jumlah',
                          value: '${_order.quantityKg} kg',
                        ),
                        _DetailLine(label: 'Total', value: _order.totalLabel),
                        _DetailLine(
                          label: 'Pembayaran',
                          value: _order.paymentMethod.label,
                        ),
                        if (_order.paymentMethod ==
                            UmkmStockPaymentMethod.transfer) ...[
                          _DetailLine(
                            label: 'Bank',
                            value: _order.bankName ?? '-',
                          ),
                          _DetailLine(
                            label: 'Rekening',
                            value: _order.accountNumber ?? '-',
                          ),
                        ],
                        _DetailLine(
                          label: 'Status',
                          value: _order.status.label,
                        ),
                        _DetailLine(
                          label: 'Catatan',
                          value: _order.note ?? 'Tidak ada catatan',
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: QrPreview(data: _order.traceCode, size: 180),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (!isDone)
                      PrimaryPillButton(
                        label: 'Tandai Selesai',
                        isLoading: _isSaving,
                        onPressed: _isSaving ? null : _finishOrder,
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
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
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
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.placeholder,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.black,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
        ),
      ),
    );
  }
}

class _MiniChip extends StatelessWidget {
  const _MiniChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: AppColors.subtitle,
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label, required this.isActive});

  final String label;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isActive
            ? AppColors.primary.withValues(alpha: 0.12)
            : AppColors.subtitle.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: isActive ? AppColors.primary : AppColors.subtitle,
        ),
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Icon(icon, color: AppColors.black),
        ),
      ),
    );
  }
}

class _PaymentChoice extends StatelessWidget {
  const _PaymentChoice({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.12)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColors.primary : const Color(0xFFE5E7EB),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: selected ? AppColors.primary : AppColors.subtitle,
          ),
        ),
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  const _Bullet({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          const Icon(Icons.circle, size: 5, color: AppColors.placeholder),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, color: AppColors.subtitle),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.placeholder,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.black,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ImageFallback extends StatelessWidget {
  const _ImageFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      alignment: Alignment.center,
      child: const Icon(
        Icons.image_outlined,
        color: AppColors.placeholder,
        size: 30,
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 48),
      child: Column(
        children: [
          Icon(icon, size: 56, color: const Color(0xFFCBD5E1)),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.subtitle,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: AppColors.placeholder),
          ),
        ],
      ),
    );
  }
}

String _formatCurrency(int value) {
  final text = value.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < text.length; i++) {
    final remaining = text.length - i;
    buffer.write(text[i]);
    if (remaining > 1 && remaining % 3 == 1) {
      buffer.write('.');
    }
  }
  return buffer.toString();
}
