import 'package:flutter/foundation.dart';
import '../../../core/storage/local_storage_service.dart';
import '../../collector/data/collector_repository.dart';
import '../../collector/models/collector_shipment_batch.dart';
import '../../farmer/data/farmer_repository.dart';
import '../../farmer/models/harvest_batch.dart';
import '../../traceability/data/traceability_repository.dart';
import '../../traceability/models/traceability_models.dart';
import '../models/distributor_acquisition_transaction.dart';
import '../models/distributor_audit_event.dart';
import '../models/distributor_horizontal_sale.dart';
import '../models/distributor_profile.dart';
import '../models/distributor_receipt.dart';
import '../models/distributor_rejection_receipt.dart';
import '../models/distributor_warehouse.dart';

// [FE - State Management] DistributorRepository mengelola profil distributor,
// memantau batch dari CollectorRepository, dan menyajikan metrik logistik.
class DistributorRepository extends ChangeNotifier {
  DistributorRepository._() {
    _loadFromLocal();
    // Dengarkan perubahan dari CollectorRepository agar metrik dan daftar
    // pengiriman ter-refresh secara real-time.
    CollectorRepository.instance.addListener(_onCollectorRepoChanged);
    FarmerRepository.instance.addListener(_onFarmerRepoChanged);
  }

  static final DistributorRepository instance = DistributorRepository._();

  static const String _kSeedDistributorId = 'distributor-001';
  static final DistributorProfile _kSeedProfile = const DistributorProfile(
    distributorId: _kSeedDistributorId,
    fullName: 'Andi Wijaya',
    roleLabel: 'Distributor Durian',
    businessName: 'PT. Trans Logistik Durian',
    contact: '081234567890',
    email: 'andi.wijaya@translogistik.com',
    location: 'Surabaya Hub, Jawa Timur',
    village: 'Genteng',
    district: 'Genteng',
    city: 'Surabaya',
    address: 'Jl. Pemuda No. 15, Surabaya',
  );

  late DistributorProfile _profile;
  late List<DistributorReceipt> _receipts;
  late List<DistributorRejectionReceipt> _rejectionReceipts;
  late List<DistributorAcquisitionTransaction> _acquisitionTransactions;
  late List<DistributorWarehouse> _warehouses;
  late List<DistributorWarehouseTransfer> _warehouseTransfers;
  late List<DistributorHorizontalSale> _horizontalSales;
  late List<DistributorAuditEvent> _auditEvents;
  late int _acquisitionTransactionCounter;
  late int _warehouseCounter;
  late int _warehouseTransferCounter;
  late int _horizontalSaleCounter;
  late int _auditEventCounter;
  late int _rejectionReceiptCounter;
  String _currentDistributorId = _kSeedDistributorId;

  DistributorProfile get profile => _profile;

  void _onCollectorRepoChanged() {
    notifyListeners();
  }

  void _onFarmerRepoChanged() {
    notifyListeners();
  }

  @override
  void dispose() {
    CollectorRepository.instance.removeListener(_onCollectorRepoChanged);
    FarmerRepository.instance.removeListener(_onFarmerRepoChanged);
    super.dispose();
  }

  // ── Local Storage & Session ────────────────────────────────────────────────

  void _loadFromLocal() {
    _currentDistributorId =
        LocalStorageService.loadString('distributor_current_id') ??
        _kSeedDistributorId;

    final profileJson = LocalStorageService.loadJson('distributor_profile');
    if (profileJson != null) {
      _profile = DistributorProfile.fromJson(profileJson);
    } else {
      _profile = _kSeedProfile;
    }

    final receiptJsonList = LocalStorageService.loadJsonList(
      'distributor_receipts',
    );
    _receipts =
        receiptJsonList?.map(DistributorReceipt.fromJson).toList() ?? [];

    final rejectionReceiptJsonList = LocalStorageService.loadJsonList(
      'distributor_rejection_receipts',
    );
    _rejectionReceipts =
        rejectionReceiptJsonList
            ?.map(DistributorRejectionReceipt.fromJson)
            .toList() ??
        [];
    _rejectionReceiptCounter =
        LocalStorageService.loadInt('distributor_rejection_receipt_counter') ??
        _rejectionReceipts.length;

    final acquisitionJsonList = LocalStorageService.loadJsonList(
      'distributor_acquisition_transactions',
    );
    _acquisitionTransactions =
        acquisitionJsonList
            ?.map(DistributorAcquisitionTransaction.fromJson)
            .toList() ??
        [];
    _acquisitionTransactionCounter =
        LocalStorageService.loadInt(
          'distributor_acquisition_transaction_counter',
        ) ??
        _acquisitionTransactions.length;

    final warehouseJsonList = LocalStorageService.loadJsonList(
      'distributor_warehouses',
    );
    _warehouses =
        warehouseJsonList?.map(DistributorWarehouse.fromJson).toList() ??
        _buildSeedWarehouses();
    _warehouseCounter =
        LocalStorageService.loadInt('distributor_warehouse_counter') ??
        _warehouses.length;

    final transferJsonList = LocalStorageService.loadJsonList(
      'distributor_warehouse_transfers',
    );
    _warehouseTransfers =
        transferJsonList?.map(DistributorWarehouseTransfer.fromJson).toList() ??
        [];
    _warehouseTransferCounter =
        LocalStorageService.loadInt('distributor_warehouse_transfer_counter') ??
        _warehouseTransfers.length;

    final horizontalSaleJsonList = LocalStorageService.loadJsonList(
      'distributor_horizontal_sales',
    );
    _horizontalSales =
        horizontalSaleJsonList
            ?.map(DistributorHorizontalSale.fromJson)
            .toList() ??
        [];
    _horizontalSaleCounter =
        LocalStorageService.loadInt('distributor_horizontal_sale_counter') ??
        _horizontalSales.length;

    final auditJsonList = LocalStorageService.loadJsonList(
      'distributor_audit_events',
    );
    _auditEvents =
        auditJsonList?.map(DistributorAuditEvent.fromJson).toList() ??
        _buildSeedAuditEvents();
    _auditEventCounter =
        LocalStorageService.loadInt('distributor_audit_event_counter') ??
        _auditEvents.length;

    if (warehouseJsonList == null || auditJsonList == null) {
      _saveToLocal();
    }
  }

  void _saveToLocal() {
    LocalStorageService.saveString(
      'distributor_current_id',
      _currentDistributorId,
    );
    LocalStorageService.saveJson('distributor_profile', _profile.toJson());
    LocalStorageService.saveJsonList(
      'distributor_receipts',
      _receipts.map((receipt) => receipt.toJson()).toList(),
    );
    LocalStorageService.saveJsonList(
      'distributor_rejection_receipts',
      _rejectionReceipts.map((receipt) => receipt.toJson()).toList(),
    );
    LocalStorageService.saveInt(
      'distributor_rejection_receipt_counter',
      _rejectionReceiptCounter,
    );
    LocalStorageService.saveJsonList(
      'distributor_acquisition_transactions',
      _acquisitionTransactions.map((item) => item.toJson()).toList(),
    );
    LocalStorageService.saveInt(
      'distributor_acquisition_transaction_counter',
      _acquisitionTransactionCounter,
    );
    LocalStorageService.saveJsonList(
      'distributor_warehouses',
      _warehouses.map((warehouse) => warehouse.toJson()).toList(),
    );
    LocalStorageService.saveInt(
      'distributor_warehouse_counter',
      _warehouseCounter,
    );
    LocalStorageService.saveJsonList(
      'distributor_warehouse_transfers',
      _warehouseTransfers.map((transfer) => transfer.toJson()).toList(),
    );
    LocalStorageService.saveInt(
      'distributor_warehouse_transfer_counter',
      _warehouseTransferCounter,
    );
    LocalStorageService.saveJsonList(
      'distributor_horizontal_sales',
      _horizontalSales.map((sale) => sale.toJson()).toList(),
    );
    LocalStorageService.saveInt(
      'distributor_horizontal_sale_counter',
      _horizontalSaleCounter,
    );
    LocalStorageService.saveJsonList(
      'distributor_audit_events',
      _auditEvents.map((event) => event.toJson()).toList(),
    );
    LocalStorageService.saveInt(
      'distributor_audit_event_counter',
      _auditEventCounter,
    );
  }

