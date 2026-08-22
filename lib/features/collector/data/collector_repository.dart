import 'package:flutter/foundation.dart';

import '../../../core/storage/local_storage_service.dart';
import '../../farmer/data/farmer_repository.dart';
import '../../farmer/models/harvest_batch.dart';
import '../models/collector_purchase_transaction.dart';
import '../models/collector_product.dart';
import '../models/collector_shipment_batch.dart';
import '../models/collector_stock_summary.dart';
import '../models/collector_warehouse.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CollectorRepository
// ─────────────────────────────────────────────────────────────────────────────

// [FE - State Management] Repository ini adalah satu-satunya sumber data
// (single source of truth) untuk seluruh layar pengepul pada fase FE-only.
// Menggunakan ChangeNotifier agar widget dapat rebuild secara reaktif —
// pola yang sama persis dengan FarmerRepository.
/// Repository in-memory untuk data pengepul (mock store, fase FE-only).
///
/// Mengimplementasikan [ChangeNotifier] agar widget yang bergantung padanya
/// (Beranda Pengepul) dapat rebuild secara reaktif saat data berubah.
///
/// Pada Role Permission Matrix, pengepul TIDAK membuat batch panen; data
/// produk berasal dari batch petani dan ditampilkan apa adanya. Seed data
/// di bawah mengikuti prototype "Beranda — Pengepul Durian".
class CollectorRepository extends ChangeNotifier {
  CollectorRepository._seed() {
    _loadFromLocal();
    _products = _buildSeedProducts();
    _syncDistributedSourceBatches();
    _farmerRepo.addListener(_onFarmerRepoChanged);
  }

  // [FE - State Management] Loader ini me-restore profil pengepul dari
  // SharedPreferences agar edit profil bertahan setelah aplikasi restart.
  void _loadFromLocal() {
    _currentCollectorId =
        LocalStorageService.loadString('collector_current_id') ??
        _kSeedCollectorId;

    final profileJson = LocalStorageService.loadJson('collector_profile');
    if (profileJson != null) {
      _profile = CollectorProfile.fromJson(profileJson);
    } else {
      _profile = _kSeedProfile;
    }

    final shipmentsJsonList = LocalStorageService.loadJsonList(
      'collector_shipment_batches',
    );
    if (shipmentsJsonList != null) {
      _shipmentBatches = shipmentsJsonList
          .map((e) => CollectorShipmentBatch.fromJson(e))
          .toList();
    } else {
      _shipmentBatches = _buildSeedShipmentBatches();
    }

    _shipmentCounter =
        LocalStorageService.loadInt('collector_shipment_counter') ??
        _shipmentBatches.length;

    final purchaseJsonList = LocalStorageService.loadJsonList(
      'collector_purchase_transactions',
    );
    if (purchaseJsonList != null) {
      _purchaseTransactions = purchaseJsonList
          .map((e) => CollectorPurchaseTransaction.fromJson(e))
          .toList();
    } else {
      _purchaseTransactions = [];
    }
    _purchaseTransactionCounter =
        LocalStorageService.loadInt('collector_purchase_transaction_counter') ??
        _purchaseTransactions.length;

    final warehousesJsonList = LocalStorageService.loadJsonList(
      'collector_warehouses',
    );
    if (warehousesJsonList != null) {
      _warehouses = warehousesJsonList
          .map((e) => CollectorWarehouse.fromJson(e))
          .toList();
    } else {
      _warehouses = _buildSeedWarehouses();
    }
    _warehouseCounter =
        LocalStorageService.loadInt('collector_warehouse_counter') ??
        _warehouses.length;

    final seedShipmentMigrated = _migratePrimarySeedShipment();
    final simulationShipmentsAdded = _ensureDistributorSimulationShipments();

    // [FE - State Management] Seed pengiriman baru disimpan setelah counter
    // siap agar fresh install tidak membaca late field yang belum diinisialisasi.
    if (shipmentsJsonList == null ||
        seedShipmentMigrated ||
        simulationShipmentsAdded ||
        warehousesJsonList == null) {
      _saveToLocal();
    }
  }

  // [FE - State Management] Saver ini menulis state profil pengepul ke JSON
  // lokal setiap ada mutasi identitas, lokasi, atau avatar.
  void _saveToLocal() {
    LocalStorageService.saveString('collector_current_id', _currentCollectorId);
    LocalStorageService.saveJson('collector_profile', _profile.toJson());
    LocalStorageService.saveJsonList(
      'collector_shipment_batches',
      _shipmentBatches.map((e) => e.toJson()).toList(),
    );
    LocalStorageService.saveInt('collector_shipment_counter', _shipmentCounter);
    LocalStorageService.saveJsonList(
      'collector_purchase_transactions',
      _purchaseTransactions.map((e) => e.toJson()).toList(),
    );
    LocalStorageService.saveInt(
      'collector_purchase_transaction_counter',
      _purchaseTransactionCounter,
    );
    LocalStorageService.saveJsonList(
      'collector_warehouses',
      _warehouses.map((e) => e.toJson()).toList(),
    );
    LocalStorageService.saveInt(
      'collector_warehouse_counter',
      _warehouseCounter,
    );
  }

