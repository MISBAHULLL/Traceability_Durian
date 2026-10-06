import 'dart:async';

import 'package:flutter/foundation.dart';
import '../../../core/network/backend_api_client.dart';
import '../../collector/data/collector_repository.dart';
import '../../collector/models/collector_shipment_batch.dart';
import '../../farmer/data/farmer_repository.dart';
import '../../farmer/models/batch_recipient.dart';
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
    CollectorRepository.instance.addListener(_onCollectorRepoChanged);
    FarmerRepository.instance.addListener(_onFarmerRepoChanged);
    unawaited(refreshFromBackend());
  }

  static final DistributorRepository instance = DistributorRepository._();

  static const String _kSeedDistributorId = 'distributor-001';
  late DistributorProfile _profile;
  late List<DistributorReceipt> _receipts;
  late List<DistributorRejectionReceipt> _rejectionReceipts;
  late List<DistributorAcquisitionTransaction> _acquisitionTransactions;
  late List<DistributorWarehouse> _warehouses;
  late List<DistributorWarehouseTransfer> _warehouseTransfers;
  late List<DistributorHorizontalSale> _horizontalSales;
  late List<DistributorAuditEvent> _auditEvents;
  List<CollectorShipmentBatch> _backendShipments = <CollectorShipmentBatch>[];
  List<HarvestBatch> _incomingFarmerBatches = <HarvestBatch>[];
  List<HarvestBatch> _saleInventoryBatches = <HarvestBatch>[];
  List<BatchRecipient> _saleRecipients = <BatchRecipient>[];
  bool _incomingFarmerBatchesLoaded = false;
  late int _acquisitionTransactionCounter;
  late int _warehouseCounter;
  late int _warehouseTransferCounter;
  late int _horizontalSaleCounter;
  late int _auditEventCounter;
  late int _rejectionReceiptCounter;
  String _currentDistributorId = _kSeedDistributorId;

  DistributorProfile get profile => _profile;
  String get currentDistributorId => _currentDistributorId;

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

  void _loadFromLocal() {
    _currentDistributorId = '';
    _profile = DistributorProfile.fromJson(const <String, dynamic>{});
    _receipts = <DistributorReceipt>[];
    _rejectionReceipts = <DistributorRejectionReceipt>[];
    _acquisitionTransactions = <DistributorAcquisitionTransaction>[];
    _warehouses = <DistributorWarehouse>[];
    _warehouseTransfers = <DistributorWarehouseTransfer>[];
    _horizontalSales = <DistributorHorizontalSale>[];
    _auditEvents = <DistributorAuditEvent>[];
    _backendShipments = <CollectorShipmentBatch>[];
    _incomingFarmerBatches = <HarvestBatch>[];
    _saleInventoryBatches = <HarvestBatch>[];
    _saleRecipients = <BatchRecipient>[];
    _incomingFarmerBatchesLoaded = false;
    _acquisitionTransactionCounter = 0;
    _warehouseCounter = 0;
    _warehouseTransferCounter = 0;
    _horizontalSaleCounter = 0;
    _auditEventCounter = 0;
    _rejectionReceiptCounter = 0;
  }

  void _saveToLocal() {
    return;
  }

  Future<void> refreshFromBackend() async {
    try {
      final profileResponse = await BackendApiClient.instance.get(
        '/distributor/profile',
      );
      final shipmentsResponse = await BackendApiClient.instance.get(
        '/distributor/shipments',
      );
      final warehousesResponse = await BackendApiClient.instance.get(
        '/distributor/warehouses',
      );
      final batchesResponse = await BackendApiClient.instance.get(
        '/distributor/batches',
      );
      if (profileResponse.data is Map) {
        final data = Map<String, dynamic>.from(profileResponse.data as Map);
        final user = Map<String, dynamic>.from(
          data['user'] as Map? ?? const {},
        );
        final profile = Map<String, dynamic>.from(
          data['profile'] as Map? ?? const {},
        );
        _profile = DistributorProfile.fromJson({
          'distributorId':
              user['id']?.toString() ??
              profile['user_id']?.toString() ??
              _profile.distributorId,
          'fullName':
              profile['business_name'] ??
              user['full_name'] ??
              '${user['first_name'] ?? ''} ${user['last_name'] ?? ''}'.trim(),
          'roleLabel': 'Distributor Durian',
          'businessName': profile['business_name'] ?? '',
          'contact': profile['contact'] ?? user['phone'] ?? '',
          'email': user['email'] ?? '',
          'location': profile['address'] ?? '',
          'village': profile['village'] ?? '',
          'district': profile['district'] ?? '',
          'city': profile['city'] ?? '',
          'province': profile['province'] ?? '',
          'address': profile['address'] ?? '',
          'avatarPath': profile['avatar_path'],
        });
      }

      if (shipmentsResponse.data is List) {
        _backendShipments = (shipmentsResponse.data as List)
            .whereType<Map>()
            .map(
              (item) => CollectorShipmentBatch.fromJson(
                Map<String, dynamic>.from(item),
              ),
            )
            .toList();
      }
      if (warehousesResponse.data is List) {
        _warehouses = (warehousesResponse.data as List)
            .whereType<Map>()
            .map(
              (item) => DistributorWarehouse.fromJson(
                Map<String, dynamic>.from(item),
              ),
            )
            .toList();
      }
      if (batchesResponse.data is List) {
        _incomingFarmerBatches = (batchesResponse.data as List)
            .whereType<Map>()
            .map(
              (item) => HarvestBatch.fromJson(
                Map<String, dynamic>.from(item),
              ),
            )
            .toList();
        _incomingFarmerBatchesLoaded = true;
      }

      try {
        final responses = await Future.wait([
          BackendApiClient.instance.get('/distributor/inventory-batches'),
          BackendApiClient.instance.get('/distributor/sale-recipients'),
          BackendApiClient.instance.get('/distributor/sales'),
        ]);
        if (responses[0].data is List) {
          _saleInventoryBatches = (responses[0].data as List)
              .whereType<Map>()
              .map(
                (item) => HarvestBatch.fromJson(
                  Map<String, dynamic>.from(item),
                ),
              )
              .toList();
        }
        if (responses[1].data is List) {
          _saleRecipients = (responses[1].data as List)
              .whereType<Map>()
              .map(
                (item) => BatchRecipient.fromJson(
                  Map<String, dynamic>.from(item),
                ),
              )
              .toList();
        }
        if (responses[2].data is List) {
          _horizontalSales = (responses[2].data as List)
              .whereType<Map>()
              .map(
                (item) => DistributorHorizontalSale.fromJson(
                  Map<String, dynamic>.from(item),
                ),
              )
              .toList();
        }
      } on BackendApiException catch (error) {
        if (kDebugMode) {
          debugPrint('[DISTRIBUTOR] sales refresh failed: ${error.message}');
        }
      }

      final receipts = <DistributorReceipt>[];
      for (final shipment in allShipments) {
        try {
          final detail = await BackendApiClient.instance.get(
            '/distributor/shipments/${shipment.code}',
          );
          if (detail.data is Map) {
            final data = Map<String, dynamic>.from(detail.data as Map);
            final receipt = data['receipt'];
            if (receipt is Map) {
              final receiptJson = Map<String, dynamic>.from(receipt);
              receiptJson['distributorId'] = _currentDistributorId;
              final parsed = DistributorReceipt.fromJson(receiptJson);
              receipts.add(parsed);
            }
          }
        } catch (_) {
          continue;
        }
      }
      if (receipts.isNotEmpty) {
        _receipts = receipts;
      }

      _currentDistributorId = _profile.distributorId;
      _saveToLocal();
      notifyListeners();
    } on BackendApiException catch (_) {
      // Cache lokal tetap dipakai.
    } catch (_) {
      // Cache lokal tetap dipakai.
    }
  }

  /// Registrasi data distributor baru setelah mendaftar via form registrasi.
  void registerDistributor({
    required String firstName,
    required String lastName,
    required String phone,
    required String email,
    String village = '',
    String district = '',
    String city = '',
    String province = '',
  }) async {
    final addressParts = [
      village,
      district,
      city,
      province,
    ].map((part) => part.trim()).where((part) => part.isNotEmpty).toList();
    _profile = DistributorProfile(
      distributorId: 'dist-reg-${DateTime.now().millisecondsSinceEpoch}',
      fullName: '$firstName $lastName'.trim(),
      roleLabel: 'Distributor Durian',
      contact: phone,
      email: email,
      location: addressParts.join(', '),
      village: village.trim(),
      district: district.trim(),
      city: city.trim(),
      province: province.trim(),
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
  Future<DistributorProfile> updateProfile({
    required String fullName,
    required String businessName,
    required String contact,
    required String email,
    required String village,
    required String district,
    required String city,
    required String province,
    required String address,
  }) async {
    final location = [
      village.trim(),
      district.trim(),
      city.trim(),
      province.trim(),
    ].where((value) => value.isNotEmpty).join(', ');
    _profile = _profile.copyWith(
      fullName: fullName.trim(),
      businessName: businessName.trim(),
      contact: contact.trim(),
      email: email.trim(),
      village: village.trim(),
      district: district.trim(),
      city: city.trim(),
      province: province.trim(),
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
    try {
      await BackendApiClient.instance.put(
        '/distributor/profile',
        body: {
          'full_name': _profile.fullName,
          'business_name': _profile.businessName,
          'contact': _profile.contact,
          'email': _profile.email,
          'village': _profile.village,
          'district': _profile.district,
          'city': _profile.city,
          'province': _profile.province,
          'address': _profile.address,
          'location': _profile.location,
        },
      );
    } on BackendApiException {
      // Local state remains available when the backend is temporarily offline.
    }
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

  List<BatchRecipient> get saleRecipients =>
      List.unmodifiable(_saleRecipients);

  List<HarvestBatch> get saleInventoryBatches =>
      List.unmodifiable(_saleInventoryBatches);

  List<DistributorHorizontalSale> get horizontalSales {
    final items = _horizontalSales
        .where((sale) => sale.sellerDistributorId == _currentDistributorId)
        .toList();
    items.sort((a, b) => b.initiatedAt.compareTo(a.initiatedAt));
    return List.unmodifiable(items);
  }

  Future<DistributorHorizontalSale> createHorizontalSale({
    required String batchCode,
    required BatchRecipient recipient,
    String? qualityNote,
  }) async {
    final response = await BackendApiClient.instance.post(
      '/distributor/sales',
      body: {
        'batch_code': batchCode,
        'recipient_user_id': recipient.userId,
        'recipient_role': switch (recipient.role) {
          BatchReceiverRole.collector => 'pengepul',
          BatchReceiverRole.distributor => 'distributor',
          BatchReceiverRole.umkm => 'umkm',
        },
        if (qualityNote?.trim().isNotEmpty == true)
          'quality_note': qualityNote!.trim(),
      },
    );
    final json = response.data;
    if (json is! Map) {
      throw const FormatException('Respons penjualan distributor tidak valid.');
    }

    final sale = DistributorHorizontalSale.fromJson(
      Map<String, dynamic>.from(json),
    );
    _horizontalSales.removeWhere((item) => item.id == sale.id);
    _horizontalSales.insert(0, sale);
    _saleInventoryBatches.removeWhere((item) => item.code == batchCode);
    notifyListeners();
    return sale;
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

  DistributorHorizontalSale? findHorizontalSaleByScanCode(String code) {
    final cleanCode = code.trim().toUpperCase();
    if (cleanCode.isEmpty) return null;
    try {
      return _horizontalSales.firstWhere(
        (sale) =>
            sale.id.toUpperCase() == cleanCode ||
            sale.itemCode.toUpperCase() == cleanCode,
      );
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

  Future<DistributorWarehouse?> createWarehouse({
    required String name,
    required String location,
    String? note,
    bool setAsDefault = false,
  }) async {
    try {
      final response = await BackendApiClient.instance.post(
        '/distributor/warehouses',
        body: {
          'name': name.trim(),
          'location': location.trim(),
          'note': note?.trim().isEmpty == true ? null : note?.trim(),
          'is_default': setAsDefault,
        },
      );
      if (response.data is! Map) return null;
      final warehouse = DistributorWarehouse.fromJson(
        Map<String, dynamic>.from(response.data as Map),
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
      notifyListeners();
      return warehouse;
    } catch (_) {
      return null;
    }
  }

  Future<bool> updateWarehouse(
    String id, {
    required String name,
    required String location,
    String? note,
    bool setAsDefault = false,
  }) async {
    final index = _warehouses.indexWhere((warehouse) => warehouse.id == id);
    if (index == -1) return false;
    try {
      final response = await BackendApiClient.instance.put(
        '/distributor/warehouses/$id',
        body: {
          'name': name.trim(),
          'location': location.trim(),
          'note': note?.trim().isEmpty == true ? null : note?.trim(),
          'is_default': setAsDefault,
        },
      );
      if (response.data is! Map) return false;
      final updated = DistributorWarehouse.fromJson(
        Map<String, dynamic>.from(response.data as Map),
      );

      if (setAsDefault) {
        _warehouses = _warehouses
            .map((item) => item.copyWith(isDefault: false))
            .toList();
      }
      final existing = _warehouses[index];
      _warehouses[index] = updated;
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
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteWarehouse(String id) async {
    final index = _warehouses.indexWhere((warehouse) => warehouse.id == id);
    if (index == -1 || _warehouses.length <= 1) return false;

    final isUsed = _warehouseTransfers.any(
      (transfer) =>
          transfer.fromWarehouseId == id || transfer.toWarehouseId == id,
    );
    if (isUsed) return false;
    try {
      await BackendApiClient.instance.delete('/distributor/warehouses/$id');
    } catch (_) {
      return false;
    }

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

  bool verifyHorizontalSaleByReceiver({
    required String saleId,
    required String receiverId,
    required TraceActorRole receiverRole,
    required String receiverName,
    required double receivedWeightKg,
    required int receivedFruitCount,
    required DistributorReceiptCondition condition,
    required String destinationLocation,
    String? discrepancyNote,
    String? qualityNote,
  }) {
    final cleanLocation = destinationLocation.trim();
    final index = _horizontalSales.indexWhere(
      (sale) =>
          sale.id == saleId &&
          sale.status == DistributorHorizontalSaleStatus.initiated,
    );
    if (index == -1 ||
        cleanLocation.isEmpty ||
        receivedWeightKg <= 0 ||
        receivedFruitCount <= 0) {
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
      actorId: receiverId,
      actorRole: receiverRole,
      actorName: receiverName,
      expectedQuantity: sale.expectedWeightKg,
      receivedQuantity: receivedWeightKg,
      unit: 'kg',
      expectedFruitCount: sale.expectedFruitCount,
      receivedFruitCount: receivedFruitCount,
      conditionLabel: condition.label,
      locationLabel: cleanLocation,
      relatedObjectId: sale.id,
      note: cleanDiscrepancy?.isNotEmpty == true
          ? cleanDiscrepancy
          : cleanQuality,
    );
    _recordAudit(
      type: DistributorAuditEventType.sale,
      action: 'Validasi T2 oleh penerima',
      objectCode: sale.id,
      description: '${sale.itemCode} diterima $receiverName di $cleanLocation.',
      metadata: {
        'Penerima': receiverName,
        'Role penerima': receiverRole.label,
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

  bool rejectHorizontalSaleByReceiver({
    required String saleId,
    required String receiverId,
    required TraceActorRole receiverRole,
    required String receiverName,
    required String destinationLocation,
    required String note,
  }) {
    final cleanNote = note.trim();
    final cleanLocation = destinationLocation.trim();
    final index = _horizontalSales.indexWhere(
      (sale) =>
          sale.id == saleId &&
          sale.status == DistributorHorizontalSaleStatus.initiated,
    );
    if (index == -1 || cleanNote.isEmpty || cleanLocation.isEmpty) {
      return false;
    }

    final sale = _horizontalSales[index];
    _horizontalSales[index] = sale.copyWith(
      status: DistributorHorizontalSaleStatus.rejected,
      verifiedAt: DateTime.now(),
      rejectionNote: cleanNote,
    );
    TraceabilityRepository.instance.recordReceiptRejection(
      batchCode: sale.itemCode,
      actorId: receiverId,
      actorRole: receiverRole,
      actorName: receiverName,
      expectedQuantity: sale.expectedWeightKg,
      unit: 'kg',
      expectedFruitCount: sale.expectedFruitCount,
      locationLabel: cleanLocation,
      relatedObjectId: sale.id,
      reason: cleanNote,
    );
    _recordAudit(
      type: DistributorAuditEventType.rejection,
      action: 'Tolak T2 oleh penerima',
      objectCode: sale.id,
      description: '${sale.itemCode} ditolak $receiverName di $cleanLocation.',
      metadata: {
        'Penerima': receiverName,
        'Role penerima': receiverRole.label,
        'Tujuan': cleanLocation,
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
  List<HarvestBatch> get availableFarmerAcquisitionBatches {
    if (_incomingFarmerBatchesLoaded) {
      return List.unmodifiable(
        _incomingFarmerBatches.where(
          (batch) => batch.status == BatchStatus.created,
        ),
      );
    }
    return FarmerRepository.instance.batchesForReceiverVerification(
      role: BatchReceiverRole.distributor,
      userId: _currentDistributorId,
    );
  }

  HarvestBatch? findFarmerAcquisitionBatch(String code) {
    final cleanCode = code.trim().toUpperCase();
    if (_incomingFarmerBatchesLoaded) {
      for (final batch in _incomingFarmerBatches) {
        if (batch.code.toUpperCase() == cleanCode) return batch;
      }
      return null;
    }
    return FarmerRepository.instance.findBatchForReceiver(
      code: cleanCode,
      role: BatchReceiverRole.distributor,
      userId: _currentDistributorId,
    );
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
    final batch = findFarmerAcquisitionBatch(batchCode);
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
  List<CollectorShipmentBatch> get allShipments =>
      List.unmodifiable(_backendShipments);

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
  Future<bool> takeShipment(String code) async {
    try {
      final success = await CollectorRepository.instance.markShipmentSent(code);
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
  Future<DistributorReceipt?> completeCollectorAcquisition({
    required String transactionId,
    required double receivedWeightKg,
    required int receivedFruitCount,
    required DistributorReceiptCondition condition,
    required String destinationLocation,
    String? discrepancyNote,
    String? qualityNote,
  }) async {
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
        !await takeShipment(shipment.code)) {
      return null;
    }

    final receipt = await receiveShipment(
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
  Future<bool> completeFarmerAcquisition({
    required String transactionId,
    required double receivedWeightKg,
    required int receivedFruitCount,
    required List<BatchGradeBreakdown> gradeBreakdown,
    required String destinationLocation,
    String? qualityNote,
  }) async {
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

    final batch = findFarmerAcquisitionBatch(
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

    final response = await BackendApiClient.instance.post(
      '/distributor/batches/${Uri.encodeComponent(batch.code)}/receive',
      body: {
        'received_quantity_kg': receivedWeightKg,
        'received_fruit_count': receivedFruitCount,
        'quality_notes': qualityNote,
      },
    );
    final responseData = response.data;
    final nestedBatch = responseData is Map ? responseData['batch'] : null;
    final receivedBatch = nestedBatch is Map
        ? HarvestBatch.fromJson({
            ...batch.toJson(),
            ...Map<String, dynamic>.from(nestedBatch),
          })
        : batch.copyWith(
            status: BatchStatus.receivedByDistributor,
            receivedQuantity: receivedWeightKg,
            receivedFruitCount: receivedFruitCount,
            qualityNotes: qualityNote,
            verifiedBy: _profile.fullName,
            verifiedByRole: BatchReceiverRole.distributor,
            verifiedAt: DateTime.now(),
          );
    final batchIndex = _incomingFarmerBatches.indexWhere(
      (item) => item.code == batch.code,
    );
    if (batchIndex >= 0) {
      _incomingFarmerBatches[batchIndex] = receivedBatch;
    } else {
      _incomingFarmerBatches.insert(0, receivedBatch);
    }
    _incomingFarmerBatchesLoaded = true;

    FarmerRepository.instance.verifyBatchByReceiver(
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
      receiverUserId: _currentDistributorId,
    );

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
  Future<DistributorReceipt?> receiveShipment({
    required String code,
    required double receivedWeightKg,
    required int receivedFruitCount,
    required DistributorReceiptCondition condition,
    required String destinationLocation,
    String? discrepancyNote,
    String? qualityNote,
  }) async {
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
    try {
      await BackendApiClient.instance.post(
        '/distributor/shipments/$code/receipt',
        body: {
          'received_weight_kg': receivedWeightKg,
          'received_fruit_count': receivedFruitCount,
          'condition': _backendReceiptCondition(condition),
          'destination_location': cleanDestination,
          'discrepancy_note': cleanDiscrepancyNote,
          'quality_note': cleanQualityNote,
        },
      );
    } on BackendApiException {
      return null;
    }

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
    final shipmentIndex = _backendShipments.indexWhere(
      (item) => item.code == shipment.code,
    );
    if (shipmentIndex != -1) {
      _backendShipments[shipmentIndex] = shipment.copyWith(
        status: CollectorShipmentStatus.completed,
        completedAt: receipt.receivedAt,
      );
    }
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

  String _backendReceiptCondition(DistributorReceiptCondition condition) {
    return switch (condition) {
      DistributorReceiptCondition.good => 'good',
      DistributorReceiptCondition.minorDamage => 'minorDamage',
      DistributorReceiptCondition.damaged => 'damaged',
    };
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
