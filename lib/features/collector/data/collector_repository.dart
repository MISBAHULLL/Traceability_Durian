import 'package:flutter/foundation.dart';

import '../../../core/storage/local_storage_service.dart';
import '../../farmer/data/farmer_repository.dart';
import '../../farmer/models/harvest_batch.dart';
import '../../traceability/data/traceability_repository.dart';
import '../../traceability/models/traceability_models.dart';
import '../models/collector_audit_event.dart';
import '../models/collector_incoming_receipt.dart';
import '../models/collector_purchase_transaction.dart';
import '../models/collector_product.dart';
import '../models/collector_shipment_batch.dart';
import '../models/collector_stock_summary.dart';
import '../models/collector_warehouse.dart';
import '../models/collector_warehouse_transfer.dart';

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
    _ensureShipmentLineageBackfilled();
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

    final auditEventsJsonList = LocalStorageService.loadJsonList(
      'collector_audit_events',
    );
    if (auditEventsJsonList != null) {
      _auditEvents = auditEventsJsonList
          .map((e) => CollectorAuditEvent.fromJson(e))
          .toList();
    } else {
      _auditEvents = [];
    }

    final incomingReceiptsJsonList = LocalStorageService.loadJsonList(
      'collector_incoming_receipts',
    );
    if (incomingReceiptsJsonList != null) {
      _incomingReceipts = incomingReceiptsJsonList
          .map((e) => CollectorIncomingReceipt.fromJson(e))
          .toList();
    } else {
      _incomingReceipts = [];
    }

    final warehouseTransfersJsonList = LocalStorageService.loadJsonList(
      'collector_warehouse_transfers',
    );
    if (warehouseTransfersJsonList != null) {
      _warehouseTransfers = warehouseTransfersJsonList
          .map((e) => CollectorWarehouseTransfer.fromJson(e))
          .toList();
    } else {
      _warehouseTransfers = [];
    }
    _warehouseTransferCounter =
        LocalStorageService.loadInt('collector_warehouse_transfer_counter') ??
        _warehouseTransfers.length;

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
    LocalStorageService.saveJsonList(
      'collector_audit_events',
      _auditEvents.map((e) => e.toJson()).toList(),
    );
    LocalStorageService.saveJsonList(
      'collector_incoming_receipts',
      _incomingReceipts.map((e) => e.toJson()).toList(),
    );
    LocalStorageService.saveJsonList(
      'collector_warehouse_transfers',
      _warehouseTransfers.map((e) => e.toJson()).toList(),
    );
    LocalStorageService.saveInt(
      'collector_warehouse_transfer_counter',
      _warehouseTransferCounter,
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

  void _ensureShipmentLineageBackfilled() {
    for (final shipment in _shipmentBatches) {
      if (TraceabilityRepository.instance.parentsOf(shipment.code).isNotEmpty) {
        continue;
      }
      final sourceBatches = shipment.sourceBatchCodes
          .map(_farmerRepo.findPublicBatch)
          .whereType<HarvestBatch>()
          .toList();
      if (sourceBatches.length != shipment.sourceBatchCodes.length) continue;

      TraceabilityRepository.instance.recordConsolidatedBatch(
        targetBatchCode: shipment.code,
        holderId: _currentCollectorId,
        holderRole: TraceActorRole.collector,
        holderName: _profile.businessName.isEmpty
            ? _profile.fullName
            : _profile.businessName,
        contributions: sourceBatches
            .map(
              (batch) => TraceLineageContribution(
                sourceBatchCode: batch.code,
                quantity: batch.receivedQuantity ?? batch.quantity,
                unit: batch.unit,
                fruitCount: batch.receivedFruitCount ?? batch.fruitCount,
                note: batch.verifiedGrade == null
                    ? null
                    : 'Grade ${batch.verifiedGrade}',
              ),
            )
            .toList(),
        productName:
            'Durian ${shipment.sourceBatchCodes.length > 1 ? 'Campuran' : sourceBatches.first.variety}',
        createdAt: shipment.packagedAt,
        locationLabel: _profile.location,
        relationType: shipment.sourceBatchCodes.length > 1
            ? TraceBatchRelationType.consolidatedFrom
            : TraceBatchRelationType.splitFrom,
        metadata: {
          'Kode pengiriman': shipment.code,
          'Tujuan': shipment.destinationName ?? shipment.destinationType.label,
          'Lokasi tujuan': shipment.destinationLocation ?? '-',
          'Migrasi': 'Backfill lineage shipment lama',
        },
      );
    }
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
  late List<CollectorAuditEvent> _auditEvents;
  late List<CollectorIncomingReceipt> _incomingReceipts;
  late List<CollectorWarehouse> _warehouses;
  late List<CollectorWarehouseTransfer> _warehouseTransfers;
  late int _shipmentCounter;
  late int _purchaseTransactionCounter;
  late int _warehouseCounter;
  late int _warehouseTransferCounter;
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

  List<CollectorWarehouseTransfer> get warehouseTransfers {
    final items = _warehouseTransfers
        .where((transfer) => transfer.collectorId == _currentCollectorId)
        .toList();
    items.sort((a, b) => b.transferredAt.compareTo(a.transferredAt));
    return List.unmodifiable(items);
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
    final updated = CollectorWarehouse(
      id: existing.id,
      name: name.trim(),
      location: location.trim(),
      note: note?.trim().isEmpty == true ? null : note?.trim(),
      isDefault: setAsDefault ? true : existing.isDefault,
      createdAt: existing.createdAt,
    );
    _warehouses[index] = updated;
    _recordManualAuditEvent(
      CollectorAuditEvent(
        id: 'AUD-WH-UPDATE--',
        type: CollectorAuditEventType.warehouse,
        action: 'Gudang diperbarui',
        actorName: _collectorActorName,
        actorRole: 'Pengepul',
        objectCode: updated.id,
        description: ' diperbarui.',
        occurredAt: DateTime.now(),
        locationLabel: updated.location,
        statusLabel: updated.isDefault ? 'Default' : 'Aktif',
        metadata: {
          'Nama lama': existing.name,
          'Nama baru': updated.name,
          'Lokasi lama': existing.location,
          'Lokasi baru': updated.location,
        },
      ),
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
    _recordManualAuditEvent(
      CollectorAuditEvent(
        id: 'AUD-WH-DELETE--',
        type: CollectorAuditEventType.warehouse,
        action: 'Gudang dihapus',
        actorName: _collectorActorName,
        actorRole: 'Pengepul',
        objectCode: removed.id,
        description: ' dihapus dari daftar gudang.',
        occurredAt: DateTime.now(),
        locationLabel: removed.location,
        statusLabel: 'Dihapus',
        metadata: {
          'Nama gudang': removed.name,
          if (removed.note?.trim().isNotEmpty == true)
            'Catatan': removed.note!.trim(),
        },
      ),
    );
    if (removed.isDefault && _warehouses.isNotEmpty) {
      _warehouses[0] = _warehouses[0].copyWith(isDefault: true);
    }
    _saveToLocal();
    notifyListeners();
    return true;
  }

  // [FE - State Management] Batch yang bisa dipindah antar gudang adalah stok
  // yang sudah diterima pengepul, punya gudang asal, dan belum dialokasikan ke
  // batch pengiriman berikutnya.
  List<HarvestBatch> get transferableWarehouseBatches {
    final allocatedCodes = _allocatedSourceBatchCodes;
    final items = stockBatches
        .where(
          (batch) =>
              batch.warehouseId?.trim().isNotEmpty == true &&
              !allocatedCodes.contains(batch.code),
        )
        .toList();
    items.sort(
      (a, b) => (b.verifiedAt ?? b.harvestDate).compareTo(
        a.verifiedAt ?? a.harvestDate,
      ),
    );
    return List.unmodifiable(items);
  }

  CollectorWarehouseTransfer? transferWarehouseStock({
    required String batchCode,
    required String fromWarehouseId,
    required String toWarehouseId,
    required String reason,
  }) {
    final cleanBatchCode = batchCode.trim().toUpperCase();
    final cleanFromId = fromWarehouseId.trim();
    final cleanToId = toWarehouseId.trim();
    final cleanReason = reason.trim();
    if (cleanBatchCode.isEmpty ||
        cleanFromId.isEmpty ||
        cleanToId.isEmpty ||
        cleanFromId == cleanToId ||
        cleanReason.isEmpty) {
      return null;
    }

    final fromWarehouse = findWarehouse(cleanFromId);
    final toWarehouse = findWarehouse(cleanToId);
    if (fromWarehouse == null || toWarehouse == null) return null;

    HarvestBatch batch;
    try {
      batch = transferableWarehouseBatches.firstWhere(
        (item) => item.code == cleanBatchCode,
      );
    } catch (_) {
      return null;
    }
    if (batch.warehouseId?.trim() != cleanFromId) return null;

    final actorName = _profile.businessName.trim().isEmpty
        ? _profile.fullName
        : _profile.businessName;
    final updated = _farmerRepo.transferCollectorBatchWarehouse(
      code: cleanBatchCode,
      fromWarehouseId: cleanFromId,
      fromWarehouseLabel: fromWarehouse.name,
      toWarehouseId: cleanToId,
      toWarehouseLabel: toWarehouse.name,
      reason: cleanReason,
      actorName: actorName,
    );
    if (!updated) return null;

    final transfer = CollectorWarehouseTransfer(
      id: _generateWarehouseTransferId(),
      collectorId: _currentCollectorId,
      batchCode: cleanBatchCode,
      fromWarehouseId: cleanFromId,
      fromWarehouseName: fromWarehouse.name,
      toWarehouseId: cleanToId,
      toWarehouseName: toWarehouse.name,
      weightKg: batch.receivedQuantity ?? batch.quantity,
      fruitCount: batch.receivedFruitCount ?? batch.fruitCount ?? 0,
      reason: cleanReason,
      actorName: actorName,
      transferredAt: DateTime.now(),
    );
    _warehouseTransfers.add(transfer);

    TraceabilityRepository.instance.recordWarehouseTransfer(
      batchCode: cleanBatchCode,
      actorId: _currentCollectorId,
      actorRole: TraceActorRole.collector,
      actorName: actorName,
      fromLocationLabel: _warehouseTraceLabel(fromWarehouse),
      toLocationLabel: _warehouseTraceLabel(toWarehouse),
      quantity: transfer.weightKg,
      unit: batch.unit,
      fruitCount: transfer.fruitCount,
      reason: cleanReason,
      relatedObjectId: transfer.id,
    );

    _saveToLocal();
    notifyListeners();
    return transfer;
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

  // [FE - State Management] Daftar ini adalah PGL dari pengepul lain yang
  // memang ditujukan ke pengepul, sehingga bisa discan dan divalidasi T2 oleh
  // role pengepul penerima.
  List<CollectorShipmentBatch> get incomingCollectorShipments {
    final items = _shipmentBatches
        .where(
          (shipment) =>
              shipment.destinationType == ShipmentDestinationType.collector &&
              shipment.collectorId != _currentCollectorId,
        )
        .toList();
    items.sort((a, b) => b.packagedAt.compareTo(a.packagedAt));
    return List.unmodifiable(items);
  }

  CollectorShipmentBatch? findIncomingCollectorShipment(String code) {
    final cleanCode = code.trim().toUpperCase();
    if (cleanCode.isEmpty) return null;
    try {
      return incomingCollectorShipments.firstWhere(
        (shipment) => shipment.code.toUpperCase() == cleanCode,
      );
    } catch (_) {
      return null;
    }
  }

  CollectorIncomingReceipt? incomingReceiptForShipment(String shipmentCode) {
    final cleanCode = shipmentCode.trim().toUpperCase();
    try {
      return _incomingReceipts.firstWhere(
        (receipt) =>
            receipt.shipmentCode.toUpperCase() == cleanCode &&
            receipt.receiverCollectorId == _currentCollectorId,
      );
    } catch (_) {
      return null;
    }
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
    TraceabilityRepository.instance.recordConsolidatedBatch(
      targetBatchCode: shipment.code,
      holderId: _currentCollectorId,
      holderRole: TraceActorRole.collector,
      holderName: _profile.businessName.isEmpty
          ? _profile.fullName
          : _profile.businessName,
      contributions: selectedBatches
          .map(
            (batch) => TraceLineageContribution(
              sourceBatchCode: batch.code,
              quantity: batch.receivedQuantity ?? batch.quantity,
              unit: batch.unit,
              fruitCount: batch.receivedFruitCount ?? batch.fruitCount,
              note: batch.verifiedGrade == null
                  ? null
                  : 'Grade ${batch.verifiedGrade}',
            ),
          )
          .toList(),
      productName:
          'Durian ${shipment.sourceBatchCodes.length > 1 ? 'Campuran' : selectedBatches.first.variety}',
      createdAt: shipment.packagedAt,
      locationLabel: _profile.location,
      relationType: shipment.sourceBatchCodes.length > 1
          ? TraceBatchRelationType.consolidatedFrom
          : TraceBatchRelationType.splitFrom,
      metadata: {
        'Kode pengiriman': shipment.code,
        'Tujuan': shipment.destinationName ?? shipment.destinationType.label,
        'Lokasi tujuan': shipment.destinationLocation ?? '-',
      },
    );
    _saveToLocal();
    notifyListeners();
    return shipment;
  }

  CollectorIncomingReceipt? receiveIncomingCollectorShipment({
    required String code,
    required double receivedWeightKg,
    required int receivedFruitCount,
    required CollectorIncomingReceiptCondition condition,
    required String destinationWarehouseId,
    String? discrepancyNote,
    String? qualityNote,
  }) {
    final cleanCode = code.trim().toUpperCase();
    final warehouse = findWarehouse(destinationWarehouseId);
    final shipment = findIncomingCollectorShipment(cleanCode);
    if (shipment == null ||
        shipment.status != CollectorShipmentStatus.sent ||
        warehouse == null ||
        receivedWeightKg <= 0 ||
        receivedFruitCount <= 0 ||
        incomingReceiptForShipment(cleanCode) != null) {
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
    final completed = completeShipment(
      cleanCode,
      warehouseNote: cleanQualityNote?.isNotEmpty == true
          ? cleanQualityNote
          : 'Diterima dan diverifikasi oleh pengepul lain.',
    );
    if (!completed) return null;

    final actorName = _profile.businessName.trim().isEmpty
        ? _profile.fullName
        : _profile.businessName;
    _farmerRepo.markBatchesReceivedByCollector(
      sourceBatchCodes: shipment.sourceBatchCodes,
      warehouseId: warehouse.id,
      warehouseLabel: warehouse.name,
      receiverName: actorName,
      qualityNote: cleanQualityNote,
    );

    final receipt = CollectorIncomingReceipt(
      shipmentCode: cleanCode,
      receiverCollectorId: _currentCollectorId,
      senderCollectorId: shipment.collectorId,
      expectedWeightKg: shipment.totalWeightKg,
      expectedFruitCount: shipment.totalFruitCount,
      receivedWeightKg: receivedWeightKg,
      receivedFruitCount: receivedFruitCount,
      condition: condition,
      receivedAt: DateTime.now(),
      destinationWarehouseId: warehouse.id,
      destinationWarehouseName: warehouse.name,
      destinationLocation: warehouse.location,
      discrepancyNote: cleanDiscrepancyNote?.isEmpty == true
          ? null
          : cleanDiscrepancyNote,
      qualityNote: cleanQualityNote?.isEmpty == true ? null : cleanQualityNote,
    );
    _incomingReceipts.add(receipt);

    TraceabilityRepository.instance.recordReceiptVariance(
      batchCode: shipment.code,
      actorId: _currentCollectorId,
      actorRole: TraceActorRole.collector,
      actorName: actorName,
      expectedQuantity: shipment.totalWeightKg,
      receivedQuantity: receivedWeightKg,
      unit: 'kg',
      expectedFruitCount: shipment.totalFruitCount,
      receivedFruitCount: receivedFruitCount,
      conditionLabel: condition.label,
      locationLabel: _warehouseTraceLabel(warehouse),
      relatedObjectId: 'COLLECTOR-RECEIPT-${receipt.shipmentCode}',
      note: cleanDiscrepancyNote?.isNotEmpty == true
          ? cleanDiscrepancyNote
          : cleanQualityNote,
    );
    _saveToLocal();
    notifyListeners();
    return receipt;
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

  String get _collectorActorName => _profile.businessName.trim().isEmpty
      ? _profile.fullName
      : _profile.businessName;

  void _recordManualAuditEvent(CollectorAuditEvent event) {
    final index = _auditEvents.indexWhere((item) => item.id == event.id);
    if (index == -1) {
      _auditEvents.add(event);
    } else {
      _auditEvents[index] = event;
    }
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

  String _warehouseTraceLabel(CollectorWarehouse warehouse) {
    final location = warehouse.location.trim();
    if (location.isEmpty) return warehouse.name;
    return '${warehouse.name}, $location';
  }

  String _generateWarehouseId() {
    _warehouseCounter++;
    final seq = _warehouseCounter.toString().padLeft(4, '0');
    return 'WH-$_currentCollectorId-$seq';
  }

  String _generateWarehouseTransferId() {
    _warehouseTransferCounter++;
    final seq = _warehouseTransferCounter.toString().padLeft(6, '0');
    return 'WHT-$_currentCollectorId-$seq';
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

  List<CollectorAuditEvent> get auditEvents {
    final items = <CollectorAuditEvent>[..._auditEvents];
    final actor = _collectorActorName;

    for (final transaction in _purchaseTransactions.where(
      (item) => item.collectorId == _currentCollectorId,
    )) {
      items.add(
        CollectorAuditEvent(
          id: 'AUD-T1-${transaction.id}',
          type: CollectorAuditEventType.purchase,
          action: 'Scan QR / T1 dibuat',
          actorName: actor,
          actorRole: 'Pengepul',
          objectCode: transaction.batchCode,
          description:
              '${transaction.batchCode} discan dari ${transaction.farmerLabel}.',
          occurredAt: transaction.initiatedAt,
          locationLabel: transaction.originLabel,
          statusLabel: transaction.status.label,
          metadata: {
            'Transaksi': transaction.id,
            'Sumber': transaction.farmerLabel,
            'Asal': transaction.originLabel,
          },
        ),
      );
    }

    for (final batch in historyBatches) {
      if (batch.verifiedAt != null &&
          (batch.verifiedByRole == null ||
              batch.verifiedByRole == BatchReceiverRole.collector)) {
        final warehouse = findWarehouse(batch.warehouseId);
        items.add(
          CollectorAuditEvent(
            id: 'AUD-RECEIPT-${batch.code}-${batch.verifiedAt!.millisecondsSinceEpoch}',
            type: CollectorAuditEventType.receipt,
            action: 'T2 penerimaan batch',
            actorName: batch.verifiedBy?.trim().isNotEmpty == true
                ? batch.verifiedBy!.trim()
                : actor,
            actorRole: 'Pengepul',
            objectCode: batch.code,
            description:
                '${batch.code} diterima dan divalidasi dari ${batch.farmName}.',
            occurredAt: batch.verifiedAt!,
            locationLabel: warehouse?.location ?? warehouse?.name,
            statusLabel: batch.status.label,
            metadata: {
              'Varietas': batch.variety,
              'Grade': batch.verifiedGrade ?? batch.grade,
              'Berat diterima':
                  '${batch.receivedQuantity ?? batch.quantity} ${batch.unit}',
              'Jumlah diterima':
                  '${batch.receivedFruitCount ?? batch.fruitCount ?? 0} butir',
              if (batch.qualityNotes?.trim().isNotEmpty == true)
                'Catatan': batch.qualityNotes!.trim(),
            },
          ),
        );

        if (batch.gradeBreakdown.isNotEmpty) {
          items.add(
            CollectorAuditEvent(
              id: 'AUD-GRADING-${batch.code}-${batch.verifiedAt!.millisecondsSinceEpoch}',
              type: CollectorAuditEventType.grading,
              action: 'Grading dicatat',
              actorName: batch.verifiedBy?.trim().isNotEmpty == true
                  ? batch.verifiedBy!.trim()
                  : actor,
              actorRole: 'Pengepul',
              objectCode: batch.code,
              description: '${batch.code} memiliki rincian grading pengepul.',
              occurredAt: batch.verifiedAt!,
              locationLabel: warehouse?.name,
              statusLabel: batch.verifiedGrade == null
                  ? null
                  : 'Dominan ${batch.verifiedGrade}',
              metadata: {
                'Rincian grade': batch.gradeBreakdown
                    .map(
                      (item) =>
                          '${item.grade}: ${item.weightKg} kg / ${item.fruitCount} butir',
                    )
                    .join(', '),
              },
            ),
          );
        }
      }
      if (batch.rejectedAt != null) {
        items.add(
          CollectorAuditEvent(
            id: 'AUD-REJECT-${batch.code}-${batch.rejectedAt!.millisecondsSinceEpoch}',
            type: CollectorAuditEventType.rejection,
            action: 'T2 ditolak',
            actorName: batch.rejectedBy?.trim().isNotEmpty == true
                ? batch.rejectedBy!.trim()
                : actor,
            actorRole: 'Pengepul',
            objectCode: batch.code,
            description: '${batch.code} ditolak saat validasi penerimaan.',
            occurredAt: batch.rejectedAt!,
            statusLabel: 'Ditolak',
            metadata: {
              'Alasan': batch.rejectionReason ?? '-',
              'Varietas': batch.variety,
              'Asal': batch.farmName,
            },
          ),
        );
      }
    }

    for (final shipment in _shipmentBatches.where(
      (item) => item.collectorId == _currentCollectorId,
    )) {
      items.add(
        CollectorAuditEvent(
          id: 'AUD-SHIP-CREATE-${shipment.code}',
          type: CollectorAuditEventType.shipment,
          action: 'Buat PGL',
          actorName: actor,
          actorRole: 'Pengepul',
          objectCode: shipment.code,
          description:
              '${shipment.code} dibuat untuk ${shipment.destinationType.label}.',
          occurredAt: shipment.packagedAt,
          locationLabel: shipment.destinationLocation,
          statusLabel: shipment.status.label,
          metadata: {
            'Tujuan':
                shipment.destinationName ?? shipment.destinationType.label,
            'Total':
                '${shipment.totalWeightKg} kg / ${shipment.totalFruitCount} butir',
            'Batch sumber': shipment.sourceBatchCodes.join(', '),
          },
        ),
      );
      if (shipment.sentAt != null) {
        items.add(
          CollectorAuditEvent(
            id: 'AUD-SHIP-SENT-${shipment.code}',
            type: CollectorAuditEventType.shipment,
            action: 'PGL discan / dikirim',
            actorName: actor,
            actorRole: 'Pengepul',
            objectCode: shipment.code,
            description: '${shipment.code} mulai dikirim ke tujuan.',
            occurredAt: shipment.sentAt!,
            locationLabel: shipment.destinationLocation,
            statusLabel: 'Dikirim',
            metadata: {'Tujuan': shipment.destinationType.label},
          ),
        );
      }
      if (shipment.completedAt != null) {
        items.add(
          CollectorAuditEvent(
            id: 'AUD-SHIP-DONE-${shipment.code}',
            type: CollectorAuditEventType.shipment,
            action: 'PGL selesai diterima',
            actorName: actor,
            actorRole: 'Pengepul',
            objectCode: shipment.code,
            description: '${shipment.code} selesai pada tujuan.',
            occurredAt: shipment.completedAt!,
            locationLabel: shipment.destinationLocation,
            statusLabel: 'Selesai',
            metadata: {
              if (shipment.warehouseNote?.trim().isNotEmpty == true)
                'Catatan': shipment.warehouseNote!.trim(),
            },
          ),
        );
      }
    }

    for (final receipt in _incomingReceipts.where(
      (item) => item.receiverCollectorId == _currentCollectorId,
    )) {
      items.add(
        CollectorAuditEvent(
          id: 'AUD-INCOMING-${receipt.shipmentCode}-${receipt.receivedAt.millisecondsSinceEpoch}',
          type: CollectorAuditEventType.incoming,
          action: 'Terima PGL dari pengepul lain',
          actorName: actor,
          actorRole: 'Pengepul',
          objectCode: receipt.shipmentCode,
          description:
              '${receipt.shipmentCode} diterima dari ${receipt.senderCollectorId}.',
          occurredAt: receipt.receivedAt,
          locationLabel: receipt.destinationLocation,
          statusLabel: receipt.condition.label,
          metadata: {
            'Gudang tujuan': receipt.destinationWarehouseName,
            'Berat diterima': '${receipt.receivedWeightKg} kg',
            'Jumlah diterima': '${receipt.receivedFruitCount} butir',
            if (receipt.discrepancyNote?.trim().isNotEmpty == true)
              'Alasan selisih': receipt.discrepancyNote!.trim(),
            if (receipt.qualityNote?.trim().isNotEmpty == true)
              'Catatan': receipt.qualityNote!.trim(),
          },
        ),
      );
    }

    for (final warehouse in _warehouses) {
      items.add(
        CollectorAuditEvent(
          id: 'AUD-WH-CREATE-${warehouse.id}',
          type: CollectorAuditEventType.warehouse,
          action: 'Gudang tercatat',
          actorName: actor,
          actorRole: 'Pengepul',
          objectCode: warehouse.id,
          description: '${warehouse.name} tercatat sebagai gudang pengepul.',
          occurredAt: warehouse.createdAt ?? DateTime(2026, 1, 1),
          locationLabel: warehouse.location,
          statusLabel: warehouse.isDefault ? 'Default' : 'Aktif',
          metadata: {
            'Nama gudang': warehouse.name,
            if (warehouse.note?.trim().isNotEmpty == true)
              'Catatan': warehouse.note!.trim(),
          },
        ),
      );
    }

    for (final transfer in warehouseTransfers) {
      items.add(
        CollectorAuditEvent(
          id: 'AUD-WH-TRANSFER-${transfer.id}',
          type: CollectorAuditEventType.transfer,
          action: 'Transfer antar gudang',
          actorName: transfer.actorName,
          actorRole: 'Pengepul',
          objectCode: transfer.batchCode,
          description:
              '${transfer.batchCode} dipindahkan dari ${transfer.fromWarehouseName} ke ${transfer.toWarehouseName}.',
          occurredAt: transfer.transferredAt,
          locationLabel: transfer.toWarehouseName,
          statusLabel: 'Selesai',
          metadata: {
            'Gudang asal': transfer.fromWarehouseName,
            'Gudang tujuan': transfer.toWarehouseName,
            'Jumlah': '${transfer.weightKg} kg / ${transfer.fruitCount} butir',
            'Alasan': transfer.reason,
          },
        ),
      );
    }

    final deduped = <String, CollectorAuditEvent>{};
    for (final event in items) {
      deduped[event.id] = event;
    }
    final result = deduped.values.toList()
      ..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
    return List.unmodifiable(result);
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
    final sourceBatch = _farmerRepo.findPublicBatch(code);
    if (sourceBatch == null) return false;

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

    final actorName = _profile.businessName.isEmpty
        ? _profile.fullName
        : _profile.businessName;
    final warehouse = findWarehouse(warehouseId);
    TraceabilityRepository.instance.recordReceiptVariance(
      batchCode: code,
      actorId: _currentCollectorId,
      actorRole: TraceActorRole.collector,
      actorName: actorName,
      expectedQuantity: sourceBatch.quantity,
      receivedQuantity: receivedQuantity,
      unit: sourceBatch.unit,
      expectedFruitCount: sourceBatch.fruitCount,
      receivedFruitCount: receivedFruitCount,
      conditionLabel: qualityNotes?.trim().isNotEmpty == true
          ? qualityNotes!.trim()
          : 'Divalidasi pengepul',
      locationLabel: warehouse?.location ?? _profile.location,
      relatedObjectId: transactionId ?? 'COLLECTOR-VERIFY-$code',
      note: qualityNotes,
    );

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
      gradedBy: _profile.businessName.isEmpty
          ? _profile.fullName
          : _profile.businessName,
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
      CollectorShipmentBatch(
        code: 'PGL-2026-000904',
        collectorId: 'collector-demo-malang',
        sourceBatchCodes: const ['DRN-DEMO-MLG-001', 'DRN-DEMO-MLG-002'],
        totalWeightKg: 360,
        totalFruitCount: 94,
        gradeBreakdown: const [
          CollectorStockBreakdown(
            key: 'A',
            label: 'Grade A',
            totalWeightKg: 210,
            totalFruitCount: 55,
            batchCount: 2,
          ),
          CollectorStockBreakdown(
            key: 'B',
            label: 'Grade B',
            totalWeightKg: 150,
            totalFruitCount: 39,
            batchCount: 2,
          ),
        ],
        varietyBreakdown: const [
          CollectorStockBreakdown(
            key: 'bawor',
            label: 'Durian Bawor',
            totalWeightKg: 220,
            totalFruitCount: 58,
            batchCount: 1,
          ),
          CollectorStockBreakdown(
            key: 'montong',
            label: 'Durian Montong',
            totalWeightKg: 140,
            totalFruitCount: 36,
            batchCount: 1,
          ),
        ],
        packagedAt: now.subtract(const Duration(hours: 3)),
        status: CollectorShipmentStatus.readyToShip,
        destinationType: ShipmentDestinationType.collector,
        destinationName: 'Lapak Durian Jember',
        destinationLocation: 'Desa Pakis, Kabupaten Jember',
        warehouseNote: 'Simulasi PGL horizontal dari Pengepul Malang.',
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