  // [FE - State Management] Sinkronisasi ini menjaga data lama/local storage:
  // shipment yang sudah dikirim/selesai harus ikut menaikkan status batch
  // sumber petani ke IN_DISTRIBUTION agar rantai traceability tidak putus.
  void _syncDistributedSourceBatches() {
    final distributedSourceCodes = _shipmentBatches
        .where(
          (shipment) =>
              shipment.status == CollectorShipmentStatus.sent ||
              shipment.status == CollectorShipmentStatus.completed,
        )
        .expand((shipment) => shipment.sourceBatchCodes)
        .toSet();

    _farmerRepo.markBatchesInDistribution(
      sourceBatchCodes: distributedSourceCodes,
    );

    // [FE - State Management] Shipment langsung yang sudah selesai di UMKM
    // dipulihkan ke status penerimaan akhir setelah restart aplikasi.
    final receivedByUmkmCodes = _shipmentBatches
        .where(
          (shipment) =>
              shipment.status == CollectorShipmentStatus.completed &&
              shipment.destinationType == ShipmentDestinationType.umkm,
        )
        .expand((shipment) => shipment.sourceBatchCodes)
        .toSet();
    _farmerRepo.markBatchesReceivedByUmkm(
      sourceBatchCodes: receivedByUmkmCodes,
    );
  }

  // [FE - State Management] Migrasi ini memperbaiki PGL demo lama agar hanya
  // memakai source Montong yang sudah diverifikasi dan jumlahnya rekonsiliasi.
  bool _migratePrimarySeedShipment() {
    if (_currentCollectorId != _kSeedCollectorId) return false;

    final index = _shipmentBatches.indexWhere(
      (shipment) => shipment.code == 'BATCH-PGL-001',
    );
    if (index == -1) return false;

    final existing = _shipmentBatches[index];
    const expectedSources = ['DRN-2026-000103', 'DRN-2026-000110'];
    if (listEquals(existing.sourceBatchCodes, expectedSources)) return false;

    _shipmentBatches[index] = CollectorShipmentBatch(
      code: existing.code,
      collectorId: existing.collectorId,
      sourceBatchCodes: expectedSources,
      totalWeightKg: 158,
      totalFruitCount: 38,
      gradeBreakdown: const [
        CollectorStockBreakdown(
          key: 'A',
          label: 'Grade A',
          totalWeightKg: 100,
          totalFruitCount: 24,
          batchCount: 2,
        ),
        CollectorStockBreakdown(
          key: 'B',
          label: 'Grade B',
          totalWeightKg: 58,
          totalFruitCount: 14,
          batchCount: 2,
        ),
      ],
      varietyBreakdown: const [
        CollectorStockBreakdown(
          key: 'montong',
          label: 'Durian Montong',
          totalWeightKg: 158,
          totalFruitCount: 38,
          batchCount: 2,
        ),
      ],
      packagedAt: existing.packagedAt,
      status: existing.status,
      warehouseNote: existing.warehouseNote,
      sentAt: existing.sentAt,
      completedAt: existing.completedAt,
    );
    return true;
  }

  // [FE - State Management] Migrasi ini menambahkan manifest siap-scan untuk
  // testing distributor tanpa menghapus shipment lokal yang sudah dibuat user.
  bool _ensureDistributorSimulationShipments() {
    final existingCodes = _shipmentBatches.map((item) => item.code).toSet();
    final simulations = _buildDistributorSimulationShipments();
    final missing = simulations
        .where((shipment) => !existingCodes.contains(shipment.code))
        .toList();
    if (missing.isEmpty) return false;

    _shipmentBatches.addAll(missing);
    if (_shipmentCounter < _shipmentBatches.length) {
      _shipmentCounter = _shipmentBatches.length;
    }
    return true;
  }

  // ── Konstanta seed ─────────────────────────────────────────────────────────

  static const String _kSeedCollectorId = 'collector-001';

  static const CollectorProfile _kSeedProfile = CollectorProfile(
    collectorId: _kSeedCollectorId,
    fullName: 'Risqi Firdaus Setiawan',
    roleLabel: 'Pengepul Durian',
    businessName: 'Lapak Durian Jember',
    contact: '081234567890',
    email: 'pengepul@example.com',
    location: 'Desa Pakis, Kabupaten Jember',
    village: 'Pakis',
    district: 'Pakis',
    city: 'Kabupaten Jember',
    address: 'Jl. Raya Pakis No. 2',
  );

  // [FE - State Management] Seed produk mengikuti prototype: Durian Montong
  // dan Durian Bawor dengan deskripsi lengkap. Field deskriptif berasal dari
  // data panen petani (warisan, read-only bagi pengepul).
  static List<CollectorProduct> _buildSeedProducts() => [
    CollectorProduct(
      code: 'DRN-2026-000128',
      name: 'Durian Montong',
      category: ProductCategory.durianSegar,
      weightRange: '3 - 6 Kg',
      taste: 'Manis legit dan intens',
      fleshDescription:
          'Berwarna kuning keemasan, teksturnya lembut, '
          'padat, creamy, dan tebal',
      location: 'Desa Panti, Kecamatan Panti, Kabupaten Jember',
      harvestDate: DateTime(2025, 2, 21),
      treeOwner: 'Bapak Rusdi',
    ),
    CollectorProduct(
      code: 'DRN-2026-000119',
      name: 'Durian Bawor',
      category: ProductCategory.durianSegar,
      weightRange: '3 - 10 Kg',
      taste: 'Manis legit yang khas',
      fleshDescription:
          'Berwarna oranye hingga kuning keemasan, tebal, '
          'dengan tekstur creamy dan legit',
      location: 'Desa Wonomulyo, Kecamatan Wonosalam, Kabupaten Jombang',
      harvestDate: DateTime(2025, 2, 15),
      treeOwner: 'Bapak Rustam',
    ),
    CollectorProduct(
      code: 'DRN-2026-000142',
      name: 'Lempok Durian',
      category: ProductCategory.durianOlahan,
      weightRange: '250 - 500 gr',
      taste: 'Manis legit khas dodol durian',
      fleshDescription:
          'Olahan daging durian dimasak hingga kalis, '
          'bertekstur kenyal dan padat',
      location: 'Desa Sumberejo, Kecamatan Ambulu, Kabupaten Jember',
      harvestDate: DateTime(2025, 2, 10),
      treeOwner: 'Bapak Hadi',
    ),
    CollectorProduct(
      code: 'DRN-2026-000156',
      name: 'Bibit Durian Musang King',
      category: ProductCategory.bibitDurian,
      weightRange: '40 - 60 cm',
      taste: '-',
      fleshDescription:
          'Bibit hasil okulasi unggul, batang kokoh, '
          'daun hijau segar siap tanam',
      location: 'Desa Pakis, Kecamatan Panti, Kabupaten Jember',
      harvestDate: DateTime(2025, 1, 28),
      treeOwner: 'Bapak Slamet',
    ),
  ];