  /// Registrasi data distributor baru setelah mendaftar via form registrasi.
  void registerDistributor({
    required String firstName,
    required String lastName,
    required String phone,
    required String email,
  }) {
    _profile = DistributorProfile(
      distributorId: 'dist-reg-${DateTime.now().millisecondsSinceEpoch}',
      fullName: '$firstName $lastName'.trim(),
      roleLabel: 'Distributor Durian',
      contact: phone,
      email: email,
      location: 'Hub Baru, Indonesia',
    );
    _recordAudit(
      type: DistributorAuditEventType.profile,
      action: 'Registrasi distributor',
      objectCode: _profile.distributorId,
      description: 'Profil distributor ${_profile.fullName} dibuat.',
    );
    _saveToLocal();
    notifyListeners();
  }

  /// Memperbarui informasi profil distributor.
  DistributorProfile updateProfile({
    required String fullName,
    required String businessName,
    required String contact,
    required String email,
    required String village,
    required String district,
    required String city,
    required String address,
  }) {
    final location = city.isNotEmpty ? '$city, Indonesia' : '';
    _profile = _profile.copyWith(
      fullName: fullName.trim(),
      businessName: businessName.trim(),
      contact: contact.trim(),
      email: email.trim(),
      village: village.trim(),
      district: district.trim(),
      city: city.trim(),
      address: address.trim(),
      location: location,
    );
    _recordAudit(
      type: DistributorAuditEventType.profile,
      action: 'Ubah profil',
      objectCode: _profile.distributorId,
      description: 'Profil distributor diperbarui.',
      metadata: {
        'Nama': _profile.fullName,
        'Kota': _profile.city.isEmpty ? '-' : _profile.city,
      },
    );
    _saveToLocal();
    notifyListeners();
    return _profile;
  }

  /// Memperbarui foto avatar distributor.
  void updateAvatar(String? path) {
    _profile = _profile.copyWith(avatarPath: path);
    _recordAudit(
      type: DistributorAuditEventType.profile,
      action: 'Ubah foto profil',
      objectCode: _profile.distributorId,
      description: path == null
          ? 'Foto profil distributor dihapus.'
          : 'Foto profil distributor diperbarui.',
    );
    _saveToLocal();
    notifyListeners();
  }

  void logout() {
    _recordAudit(
      type: DistributorAuditEventType.session,
      action: 'Logout',
      objectCode: _profile.distributorId,
      description: '${_profile.fullName} keluar dari sesi distributor.',
    );
    _saveToLocal();
    notifyListeners();
  }

  // ── Shipments & Metrics ────────────────────────────────────────────────────

  // [FE - State Management] Daftar gudang distributor diurutkan default dulu.
  List<DistributorWarehouse> get warehouses {
    final items = List<DistributorWarehouse>.from(_warehouses);
    items.sort((a, b) {
      if (a.isDefault != b.isDefault) return a.isDefault ? -1 : 1;
      return a.name.compareTo(b.name);
    });
    return List.unmodifiable(items);
  }

  DistributorWarehouse? get defaultWarehouse {
    if (_warehouses.isEmpty) return null;
    try {
      return _warehouses.firstWhere((warehouse) => warehouse.isDefault);
    } catch (_) {
      return _warehouses.first;
    }
  }

  DistributorWarehouse? findWarehouse(String? id) {
    if (id == null || id.trim().isEmpty) return null;
    try {
      return _warehouses.firstWhere((warehouse) => warehouse.id == id);
    } catch (_) {
      return null;
    }
  }

  String warehouseLabel(String? id) {
    final warehouse = findWarehouse(id);
    return warehouse == null ? 'Gudang belum dipilih' : warehouse.name;
  }

  List<DistributorWarehouseTransfer> get warehouseTransfers {
    final items = _warehouseTransfers
        .where((item) => item.distributorId == _currentDistributorId)
        .toList();
    items.sort((a, b) => b.transferredAt.compareTo(a.transferredAt));
    return List.unmodifiable(items);
  }

  List<DistributorAuditEvent> get auditEvents {
    final items = _auditEvents
        .where((event) => event.distributorId == _currentDistributorId)
        .toList();
    items.sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
    return List.unmodifiable(items);
  }

  List<String> get auditActors {
    final actors = auditEvents.map((event) => event.actorName).toSet().toList();
    actors.sort();
    return List.unmodifiable(actors);
  }

  List<DistributorPartner> get distributorPartners => const [
    DistributorPartner(
      id: 'distributor-002',
      name: 'CV Nusantara Durian',
      city: 'Bandung',
      address: 'Jl. Soekarno Hatta No. 88, Bandung',
    ),
    DistributorPartner(
      id: 'distributor-003',
      name: 'Makassar Fruit Hub',
      city: 'Makassar',
      address: 'Pergudangan Parangloe Blok B2, Makassar',
    ),
    DistributorPartner(
      id: 'distributor-004',
      name: 'Medan Durian Sentra',
      city: 'Medan',
      address: 'Jl. Gatot Subroto No. 41, Medan',
    ),
  ];

  List<DistributorHorizontalSale> get horizontalSales {
    final items = _horizontalSales
        .where((sale) => sale.sellerDistributorId == _currentDistributorId)
        .toList();
    items.sort((a, b) => b.initiatedAt.compareTo(a.initiatedAt));
    return List.unmodifiable(items);
  }

  List<DistributorHorizontalSale> get allHorizontalSales {
    final items = List<DistributorHorizontalSale>.from(_horizontalSales);
    items.sort((a, b) => b.initiatedAt.compareTo(a.initiatedAt));
    return List.unmodifiable(items);
  }

  List<DistributorHorizontalSale> get pendingHorizontalSales {
    return List.unmodifiable(
      horizontalSales.where(
        (sale) => sale.status == DistributorHorizontalSaleStatus.initiated,
      ),
    );
  }

  DistributorHorizontalSale? findHorizontalSale(String id) {
    try {
      return horizontalSales.firstWhere((sale) => sale.id == id);
    } catch (_) {
      return null;
    }
  }

  DistributorPartner? _findDistributorPartner(String id) {
    try {
      return distributorPartners.firstWhere((partner) => partner.id == id);
    } catch (_) {
      return null;
    }
  }

  DistributorWarehouse createWarehouse({
    required String name,
    required String location,
    String? note,
    bool setAsDefault = false,
  }) {
    final warehouse = DistributorWarehouse(
      id: _generateWarehouseId(),
      name: name.trim(),
      location: location.trim(),
      note: note?.trim().isEmpty == true ? null : note?.trim(),
      isDefault: setAsDefault || _warehouses.isEmpty,
      createdAt: DateTime.now(),
    );
    if (warehouse.isDefault) {
      _warehouses = _warehouses
          .map((item) => item.copyWith(isDefault: false))
          .toList();
    }
    _warehouses.add(warehouse);
    _recordAudit(
      type: DistributorAuditEventType.warehouse,
      action: 'Tambah gudang',
      objectCode: warehouse.id,
      description: 'Gudang ${warehouse.name} ditambahkan.',
      metadata: {
        'Lokasi': warehouse.location,
        'Default': warehouse.isDefault ? 'Ya' : 'Tidak',
      },
    );
    _saveToLocal();
    notifyListeners();
    return warehouse;
  }

  bool updateWarehouse(
    String id, {
    required String name,
    required String location,
    String? note,
    bool setAsDefault = false,
  }) {
    final index = _warehouses.indexWhere((warehouse) => warehouse.id == id);
    if (index == -1) return false;

    if (setAsDefault) {
      _warehouses = _warehouses
          .map((item) => item.copyWith(isDefault: false))
          .toList();
    }
    final existing = _warehouses[index];
    _warehouses[index] = DistributorWarehouse(
      id: existing.id,
      name: name.trim(),
      location: location.trim(),
      note: note?.trim().isEmpty == true ? null : note?.trim(),
      isDefault: setAsDefault ? true : existing.isDefault,
      createdAt: existing.createdAt,
    );
    _recordAudit(
      type: DistributorAuditEventType.warehouse,
      action: 'Ubah gudang',
      objectCode: existing.id,
      description: 'Gudang ${_warehouses[index].name} diperbarui.',
      metadata: {
        'Lokasi': _warehouses[index].location,
        'Default': _warehouses[index].isDefault ? 'Ya' : 'Tidak',
      },
    );
    _saveToLocal();
    notifyListeners();
    return true;
  }

