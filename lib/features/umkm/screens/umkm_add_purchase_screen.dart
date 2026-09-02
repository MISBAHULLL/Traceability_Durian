import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_top_bar.dart';
import '../../../shared/widgets/mobile_scanner_feedback.dart';
import '../../../shared/widgets/primary_pill_button.dart';
import '../../../shared/widgets/product_media_tile.dart';
import '../../../shared/widgets/qr_preview.dart';
import '../../collector/models/collector_delivery_receipt.dart';
import '../../collector/models/collector_shipment_batch.dart';
import '../../distributor/models/distributor_horizontal_sale.dart';
import '../../distributor/models/distributor_receipt.dart';
import '../../farmer/models/harvest_batch.dart';
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
  final _drnCtrl = TextEditingController();
  final _pglCtrl = TextEditingController();
  final _dstCtrl = TextEditingController();
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
    _drnCtrl.dispose();
    _pglCtrl.dispose();
    _dstCtrl.dispose();
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

  Future<void> _openIncomingScanner() async {
    final completed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const UmkmIncomingQrScanScreen()),
    );
    if (completed == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Stok masuk berhasil diproses.')),
      );
    }
  }

  Future<void> _openDirectFarmerBatch() async {
    final input = _drnCtrl.text.trim().toUpperCase();
    final match = RegExp(r'DRN-\d{4}-\d{6}').firstMatch(input);
    final code = match?.group(0) ?? input;
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Masukkan kode DRN terlebih dahulu.')),
      );
      return;
    }

    final batch = _repo.findFarmerBatch(code);
    if (batch == null || batch.status != BatchStatus.created) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Batch DRN tidak tersedia untuk diterima UMKM.'),
        ),
      );
      return;
    }

    _repo.recordFarmerBatchScan(code);
    final success = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => UmkmDirectFarmerReceiveScreen(batchCode: code),
      ),
    );
    if (success == true && mounted) {
      _drnCtrl.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Batch petani berhasil diterima UMKM.')),
      );
    }
  }

  Future<void> _openCollectorShipment() async {
    final input = _pglCtrl.text.trim().toUpperCase();
    final match = RegExp(r'PGL-\d{4}-\d{6}').firstMatch(input);
    final code = match?.group(0) ?? input;
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Masukkan kode PGL terlebih dahulu.')),
      );
      return;
    }

    final shipment = _repo.scanCollectorShipment(code);
    if (shipment == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('PGL tidak tersedia atau bukan tujuan UMKM ini.'),
        ),
      );
      return;
    }
    if (shipment.status == CollectorShipmentStatus.completed ||
        shipment.status == CollectorShipmentStatus.rejected) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('PGL ini sudah ${shipment.status.label}.')),
      );
      return;
    }

    final success = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => UmkmCollectorShipmentReceiveScreen(shipmentCode: code),
      ),
    );
    if (success == true && mounted) {
      _pglCtrl.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PGL pengepul berhasil diproses.')),
      );
    }
  }

  Future<void> _openDistributorSale() async {
    final input = _dstCtrl.text.trim().toUpperCase();
    final match = RegExp(
      r'JDL-DST-\d{4}-\d{6}',
      caseSensitive: false,
    ).firstMatch(input);
    final code = match?.group(0)?.toUpperCase() ?? input;
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Masukkan kode transaksi distributor terlebih dahulu.'),
        ),
      );
      return;
    }

    final sale = _repo.scanDistributorSale(code);
    if (sale == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Transaksi distributor tidak tersedia untuk diterima UMKM.',
          ),
        ),
      );
      return;
    }

    final success = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => UmkmDistributorSaleReceiveScreen(saleId: sale.id),
      ),
    );
    if (success == true && mounted) {
      _dstCtrl.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Stok distributor berhasil diproses.')),
      );
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
        _ScanEntryCard(onScan: _openIncomingScanner),
        const SizedBox(height: 14),
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
        _DirectFarmerReceiveCard(
          controller: _drnCtrl,
          title: 'Terima DRN dari Petani',
          hint: 'DRN-2026-000009',
          onSubmit: _openDirectFarmerBatch,
        ),
        const SizedBox(height: 10),
        _DirectFarmerReceiveCard(
          controller: _pglCtrl,
          title: 'Terima PGL dari Pengepul',
          hint: 'PGL-2026-000905',
          onSubmit: _openCollectorShipment,
        ),
        const SizedBox(height: 10),
        _DirectFarmerReceiveCard(
          controller: _dstCtrl,
          title: 'Terima Stok dari Distributor',
          hint: 'JDL-DST-2026-000001',
          onSubmit: _openDistributorSale,
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

class UmkmDirectFarmerReceiveScreen extends StatefulWidget {
  const UmkmDirectFarmerReceiveScreen({super.key, required this.batchCode});

  final String batchCode;

  @override
  State<UmkmDirectFarmerReceiveScreen> createState() =>
      _UmkmDirectFarmerReceiveScreenState();
}

class UmkmCollectorShipmentReceiveScreen extends StatefulWidget {
  const UmkmCollectorShipmentReceiveScreen({
    super.key,
    required this.shipmentCode,
  });

  final String shipmentCode;

  @override
  State<UmkmCollectorShipmentReceiveScreen> createState() =>
      _UmkmCollectorShipmentReceiveScreenState();
}

class UmkmIncomingQrScanScreen extends StatefulWidget {
  const UmkmIncomingQrScanScreen({super.key});

  @override
  State<UmkmIncomingQrScanScreen> createState() =>
      _UmkmIncomingQrScanScreenState();
}

class _UmkmIncomingQrScanScreenState extends State<UmkmIncomingQrScanScreen> {
  final _repo = UmkmRepository.instance;
  final _codeCtrl = TextEditingController();
  final _scannerController = MobileScannerController();
  var _isCameraMode = true;
  var _isHandlingScan = false;

  @override
  void dispose() {
    _codeCtrl.dispose();
    _scannerController.dispose();
    super.dispose();
  }

  _IncomingScanCode _extractCode(String raw) {
    final text = raw.trim();
    final drn = RegExp(
      r'DRN-\d{4}-\d{6}',
      caseSensitive: false,
    ).firstMatch(text);
    if (drn != null) {
      return _IncomingScanCode(
        kind: _IncomingScanKind.farmer,
        value: drn.group(0)!.toUpperCase(),
      );
    }

    final pgl = RegExp(
      r'(?:BATCH-)?PGL-\d{3,4}-\d{3,6}',
      caseSensitive: false,
    ).firstMatch(text);
    if (pgl != null) {
      return _IncomingScanCode(
        kind: _IncomingScanKind.collector,
        value: pgl.group(0)!.toUpperCase(),
      );
    }

    final sale = RegExp(
      r'JDL-DST-\d{4}-\d{6}',
      caseSensitive: false,
    ).firstMatch(text);
    if (sale != null) {
      return _IncomingScanCode(
        kind: _IncomingScanKind.distributor,
        value: sale.group(0)!.toUpperCase(),
      );
    }

    final upper = text.toUpperCase();
    if (upper.startsWith('DRN-')) {
      return _IncomingScanCode(kind: _IncomingScanKind.farmer, value: upper);
    }
    if (upper.startsWith('JDL-DST-')) {
      return _IncomingScanCode(
        kind: _IncomingScanKind.distributor,
        value: upper,
      );
    }
    return _IncomingScanCode(kind: _IncomingScanKind.collector, value: upper);
  }

  Future<void> _handleManualSubmit() async {
    FocusScope.of(context).unfocus();
    final code = _extractCode(_codeCtrl.text);
    if (code.value.isEmpty) {
      _showError('Masukkan atau scan kode QR stok terlebih dahulu.');
      return;
    }
    await _processCode(code);
  }

  Future<void> _handleCameraDetect(BarcodeCapture capture) async {
    if (_isHandlingScan) return;
    final rawValue = capture.barcodes
        .map((barcode) => barcode.rawValue)
        .whereType<String>()
        .firstWhere((value) => value.trim().isNotEmpty, orElse: () => '');
    if (rawValue.isEmpty) return;

    setState(() => _isHandlingScan = true);
    await _scannerController.stop();
    await _processCode(_extractCode(rawValue));
  }

  Future<void> _processCode(_IncomingScanCode code) async {
    switch (code.kind) {
      case _IncomingScanKind.farmer:
        await _openFarmerBatch(code.value);
        return;
      case _IncomingScanKind.collector:
        await _openCollectorShipment(code.value);
        return;
      case _IncomingScanKind.distributor:
        await _openDistributorSale(code.value);
        return;
    }
  }

  Future<void> _openFarmerBatch(String code) async {
    final batch = _repo.findFarmerBatch(code);
    if (batch == null || batch.status != BatchStatus.created) {
      await _restartAfterError('DRN tidak tersedia untuk diterima UMKM.');
      return;
    }

    _repo.recordFarmerBatchScan(code);
    if (!mounted) return;
    final success = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => UmkmDirectFarmerReceiveScreen(batchCode: code),
      ),
    );
    await _handleFlowResult(success);
  }

  Future<void> _openCollectorShipment(String code) async {
    final shipment = _repo.scanCollectorShipment(code);
    if (shipment == null ||
        shipment.status == CollectorShipmentStatus.completed ||
        shipment.status == CollectorShipmentStatus.rejected) {
      await _restartAfterError('PGL tidak tersedia untuk diterima UMKM.');
      return;
    }

    if (!mounted) return;
    final success = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            UmkmCollectorShipmentReceiveScreen(shipmentCode: shipment.code),
      ),
    );
    await _handleFlowResult(success);
  }

  Future<void> _openDistributorSale(String code) async {
    final sale = _repo.scanDistributorSale(code);
    if (sale == null) {
      await _restartAfterError(
        'Transaksi distributor tidak tersedia untuk diterima UMKM.',
      );
      return;
    }

    if (!mounted) return;
    final success = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => UmkmDistributorSaleReceiveScreen(saleId: sale.id),
      ),
    );
    await _handleFlowResult(success);
  }

  Future<void> _handleFlowResult(bool? success) async {
    if (!mounted) return;
    if (success == true) {
      Navigator.pop(context, true);
      return;
    }
    setState(() => _isHandlingScan = false);
    if (_isCameraMode) await _scannerController.start();
  }

  Future<void> _restartAfterError(String message) async {
    _showError(message);
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    setState(() => _isHandlingScan = false);
    if (_isCameraMode) await _scannerController.start();
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  InputDecoration _receiveInputDecoration(String hint) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            const AppTopBar(title: 'Scan QR Stok Masuk'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
                children: [
                  _InfoCard(
                    title: 'Pilih Mode',
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _ScanModeButton(
                              label: 'Kamera',
                              icon: Icons.qr_code_scanner_rounded,
                              selected: _isCameraMode,
                              onTap: () async {
                                setState(() {
                                  _isCameraMode = true;
                                  _isHandlingScan = false;
                                });
                                await _scannerController.start();
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _ScanModeButton(
                              label: 'Input Kode',
                              icon: Icons.keyboard_alt_outlined,
                              selected: !_isCameraMode,
                              onTap: () async {
                                setState(() {
                                  _isCameraMode = false;
                                  _isHandlingScan = false;
                                });
                                await _scannerController.stop();
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  if (_isCameraMode)
                    _UmkmCameraScannerBox(
                      controller: _scannerController,
                      isHandlingScan: _isHandlingScan,
                      onDetect: _handleCameraDetect,
                    )
                  else
                    _InfoCard(
                      title: 'Input Kode QR',
                      children: [
                        TextField(
                          controller: _codeCtrl,
                          textCapitalization: TextCapitalization.characters,
                          decoration: _receiveInputDecoration(
                            'DRN, PGL, atau JDL-DST',
                          ),
                          onSubmitted: (_) => _handleManualSubmit(),
                        ),
                        const SizedBox(height: 12),
                        PrimaryPillButton(
                          label: 'CEK STOK',
                          onPressed: _handleManualSubmit,
                        ),
                      ],
                    ),
                  const SizedBox(height: 16),
                  _InfoCard(
                    title: 'Kode yang Didukung',
                    children: const [
                      _DetailLine(label: 'Petani', value: 'DRN-2026-000009'),
                      _DetailLine(label: 'Pengepul', value: 'PGL-2026-000905'),
                      _DetailLine(
                        label: 'Distributor',
                        value: 'JDL-DST-2026-000001',
                      ),
                    ],
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

class _UmkmCollectorShipmentReceiveScreenState
    extends State<UmkmCollectorShipmentReceiveScreen> {
  final _repo = UmkmRepository.instance;
  final _weightCtrl = TextEditingController();
  final _fruitCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _discrepancyCtrl = TextEditingController();
  final _qualityCtrl = TextEditingController();
  final _conditions = CollectorDeliveryReceiptCondition.values;
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Berat dan jumlah aktual wajib valid.')),
      );
      return;
    }
    if (_locationCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lokasi penerimaan wajib diisi.')),
      );
      return;
    }
    if (_hasDiscrepancy(shipment) && _discrepancyCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Isi catatan untuk selisih stok.')),
      );
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Penerimaan PGL gagal disimpan.')),
      );
      return;
    }
    Navigator.pop(context, true);
  }

  Future<void> _reject(CollectorShipmentBatch shipment) async {
    final reason = _qualityCtrl.text.trim();
    if (reason.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Isi catatan sebagai alasan penolakan.')),
      );
      return;
    }
    if (_locationCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lokasi pemeriksaan wajib diisi.')),
      );
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Penolakan PGL gagal disimpan.')),
      );
      return;
    }
    Navigator.pop(context, true);
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
            const AppTopBar(title: 'Validasi PGL Pengepul'),
            Expanded(
              child: unavailable
                  ? const _EmptyState(
                      icon: Icons.inventory_2_outlined,
                      title: 'PGL tidak tersedia',
                      subtitle:
                          'PGL ini sudah diproses atau bukan tujuan UMKM.',
                    )
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
                            title: 'Validasi Stok Masuk',
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _weightCtrl,
                                      keyboardType: TextInputType.number,
                                      decoration: _receiveInputDecoration(
                                        'Berat aktual kg',
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: TextField(
                                      controller: _fruitCtrl,
                                      keyboardType: TextInputType.number,
                                      decoration: _receiveInputDecoration(
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
                                  decoration: _receiveInputDecoration(
                                    'Catatan selisih wajib diisi',
                                  ),
                                ),
                              ],
                              const SizedBox(height: 12),
                              TextField(
                                controller: _locationCtrl,
                                decoration: _receiveInputDecoration(
                                  'Lokasi penerimaan',
                                ),
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: _conditions.map((condition) {
                                  final selected = condition == _condition;
                                  return ChoiceChip(
                                    label: Text(condition.label),
                                    selected: selected,
                                    onSelected: (_) =>
                                        setState(() => _condition = condition),
                                    selectedColor: AppColors.primaryContainer
                                        .withValues(alpha: 0.18),
                                    labelStyle: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      color: selected
                                          ? AppColors.primary
                                          : AppColors.subtitle,
                                    ),
                                    side: BorderSide(
                                      color: selected
                                          ? AppColors.primaryContainer
                                          : const Color(0xFFE5E7EB),
                                    ),
                                  );
                                }).toList(),
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: _qualityCtrl,
                                maxLines: 3,
                                decoration: _receiveInputDecoration(
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

  InputDecoration _receiveInputDecoration(String hint) {
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

class UmkmDistributorSaleReceiveScreen extends StatefulWidget {
  const UmkmDistributorSaleReceiveScreen({super.key, required this.saleId});

  final String saleId;

  @override
  State<UmkmDistributorSaleReceiveScreen> createState() =>
      _UmkmDistributorSaleReceiveScreenState();
}

class _UmkmDistributorSaleReceiveScreenState
    extends State<UmkmDistributorSaleReceiveScreen> {
  final _repo = UmkmRepository.instance;
  final _weightCtrl = TextEditingController();
  final _fruitCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _discrepancyCtrl = TextEditingController();
  final _qualityCtrl = TextEditingController();
  final _conditions = DistributorReceiptCondition.values;
  var _condition = DistributorReceiptCondition.good;
  var _isSaving = false;

  DistributorHorizontalSale? get _sale =>
      _repo.findDistributorSale(widget.saleId);

  @override
  void initState() {
    super.initState();
    final sale = _sale;
    if (sale != null) {
      _weightCtrl.text = _formatNumber(sale.expectedWeightKg);
      _fruitCtrl.text = '${sale.expectedFruitCount}';
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

  bool _hasDiscrepancy(DistributorHorizontalSale sale) {
    final weight = _weight;
    final fruit = _fruit;
    if (weight == null || fruit == null) return false;
    return (weight - sale.expectedWeightKg).abs() > 0.01 ||
        fruit != sale.expectedFruitCount;
  }

  Future<void> _accept(DistributorHorizontalSale sale) async {
    final weight = _weight;
    final fruit = _fruit;
    if (weight == null || weight <= 0 || fruit == null || fruit <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Berat dan jumlah aktual wajib valid.')),
      );
      return;
    }
    if (_locationCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lokasi penerimaan wajib diisi.')),
      );
      return;
    }
    if (_hasDiscrepancy(sale) && _discrepancyCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Isi catatan untuk selisih stok.')),
      );
      return;
    }

    setState(() => _isSaving = true);
    await Future.delayed(const Duration(milliseconds: 350));
    final ok = _repo.receiveDistributorSale(
      saleId: sale.id,
      receivedWeightKg: weight,
      receivedFruitCount: fruit,
      condition: _condition,
      destinationLocation: _locationCtrl.text,
      discrepancyNote: _discrepancyCtrl.text,
      qualityNote: _qualityCtrl.text,
    );
    if (!mounted) return;
    setState(() => _isSaving = false);
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Penerimaan stok distributor gagal disimpan.'),
        ),
      );
      return;
    }
    Navigator.pop(context, true);
  }

  Future<void> _reject(DistributorHorizontalSale sale) async {
    final reason = _qualityCtrl.text.trim();
    if (reason.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Isi catatan sebagai alasan penolakan.')),
      );
      return;
    }
    if (_locationCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lokasi pemeriksaan wajib diisi.')),
      );
      return;
    }

    setState(() => _isSaving = true);
    await Future.delayed(const Duration(milliseconds: 300));
    final ok = _repo.rejectDistributorSale(
      saleId: sale.id,
      reason: reason,
      destinationLocation: _locationCtrl.text,
    );
    if (!mounted) return;
    setState(() => _isSaving = false);
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Penolakan stok distributor gagal.')),
      );
      return;
    }
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final sale = _sale;
    final unavailable =
        sale == null ||
        sale.status != DistributorHorizontalSaleStatus.initiated;

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            const AppTopBar(title: 'Validasi Stok Distributor'),
            Expanded(
              child: unavailable
                  ? const _EmptyState(
                      icon: Icons.inventory_2_outlined,
                      title: 'Transaksi tidak tersedia',
                      subtitle:
                          'Kode distributor ini sudah diproses atau belum tersedia untuk UMKM.',
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _InfoCard(
                            title: 'Ringkasan Distributor',
                            children: [
                              _DetailLine(label: 'Kode T1', value: sale.id),
                              _DetailLine(
                                label: 'Kode Stok',
                                value: sale.itemCode,
                              ),
                              _DetailLine(
                                label: 'Distributor',
                                value: sale.sellerName,
                              ),
                              _DetailLine(
                                label: 'Gudang Asal',
                                value: sale.sourceWarehouseName,
                              ),
                              _DetailLine(
                                label: 'Tujuan',
                                value: sale.destinationLocation,
                              ),
                              _DetailLine(
                                label: 'Jumlah Kirim',
                                value:
                                    '${_formatNumber(sale.expectedWeightKg)} kg / ${sale.expectedFruitCount} butir',
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _InfoCard(
                            title: 'Validasi Stok Masuk',
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _weightCtrl,
                                      keyboardType: TextInputType.number,
                                      decoration: _receiveInputDecoration(
                                        'Berat aktual kg',
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: TextField(
                                      controller: _fruitCtrl,
                                      keyboardType: TextInputType.number,
                                      decoration: _receiveInputDecoration(
                                        'Jumlah butir',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (_hasDiscrepancy(sale)) ...[
                                const SizedBox(height: 12),
                                TextField(
                                  controller: _discrepancyCtrl,
                                  maxLines: 2,
                                  decoration: _receiveInputDecoration(
                                    'Catatan selisih wajib diisi',
                                  ),
                                ),
                              ],
                              const SizedBox(height: 12),
                              TextField(
                                controller: _locationCtrl,
                                decoration: _receiveInputDecoration(
                                  'Lokasi penerimaan',
                                ),
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: _conditions.map((condition) {
                                  final selected = condition == _condition;
                                  return ChoiceChip(
                                    label: Text(condition.label),
                                    selected: selected,
                                    onSelected: (_) =>
                                        setState(() => _condition = condition),
                                    selectedColor: AppColors.primaryContainer
                                        .withValues(alpha: 0.18),
                                    labelStyle: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      color: selected
                                          ? AppColors.primary
                                          : AppColors.subtitle,
                                    ),
                                    side: BorderSide(
                                      color: selected
                                          ? AppColors.primaryContainer
                                          : const Color(0xFFE5E7EB),
                                    ),
                                  );
                                }).toList(),
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: _qualityCtrl,
                                maxLines: 3,
                                decoration: _receiveInputDecoration(
                                  'Catatan kondisi atau alasan penolakan',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          PrimaryPillButton(
                            label: 'TERIMA STOK',
                            isLoading: _isSaving,
                            onPressed: _isSaving ? null : () => _accept(sale),
                          ),
                          const SizedBox(height: 10),
                          OutlinedButton.icon(
                            onPressed: _isSaving ? null : () => _reject(sale),
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

  InputDecoration _receiveInputDecoration(String hint) {
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

class _UmkmDirectFarmerReceiveScreenState
    extends State<UmkmDirectFarmerReceiveScreen> {
  final _repo = UmkmRepository.instance;
  final _weightCtrl = TextEditingController();
  final _fruitCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  final _conditions = const ['Baik', 'Perlu sortir', 'Rusak sebagian'];
  var _condition = 'Baik';
  var _isSaving = false;

  HarvestBatch? get _batch => _repo.findFarmerBatch(widget.batchCode);

  @override
  void initState() {
    super.initState();
    final batch = _batch;
    if (batch != null) {
      _weightCtrl.text = batch.quantity.toStringAsFixed(0);
      _fruitCtrl.text = '${batch.fruitCount ?? 0}';
    }
  }

  @override
  void dispose() {
    _weightCtrl.dispose();
    _fruitCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  double? get _weight =>
      double.tryParse(_weightCtrl.text.trim().replaceAll(',', '.'));

  int? get _fruit => int.tryParse(_fruitCtrl.text.trim());

  Future<void> _accept() async {
    final weight = _weight;
    final fruit = _fruit;
    if (weight == null || weight <= 0 || fruit == null || fruit <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Berat dan jumlah aktual wajib valid.')),
      );
      return;
    }

    setState(() => _isSaving = true);
    await Future.delayed(const Duration(milliseconds: 400));
    final note = _noteCtrl.text.trim();
    final ok = _repo.receiveFarmerBatch(
      code: widget.batchCode,
      receivedWeightKg: weight,
      receivedFruitCount: fruit,
      conditionNote: note.isEmpty
          ? 'Kondisi fisik: $_condition'
          : 'Kondisi fisik: $_condition. $note',
    );
    if (!mounted) return;
    setState(() => _isSaving = false);
    if (!ok) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Validasi gagal disimpan.')));
      return;
    }
    Navigator.pop(context, true);
  }

  Future<void> _reject() async {
    final reason = _noteCtrl.text.trim();
    if (reason.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Isi catatan sebagai alasan penolakan.')),
      );
      return;
    }

    setState(() => _isSaving = true);
    await Future.delayed(const Duration(milliseconds: 300));
    final ok = _repo.rejectFarmerBatch(code: widget.batchCode, reason: reason);
    if (!mounted) return;
    setState(() => _isSaving = false);
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Penolakan gagal disimpan.')),
      );
      return;
    }
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final batch = _batch;
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            const AppTopBar(title: 'Validasi DRN Petani'),
            Expanded(
              child: batch == null || batch.status != BatchStatus.created
                  ? const _EmptyState(
                      icon: Icons.search_off_rounded,
                      title: 'Batch tidak tersedia',
                      subtitle: 'DRN ini tidak dapat diterima oleh UMKM.',
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _InfoCard(
                            title: 'Batch Petani',
                            children: [
                              _DetailLine(label: 'Kode', value: batch.code),
                              _DetailLine(
                                label: 'Varietas',
                                value: batch.variety,
                              ),
                              _DetailLine(
                                label: 'Kebun',
                                value: batch.farmName,
                              ),
                              _DetailLine(
                                label: 'Grade Awal',
                                value: 'Grade ${batch.grade}',
                              ),
                              _DetailLine(
                                label: 'Manifest',
                                value:
                                    '${batch.quantity.toStringAsFixed(0)} ${batch.unit} / ${batch.fruitCount ?? 0} butir',
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _InfoCard(
                            title: 'Hasil Pemeriksaan UMKM',
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _weightCtrl,
                                      keyboardType: TextInputType.number,
                                      decoration: _receiveInputDecoration(
                                        'Berat aktual kg',
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: TextField(
                                      controller: _fruitCtrl,
                                      keyboardType: TextInputType.number,
                                      decoration: _receiveInputDecoration(
                                        'Jumlah butir',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: _conditions.map((condition) {
                                  final selected = condition == _condition;
                                  return ChoiceChip(
                                    label: Text(condition),
                                    selected: selected,
                                    onSelected: (_) =>
                                        setState(() => _condition = condition),
                                    selectedColor: AppColors.primaryContainer
                                        .withValues(alpha: 0.18),
                                    labelStyle: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      color: selected
                                          ? AppColors.primary
                                          : AppColors.subtitle,
                                    ),
                                    side: BorderSide(
                                      color: selected
                                          ? AppColors.primaryContainer
                                          : const Color(0xFFE5E7EB),
                                    ),
                                  );
                                }).toList(),
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: _noteCtrl,
                                maxLines: 3,
                                decoration: _receiveInputDecoration(
                                  'Catatan kondisi atau alasan penolakan',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          PrimaryPillButton(
                            label: 'TERIMA STOK',
                            isLoading: _isSaving,
                            onPressed: _isSaving ? null : _accept,
                          ),
                          const SizedBox(height: 10),
                          OutlinedButton.icon(
                            onPressed: _isSaving ? null : _reject,
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

  InputDecoration _receiveInputDecoration(String hint) {
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

enum _IncomingScanKind { farmer, collector, distributor }

class _IncomingScanCode {
  const _IncomingScanCode({required this.kind, required this.value});

  final _IncomingScanKind kind;
  final String value;
}

String _formatNumber(double value) {
  if (value % 1 == 0) return value.toStringAsFixed(0);
  return value.toStringAsFixed(1);
}

class _ScanEntryCard extends StatelessWidget {
  const _ScanEntryCard({required this.onScan});

  final VoidCallback onScan;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Scan QR Stok Masuk',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: AppColors.white,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'DRN petani, PGL pengepul, atau transaksi distributor.',
                  style: TextStyle(
                    fontSize: 11,
                    height: 1.35,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFEAF7E5),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 54,
            height: 54,
            child: ElevatedButton(
              onPressed: onScan,
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.zero,
                shape: const CircleBorder(),
                backgroundColor: AppColors.white,
                foregroundColor: AppColors.primary,
                elevation: 0,
              ),
              child: const Icon(Icons.qr_code_scanner_rounded, size: 28),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScanModeButton extends StatelessWidget {
  const _ScanModeButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(44),
        backgroundColor: selected
            ? AppColors.primary.withValues(alpha: 0.10)
            : AppColors.white,
        foregroundColor: selected ? AppColors.primary : AppColors.subtitle,
        side: BorderSide(
          color: selected ? AppColors.primary : const Color(0xFFE5E7EB),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
      ),
    );
  }
}

class _UmkmCameraScannerBox extends StatelessWidget {
  const _UmkmCameraScannerBox({
    required this.controller,
    required this.isHandlingScan,
    required this.onDetect,
  });

  final MobileScannerController controller;
  final bool isHandlingScan;
  final ValueChanged<BarcodeCapture> onDetect;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          fit: StackFit.expand,
          children: [
            MobileScanner(
              controller: controller,
              onDetect: isHandlingScan ? null : onDetect,
              errorBuilder: (context, error) =>
                  MobileScannerFeedback(error: error),
              placeholderBuilder: (context) => const MobileScannerLoading(),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.75),
                  width: 3,
                ),
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                margin: const EdgeInsets.all(14),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.62),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  isHandlingScan
                      ? 'Memproses QR...'
                      : 'Arahkan kamera ke QR stok masuk',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppColors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DirectFarmerReceiveCard extends StatelessWidget {
  const _DirectFarmerReceiveCard({
    required this.controller,
    required this.title,
    required this.hint,
    required this.onSubmit,
  });

  final TextEditingController controller;
  final String title;
  final String hint;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAF7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE1E6DF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.qr_code_scanner_rounded,
                size: 18,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: AppColors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: const TextStyle(
                      fontSize: 13,
                      color: AppColors.placeholder,
                    ),
                    filled: true,
                    fillColor: AppColors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                height: 46,
                child: ElevatedButton(
                  onPressed: onSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                  ),
                  child: const Text(
                    'Validasi',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

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
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ProductMediaTile(imagePath: offer.imagePath),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    offer.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.25,
                      fontWeight: FontWeight.w800,
                      color: AppColors.black,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _MiniChip(label: offer.supplierType.label),
                      _MiniChip(label: offer.traceCode),
                    ],
                  ),
                  const SizedBox(height: 7),
                  Text(
                    offer.priceLabel,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    offer.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      height: 1.35,
                      color: AppColors.placeholder,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _OfferMetaLine(
                    icon: Icons.inventory_2_outlined,
                    text: offer.stockLabel,
                  ),
                  _OfferMetaLine(
                    icon: Icons.storefront_outlined,
                    text: offer.supplierName,
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

class _OfferMetaLine extends StatelessWidget {
  const _OfferMetaLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        children: [
          Icon(icon, size: 12, color: AppColors.placeholder),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 10,
                height: 1.25,
                color: AppColors.placeholder,
              ),
            ),
          ),
        ],
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

// ignore: unused_element
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

// ignore: unused_element
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