  /// Singleton instance — diakses dari seluruh UI pengepul.
  static final CollectorRepository instance = CollectorRepository._seed();

  // ── State internal ──────────────────────────────────────────────────────────

  late String _currentCollectorId;
  late CollectorProfile _profile;
  late List<CollectorProduct> _products;
  late List<CollectorShipmentBatch> _shipmentBatches;
  late List<CollectorPurchaseTransaction> _purchaseTransactions;
  late List<CollectorWarehouse> _warehouses;
  late int _shipmentCounter;
  late int _purchaseTransactionCounter;
  late int _warehouseCounter;
  final FarmerRepository _farmerRepo = FarmerRepository.instance;

  // ── Identitas sesi ──────────────────────────────────────────────────────────

  /// ID pengepul yang sedang login (mock).
  String get currentCollectorId => _currentCollectorId;

  /// Profil pengepul yang sedang login.
  CollectorProfile get profile => _profile;

  // ── Produk ──────────────────────────────────────────────────────────────────

  // [FE - State Management] Produk segar dibentuk dari antrean batch petani,
  // sedangkan produk olahan/bibit masih memakai seed prototype sementara.
  List<CollectorProduct> get products {
    final freshProducts = _farmerRepo.batchesForCollectorVerification
        .map(_productFromHarvestBatch)
        .toList();
    final prototypeProducts = _products
        .where((p) => p.category != ProductCategory.durianSegar)
        .toList();
    return List.unmodifiable([...freshProducts, ...prototypeProducts]);
  }

  /// Mencari satu produk berdasarkan [code].
  CollectorProduct? findProduct(String code) {
    try {
      return products.firstWhere((p) => p.code == code);
    } catch (_) {
      return null;
    }
  }

  // [FE - State Management] Stok pengepul dibentuk dari batch petani yang
  // sudah diverifikasi pengepul dan siap masuk flow distribusi berikutnya.
  List<HarvestBatch> get stockBatches => _farmerRepo.batchesForCollectorStock;

  List<CollectorWarehouse> get warehouses {
    final items = List<CollectorWarehouse>.from(_warehouses);
    items.sort((a, b) {
      if (a.isDefault != b.isDefault) return a.isDefault ? -1 : 1;
      return a.name.compareTo(b.name);
    });
    return List.unmodifiable(items);
  }

  CollectorWarehouse? get defaultWarehouse {
    if (_warehouses.isEmpty) return null;
    try {
      return _warehouses.firstWhere((warehouse) => warehouse.isDefault);
    } catch (_) {
      return _warehouses.first;
    }
  }