  bool deleteWarehouse(String id) {
    final index = _warehouses.indexWhere((warehouse) => warehouse.id == id);
    if (index == -1 || _warehouses.length <= 1) return false;

    final isUsed = _warehouseTransfers.any(
      (transfer) =>
          transfer.fromWarehouseId == id || transfer.toWarehouseId == id,
    );
    if (isUsed) return false;

    final removed = _warehouses.removeAt(index);
    if (removed.isDefault && _warehouses.isNotEmpty) {
      _warehouses[0] = _warehouses[0].copyWith(isDefault: true);
    }
    _recordAudit(
      type: DistributorAuditEventType.warehouse,
      action: 'Hapus gudang',
      objectCode: removed.id,
      description: 'Gudang ${removed.name} dihapus.',
      metadata: {'Lokasi': removed.location},
    );
    _saveToLocal();
    notifyListeners();
    return true;
  }

  DistributorWarehouseTransfer? createWarehouseTransfer({
    required String fromWarehouseId,
    required String toWarehouseId,
    required String itemCode,
    required double weightKg,
    required int fruitCount,
    String? note,
  }) {
    if (fromWarehouseId == toWarehouseId ||
        findWarehouse(fromWarehouseId) == null ||
        findWarehouse(toWarehouseId) == null ||
        itemCode.trim().isEmpty ||
        weightKg <= 0 ||
        fruitCount <= 0) {
      return null;
    }

    final transfer = DistributorWarehouseTransfer(
      id: _generateWarehouseTransferId(),
      distributorId: _currentDistributorId,
      fromWarehouseId: fromWarehouseId,
      toWarehouseId: toWarehouseId,
      itemCode: itemCode.trim().toUpperCase(),
      weightKg: weightKg,
      fruitCount: fruitCount,
      transferredAt: DateTime.now(),
      note: note?.trim().isEmpty == true ? null : note?.trim(),
    );
    _warehouseTransfers.add(transfer);
    final cleanNote = transfer.note?.trim();
    TraceabilityRepository.instance.recordWarehouseTransfer(
      batchCode: transfer.itemCode,
      actorId: _currentDistributorId,
      actorRole: TraceActorRole.distributor,
      actorName: _distributorActorName,
      fromLocationLabel: warehouseLabel(transfer.fromWarehouseId),
      toLocationLabel: warehouseLabel(transfer.toWarehouseId),
      quantity: transfer.weightKg,
      unit: 'kg',
      fruitCount: transfer.fruitCount,
      relatedObjectId: transfer.id,
      reason: cleanNote?.isNotEmpty == true
          ? cleanNote!
          : 'Transfer internal distributor',
    );
    _recordAudit(
      type: DistributorAuditEventType.transfer,
      action: 'Transfer gudang',
      objectCode: transfer.id,
      description:
          'Transfer internal ${transfer.itemCode} dari ${warehouseLabel(transfer.fromWarehouseId)} ke ${warehouseLabel(transfer.toWarehouseId)}.',
      metadata: {
        'Gudang asal': warehouseLabel(transfer.fromWarehouseId),
        'Gudang tujuan': warehouseLabel(transfer.toWarehouseId),
        'Berat': '${transfer.weightKg} kg',
        'Jumlah': '${transfer.fruitCount} butir',
        if (cleanNote?.isNotEmpty == true) 'Catatan': cleanNote!,
      },
    );
    _saveToLocal();
    notifyListeners();
    return transfer;
  }

  DistributorHorizontalSale? initiateHorizontalSale({
    required String buyerDistributorId,
    required String sourceWarehouseId,
    required String itemCode,
    required double expectedWeightKg,
    required int expectedFruitCount,
    required String destinationLocation,
    String? qualityNote,
  }) {
    final buyer = _findDistributorPartner(buyerDistributorId);
    final warehouse = findWarehouse(sourceWarehouseId);
    final cleanCode = itemCode.trim().toUpperCase();
    final cleanDestination = destinationLocation.trim();
    if (buyer == null ||
        warehouse == null ||
        cleanCode.isEmpty ||
        cleanDestination.isEmpty ||
        expectedWeightKg <= 0 ||
        expectedFruitCount <= 0) {
      return null;
    }

    final sale = DistributorHorizontalSale(
      id: _generateHorizontalSaleId(),
      sellerDistributorId: _currentDistributorId,
      sellerName: _profile.businessName.isEmpty
          ? _profile.fullName
          : _profile.businessName,
      buyerDistributorId: buyer.id,
      buyerName: buyer.name,
      sourceWarehouseId: warehouse.id,
      sourceWarehouseName: warehouse.name,
      destinationLocation: cleanDestination,
      itemCode: cleanCode,
      expectedWeightKg: expectedWeightKg,
      expectedFruitCount: expectedFruitCount,
      initiatedAt: DateTime.now(),
      status: DistributorHorizontalSaleStatus.initiated,
      qualityNote: qualityNote?.trim().isEmpty == true
          ? null
          : qualityNote?.trim(),
    );
    _horizontalSales.add(sale);
    _recordAudit(
      type: DistributorAuditEventType.sale,
      action: 'Buat T1 jual distributor',
      objectCode: sale.id,
      description:
          '${sale.itemCode} dijual dari ${sale.sourceWarehouseName} ke ${sale.buyerName}.',
      metadata: {
        'Pembeli': sale.buyerName,
        'Gudang asal': sale.sourceWarehouseName,
        'Tujuan': sale.destinationLocation,
        'Berat dikirim': '${sale.expectedWeightKg} kg',
        'Jumlah dikirim': '${sale.expectedFruitCount} butir',
        if (sale.qualityNote?.isNotEmpty == true)
          'Catatan mutu': sale.qualityNote!,
      },
    );
    _saveToLocal();
    notifyListeners();
    return sale;
  }

  bool verifyHorizontalSale({
    required String saleId,
    required double receivedWeightKg,
    required int receivedFruitCount,
    required DistributorReceiptCondition condition,
    String? discrepancyNote,
    String? qualityNote,
  }) {
    final index = _horizontalSales.indexWhere(
      (sale) =>
          sale.id == saleId &&
          sale.sellerDistributorId == _currentDistributorId &&
          sale.status == DistributorHorizontalSaleStatus.initiated,
    );
    if (index == -1 || receivedWeightKg <= 0 || receivedFruitCount <= 0) {
      return false;
    }

    final sale = _horizontalSales[index];
    final hasDiscrepancy =
        (receivedWeightKg - sale.expectedWeightKg).abs() > 0.01 ||
        receivedFruitCount != sale.expectedFruitCount;
    final cleanDiscrepancy = discrepancyNote?.trim();
    if (hasDiscrepancy &&
        (cleanDiscrepancy == null || cleanDiscrepancy.isEmpty)) {
      return false;
    }

    final cleanQuality = qualityNote?.trim();
    _horizontalSales[index] = sale.copyWith(
      status: DistributorHorizontalSaleStatus.verified,
      verifiedAt: DateTime.now(),
      receivedWeightKg: receivedWeightKg,
      receivedFruitCount: receivedFruitCount,
      condition: condition,
      discrepancyNote: cleanDiscrepancy?.isEmpty == true
          ? null
          : cleanDiscrepancy,
      qualityNote: cleanQuality?.isEmpty == true ? null : cleanQuality,
    );
    TraceabilityRepository.instance.recordReceiptVariance(
      batchCode: sale.itemCode,
      actorId: sale.buyerDistributorId,
      actorRole: TraceActorRole.distributor,
      actorName: sale.buyerName,
      expectedQuantity: sale.expectedWeightKg,
      receivedQuantity: receivedWeightKg,
      unit: 'kg',
      expectedFruitCount: sale.expectedFruitCount,
      receivedFruitCount: receivedFruitCount,
      conditionLabel: condition.label,
      locationLabel: sale.destinationLocation,
      relatedObjectId: sale.id,
      note: cleanDiscrepancy?.isNotEmpty == true
          ? cleanDiscrepancy
          : cleanQuality,
    );
    _recordAudit(
      type: DistributorAuditEventType.sale,
      action: 'Validasi T2 jual distributor',
      objectCode: sale.id,
      description:
          '${sale.itemCode} diterima ${sale.buyerName} di ${sale.destinationLocation}.',
      metadata: {
        'Pembeli': sale.buyerName,
        'Kondisi': condition.label,
        'Berat dikirim': '${sale.expectedWeightKg} kg',
        'Berat diterima': '$receivedWeightKg kg',
        'Selisih berat': '${receivedWeightKg - sale.expectedWeightKg} kg',
        'Jumlah dikirim': '${sale.expectedFruitCount} butir',
        'Jumlah diterima': '$receivedFruitCount butir',
        'Selisih jumlah':
            '${receivedFruitCount - sale.expectedFruitCount} butir',
        if (cleanDiscrepancy?.isNotEmpty == true)
          'Catatan selisih': cleanDiscrepancy!,
        if (cleanQuality?.isNotEmpty == true) 'Catatan mutu': cleanQuality!,
      },
    );
    _saveToLocal();
    notifyListeners();
    return true;
  }

