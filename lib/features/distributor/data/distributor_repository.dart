import 'package:flutter/foundation.dart';
import '../../../core/storage/local_storage_service.dart';
import '../../collector/data/collector_repository.dart';
import '../../collector/models/collector_shipment_batch.dart';
import '../../farmer/data/farmer_repository.dart';
import '../../farmer/models/harvest_batch.dart';
import '../models/distributor_acquisition_transaction.dart';
import '../models/distributor_profile.dart';
import '../models/distributor_receipt.dart';
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
  late List<DistributorAcquisitionTransaction> _acquisitionTransactions;
  late List<DistributorWarehouse> _warehouses;
  late List<DistributorWarehouseTransfer> _warehouseTransfers;
  late int _acquisitionTransactionCounter;
  late int _warehouseCounter;
  late int _warehouseTransferCounter;
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

    if (warehouseJsonList == null) {
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
    _saveToLocal();
    notifyListeners();
    return _profile;
  }

  /// Memperbarui foto avatar distributor.
  void updateAvatar(String? path) {
    _profile = _profile.copyWith(avatarPath: path);
    _saveToLocal();
    notifyListeners();
  }

  void logout() {
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
    _saveToLocal();
    notifyListeners();
    return transfer;
  }

  // [FE - State Management] Batch DRN yang masih CREATED menjadi kandidat
  // pembelian langsung distributor dari petani, mengikuti pintu T1 pengepul.
  List<HarvestBatch> get availableFarmerAcquisitionBatches =>
      FarmerRepository.instance.batchesForCollectorVerification;

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
        shipment.status == CollectorShipmentStatus.completed) {
      return null;
    }

    final existing = _pendingAcquisitionFor(
      source: DistributorAcquisitionSource.collector,
      itemCode: shipment.code,
    );
    if (existing != null) return existing;

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
    if (existing != null) return existing;

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

  /// Daftar pengiriman aktif (Status = Transit / Sent)
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
    double? temperatureCelsius,
  }) {
    final transaction = findAcquisitionTransaction(transactionId);
    if (transaction == null ||
        transaction.status != DistributorAcquisitionStatus.initiated ||
        transaction.source != DistributorAcquisitionSource.collector ||
        !_isValidReceiptTemperature(temperatureCelsius)) {
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
      temperatureCelsius: temperatureCelsius,
    );
    if (receipt == null) return null;

    _closeAcquisitionTransaction(
      transactionId: transaction.id,
      status: DistributorAcquisitionStatus.verified,
      note: qualityNote,
      destinationLocation: destinationLocation,
      temperatureCelsius: temperatureCelsius,
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
    double? temperatureCelsius,
  }) {
    final cleanDestination = destinationLocation.trim();
    final transaction = findAcquisitionTransaction(transactionId);
    if (transaction == null ||
        transaction.status != DistributorAcquisitionStatus.initiated ||
        transaction.source != DistributorAcquisitionSource.farmer ||
        cleanDestination.isEmpty ||
        !_isValidReceiptTemperature(temperatureCelsius) ||
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

    final ok = FarmerRepository.instance.verifyBatchByCollector(
      code: batch.code,
      receivedQuantity: receivedWeightKg,
      receivedFruitCount: receivedFruitCount,
      gradeBreakdown: cleanBreakdown,
      qualityNotes: qualityNote,
      verifiedBy: _profile.fullName,
    );
    if (!ok) return false;

    _closeAcquisitionTransaction(
      transactionId: transaction.id,
      status: DistributorAcquisitionStatus.verified,
      note: qualityNote,
      destinationLocation: cleanDestination,
      temperatureCelsius: temperatureCelsius,
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
      final ok = FarmerRepository.instance.rejectBatchByCollector(
        code: transaction.itemCode,
        reason: cleanNote,
        rejectedBy: _profile.fullName,
      );
      if (!ok) return false;
    }

    _closeAcquisitionTransaction(
      transactionId: transaction.id,
      status: DistributorAcquisitionStatus.rejected,
      note: cleanNote,
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
    double? temperatureCelsius,
  }) {
    final cleanDestination = destinationLocation.trim();
    final shipment = findShipment(code);
    if (shipment == null ||
        shipment.status != CollectorShipmentStatus.sent ||
        cleanDestination.isEmpty ||
        !_isValidReceiptTemperature(temperatureCelsius) ||
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
      temperatureCelsius: temperatureCelsius,
    );
    _receipts.add(receipt);
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

  bool _isValidReceiptTemperature(double? value) {
    return value == null || (value >= -30 && value <= 60);
  }

  String _generateWarehouseTransferId() {
    _warehouseTransferCounter++;
    final year = DateTime.now().year;
    final seq = _warehouseTransferCounter.toString().padLeft(6, '0');
    return 'TRF-DST-$year-$seq';
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
    double? temperatureCelsius,
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
      temperatureCelsius: temperatureCelsius,
    );
  }
}