  CollectorWarehouse? findWarehouse(String? id) {
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

  CollectorWarehouse createWarehouse({
    required String name,
    required String location,
    String? note,
    bool setAsDefault = false,
  }) {
    final warehouse = CollectorWarehouse(
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
    _warehouses[index] = CollectorWarehouse(
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
    if (index == -1) return false;

    final isUsed = stockBatches.any((batch) => batch.warehouseId == id);
    if (isUsed || _warehouses.length <= 1) return false;

    final removed = _warehouses.removeAt(index);
    if (removed.isDefault && _warehouses.isNotEmpty) {
      _warehouses[0] = _warehouses[0].copyWith(isDefault: true);
    }
    _saveToLocal();
    notifyListeners();
    return true;
  }

  // [FE - State Management] Batch tersedia untuk agregasi mengecualikan
  // source batch yang sudah pernah masuk batch pengiriman pengepul.
  List<HarvestBatch> get availableStockBatches {
    final allocatedCodes = _allocatedSourceBatchCodes;
    return List.unmodifiable(
      stockBatches.where((batch) => !allocatedCodes.contains(batch.code)),
    );
  }

  // [FE - State Management] Daftar batch pengiriman adalah hasil agregasi
  // stok pengepul dan menjadi calon data untuk QR pengiriman ke distributor.
  List<CollectorShipmentBatch> get shipmentBatches {
    final items = _shipmentBatches
        .where((batch) => batch.collectorId == _currentCollectorId)
        .toList();
    items.sort((a, b) => b.packagedAt.compareTo(a.packagedAt));
    return List.unmodifiable(items);
  }

  // [FE - State Management] Feed lintas pengepul ini hanya untuk role
  // penerima; backend nanti menggantinya dengan query berdasarkan destination.
  List<CollectorShipmentBatch> get allShipmentBatches {
    final items = List<CollectorShipmentBatch>.from(_shipmentBatches);
    items.sort((a, b) => b.packagedAt.compareTo(a.packagedAt));
    return List.unmodifiable(items);
  }

  // [FE - State Management] Lookup ini dipakai layar QR pengiriman untuk
  // membaca batch PGL yang dipilih pengepul.
  CollectorShipmentBatch? findShipmentBatch(String code) {
    try {
      return shipmentBatches.firstWhere((shipment) => shipment.code == code);
    } catch (_) {
      return null;
    }
  }

  // [UTIL - Helper Function] Payload QR ini menjadi kontrak FE sementara
  // untuk distributor; nanti endpoint/URL diganti oleh backend.
  String shipmentQrPayload(String code) {
    return 'https://duriantrace.id/shipments/$code';
  }

  // [FE - State Management] Lookup ini mencari batch pengiriman yang memakai
  // sebuah source batch petani agar UI stok bisa menandai alokasi provenance.
  CollectorShipmentBatch? shipmentForSourceBatch(String sourceBatchCode) {
    try {
      return shipmentBatches.firstWhere(
        (shipment) => shipment.sourceBatchCodes.contains(sourceBatchCode),
      );
    } catch (_) {
      return null;
    }
  }

  Set<String> get _allocatedSourceBatchCodes {
    return _shipmentBatches
        .where((batch) => batch.collectorId == _currentCollectorId)
        .expand((batch) => batch.sourceBatchCodes)
        .toSet();
  }

  // [FE - State Management] Overview stok ini menjadi DTO mock untuk dashboard
  // gudang; nantinya bisa diganti langsung oleh response backend.
  CollectorStockOverview get stockOverview => _overviewForBatches(stockBatches);

  // [FE - State Management] Daftar transaksi T1 yang dibuat saat pengepul
  // memindai QR batch petani. Status initiated berarti menunggu T2.
  List<CollectorPurchaseTransaction> get purchaseTransactions {
    final items = _purchaseTransactions
        .where((item) => item.collectorId == _currentCollectorId)
        .toList();
    items.sort((a, b) => b.initiatedAt.compareTo(a.initiatedAt));
    return List.unmodifiable(items);
  }

  List<CollectorPurchaseTransaction> get pendingPurchaseTransactions {
    return List.unmodifiable(
      purchaseTransactions.where(
        (item) => item.status == CollectorPurchaseStatus.initiated,
      ),
    );
  }

  CollectorPurchaseTransaction? findPurchaseTransaction(String id) {
    try {
      return purchaseTransactions.firstWhere((item) => item.id == id);
    } catch (_) {
      return null;
    }
  }

  // [FE - Event Handler] Inisiasi T1 dari scan QR. Transaksi ini hanya
  // menyimpan bukti penerimaan awal/provenance, bukan harga atau pembayaran.
  CollectorPurchaseTransaction? initiatePurchaseTransaction(String batchCode) {
    final product = findProduct(batchCode);
    if (product == null || product.category != ProductCategory.durianSegar) {
      return null;
    }

    final existing = _purchaseTransactions.where((item) {
      return item.collectorId == _currentCollectorId &&
          item.batchCode == product.code &&
          item.status == CollectorPurchaseStatus.initiated;
    }).toList();
    if (existing.isNotEmpty) return existing.first;

    final transaction = CollectorPurchaseTransaction(
      id: _generatePurchaseTransactionId(),
      collectorId: _currentCollectorId,
      batchCode: product.code,
      batchName: product.name,
      originLabel: product.location,
      farmerLabel: product.treeOwner,
      initiatedAt: DateTime.now(),
      status: CollectorPurchaseStatus.initiated,
    );

    _purchaseTransactions.add(transaction);
    _farmerRepo.recordBatchQrScan(
      code: product.code,
      receiverRole: BatchReceiverRole.collector,
      actorName: _profile.businessName.isEmpty
          ? _profile.fullName
          : _profile.businessName,
      locationLabel: _profile.location,
    );
    _saveToLocal();
    notifyListeners();
    return transaction;
  }

  // [FE - Event Handler] Mutasi ini membuat batch pengiriman agregat dari
  // beberapa batch petani terverifikasi tanpa menyentuh blockchain/backend.
  CollectorShipmentBatch? createShipmentBatch({
    required List<String> sourceBatchCodes,
    required ShipmentDestinationType destinationType,
    String? destinationName,
    String? destinationLocation,
    String? warehouseNote,
  }) {
    final cleanCodes = sourceBatchCodes.toSet().toList();
    if (cleanCodes.isEmpty) return null;
    final cleanDestinationName = destinationName?.trim();
    final cleanDestinationLocation = destinationLocation?.trim();
    if (cleanDestinationName == null ||
        cleanDestinationName.isEmpty ||
        cleanDestinationLocation == null ||
        cleanDestinationLocation.isEmpty) {
      return null;
    }

    final availableByCode = {
      for (final batch in availableStockBatches) batch.code: batch,
    };
    final selectedBatches = cleanCodes
        .map((code) => availableByCode[code])
        .whereType<HarvestBatch>()
        .toList();
    if (selectedBatches.length != cleanCodes.length) return null;

    final overview = _overviewForBatches(selectedBatches);
    final shipment = CollectorShipmentBatch(
      code: _generateShipmentCode(),
      collectorId: _currentCollectorId,
      sourceBatchCodes: cleanCodes,
      totalWeightKg: overview.totalWeightKg,
      totalFruitCount: overview.totalFruitCount,
      gradeBreakdown: overview.gradeBreakdown,
      varietyBreakdown: overview.varietyBreakdown,
      packagedAt: DateTime.now(),
      status: CollectorShipmentStatus.readyToShip,
      destinationType: destinationType,
      destinationName: cleanDestinationName,
      destinationLocation: cleanDestinationLocation,
      warehouseNote: warehouseNote?.trim().isEmpty == true
          ? null
          : warehouseNote?.trim(),
    );

    _shipmentBatches.add(shipment);
    _saveToLocal();
    notifyListeners();
    return shipment;
  }

  // [FE - Event Handler] Mutasi ini mensimulasikan distributor men-scan QR
  // dan mengonfirmasi bahwa batch pengiriman mulai dibawa/diserahkan.
  bool markShipmentSent(String code) {
    final index = _shipmentBatches.indexWhere(
      (shipment) => shipment.code == code,
    );
    if (index == -1) return false;

    final existing = _shipmentBatches[index];
    if (existing.status != CollectorShipmentStatus.readyToShip) return false;

    _shipmentBatches[index] = existing.copyWith(
      status: CollectorShipmentStatus.sent,
      sentAt: DateTime.now(),
    );
    // [FE - State Management] Saat distributor mengambil shipment, source
    // batch petani ikut naik status ke IN_DISTRIBUTION sebagai kontrak FE
    // sementara sebelum mutasi ini dipindahkan ke backend/smart contract.
    _farmerRepo.markBatchesInDistribution(
      sourceBatchCodes: existing.sourceBatchCodes,
    );
    _saveToLocal();
    notifyListeners();
    return true;
  }

  // [FE - Event Handler] Mutasi ini mensimulasikan konfirmasi final dari
  // distributor bahwa batch pengiriman sudah diterima/selesai.
  bool completeShipment(String code, {String? warehouseNote}) {
    final index = _shipmentBatches.indexWhere(
      (shipment) => shipment.code == code,
    );
    if (index == -1) return false;

    final existing = _shipmentBatches[index];
    if (existing.status != CollectorShipmentStatus.sent) return false;

    _shipmentBatches[index] = existing.copyWith(
      status: CollectorShipmentStatus.completed,
      completedAt: DateTime.now(),
      warehouseNote: warehouseNote,
    );
    // [FE - State Management] Distributor mempertahankan status distribusi,
    // sedangkan konfirmasi tujuan UMKM menutup handover sebagai penerimaan.
    _farmerRepo.markBatchesInDistribution(
      sourceBatchCodes: existing.sourceBatchCodes,
    );
    if (existing.destinationType == ShipmentDestinationType.umkm) {
      _farmerRepo.markBatchesReceivedByUmkm(
        sourceBatchCodes: existing.sourceBatchCodes,
      );
    }
    _saveToLocal();
    notifyListeners();
    return true;
  }

  // [UTIL - Helper Function] Generator ini membuat kode batch pengiriman
  // monotetik agar FE mock mendekati pola ID yang nanti dibuat backend.
  String _generateShipmentCode() {
    _shipmentCounter++;
    final year = DateTime.now().year;
    final seq = _shipmentCounter.toString().padLeft(6, '0');
    return 'PGL-$year-$seq';
  }

  String _generatePurchaseTransactionId() {
    _purchaseTransactionCounter++;
    final year = DateTime.now().year;
    final seq = _purchaseTransactionCounter.toString().padLeft(6, '0');
    return 'T1-$year-$seq';
  }

  String _generateWarehouseId() {
    _warehouseCounter++;
    final seq = _warehouseCounter.toString().padLeft(4, '0');
    return 'WH-$_currentCollectorId-$seq';
  }

  void _closePurchaseTransaction({
    required String batchCode,
    required CollectorPurchaseStatus status,
    String? transactionId,
  }) {
    final index = _purchaseTransactions.indexWhere((item) {
      final matchesTransaction =
          transactionId != null && item.id == transactionId;
      final matchesBatch =
          transactionId == null &&
          item.collectorId == _currentCollectorId &&
          item.batchCode == batchCode &&
          item.status == CollectorPurchaseStatus.initiated;
      return matchesTransaction || matchesBatch;
    });
    if (index == -1) return;

    _purchaseTransactions[index] = _purchaseTransactions[index].copyWith(
      status: status,
      closedAt: DateTime.now(),
    );
  }

  // [UTIL - Helper Function] Helper ini menghitung overview dari kumpulan
  // batch tertentu, dipakai oleh dashboard stok dan pembuatan batch agregat.
  CollectorStockOverview _overviewForBatches(List<HarvestBatch> batches) {
    final gradeBuckets = <String, _MutableStockBucket>{};
    final varietyBuckets = <String, _MutableStockBucket>{};
    var totalWeightKg = 0.0;
    var totalFruitCount = 0;

    for (final batch in batches) {
      final weightKg = batch.receivedQuantity ?? batch.quantity;
      final fruitCount = batch.receivedFruitCount ?? batch.fruitCount ?? 0;
      totalWeightKg += weightKg;
      totalFruitCount += fruitCount;

      _addToBucket(
        varietyBuckets,
        key: batch.variety.toLowerCase(),
        label: batch.variety,
        weightKg: weightKg,
        fruitCount: fruitCount,
      );

      if (batch.gradeBreakdown.isEmpty) {
        final grade = batch.verifiedGrade ?? batch.grade;
        _addToBucket(
          gradeBuckets,
          key: grade.toUpperCase(),
          label: 'Grade ${grade.toUpperCase()}',
          weightKg: weightKg,
          fruitCount: fruitCount,
        );
      } else {
        for (final item in batch.gradeBreakdown.where((e) => e.hasValue)) {
          final grade = item.grade.toUpperCase();
          _addToBucket(
            gradeBuckets,
            key: grade,
            label: 'Grade $grade',
            weightKg: item.weightKg,
            fruitCount: item.fruitCount,
          );
        }
      }
    }

    return CollectorStockOverview(
      activeBatchCount: batches.length,
      totalWeightKg: totalWeightKg,
      totalFruitCount: totalFruitCount,
      gradeBreakdown: _sortedBuckets(gradeBuckets),
      varietyBreakdown: _sortedBuckets(varietyBuckets),
    );
  }

  // [UTIL - Helper Function] Helper ini mengakumulasi stok ke bucket grade
  // atau varietas agar kalkulasi dashboard tidak tersebar di widget UI.
  void _addToBucket(
    Map<String, _MutableStockBucket> buckets, {
    required String key,
    required String label,
    required double weightKg,
    required int fruitCount,
  }) {
    final normalizedKey = key.trim();
    final bucket = buckets.putIfAbsent(
      normalizedKey,
      () => _MutableStockBucket(key: normalizedKey, label: label.trim()),
    );
    bucket.totalWeightKg += weightKg;
    bucket.totalFruitCount += fruitCount;
    bucket.batchCount++;
  }

  // [UTIL - Helper Function] Sorter ini membuat output summary stabil untuk
  // UI dan calon kontrak API backend.
  List<CollectorStockBreakdown> _sortedBuckets(
    Map<String, _MutableStockBucket> buckets,
  ) {
    final values = buckets.values
        .map((bucket) => bucket.toBreakdown())
        .toList();
    values.sort((a, b) => a.label.compareTo(b.label));
    return List.unmodifiable(values);
  }

  // [FE - State Management] Riwayat pengepul menggabungkan batch yang sudah
  // diverifikasi dan ditolak untuk kebutuhan audit FE sementara.
  List<HarvestBatch> get historyBatches =>
      _farmerRepo.batchesForCollectorHistory;

  // [UTIL - Helper Function] Mapper ini mengubah HarvestBatch milik petani
  // menjadi CollectorProduct read-only untuk UI pengepul.
  CollectorProduct _productFromHarvestBatch(HarvestBatch batch) {
    final quantityText = batch.quantity % 1 == 0
        ? batch.quantity.toStringAsFixed(0)
        : batch.quantity.toStringAsFixed(2);
    final shelfText = batch.shelfLifeEstimate?.isNotEmpty == true
        ? ', estimasi simpan ${batch.shelfLifeEstimate}'
        : '';
    final maturityText = batch.maturityLevel?.isNotEmpty == true
        ? 'Kematangan ${batch.maturityLevel}'
        : 'Kematangan belum dicatat';

    return CollectorProduct(
      code: batch.code,
      name: 'Durian ${batch.variety}',
      category: ProductCategory.durianSegar,
      weightRange: '$quantityText ${batch.unit}',
      taste: 'Grade awal petani ${batch.grade}',
      fleshDescription: '$maturityText$shelfText',
      location: batch.farmName,
      harvestDate: batch.harvestDate,
      treeOwner: 'Petani Durian',
      grade: batch.grade,
      fruitCount: batch.fruitCount,
      maturityLevel: batch.maturityLevel,
      shelfLifeEstimate: batch.shelfLifeEstimate,
      storageSuggestion: batch.storageSuggestion,
    );
  }

  // [FE - State Management] Listener ini meneruskan perubahan batch petani
  // agar Beranda/Form pengepul rebuild saat ada batch baru atau terverifikasi.
  void _onFarmerRepoChanged() {
    notifyListeners();
  }

  // [FE - Event Handler] Submit verifikasi pengepul meneruskan aksi ke
  // FarmerRepository karena status batch adalah state utama rantai pasok.
  bool verifyFreshBatch({
    required String code,
    required double receivedQuantity,
    required int receivedFruitCount,
    required List<BatchGradeBreakdown> gradeBreakdown,
    String? warehouseId,
    String? verificationPhotoPath,
    String? qualityNotes,
    String? transactionId,
  }) {
    final ok = _farmerRepo.verifyBatchByCollector(
      code: code,
      receivedQuantity: receivedQuantity,
      receivedFruitCount: receivedFruitCount,
      gradeBreakdown: gradeBreakdown,
      warehouseId: warehouseId,
      verificationPhotoPath: verificationPhotoPath,
      qualityNotes: qualityNotes,
      verifiedBy: _profile.fullName,
    );
    if (!ok) return false;

    _closePurchaseTransaction(
      batchCode: code,
      transactionId: transactionId,
      status: CollectorPurchaseStatus.verified,
    );
    _saveToLocal();
    notifyListeners();
    return true;
  }

  // [FE - Event Handler] Grading lanjutan memecah stok terverifikasi menjadi
  // sub-batch grade lebih detail tanpa mengubah status kepemilikan batch.
  bool updateAdvancedGrading({
    required String code,
    required List<BatchGradeBreakdown> gradeBreakdown,
  }) {
    final ok = _farmerRepo.updateCollectorAdvancedGrading(
      code: code,
      gradeBreakdown: gradeBreakdown,
    );
    if (!ok) return false;

    notifyListeners();
    return true;
  }

  // [FE - Event Handler] Submit penolakan pengepul meneruskan alasan reject
  // ke FarmerRepository sebagai state utama rantai pasok.
  bool rejectFreshBatch({
    required String code,
    required String reason,
    String? transactionId,
  }) {
    final ok = _farmerRepo.rejectBatchByCollector(
      code: code,
      reason: reason,
      rejectedBy: _profile.fullName,
    );
    if (!ok) return false;

    _closePurchaseTransaction(
      batchCode: code,
      transactionId: transactionId,
      status: CollectorPurchaseStatus.rejected,
    );
    _saveToLocal();
    notifyListeners();
    return true;
  }

  // ── Sesi ─────────────────────────────────────────────────────────────────────

  // [FE - State Management] registerCollector menjadikan akun yang baru
  // didaftarkan sebagai pengepul aktif — mengganti profil seed dengan data
  // input registrasi sehingga Beranda/Profil menampilkan identitas user.
  /// Mendaftarkan dan mengaktifkan pengepul baru dari data form registrasi.
  CollectorProfile registerCollector({
    required String firstName,
    required String lastName,
    String phone = '',
    String email = '',
    String roleLabel = 'Pengepul Durian',
  }) {
    final id = 'collector-${DateTime.now().millisecondsSinceEpoch}';
    final fullName = '$firstName $lastName'.trim();
    final profile = CollectorProfile(
      collectorId: id,
      fullName: fullName.isEmpty ? 'Pengepul' : fullName,
      roleLabel: roleLabel,
      contact: phone.isEmpty ? '' : '+62 $phone',
      email: email.trim(),
    );

    _currentCollectorId = id;
    _profile = profile;
    _saveToLocal();
    notifyListeners();
    return profile;
  }

  // [FE - State Management] updateProfile memperbarui identitas dan lokasi
  // operasional pengepul yang dipakai di Beranda, Profil, dan aksi verifikasi.
  CollectorProfile updateProfile({
    required String fullName,
    required String contact,
    required String email,
    required String businessName,
    required String village,
    required String district,
    required String city,
    required String address,
  }) {
    final locationParts = <String>[
      if (village.trim().isNotEmpty) 'Desa ${village.trim()}',
      if (city.trim().isNotEmpty) city.trim(),
    ];
    final location = locationParts.join(', ');

    _profile = _profile.copyWith(
      fullName: fullName.trim(),
      contact: contact.trim(),
      email: email.trim(),
      businessName: businessName.trim(),
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

  // [FE - State Management] updateAvatar menyimpan path foto profil baru dan
  // notifikasi listener agar header Beranda dan drawer langsung ter-refresh.
  /// Memperbarui foto profil pengepul yang sedang login.
  void updateAvatar(String? path) {
    _profile = _profile.copyWith(avatarPath: path);
    _saveToLocal();
    notifyListeners();
  }

  // [FE - State Management] logout menyimpan state mock terakhir agar data
  // testing pengepul tetap ada setelah user keluar masuk aplikasi.
  /// Menyimpan state profil mock sebelum keluar dari sesi.
  void logout() {
    _saveToLocal();
    notifyListeners();
  }

  static List<CollectorWarehouse> _buildSeedWarehouses() {
    return [
      CollectorWarehouse(
        id: 'WH-collector-001-0001',
        name: 'Gudang Utama Pakis',
        location: 'Desa Pakis, Kecamatan Panti, Jember',
        note: 'Lokasi penerimaan utama dari petani sekitar Pakis.',
        isDefault: true,
        createdAt: DateTime(2026, 1, 1),
      ),
      CollectorWarehouse(
        id: 'WH-collector-001-0002',
        name: 'Gudang Sortir Semboro',
        location: 'Kecamatan Semboro, Jember',
        note: 'Dipakai saat volume masuk tinggi.',
        createdAt: DateTime(2026, 1, 5),
      ),
    ];
  }

  static List<CollectorShipmentBatch> _buildSeedShipmentBatches() {
    final now = DateTime.now();
    return [
      // 1 Transit shipment
      CollectorShipmentBatch(
        code: 'BATCH-PGL-001',
        collectorId: 'collector-001',
        sourceBatchCodes: const ['DRN-2026-000103', 'DRN-2026-000110'],
        totalWeightKg: 158.0,
        totalFruitCount: 38,
        gradeBreakdown: const [
          CollectorStockBreakdown(
            key: 'A',
            label: 'Grade A',
            totalWeightKg: 100.0,
            totalFruitCount: 24,
            batchCount: 2,
          ),
          CollectorStockBreakdown(
            key: 'B',
            label: 'Grade B',
            totalWeightKg: 58.0,
            totalFruitCount: 14,
            batchCount: 2,
          ),
        ],
        varietyBreakdown: const [
          CollectorStockBreakdown(
            key: 'montong',
            label: 'Durian Montong',
            totalWeightKg: 158.0,
            totalFruitCount: 38,
            batchCount: 2,
          ),
        ],
        packagedAt: now.subtract(const Duration(hours: 4)),
        sentAt: now.subtract(const Duration(hours: 3)),
        status: CollectorShipmentStatus.sent,
        warehouseNote: 'Pengiriman via truk pendingin JNE Logistics',
      ),
      // 11 Completed shipments
      for (int i = 1; i <= 11; i++)
        CollectorShipmentBatch(
          code: 'PGL-2026-${(100 + i).toString()}',
          collectorId: 'collector-001',
          sourceBatchCodes: const ['DRN-2026-000142'],
          totalWeightKg: 120.0 + (i * 12),
          totalFruitCount: 30 + i,
          gradeBreakdown: [
            CollectorStockBreakdown(
              key: 'A',
              label: 'Grade A',
              totalWeightKg: 120.0 + (i * 12),
              totalFruitCount: 30 + i,
              batchCount: 1,
            ),
          ],
          varietyBreakdown: [
            CollectorStockBreakdown(
              key: 'lempok',
              label: 'Lempok Durian',
              totalWeightKg: 120.0 + (i * 12),
              totalFruitCount: 30 + i,
              batchCount: 1,
            ),
          ],
          packagedAt: now.subtract(Duration(days: i + 1)),
          sentAt: now.subtract(Duration(days: i + 1, hours: 2)),
          completedAt: now.subtract(Duration(days: i, hours: 23)),
          status: CollectorShipmentStatus.completed,
          warehouseNote: 'Selesai diantar ke hub distributor $i',
        ),
    ];
  }

  // [FE - State Management] Seed simulasi menyediakan beberapa kondisi
  // manifest agar scan, penerimaan sesuai, dan penerimaan berselisih bisa dites.
  static List<CollectorShipmentBatch> _buildDistributorSimulationShipments() {
    final now = DateTime.now();
    return [
      CollectorShipmentBatch(
        code: 'PGL-2026-000901',
        collectorId: 'collector-demo-pakis',
        sourceBatchCodes: const ['DRN-DEMO-PAKIS-001'],
        totalWeightKg: 245,
        totalFruitCount: 67,
        gradeBreakdown: const [
          CollectorStockBreakdown(
            key: 'A',
            label: 'Grade A',
            totalWeightKg: 150,
            totalFruitCount: 40,
            batchCount: 1,
          ),
          CollectorStockBreakdown(
            key: 'B',
            label: 'Grade B',
            totalWeightKg: 95,
            totalFruitCount: 27,
            batchCount: 1,
          ),
        ],
        varietyBreakdown: const [
          CollectorStockBreakdown(
            key: 'bawor',
            label: 'Durian Bawor',
            totalWeightKg: 245,
            totalFruitCount: 67,
            batchCount: 1,
          ),
        ],
        packagedAt: now.subtract(const Duration(hours: 2)),
        status: CollectorShipmentStatus.readyToShip,
        destinationType: ShipmentDestinationType.distributor,
        warehouseNote: 'Simulasi dari Pengepul Pakis.',
      ),
      CollectorShipmentBatch(
        code: 'PGL-2026-000902',
        collectorId: 'collector-demo-semboro',
        sourceBatchCodes: const [
          'DRN-DEMO-SEMBORO-001',
          'DRN-DEMO-SEMBORO-002',
        ],
        totalWeightKg: 520,
        totalFruitCount: 136,
        gradeBreakdown: const [
          CollectorStockBreakdown(
            key: 'A',
            label: 'Grade A',
            totalWeightKg: 320,
            totalFruitCount: 82,
            batchCount: 2,
          ),
          CollectorStockBreakdown(
            key: 'B',
            label: 'Grade B',
            totalWeightKg: 200,
            totalFruitCount: 54,
            batchCount: 2,
          ),
        ],
        varietyBreakdown: const [
          CollectorStockBreakdown(
            key: 'montong',
            label: 'Durian Montong',
            totalWeightKg: 520,
            totalFruitCount: 136,
            batchCount: 2,
          ),
        ],
        packagedAt: now.subtract(const Duration(hours: 5)),
        status: CollectorShipmentStatus.readyToShip,
        destinationType: ShipmentDestinationType.distributor,
        warehouseNote: 'Simulasi muatan sedang dari Pengepul Semboro.',
      ),
      CollectorShipmentBatch(
        code: 'PGL-2026-000903',
        collectorId: 'collector-demo-banyuwangi',
        sourceBatchCodes: const [
          'DRN-DEMO-BWI-001',
          'DRN-DEMO-BWI-002',
          'DRN-DEMO-BWI-003',
        ],
        totalWeightKg: 1080,
        totalFruitCount: 281,
        gradeBreakdown: const [
          CollectorStockBreakdown(
            key: 'A',
            label: 'Grade A',
            totalWeightKg: 610,
            totalFruitCount: 156,
            batchCount: 3,
          ),
          CollectorStockBreakdown(
            key: 'B',
            label: 'Grade B',
            totalWeightKg: 470,
            totalFruitCount: 125,
            batchCount: 3,
          ),
        ],
        varietyBreakdown: const [
          CollectorStockBreakdown(
            key: 'musang-king',
            label: 'Durian Musang King',
            totalWeightKg: 640,
            totalFruitCount: 161,
            batchCount: 2,
          ),
          CollectorStockBreakdown(
            key: 'montong',
            label: 'Durian Montong',
            totalWeightKg: 440,
            totalFruitCount: 120,
            batchCount: 1,
          ),
        ],
        packagedAt: now.subtract(const Duration(hours: 8)),
        status: CollectorShipmentStatus.readyToShip,
        destinationType: ShipmentDestinationType.distributor,
        warehouseNote: 'Simulasi muatan besar dari Pengepul Banyuwangi.',
      ),
    ];
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// searchAndFilterProducts — helper murni
// ─────────────────────────────────────────────────────────────────────────────

// [UTIL - Helper Function] searchAndFilterProducts adalah fungsi murni yang
// memisahkan logika filter dari UI — mudah diuji secara independen dan
// dipakai ulang di mana pun daftar produk perlu difilter.
/// Menyaring [products] berdasarkan [category] dan [query] pencarian.
///
/// Fungsi ini **murni** (pure function): hasilnya hanya bergantung pada
/// argumen yang diberikan.
///
/// - [category]: kategori chip aktif.
/// - [query]: teks pencarian; pencocokan case-insensitive pada
///   [CollectorProduct.code] dan [CollectorProduct.name]. String kosong
///   berarti tidak ada filter teks.
///
/// Produk yang dikembalikan memenuhi **kedua** kriteria (kategori AND query).
// [UTIL - Helper Function] Bucket internal ini hanya dipakai repository untuk
// membangun DTO CollectorStockOverview dari batch stok mock.
class _MutableStockBucket {
  _MutableStockBucket({required this.key, required this.label});

  final String key;
  final String label;
  double totalWeightKg = 0;
  int totalFruitCount = 0;
  int batchCount = 0;

  CollectorStockBreakdown toBreakdown() {
    return CollectorStockBreakdown(
      key: key,
      label: label,
      totalWeightKg: totalWeightKg,
      totalFruitCount: totalFruitCount,
      batchCount: batchCount,
    );
  }
}

List<CollectorProduct> searchAndFilterProducts(
  List<CollectorProduct> products,
  ProductCategory category,
  String query,
) {
  final q = query.trim().toLowerCase();
  return products.where((p) {
    final matchCategory = p.category == category;
    final matchQuery =
        q.isEmpty ||
        p.code.toLowerCase().contains(q) ||
        p.name.toLowerCase().contains(q);
    return matchCategory && matchQuery;
  }).toList();
}