  bool rejectHorizontalSale({required String saleId, required String note}) {
    final cleanNote = note.trim();
    final index = _horizontalSales.indexWhere(
      (sale) =>
          sale.id == saleId &&
          sale.sellerDistributorId == _currentDistributorId &&
          sale.status == DistributorHorizontalSaleStatus.initiated,
    );
    if (index == -1 || cleanNote.isEmpty) return false;

    final sale = _horizontalSales[index];
    _horizontalSales[index] = sale.copyWith(
      status: DistributorHorizontalSaleStatus.rejected,
      verifiedAt: DateTime.now(),
      rejectionNote: cleanNote,
    );
    TraceabilityRepository.instance.recordReceiptRejection(
      batchCode: sale.itemCode,
      actorId: sale.buyerDistributorId,
      actorRole: TraceActorRole.distributor,
      actorName: sale.buyerName,
      expectedQuantity: sale.expectedWeightKg,
      unit: 'kg',
      expectedFruitCount: sale.expectedFruitCount,
      locationLabel: sale.destinationLocation,
      relatedObjectId: sale.id,
      reason: cleanNote,
    );
    _recordAudit(
      type: DistributorAuditEventType.rejection,
      action: 'Tolak jual distributor',
      objectCode: sale.id,
      description: '${sale.itemCode} ke ${sale.buyerName} ditolak.',
      metadata: {
        'Pembeli': sale.buyerName,
        'Tujuan': sale.destinationLocation,
        'Berat dikirim': '${sale.expectedWeightKg} kg',
        'Jumlah dikirim': '${sale.expectedFruitCount} butir',
        'Alasan': cleanNote,
      },
    );
    _saveToLocal();
    notifyListeners();
    return true;
  }

  // [FE - State Management] Batch DRN yang masih CREATED menjadi kandidat
  // pembelian langsung distributor dari petani, mengikuti pintu T1 pengepul.
  List<HarvestBatch> get availableFarmerAcquisitionBatches =>
      FarmerRepository.instance.batchesForCollectorVerification;

  HarvestBatch? findFarmerAcquisitionBatch(String code) {
    return FarmerRepository.instance.findPublicBatch(code);
  }

  // [FE - State Management] Manifest PGL siap diambil menjadi kandidat
  // pembelian distributor dari pengepul.
  List<CollectorShipmentBatch> get availableCollectorAcquisitionShipments =>
      readyToPickShipments;

  // [FE - State Management] Riwayat T1/T2 akuisisi distributor.
  List<DistributorAcquisitionTransaction> get acquisitionTransactions {
    final items = _acquisitionTransactions
        .where((item) => item.distributorId == _currentDistributorId)
        .toList();
    items.sort((a, b) => b.initiatedAt.compareTo(a.initiatedAt));
    return List.unmodifiable(items);
  }

  List<DistributorAcquisitionTransaction> get pendingAcquisitionTransactions {
    return List.unmodifiable(
      acquisitionTransactions.where(
        (item) => item.status == DistributorAcquisitionStatus.initiated,
      ),
    );
  }

  DistributorAcquisitionTransaction? findAcquisitionTransaction(String id) {
    try {
      return acquisitionTransactions.firstWhere((item) => item.id == id);
    } catch (_) {
      return null;
    }
  }

  // [FE - Event Handler] T1 pembelian dari pengepul dibuat dari manifest PGL.
  DistributorAcquisitionTransaction? initiateCollectorAcquisition(
    String shipmentCode,
  ) {
    final shipment = findShipment(shipmentCode);
    if (shipment == null ||
        shipment.status == CollectorShipmentStatus.completed ||
        shipment.status == CollectorShipmentStatus.rejected) {
      return null;
    }

    final existing = _pendingAcquisitionFor(
      source: DistributorAcquisitionSource.collector,
      itemCode: shipment.code,
    );
    if (existing != null) {
      _recordAudit(
        type: DistributorAuditEventType.scan,
        action: 'Scan ulang akuisisi PGL',
        objectCode: existing.itemCode,
        description:
            'Manifest ${existing.itemCode} discan ulang dan diarahkan ke T1 ${existing.id}.',
        metadata: {
          'Transaksi': existing.id,
          'Status': existing.status.label,
          'Sumber': existing.source.label,
          'Supplier': existing.supplierLabel,
        },
      );
      _saveToLocal();
      notifyListeners();
      return existing;
    }

    final transaction = DistributorAcquisitionTransaction(
      id: _generateAcquisitionTransactionId(),
      distributorId: _currentDistributorId,
      source: DistributorAcquisitionSource.collector,
      itemCode: shipment.code,
      itemName: 'Manifest ${shipment.code}',
      originLabel: shipment.destinationLocation ?? 'Gudang pengepul',
      supplierLabel: shipment.collectorId,
      expectedWeightKg: shipment.totalWeightKg,
      expectedFruitCount: shipment.totalFruitCount,
      initiatedAt: DateTime.now(),
      status: DistributorAcquisitionStatus.initiated,
    );
    _acquisitionTransactions.add(transaction);
    _recordAudit(
      type: DistributorAuditEventType.scan,
      action: 'Mulai akuisisi PGL',
      objectCode: transaction.itemCode,
      description:
          'Scan/validasi awal manifest ${transaction.itemCode} dari pengepul ${transaction.supplierLabel}.',
      metadata: {
        'Transaksi': transaction.id,
        'Sumber': transaction.source.label,
        'Supplier': transaction.supplierLabel,
        'Asal': transaction.originLabel,
        'Berat dikirim': '${transaction.expectedWeightKg} kg',
        'Jumlah dikirim': '${transaction.expectedFruitCount} butir',
      },
    );
    _saveToLocal();
    notifyListeners();
    return transaction;
  }

  // [FE - Event Handler] T1 pembelian langsung dari petani dibuat dari batch
  // DRN yang masih menunggu verifikasi fisik.
  DistributorAcquisitionTransaction? initiateFarmerAcquisition(
    String batchCode,
  ) {
    final batch = FarmerRepository.instance.findPublicBatch(batchCode);
    if (batch == null || batch.status != BatchStatus.created) return null;

    final existing = _pendingAcquisitionFor(
      source: DistributorAcquisitionSource.farmer,
      itemCode: batch.code,
    );
    if (existing != null) {
      FarmerRepository.instance.recordBatchQrScan(
        code: batch.code,
        receiverRole: BatchReceiverRole.distributor,
        actorName: _distributorActorName,
        locationLabel: defaultWarehouse?.location ?? _profile.location,
      );
      _recordAudit(
        type: DistributorAuditEventType.scan,
        action: 'Scan ulang akuisisi DRN',
        objectCode: existing.itemCode,
        description:
            'Batch ${existing.itemCode} discan ulang dan diarahkan ke T1 ${existing.id}.',
        metadata: {
          'Transaksi': existing.id,
          'Status': existing.status.label,
          'Sumber': existing.source.label,
          'Supplier': existing.supplierLabel,
        },
      );
      _saveToLocal();
      notifyListeners();
      return existing;
    }

    final transaction = DistributorAcquisitionTransaction(
      id: _generateAcquisitionTransactionId(),
      distributorId: _currentDistributorId,
      source: DistributorAcquisitionSource.farmer,
      itemCode: batch.code,
      itemName: 'Durian ${batch.variety}',
      originLabel: batch.farmName,
      supplierLabel: 'Petani ${batch.farmerId}',
      expectedWeightKg: batch.quantity,
      expectedFruitCount: batch.fruitCount ?? 0,
      initiatedAt: DateTime.now(),
      status: DistributorAcquisitionStatus.initiated,
    );
    _acquisitionTransactions.add(transaction);
    FarmerRepository.instance.recordBatchQrScan(
      code: batch.code,
      receiverRole: BatchReceiverRole.distributor,
      actorName: _profile.businessName.trim().isEmpty
          ? _profile.fullName
          : _profile.businessName,
      locationLabel: defaultWarehouse?.location ?? _profile.location,
    );
    _recordAudit(
      type: DistributorAuditEventType.scan,
      action: 'Mulai akuisisi DRN',
      objectCode: transaction.itemCode,
      description:
          'Scan/validasi awal batch ${transaction.itemCode} dari ${transaction.supplierLabel}.',
      metadata: {
        'Transaksi': transaction.id,
        'Sumber': transaction.source.label,
        'Supplier': transaction.supplierLabel,
        'Kebun': transaction.originLabel,
        'Berat dikirim': '${transaction.expectedWeightKg} kg',
        'Jumlah dikirim': '${transaction.expectedFruitCount} butir',
      },
    );
    _saveToLocal();
    notifyListeners();
    return transaction;
  }

  // [FE - State Management] Distributor hanya membaca manifest yang tujuan
  // penerimanya distributor; pengiriman langsung UMKM tetap terisolasi.
  List<CollectorShipmentBatch> get allShipments => CollectorRepository
      .instance
      .allShipmentBatches
      .where(
        (shipment) =>
            shipment.destinationType == ShipmentDestinationType.distributor,
      )
      .toList();

  // [FE - State Management] Lookup ini menjadi jembatan detail distributor
  // dari kode shipment PGL ke data agregat pengepul yang sedang dipilih.
  CollectorShipmentBatch? findShipment(String code) {
    try {
      return allShipments.firstWhere((shipment) => shipment.code == code);
    } catch (_) {
      return null;
    }
  }

  // [FE - State Management] Resolver provenance ini menghubungkan batch
  // pengiriman pengepul dengan batch panen petani asal untuk detail trace.
  List<HarvestBatch> sourceBatchesForShipment(CollectorShipmentBatch shipment) {
    final farmerRepo = FarmerRepository.instance;
    return shipment.sourceBatchCodes
        .map(farmerRepo.findPublicBatch)
        .whereType<HarvestBatch>()
        .toList();
  }

  // [FE - State Management] Lookup receipt menghubungkan manifest dengan
  // hasil timbang dan inspeksi aktual yang disimpan oleh distributor.
  DistributorReceipt? receiptForShipment(String shipmentCode) {
    try {
      return _receipts.firstWhere(
        (receipt) =>
            receipt.shipmentCode == shipmentCode &&
            receipt.distributorId == _currentDistributorId,
      );
    } catch (_) {
      return null;
    }
  }

  // [FE - State Management] Riwayat receipt menyajikan bukti penerimaan
  // distributor terbaru lebih dulu untuk tab audit aktivitas barang masuk.
  List<DistributorReceipt> get receiptHistory {
    final items = _receipts
        .where((receipt) => receipt.distributorId == _currentDistributorId)
        .toList();
    items.sort((a, b) => b.receivedAt.compareTo(a.receivedAt));
    return List.unmodifiable(items);
  }

  DistributorRejectionReceipt? rejectionReceiptForTransaction(
    String transactionId,
  ) {
    try {
      return _rejectionReceipts.firstWhere(
        (receipt) =>
            receipt.transactionId == transactionId &&
            receipt.distributorId == _currentDistributorId,
      );
    } catch (_) {
      return null;
    }
  }

  List<DistributorRejectionReceipt> get rejectionReceiptHistory {
    final items = _rejectionReceipts
        .where((receipt) => receipt.distributorId == _currentDistributorId)
        .toList();
    items.sort((a, b) => b.rejectedAt.compareTo(a.rejectedAt));
    return List.unmodifiable(items);
  }

  /// Metrik 1: Total Kirim (Transit + Tiba)
  int get totalKirim => allShipments
      .where(
        (e) =>
            e.status == CollectorShipmentStatus.sent ||
            e.status == CollectorShipmentStatus.completed,
      )
      .length;

  /// Metrik 2: Transit (Sedang Dikirim)
  int get transit => allShipments
      .where((e) => e.status == CollectorShipmentStatus.sent)
      .length;

  /// Metrik 3: Tiba (Selesai Dikirim)
  int get tiba => allShipments
      .where((e) => e.status == CollectorShipmentStatus.completed)
      .length;

  /// Daftar PGL yang sudah berstatus sent dan masih perlu receipt.
  List<CollectorShipmentBatch> get activeShipments =>
      allShipments
          .where((e) => e.status == CollectorShipmentStatus.sent)
          .toList()
        ..sort((a, b) => b.sentAt?.compareTo(a.sentAt ?? DateTime.now()) ?? 0);

  /// Daftar pengiriman yang sudah selesai (Status = Completed)
  List<CollectorShipmentBatch> get historyShipments =>
      allShipments
          .where((e) => e.status == CollectorShipmentStatus.completed)
          .toList()
        ..sort(
          (a, b) =>
              b.completedAt?.compareTo(a.completedAt ?? DateTime.now()) ?? 0,
        );

  /// Daftar pengiriman dari pengepul yang siap diambil (Status = ReadyToShip)
  List<CollectorShipmentBatch> get readyToPickShipments =>
      allShipments
          .where((e) => e.status == CollectorShipmentStatus.readyToShip)
          .toList()
        ..sort((a, b) => b.packagedAt.compareTo(a.packagedAt));

  /// Menandai shipment batch sebagai "Sent" (Handover pengiriman diambil).
  bool takeShipment(String code) {
    try {
      final success = CollectorRepository.instance.markShipmentSent(code);
      if (success) {
        _recordAudit(
          type: DistributorAuditEventType.scan,
          action: 'Scan PGL / mulai T1',
          objectCode: code,
          description:
              'Manifest $code ditandai siap masuk receipt penerimaan distributor.',
          metadata: {
            'Status': 'Menunggu T2 penerimaan',
            'Tujuan': defaultWarehouse?.location ?? _profile.location,
          },
        );
        _saveToLocal();
        notifyListeners();
        return true;
      }
    } catch (_) {}
    return false;
  }

  // [FE - Event Handler] T2 pembelian dari pengepul memakai flow receipt
  // pengiriman yang sudah ada agar manifest PGL tetap menjadi sumber benar.
  DistributorReceipt? completeCollectorAcquisition({
    required String transactionId,
    required double receivedWeightKg,
    required int receivedFruitCount,
    required DistributorReceiptCondition condition,
    required String destinationLocation,
    String? discrepancyNote,
    String? qualityNote,
  }) {
    final transaction = findAcquisitionTransaction(transactionId);
    if (transaction == null ||
        transaction.status != DistributorAcquisitionStatus.initiated ||
        transaction.source != DistributorAcquisitionSource.collector) {
      return null;
    }

    final shipment = findShipment(transaction.itemCode);
    if (shipment == null ||
        shipment.status == CollectorShipmentStatus.completed) {
      return null;
    }

    if (shipment.status == CollectorShipmentStatus.readyToShip &&
        !takeShipment(shipment.code)) {
      return null;
    }

    final receipt = receiveShipment(
      code: shipment.code,
      receivedWeightKg: receivedWeightKg,
      receivedFruitCount: receivedFruitCount,
      condition: condition,
      destinationLocation: destinationLocation,
      discrepancyNote: discrepancyNote,
      qualityNote: qualityNote,
    );
    if (receipt == null) return null;

    _closeAcquisitionTransaction(
      transactionId: transaction.id,
      status: DistributorAcquisitionStatus.verified,
      note: qualityNote,
      destinationLocation: destinationLocation,
    );
    _recordAudit(
      type: DistributorAuditEventType.acquisition,
      action: 'Validasi penerimaan PGL',
      objectCode: transaction.itemCode,
      description:
          'Manifest ${transaction.itemCode} selesai divalidasi ke ${receipt.destinationLocation}.',
      metadata: {
        'Transaksi': transaction.id,
        'Supplier': transaction.supplierLabel,
        'Tujuan': receipt.destinationLocation,
        'Kondisi': receipt.condition.label,
        'Berat dikirim': '${receipt.expectedWeightKg} kg',
        'Berat diterima': '${receipt.receivedWeightKg} kg',
        'Selisih berat': '${receipt.weightDifferenceKg} kg',
        'Jumlah dikirim': '${receipt.expectedFruitCount} butir',
        'Jumlah diterima': '${receipt.receivedFruitCount} butir',
        'Selisih jumlah': '${receipt.fruitDifference} butir',
        if (receipt.discrepancyNote?.isNotEmpty == true)
          'Catatan selisih': receipt.discrepancyNote!,
        if (receipt.qualityNote?.isNotEmpty == true)
          'Catatan mutu': receipt.qualityNote!,
      },
    );
    _saveToLocal();
    notifyListeners();
    return receipt;
  }

  // [FE - Event Handler] T2 pembelian langsung dari petani mengikuti pola
  // verifikasi pengepul: timbang aktual, grade breakdown, dan catatan fisik.
  bool completeFarmerAcquisition({
    required String transactionId,
    required double receivedWeightKg,
    required int receivedFruitCount,
    required List<BatchGradeBreakdown> gradeBreakdown,
    required String destinationLocation,
    String? qualityNote,
  }) {
    final cleanDestination = destinationLocation.trim();
    final transaction = findAcquisitionTransaction(transactionId);
    if (transaction == null ||
        transaction.status != DistributorAcquisitionStatus.initiated ||
        transaction.source != DistributorAcquisitionSource.farmer ||
        cleanDestination.isEmpty ||
        receivedWeightKg <= 0 ||
        receivedFruitCount <= 0) {
      return false;
    }

    final batch = FarmerRepository.instance.findPublicBatch(
      transaction.itemCode,
    );
    if (batch == null || batch.status != BatchStatus.created) return false;

    final cleanBreakdown = gradeBreakdown
        .where((item) => item.hasValue)
        .toList();
    if (cleanBreakdown.isEmpty) return false;

    final totalWeight = cleanBreakdown.fold<double>(
      0,
      (sum, item) => sum + item.weightKg,
    );
    final totalFruit = cleanBreakdown.fold<int>(
      0,
      (sum, item) => sum + item.fruitCount,
    );
    if ((totalWeight - receivedWeightKg).abs() > 0.01 ||
        totalFruit != receivedFruitCount) {
      return false;
    }

    final ok = FarmerRepository.instance.verifyBatchByReceiver(
      code: batch.code,
      receiverRole: BatchReceiverRole.distributor,
      receivedQuantity: receivedWeightKg,
      receivedFruitCount: receivedFruitCount,
      gradeBreakdown: cleanBreakdown,
      warehouseId: defaultWarehouse?.id,
      qualityNotes: qualityNote,
      receiverName: _profile.businessName.trim().isEmpty
          ? _profile.fullName
          : _profile.businessName,
    );
    if (!ok) return false;

    _closeAcquisitionTransaction(
      transactionId: transaction.id,
      status: DistributorAcquisitionStatus.verified,
      note: qualityNote,
      destinationLocation: cleanDestination,
    );
    TraceabilityRepository.instance.recordReceiptVariance(
      batchCode: transaction.itemCode,
      actorId: _currentDistributorId,
      actorRole: TraceActorRole.distributor,
      actorName: _profile.businessName.trim().isEmpty
          ? _profile.fullName
          : _profile.businessName,
      expectedQuantity: transaction.expectedWeightKg,
      receivedQuantity: receivedWeightKg,
      unit: 'kg',
      expectedFruitCount: transaction.expectedFruitCount,
      receivedFruitCount: receivedFruitCount,
      conditionLabel: 'Divalidasi distributor',
      locationLabel: cleanDestination,
      relatedObjectId: transaction.id,
      note: qualityNote,
    );
    _recordAudit(
      type: DistributorAuditEventType.acquisition,
      action: 'Validasi penerimaan DRN',
      objectCode: transaction.itemCode,
      description:
          'Batch ${transaction.itemCode} selesai divalidasi ke $cleanDestination.',
      metadata: {
        'Transaksi': transaction.id,
        'Supplier': transaction.supplierLabel,
        'Tujuan': cleanDestination,
        'Berat dikirim': '${transaction.expectedWeightKg} kg',
        'Berat diterima': '$receivedWeightKg kg',
        'Selisih berat':
            '${receivedWeightKg - transaction.expectedWeightKg} kg',
        'Jumlah dikirim': '${transaction.expectedFruitCount} butir',
        'Jumlah diterima': '$receivedFruitCount butir',
        'Selisih jumlah':
            '${receivedFruitCount - transaction.expectedFruitCount} butir',
        if (qualityNote?.trim().isNotEmpty == true)
          'Catatan mutu': qualityNote!.trim(),
      },
    );
    _recordAudit(
      type: DistributorAuditEventType.receipt,
      action: 'Receipt DRN langsung',
      objectCode: transaction.itemCode,
      description:
          'Receipt langsung ${transaction.itemCode} dari petani dicatat di $cleanDestination.',
      metadata: {
        'Transaksi': transaction.id,
        'Sumber': transaction.source.label,
        'Supplier': transaction.supplierLabel,
        'Tujuan': cleanDestination,
        'Berat dikirim': '${transaction.expectedWeightKg} kg',
        'Berat diterima': '$receivedWeightKg kg',
        'Jumlah dikirim': '${transaction.expectedFruitCount} butir',
        'Jumlah diterima': '$receivedFruitCount butir',
      },
    );
    _saveToLocal();
    notifyListeners();
    return true;
  }

  bool rejectAcquisition({
    required String transactionId,
    required String note,
  }) {
    final cleanNote = note.trim();
    if (cleanNote.isEmpty) return false;

    final transaction = findAcquisitionTransaction(transactionId);
    if (transaction == null ||
        transaction.status != DistributorAcquisitionStatus.initiated) {
      return false;
    }

    if (transaction.source == DistributorAcquisitionSource.farmer) {
      final ok = FarmerRepository.instance.rejectBatchByReceiver(
        code: transaction.itemCode,
        reason: cleanNote,
        receiverRole: BatchReceiverRole.distributor,
        rejectedBy: _distributorActorName,
      );
      if (!ok) return false;
      TraceabilityRepository.instance.recordReceiptRejection(
        batchCode: transaction.itemCode,
        actorId: _currentDistributorId,
        actorRole: TraceActorRole.distributor,
        actorName: _distributorActorName,
        expectedQuantity: transaction.expectedWeightKg,
        unit: 'kg',
        expectedFruitCount: transaction.expectedFruitCount,
        locationLabel: defaultWarehouse?.location ?? _profile.location,
        relatedObjectId: transaction.id,
        reason: cleanNote,
      );
    } else {
      final shipment = findShipment(transaction.itemCode);
      if (shipment == null ||
          shipment.status == CollectorShipmentStatus.completed ||
          shipment.status == CollectorShipmentStatus.rejected) {
        return false;
      }
      final rejected = CollectorRepository.instance.rejectShipment(
        shipment.code,
        reason: cleanNote,
      );
      if (!rejected) return false;
      TraceabilityRepository.instance.recordReceiptRejection(
        batchCode: shipment.code,
        actorId: _currentDistributorId,
        actorRole: TraceActorRole.distributor,
        actorName: _distributorActorName,
        expectedQuantity: shipment.totalWeightKg,
        unit: 'kg',
        expectedFruitCount: shipment.totalFruitCount,
        locationLabel: defaultWarehouse?.location ?? _profile.location,
        relatedObjectId: transaction.id,
        reason: cleanNote,
      );
    }

    final rejectionLocation = defaultWarehouse?.location ?? _profile.location;
    final rejectionReceipt = DistributorRejectionReceipt(
      id: _generateRejectionReceiptId(),
      transactionId: transaction.id,
      itemCode: transaction.itemCode,
      distributorId: _currentDistributorId,
      source: transaction.source,
      supplierLabel: transaction.supplierLabel,
      expectedWeightKg: transaction.expectedWeightKg,
      expectedFruitCount: transaction.expectedFruitCount,
      rejectedAt: DateTime.now(),
      rejectedBy: _distributorActorName,
      rejectionLocation: rejectionLocation,
      reason: cleanNote,
    );
    _rejectionReceipts.add(rejectionReceipt);
    _closeAcquisitionTransaction(
      transactionId: transaction.id,
      status: DistributorAcquisitionStatus.rejected,
      note: cleanNote,
      destinationLocation: rejectionLocation,
    );
    _recordAudit(
      type: DistributorAuditEventType.rejection,
      action: 'Tolak akuisisi',
      objectCode: transaction.itemCode,
      description:
          'Receipt penolakan ${rejectionReceipt.id} dibuat untuk ${transaction.itemCode}.',
      metadata: {
        'Receipt': rejectionReceipt.id,
        'Transaksi': rejectionReceipt.transactionId,
        'Sumber': rejectionReceipt.source.label,
        'Supplier': rejectionReceipt.supplierLabel,
        'Lokasi': rejectionReceipt.rejectionLocation,
        'Berat dikirim': '${rejectionReceipt.expectedWeightKg} kg',
        'Jumlah dikirim': '${rejectionReceipt.expectedFruitCount} butir',
        'Alasan': rejectionReceipt.reason,
      },
    );
    _saveToLocal();
    notifyListeners();
    return true;
  }

  // [FE - Event Handler] Mutasi penerimaan menyimpan hasil inspeksi aktual
  // lalu menyelesaikan handover manifest dari pengepul secara konsisten.
  DistributorReceipt? receiveShipment({
    required String code,
    required double receivedWeightKg,
    required int receivedFruitCount,
    required DistributorReceiptCondition condition,
    required String destinationLocation,
    String? discrepancyNote,
    String? qualityNote,
  }) {
    final cleanDestination = destinationLocation.trim();
    final shipment = findShipment(code);
    if (shipment == null ||
        shipment.status != CollectorShipmentStatus.sent ||
        cleanDestination.isEmpty ||
        receivedWeightKg <= 0 ||
        receivedFruitCount <= 0 ||
        receiptForShipment(code) != null) {
      return null;
    }

    final weightDifference = receivedWeightKg - shipment.totalWeightKg;
    final fruitDifference = receivedFruitCount - shipment.totalFruitCount;
    final hasDiscrepancy =
        weightDifference.abs() > 0.01 || fruitDifference != 0;
    final cleanDiscrepancyNote = discrepancyNote?.trim();
    if (hasDiscrepancy &&
        (cleanDiscrepancyNote == null || cleanDiscrepancyNote.isEmpty)) {
      return null;
    }

    final cleanQualityNote = qualityNote?.trim();
    final completed = CollectorRepository.instance.completeShipment(
      code,
      warehouseNote: cleanQualityNote?.isNotEmpty == true
          ? cleanQualityNote
          : 'Diterima dan diverifikasi oleh distributor.',
    );
    if (!completed) return null;

    final receipt = DistributorReceipt(
      shipmentCode: code,
      distributorId: _currentDistributorId,
      expectedWeightKg: shipment.totalWeightKg,
      expectedFruitCount: shipment.totalFruitCount,
      receivedWeightKg: receivedWeightKg,
      receivedFruitCount: receivedFruitCount,
      condition: condition,
      receivedAt: DateTime.now(),
      destinationLocation: cleanDestination,
      discrepancyNote: cleanDiscrepancyNote?.isEmpty == true
          ? null
          : cleanDiscrepancyNote,
      qualityNote: cleanQualityNote?.isEmpty == true ? null : cleanQualityNote,
    );
    _receipts.add(receipt);
    TraceabilityRepository.instance.recordReceiptVariance(
      batchCode: shipment.code,
      actorId: _currentDistributorId,
      actorRole: TraceActorRole.distributor,
      actorName: _profile.businessName.trim().isEmpty
          ? _profile.fullName
          : _profile.businessName,
      expectedQuantity: shipment.totalWeightKg,
      receivedQuantity: receivedWeightKg,
      unit: 'kg',
      expectedFruitCount: shipment.totalFruitCount,
      receivedFruitCount: receivedFruitCount,
      conditionLabel: condition.label,
      locationLabel: cleanDestination,
      relatedObjectId: receipt.shipmentCode,
      note: cleanDiscrepancyNote?.isNotEmpty == true
          ? cleanDiscrepancyNote
          : cleanQualityNote,
    );
    _recordAudit(
      type: DistributorAuditEventType.receipt,
      action: 'Buat receipt',
      objectCode: receipt.shipmentCode,
      description:
          'Receipt ${receipt.shipmentCode} dibuat di ${receipt.destinationLocation}.',
      metadata: {
        'Tujuan': receipt.destinationLocation,
        'Kondisi': receipt.condition.label,
        'Berat dikirim': '${receipt.expectedWeightKg} kg',
        'Berat diterima': '${receipt.receivedWeightKg} kg',
        'Selisih berat': '${receipt.weightDifferenceKg} kg',
        'Jumlah dikirim': '${receipt.expectedFruitCount} butir',
        'Jumlah diterima': '${receipt.receivedFruitCount} butir',
        'Selisih jumlah': '${receipt.fruitDifference} butir',
        if (receipt.discrepancyNote?.isNotEmpty == true)
          'Catatan selisih': receipt.discrepancyNote!,
        if (receipt.qualityNote?.isNotEmpty == true)
          'Catatan mutu': receipt.qualityNote!,
      },
    );
    _saveToLocal();
    notifyListeners();
    return receipt;
  }

  DistributorAcquisitionTransaction? _pendingAcquisitionFor({
    required DistributorAcquisitionSource source,
    required String itemCode,
  }) {
    try {
      return acquisitionTransactions.firstWhere(
        (item) =>
            item.source == source &&
            item.itemCode == itemCode &&
            item.status == DistributorAcquisitionStatus.initiated,
      );
    } catch (_) {
      return null;
    }
  }

  String _generateWarehouseId() {
    _warehouseCounter++;
    final seq = _warehouseCounter.toString().padLeft(4, '0');
    return 'WH-DST-$_currentDistributorId-$seq';
  }

  String _generateRejectionReceiptId() {
    _rejectionReceiptCounter++;
    final year = DateTime.now().year;
    final seq = _rejectionReceiptCounter.toString().padLeft(6, '0');
    return 'RJT-DST-$year-$seq';
  }

  String get _distributorActorName => _profile.businessName.trim().isEmpty
      ? _profile.fullName
      : _profile.businessName;

  void _recordAudit({
    required DistributorAuditEventType type,
    required String action,
    required String objectCode,
    required String description,
    Map<String, String> metadata = const {},
    DateTime? occurredAt,
  }) {
    _auditEventCounter++;
    final seq = _auditEventCounter.toString().padLeft(6, '0');
    final event = DistributorAuditEvent(
      id: 'AUD-DST-$seq',
      distributorId: _currentDistributorId,
      actorId: _profile.distributorId,
      actorName: _profile.fullName,
      actorRole: _profile.roleLabel,
      type: type,
      action: action,
      objectCode: objectCode,
      description: description,
      occurredAt: occurredAt ?? DateTime.now(),
      metadata: metadata,
    );
    _auditEvents.add(event);
    if (_auditEvents.length > 300) {
      _auditEvents = _auditEvents.skip(_auditEvents.length - 300).toList();
    }
  }

  String _generateWarehouseTransferId() {
    _warehouseTransferCounter++;
    final year = DateTime.now().year;
    final seq = _warehouseTransferCounter.toString().padLeft(6, '0');
    return 'TRF-DST-$year-$seq';
  }

  String _generateHorizontalSaleId() {
    _horizontalSaleCounter++;
    final year = DateTime.now().year;
    final seq = _horizontalSaleCounter.toString().padLeft(6, '0');
    return 'JDL-DST-$year-$seq';
  }

  static List<DistributorWarehouse> _buildSeedWarehouses() {
    return [
      DistributorWarehouse(
        id: 'WH-DST-distributor-001-0001',
        name: 'Gudang Hub Surabaya',
        location: 'Jl. Pemuda No. 15, Surabaya',
        note: 'Gudang penerimaan utama dari pengepul Jawa Timur.',
        isDefault: true,
        createdAt: DateTime(2026, 1, 3),
      ),
      DistributorWarehouse(
        id: 'WH-DST-distributor-001-0002',
        name: 'Gudang Transit Sidoarjo',
        location: 'Kawasan Pergudangan Sidoarjo',
        note: 'Dipakai untuk pemecahan muatan lintas kota.',
        createdAt: DateTime(2026, 1, 8),
      ),
    ];
  }

  List<DistributorAuditEvent> _buildSeedAuditEvents() {
    final events = <DistributorAuditEvent>[];
    var counter = 0;

    DistributorAuditEvent event({
      required DistributorAuditEventType type,
      required String action,
      required String objectCode,
      required String description,
      required DateTime occurredAt,
      Map<String, String> metadata = const {},
    }) {
      counter++;
      return DistributorAuditEvent(
        id: 'AUD-DST-${counter.toString().padLeft(6, '0')}',
        distributorId: _currentDistributorId,
        actorId: _profile.distributorId,
        actorName: _profile.fullName,
        actorRole: _profile.roleLabel,
        type: type,
        action: action,
        objectCode: objectCode,
        description: description,
        occurredAt: occurredAt,
        metadata: metadata,
      );
    }

    for (final warehouse in _warehouses) {
      events.add(
        event(
          type: DistributorAuditEventType.warehouse,
          action: 'Seed gudang',
          objectCode: warehouse.id,
          description: 'Gudang ${warehouse.name} tersedia di data awal.',
          occurredAt: warehouse.createdAt ?? DateTime(2026, 1, 1),
          metadata: {'Lokasi': warehouse.location},
        ),
      );
    }

    for (final transfer in _warehouseTransfers) {
      events.add(
        event(
          type: DistributorAuditEventType.transfer,
          action: 'Transfer gudang',
          objectCode: transfer.id,
          description:
              'Transfer internal ${transfer.itemCode} dari ${warehouseLabel(transfer.fromWarehouseId)} ke ${warehouseLabel(transfer.toWarehouseId)}.',
          occurredAt: transfer.transferredAt,
          metadata: {
            'Gudang asal': warehouseLabel(transfer.fromWarehouseId),
            'Gudang tujuan': warehouseLabel(transfer.toWarehouseId),
            'Berat': '${transfer.weightKg} kg',
            'Jumlah': '${transfer.fruitCount} butir',
            if (transfer.note?.isNotEmpty == true) 'Catatan': transfer.note!,
          },
        ),
      );
    }

    for (final transaction in _acquisitionTransactions) {
      events.add(
        event(
          type: transaction.status == DistributorAcquisitionStatus.rejected
              ? DistributorAuditEventType.rejection
              : transaction.status == DistributorAcquisitionStatus.initiated
              ? DistributorAuditEventType.scan
              : DistributorAuditEventType.acquisition,
          action: transaction.status == DistributorAcquisitionStatus.initiated
              ? 'Mulai akuisisi ${transaction.source.label}'
              : transaction.status == DistributorAcquisitionStatus.rejected
              ? 'Tolak akuisisi'
              : 'Akuisisi ${transaction.status.label}',
          objectCode: transaction.itemCode,
          description:
              '${transaction.source.label} ${transaction.itemCode} tercatat sebagai ${transaction.status.label}.',
          occurredAt: transaction.closedAt ?? transaction.initiatedAt,
          metadata: {
            'Transaksi': transaction.id,
            'Sumber': transaction.source.label,
            'Supplier': transaction.supplierLabel,
            'Berat dikirim': '${transaction.expectedWeightKg} kg',
            'Jumlah dikirim': '${transaction.expectedFruitCount} butir',
            if (transaction.destinationLocation?.isNotEmpty == true)
              'Tujuan': transaction.destinationLocation!,
            ...transaction.note?.isNotEmpty == true
                ? {
                    transaction.status == DistributorAcquisitionStatus.rejected
                            ? 'Alasan'
                            : 'Catatan':
                        transaction.note!,
                  }
                : <String, String>{},
          },
        ),
      );
    }

    for (final sale in _horizontalSales) {
      events.add(
        event(
          type: sale.status == DistributorHorizontalSaleStatus.rejected
              ? DistributorAuditEventType.rejection
              : DistributorAuditEventType.sale,
          action: sale.status == DistributorHorizontalSaleStatus.initiated
              ? 'T1 jual distributor'
              : sale.status == DistributorHorizontalSaleStatus.rejected
              ? 'Tolak jual distributor'
              : 'Jual distributor ${sale.status.label}',
          objectCode: sale.id,
          description:
              '${sale.itemCode} dari ${sale.sourceWarehouseName} ke ${sale.buyerName}.',
          occurredAt: sale.verifiedAt ?? sale.initiatedAt,
          metadata: {
            'Pembeli': sale.buyerName,
            'Gudang asal': sale.sourceWarehouseName,
            'Tujuan': sale.destinationLocation,
            'Berat dikirim': '${sale.expectedWeightKg} kg',
            'Jumlah dikirim': '${sale.expectedFruitCount} butir',
            if (sale.receivedWeightKg != null)
              'Berat diterima': '${sale.receivedWeightKg} kg',
            if (sale.receivedFruitCount != null)
              'Jumlah diterima': '${sale.receivedFruitCount} butir',
            if (sale.condition != null) 'Kondisi': sale.condition!.label,
            if (sale.rejectionNote?.isNotEmpty == true)
              'Alasan': sale.rejectionNote!,
          },
        ),
      );
    }

    for (final receipt in _receipts) {
      events.add(
        event(
          type: DistributorAuditEventType.receipt,
          action: 'Buat receipt',
          objectCode: receipt.shipmentCode,
          description:
              'Receipt ${receipt.shipmentCode} dibuat di ${receipt.destinationLocation}.',
          occurredAt: receipt.receivedAt,
          metadata: {
            'Tujuan': receipt.destinationLocation,
            'Kondisi': receipt.condition.label,
            'Berat dikirim': '${receipt.expectedWeightKg} kg',
            'Berat diterima': '${receipt.receivedWeightKg} kg',
            'Selisih berat': '${receipt.weightDifferenceKg} kg',
            'Jumlah dikirim': '${receipt.expectedFruitCount} butir',
            'Jumlah diterima': '${receipt.receivedFruitCount} butir',
            'Selisih jumlah': '${receipt.fruitDifference} butir',
          },
        ),
      );
    }

    events.sort((a, b) => a.occurredAt.compareTo(b.occurredAt));
    return events;
  }

  String _generateAcquisitionTransactionId() {
    _acquisitionTransactionCounter++;
    final year = DateTime.now().year;
    final seq = _acquisitionTransactionCounter.toString().padLeft(6, '0');
    return 'T1-DST-$year-$seq';
  }

  void _closeAcquisitionTransaction({
    required String transactionId,
    required DistributorAcquisitionStatus status,
    String? note,
    String? destinationLocation,
  }) {
    final index = _acquisitionTransactions.indexWhere(
      (item) =>
          item.id == transactionId &&
          item.distributorId == _currentDistributorId,
    );
    if (index == -1) return;

    _acquisitionTransactions[index] = _acquisitionTransactions[index].copyWith(
      status: status,
      closedAt: DateTime.now(),
      note: note?.trim().isEmpty == true ? null : note?.trim(),
      destinationLocation: destinationLocation?.trim().isEmpty == true
          ? null
          : destinationLocation?.trim(),
    );
  }
}
