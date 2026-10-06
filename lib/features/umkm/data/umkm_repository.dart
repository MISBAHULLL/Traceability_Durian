import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/network/backend_api_client.dart';
import '../../farmer/data/farmer_repository.dart';
import '../../farmer/models/harvest_batch.dart';
import '../../traceability/data/traceability_repository.dart';
import '../../traceability/models/traceability_models.dart';
import '../../collector/data/collector_repository.dart';
import '../../collector/models/collector_delivery_receipt.dart';
import '../../collector/models/collector_shipment_batch.dart';
import '../../distributor/data/distributor_repository.dart';
import '../../distributor/models/distributor_horizontal_sale.dart';
import '../../distributor/models/distributor_receipt.dart';
import '../models/umkm_audit_entry.dart';
import '../models/umkm_material_inventory.dart';
import '../models/umkm_order.dart';
import '../models/umkm_production_record.dart';
import '../models/umkm_product.dart';
import '../models/umkm_profile.dart';
import '../models/umkm_purchase.dart';
import '../models/umkm_stock_offer.dart';
import '../models/umkm_stock_order.dart';

class UmkmRepository extends ChangeNotifier {
  UmkmRepository._() {
    _loadFromLocal();
    unawaited(refreshFromBackend());
  }

  static final UmkmRepository instance = UmkmRepository._();

  UmkmProfile? _profile;
  List<UmkmProduct>? _products;
  List<UmkmOrder>? _orders;
  List<UmkmPurchase>? _purchases;
  List<UmkmMaterialInventory>? _materialInventories;
  List<UmkmMaterialMovement>? _materialMovements;
  List<UmkmProductionRecord>? _productionRecords;
  List<UmkmStockOffer>? _stockOffers;
  List<UmkmStockOrder>? _stockOrders;
  final List<CollectorDeliveryReceipt> _collectorDeliveryReceipts = [];
  List<HarvestBatch> _incomingFarmerBatches = <HarvestBatch>[];
  List<HarvestBatch> _receivedMaterialBatches = <HarvestBatch>[];
  bool _incomingFarmerBatchesLoaded = false;
  bool? _isRefreshingFarmerBatches;
  String? _farmerBatchesLoadError;

  UmkmProfile get profile =>
      _profile ??= UmkmProfile.fromJson(const <String, dynamic>{});
  List<UmkmProduct> get products =>
      List.unmodifiable(_products ??= <UmkmProduct>[]);
  List<UmkmOrder> get orders => List.unmodifiable(_orders ??= <UmkmOrder>[]);
  List<UmkmPurchase> get purchases =>
      List.unmodifiable(_purchases ??= <UmkmPurchase>[]);
  List<UmkmMaterialInventory> get materialInventories =>
      List.unmodifiable(_materialInventories ??= <UmkmMaterialInventory>[]);
  List<UmkmMaterialMovement> get materialMovements =>
      List.unmodifiable(_materialMovements ??= <UmkmMaterialMovement>[]);
  List<UmkmProductionRecord> get productionRecords =>
      List.unmodifiable(_productionRecords ??= <UmkmProductionRecord>[]);
  List<CollectorDeliveryReceipt> get collectorDeliveryReceipts =>
      List.unmodifiable(_collectorDeliveryReceipts);
  List<UmkmAuditEntry> get auditEntries => _buildAuditEntries();
  List<UmkmStockOffer> get stockOffers {
    _stockOffers ??= <UmkmStockOffer>[];
    return List.unmodifiable(_stockOffers!);
  }

  List<UmkmStockOrder> get stockOrders =>
      List.unmodifiable(_stockOrders ??= <UmkmStockOrder>[]);

  List<UmkmProduct> _productsOrCreate() => _products ??= <UmkmProduct>[];
  List<UmkmOrder> _ordersOrCreate() => _orders ??= <UmkmOrder>[];
  List<UmkmPurchase> _purchasesOrCreate() => _purchases ??= <UmkmPurchase>[];
  List<UmkmMaterialInventory> _materialInventoriesOrCreate() =>
      _materialInventories ??= <UmkmMaterialInventory>[];
  List<UmkmMaterialMovement> _materialMovementsOrCreate() =>
      _materialMovements ??= <UmkmMaterialMovement>[];
  List<UmkmProductionRecord> _productionRecordsOrCreate() =>
      _productionRecords ??= <UmkmProductionRecord>[];
  List<UmkmStockOffer> _stockOffersOrCreate() =>
      _stockOffers ??= <UmkmStockOffer>[];
  List<UmkmStockOrder> _stockOrdersOrCreate() =>
      _stockOrders ??= <UmkmStockOrder>[];

  List<UmkmTraceMaterialStock> get traceableMaterialStocks =>
      _materialStocks(availableOnly: true);

  List<UmkmTraceMaterialStock> get materialStockLedger =>
      _materialStocks(availableOnly: false);

  void _loadFromLocal() {
    _profile = UmkmProfile.fromJson(const <String, dynamic>{});
    _products = <UmkmProduct>[];
    _orders = <UmkmOrder>[];
    _purchases = <UmkmPurchase>[];
    _materialInventories = <UmkmMaterialInventory>[];
    _materialMovements = <UmkmMaterialMovement>[];
    _productionRecords = <UmkmProductionRecord>[];
    _stockOffers = <UmkmStockOffer>[];
    _stockOrders = <UmkmStockOrder>[];
    _collectorDeliveryReceipts.clear();
  }

  void _saveToLocal() {
    return;
  }

  Future<void> refreshFromBackend() async {
    try {
      final profileResponse = await BackendApiClient.instance.get(
        '/umkm/profile',
      );
      final productsResponse = await BackendApiClient.instance.get(
        '/umkm/products',
      );
      final ordersResponse = await BackendApiClient.instance.get(
        '/umkm/orders',
      );
      final batchesResponse = await BackendApiClient.instance.get(
        '/umkm/batches',
      );
      final materialsResponse = await BackendApiClient.instance.get(
        '/umkm/material-batches',
      );

      if (profileResponse.data is Map) {
        final data = Map<String, dynamic>.from(profileResponse.data as Map);
        final user = Map<String, dynamic>.from(
          data['user'] as Map? ?? const {},
        );
        final profile = Map<String, dynamic>.from(
          data['profile'] as Map? ?? const {},
        );
        _profile = UmkmProfile.fromJson({
          'umkmId':
              user['id']?.toString() ?? profile['user_id']?.toString() ?? '',
          'name': profile['name'] ?? user['full_name'] ?? '',
          'ownerName': profile['owner_name'] ?? user['full_name'] ?? '',
          'contact': profile['contact'] ?? user['phone'] ?? '',
          'email': user['email'] ?? '',
          'location': profile['address'] ?? '',
          'village': profile['village'] ?? '',
          'district': profile['district'] ?? '',
          'city': profile['city'] ?? '',
          'province': profile['province'] ?? '',
          'about': profile['about'] ?? '',
          'imagePath': profile['image_path'],
        });
      }

      if (productsResponse.data is List) {
        _products = (productsResponse.data as List)
            .whereType<Map>()
            .map(
              (item) => UmkmProduct.fromJson(Map<String, dynamic>.from(item)),
            )
            .toList();
      }

      if (ordersResponse.data is List) {
        _orders = (ordersResponse.data as List)
            .whereType<Map>()
            .map((item) => UmkmOrder.fromJson(Map<String, dynamic>.from(item)))
            .toList();
      }

      if (batchesResponse.data is List) {
        _incomingFarmerBatches = (batchesResponse.data as List)
            .whereType<Map>()
            .map(
              (item) => HarvestBatch.fromJson(Map<String, dynamic>.from(item)),
            )
            .toList();
        _incomingFarmerBatchesLoaded = true;
      }

      if (materialsResponse.data is List) {
        _receivedMaterialBatches = (materialsResponse.data as List)
            .whereType<Map>()
            .map(
              (item) => HarvestBatch.fromJson(Map<String, dynamic>.from(item)),
            )
            .toList();
      }

      _saveToLocal();
      notifyListeners();
    } on BackendApiException catch (_) {
      // cache lokal saja
    } catch (_) {
      // cache lokal saja
    }
  }

  List<UmkmTraceMaterialStock> _materialStocks({required bool availableOnly}) {
    final purchaseByCode = {
      for (final purchase in purchases)
        purchase.qrCodeData.trim().toUpperCase(): purchase,
    };
    final items = <UmkmTraceMaterialStock>[
      ..._materialInventoryStocks(availableOnly: availableOnly),
    ];
    final seenCodes = <String>{};
    for (final item in items) {
      seenCodes.add(item.traceCode.trim().toUpperCase());
    }
    for (final batch in _receivedMaterialBatches) {
      final code = batch.code.trim().toUpperCase();
      if (seenCodes.contains(code)) continue;
      seenCodes.add(code);
      final quantity = batch.receivedQuantity ?? batch.quantity;
      items.add(
        UmkmTraceMaterialStock(
          id: code,
          traceCode: code,
          publicTraceCode: code,
          sourceTraceCodes: const [],
          productName: 'Durian ${batch.variety}',
          supplierName: batch.farmName,
          initialQuantity: quantity,
          remainingQuantity: quantity,
          unit: batch.unit,
          status: TraceBatchStatus.active,
          createdAt: batch.createdAt ?? DateTime.now(),
        ),
      );
    }
    for (final batch in TraceabilityRepository.instance.batches) {
      final code = batch.code.trim().toUpperCase();
      if (seenCodes.contains(code) ||
          batch.productForm == 'processed_product') {
        continue;
      }
      if (availableOnly &&
          (batch.quantityCurrent <= 0 ||
              batch.status != TraceBatchStatus.active)) {
        continue;
      }

      final purchase = purchaseByCode[code];
      final isHeldByUmkm =
          batch.currentHolderRole == TraceActorRole.umkm &&
          (batch.currentHolderId == profile.umkmId ||
              batch.currentHolderName == profile.name);
      if (purchase == null && !isHeldByUmkm) continue;

      final parentCodes = TraceabilityRepository.instance
          .parentsOf(code)
          .map((relation) => relation.sourceBatchCode.trim().toUpperCase())
          .where((parentCode) => parentCode.isNotEmpty)
          .toList();
      final publicTraceCode = code.startsWith('DRN-')
          ? code
          : parentCodes.firstWhere(
              (parentCode) => parentCode.startsWith('DRN-'),
              orElse: () => code,
            );
      seenCodes.add(code);
      items.add(
        UmkmTraceMaterialStock(
          id: purchase?.id ?? code,
          traceCode: code,
          publicTraceCode: publicTraceCode,
          sourceTraceCodes: parentCodes,
          productName: purchase?.productName ?? batch.productName,
          supplierName:
              purchase?.supplierName ??
              (batch.originActorName.isEmpty
                  ? batch.currentHolderName
                  : batch.originActorName),
          initialQuantity: batch.quantityInitial,
          remainingQuantity: batch.quantityCurrent,
          unit: batch.unit,
          status: batch.status,
          createdAt: purchase?.createdAt ?? batch.createdAt,
        ),
      );
    }
    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return List.unmodifiable(items);
  }

  List<UmkmTraceMaterialStock> _materialInventoryStocks({
    required bool availableOnly,
  }) {
    final items = <UmkmTraceMaterialStock>[];
    for (final inventory in _materialInventories ?? <UmkmMaterialInventory>[]) {
      if (availableOnly && !inventory.isAvailable) continue;
      items.add(
        UmkmTraceMaterialStock(
          id: inventory.id,
          traceCode: inventory.traceCode,
          publicTraceCode: inventory.publicTraceCode,
          sourceTraceCodes: inventory.sourceTraceCodes,
          productName: inventory.productName,
          supplierName: inventory.supplierName,
          initialQuantity: inventory.receivedQuantity,
          remainingQuantity: inventory.availableQuantity,
          unit: inventory.unit,
          status: inventory.isAvailable
              ? TraceBatchStatus.active
              : TraceBatchStatus.transformed,
          createdAt: inventory.receivedAt,
        ),
      );
    }
    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return List.unmodifiable(items);
  }

  bool _isValidStockOffers(List<UmkmStockOffer> offers) {
    try {
      for (final offer in offers) {
        if (offer.id.isEmpty ||
            offer.traceCode.isEmpty ||
            offer.name.isEmpty ||
            offer.supplierName.isEmpty ||
            offer.description.isEmpty) {
          return false;
        }
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  List<UmkmAuditEntry> _buildAuditEntries() {
    final entries = <UmkmAuditEntry>[];
    final profileName = profile.name;

    for (final event in TraceabilityRepository.instance.events.where(
      (event) =>
          event.actorRole == TraceActorRole.umkm ||
          event.actorId == profile.umkmId ||
          event.actorName == profileName,
    )) {
      entries.add(
        UmkmAuditEntry(
          id: event.id,
          type: _auditTypeForTraceEvent(event.type),
          title: event.title,
          actorName: event.actorName,
          occurredAt: event.occurredAt,
          referenceCode: event.relatedObjectId,
          batchCode: event.batchCode,
          description: event.description,
          metadata: {
            'Tipe trace': event.type.label,
            if (event.locationLabel != null &&
                event.locationLabel!.trim().isNotEmpty)
              'Lokasi': event.locationLabel!.trim(),
            ...event.metadata,
          },
        ),
      );
    }

    for (final movement in materialMovements) {
      entries.add(
        UmkmAuditEntry(
          id: movement.id,
          type: UmkmAuditEventType.materialMovement,
          title: movement.type.label,
          actorName: movement.actorName,
          occurredAt: movement.occurredAt,
          referenceCode: movement.relatedObjectId,
          batchCode: movement.traceCode,
          description: movement.note,
          metadata: {
            'Jumlah': _formatQuantity(movement.quantity, movement.unit),
          },
        ),
      );
    }

    for (final record in productionRecords) {
      entries.add(
        UmkmAuditEntry(
          id: record.id,
          type: UmkmAuditEventType.production,
          title: 'Produk dibuat',
          actorName: profileName,
          occurredAt: record.producedAt,
          referenceCode: record.productCode,
          batchCode: record.sourceMaterials
              .map((material) => material.traceCode)
              .join(', '),
          description: '${record.productName} / ${record.lotNumber}',
          metadata: {
            'Metode': record.processMethod,
            'Hasil': record.outputLabel,
            'Input': record.inputWeightLabel,
            'Loss/Waste': record.lossWeightLabel,
          },
        ),
      );
    }

    for (final order in orders) {
      entries.add(
        UmkmAuditEntry(
          id: order.id,
          type: order.status == UmkmOrderStatus.selesai
              ? UmkmAuditEventType.sale
              : UmkmAuditEventType.order,
          title: order.status == UmkmOrderStatus.selesai
              ? 'Order selesai'
              : 'Order dibuat',
          actorName: profileName,
          occurredAt: order.completedAt ?? order.createdAt,
          referenceCode: order.id,
          batchCode: order.productCode,
          description: '${order.productName} / ${order.buyerName}',
          metadata: {
            'Jumlah': '${order.quantity} item',
            'Total': order.totalLabel,
            'Status': order.status.label,
            if (order.note != null && order.note!.trim().isNotEmpty)
              'Catatan': order.note!.trim(),
          },
        ),
      );
    }

    for (final receipt in _collectorDeliveryReceipts) {
      final accepted =
          receipt.decision == CollectorDeliveryReceiptDecision.accepted;
      entries.add(
        UmkmAuditEntry(
          id: receipt.id,
          type: accepted
              ? UmkmAuditEventType.receiptAccepted
              : UmkmAuditEventType.receiptRejected,
          title: accepted ? 'Stok diterima' : 'Stok ditolak',
          actorName: receipt.receiverName,
          occurredAt: receipt.checkedAt,
          referenceCode: receipt.id,
          batchCode: receipt.shipmentCode,
          description: accepted
              ? 'Penerimaan dari pengiriman pengepul.'
              : receipt.rejectionReason,
          metadata: {
            'Ekspektasi':
                '${receipt.expectedWeightKg.toStringAsFixed(0)} kg / ${receipt.expectedFruitCount} butir',
            if (receipt.receivedWeightKg != null)
              'Diterima':
                  '${receipt.receivedWeightKg!.toStringAsFixed(0)} kg / ${receipt.receivedFruitCount ?? 0} butir',
            if (receipt.condition != null) 'Kondisi': receipt.condition!.label,
            if (receipt.destinationLocation.trim().isNotEmpty)
              'Lokasi': receipt.destinationLocation.trim(),
          },
        ),
      );
    }

    entries.sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
    return List.unmodifiable(entries);
  }

  UmkmAuditEventType _auditTypeForTraceEvent(TraceEventType type) {
    switch (type) {
      case TraceEventType.handoverReceived:
      case TraceEventType.receiptDisputed:
        return UmkmAuditEventType.receiptAccepted;
      case TraceEventType.handoverCancelled:
      case TraceEventType.lossRecorded:
      case TraceEventType.disposalRecorded:
        return UmkmAuditEventType.receiptRejected;
      case TraceEventType.processed:
        return UmkmAuditEventType.production;
      case TraceEventType.consumerReleased:
        return UmkmAuditEventType.sale;
      case TraceEventType.handoverProposed:
      case TraceEventType.handoverConfirmed:
      case TraceEventType.handoverDispatched:
      case TraceEventType.handoverCompleted:
      case TraceEventType.harvestCreated:
      case TraceEventType.gradingRecorded:
      case TraceEventType.splitCreated:
      case TraceEventType.consolidated:
      case TraceEventType.correctionRecorded:
      case TraceEventType.warehouseTransferred:
        return UmkmAuditEventType.traceEvent;
    }
  }

  String _formatQuantity(double value, String unit) {
    final text = value % 1 == 0
        ? value.toStringAsFixed(0)
        : value.toStringAsFixed(1);
    return '$text $unit';
  }

  Future<bool> updateProfile(UmkmProfile profile) async {
    try {
      await BackendApiClient.instance.put(
        '/umkm/profile',
        body: {
          'name': profile.name,
          'owner_name': profile.ownerName,
          'contact': profile.contact,
          'address': profile.location,
          'village': profile.village,
          'district': profile.district,
          'city': profile.city,
          'province': profile.province,
          'about': profile.about,
          'image_path': profile.imagePath,
        },
      );
      _profile = profile;
      _saveToLocal();
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  UmkmProductionRecord? productionRecordForProduct(String productCode) {
    try {
      return (_productionRecords ?? <UmkmProductionRecord>[]).firstWhere(
        (record) => record.productCode == productCode,
      );
    } catch (_) {
      return null;
    }
  }

  Future<UmkmProduct?> addProduct(
    UmkmProduct product, {
    UmkmProductionRecord? productionRecord,
  }) async {
    BackendApiResponse response;
    try {
      response = await BackendApiClient.instance.post(
        '/umkm/products',
        body: {
          'category': product.category,
          'name': product.name,
          'price_label': product.priceLabel,
          'stock_label': product.stockLabel,
          'description': product.description,
          'status': product.status.name,
          'photo_path': product.imagePath,
          'source_codes': product.sourceMaterials
              .map((material) => material.traceCode.trim())
              .where((code) => code.isNotEmpty)
              .toSet()
              .toList(),
        },
      );
    } on BackendApiException {
      return null;
    }

    if (response.data is! Map) return null;
    final productData = Map<String, dynamic>.from(response.data as Map);
    final responseSources =
        productData['sourceMaterials'] ?? productData['source_materials'];
    if (responseSources is! List || responseSources.isEmpty) {
      productData['sourceMaterials'] = product.sourceMaterials
          .map((material) => material.toJson())
          .toList();
    }
    final savedProduct = UmkmProduct.fromJson(productData);
    final sourceCodes = product.sourceTraceCodes
        .map((code) => code.trim().toUpperCase())
        .toSet();
    _receivedMaterialBatches.removeWhere(
      (batch) => sourceCodes.contains(batch.code.trim().toUpperCase()),
    );
    _productsOrCreate().removeWhere((item) => item.code == savedProduct.code);
    _productsOrCreate().insert(0, savedProduct);
    notifyListeners();
    return savedProduct;
  }

  Future<void> deleteProduct(String productCode) async {
    await BackendApiClient.instance.delete(
      '/umkm/products/${Uri.encodeComponent(productCode)}',
    );
    _productsOrCreate().removeWhere((product) => product.code == productCode);
    final materialsResponse = await BackendApiClient.instance.get(
      '/umkm/material-batches',
    );
    if (materialsResponse.data is! List) {
      throw BackendApiException('Respons daftar bahan baku UMKM tidak valid.');
    }
    _receivedMaterialBatches = (materialsResponse.data as List)
        .whereType<Map>()
        .map((item) => HarvestBatch.fromJson(Map<String, dynamic>.from(item)))
        .toList();
    notifyListeners();
  }

  bool _recordProductProcessing(
    UmkmProduct product, {
    UmkmProductionRecord? productionRecord,
  }) {
    final materials = product.sourceMaterials
        .where(
          (material) =>
              material.traceCode.trim().isNotEmpty && material.quantityKg > 0,
        )
        .toList();
    if (materials.isEmpty) return false;

    final contributions = <TraceLineageContribution>[];
    for (final material in materials) {
      final code = material.traceCode.trim().toUpperCase();
      final sourceBatch = TraceabilityRepository.instance.findBatch(code);
      if (sourceBatch == null || sourceBatch.quantityCurrent <= 0) continue;
      final usableQuantity = material.quantityKg > sourceBatch.quantityCurrent
          ? sourceBatch.quantityCurrent
          : material.quantityKg;
      if (usableQuantity <= 0) continue;
      contributions.add(
        TraceLineageContribution(
          sourceBatchCode: sourceBatch.code,
          quantity: usableQuantity,
          unit: sourceBatch.unit,
          fruitCount: null,
          note: '${material.productName} dari ${material.supplierName}',
        ),
      );
    }
    if (contributions.isEmpty) return false;

    return TraceabilityRepository.instance.recordConsolidatedBatch(
      targetBatchCode: product.code,
      holderId: profile.umkmId,
      holderRole: TraceActorRole.umkm,
      holderName: profile.name,
      contributions: contributions,
      productName: product.name,
      productForm: product.category.toLowerCase() == 'segar'
          ? 'whole_fruit'
          : 'processed_product',
      createdAt: DateTime.now(),
      locationLabel: profile.location,
      relationType: TraceBatchRelationType.processedFrom,
      metadata: {
        'Kategori': product.category,
        'Stok produk': product.stockLabel,
        'QR Produk': product.qrCodeData,
        'Bahan baku': product.sourceMaterialLabel,
        if (productionRecord != null) ...{
          'Lot Produksi': productionRecord.lotNumber,
          'Metode Proses': productionRecord.processMethod,
          'Tanggal Produksi': _formatDateTime(productionRecord.producedAt),
          if (productionRecord.expiryDate != null)
            'Kedaluwarsa': _formatDate(productionRecord.expiryDate!),
          'Hasil Produksi': productionRecord.outputLabel,
          'Input bahan baku': productionRecord.inputWeightLabel,
          'Loss/Waste': productionRecord.lossWeightLabel,
          'Yield': productionRecord.yieldWeightLabel,
          if (productionRecord.note != null &&
              productionRecord.note!.trim().isNotEmpty)
            'Catatan Produksi': productionRecord.note!.trim(),
        },
      },
    );
  }

  void _recordMaterialUsageForProduct(
    UmkmProduct product, {
    UmkmProductionRecord? productionRecord,
  }) {
    for (final material in product.sourceMaterials) {
      final traceCode = material.traceCode.trim().toUpperCase();
      if (traceCode.isEmpty || material.quantityKg <= 0) continue;
      _recordMaterialMovement(
        traceCode: traceCode,
        type: UmkmMaterialMovementType.usedForProduction,
        quantity: material.quantityKg,
        unit: 'kg',
        relatedObjectId: product.code,
        note:
            'Dipakai untuk ${product.name}'
            '${productionRecord == null ? '' : ' / ${productionRecord.lotNumber}'}',
      );
    }
  }

  String _formatDate(DateTime date) {
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
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _formatDateTime(DateTime date) {
    final h = date.hour.toString().padLeft(2, '0');
    final m = date.minute.toString().padLeft(2, '0');
    return '${_formatDate(date)}, $h:$m';
  }

  void addOrder(UmkmOrder order) {
    _ordersOrCreate().insert(0, order);
    _saveToLocal();
    notifyListeners();
  }

  Future<void> updateOrder(UmkmOrder updatedOrder) async {
    final orders = _ordersOrCreate();
    final index = orders.indexWhere((order) => order.id == updatedOrder.id);
    if (index == -1) return;
    final previousOrder = orders[index];

    final response = await BackendApiClient.instance.patch(
      '/umkm/orders/${Uri.encodeComponent(updatedOrder.id)}',
      body: {'status': updatedOrder.status.name},
    );
    if (response.data is! Map) {
      throw BackendApiException('Respons pembaruan pesanan tidak valid.');
    }

    orders[index] = updatedOrder;
    if (previousOrder.status != UmkmOrderStatus.selesai &&
        updatedOrder.status == UmkmOrderStatus.selesai) {
      _recordConsumerReleaseForOrder(updatedOrder);
    }
    _saveToLocal();
    notifyListeners();
  }

  void _recordConsumerReleaseForOrder(UmkmOrder order) {
    final product = _productForOrder(order);
    if (product == null) return;
    final releasedAt = order.completedAt ?? DateTime.now();
    TraceabilityRepository.instance.recordConsumerRelease(
      batchCode: product.code,
      actorId: profile.umkmId,
      actorRole: TraceActorRole.umkm,
      actorName: profile.name,
      orderId: order.id,
      buyerName: order.buyerName,
      quantity: order.quantity,
      releasedAt: releasedAt,
      locationLabel: profile.location,
      note: order.note,
    );
  }

  UmkmProduct? _productForOrder(UmkmOrder order) {
    final cleanProductCode = order.productCode?.trim().toUpperCase();
    if (cleanProductCode != null && cleanProductCode.isNotEmpty) {
      try {
        return products.firstWhere(
          (product) => product.code.trim().toUpperCase() == cleanProductCode,
        );
      } catch (_) {
        // Fallback ke nama produk untuk order lama yang belum menyimpan kode.
      }
    }
    try {
      return products.firstWhere(
        (product) => product.name == order.productName,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> deleteOrder(String orderId) async {
    final orders = _ordersOrCreate();
    final index = orders.indexWhere((order) => order.id == orderId);
    if (index == -1) return;

    await BackendApiClient.instance.delete(
      '/umkm/orders/${Uri.encodeComponent(orderId)}',
    );
    orders.removeAt(index);
    _saveToLocal();
    notifyListeners();
  }

  void addPurchase(UmkmPurchase purchase) {
    _purchasesOrCreate().insert(0, purchase);
    _saveToLocal();
    notifyListeners();
  }

  void _recordMaterialReceived({
    required String traceCode,
    required String productName,
    required String supplierName,
    required double quantity,
    required String unit,
    required DateTime receivedAt,
    String? relatedPurchaseId,
    String? note,
  }) {
    final cleanCode = traceCode.trim().toUpperCase();
    if (cleanCode.isEmpty || quantity <= 0) return;

    final inventories = _materialInventoriesOrCreate();
    final index = inventories.indexWhere(
      (inventory) => inventory.traceCode == cleanCode,
    );
    if (index == -1) {
      inventories.insert(
        0,
        UmkmMaterialInventory(
          id: 'UMKM-INV-${DateTime.now().millisecondsSinceEpoch}',
          traceCode: cleanCode,
          publicTraceCode: _publicTraceCodeFor(cleanCode),
          sourceTraceCodes: _sourceTraceCodesFor(cleanCode),
          productName: productName,
          supplierName: supplierName,
          receivedQuantity: quantity,
          availableQuantity: quantity,
          unit: unit,
          status: UmkmMaterialInventoryStatus.tersedia,
          receivedAt: receivedAt,
          relatedPurchaseId: relatedPurchaseId,
          note: note,
        ),
      );
    } else {
      final current = inventories[index];
      final nextAvailable = current.availableQuantity + quantity;
      inventories[index] = current.copyWith(
        receivedQuantity: current.receivedQuantity + quantity,
        availableQuantity: nextAvailable,
        status: nextAvailable > 0
            ? UmkmMaterialInventoryStatus.tersedia
            : UmkmMaterialInventoryStatus.habis,
        note: note?.trim().isNotEmpty == true ? note : current.note,
      );
    }

    final inventory = inventories.firstWhere(
      (item) => item.traceCode == cleanCode,
    );
    _materialMovementsOrCreate().insert(
      0,
      UmkmMaterialMovement(
        id: 'UMKM-MOV-${DateTime.now().millisecondsSinceEpoch}',
        inventoryId: inventory.id,
        traceCode: cleanCode,
        type: UmkmMaterialMovementType.received,
        quantity: quantity,
        unit: unit,
        occurredAt: receivedAt,
        actorName: profile.name,
        relatedObjectId: relatedPurchaseId,
        note: note,
      ),
    );
  }

  void _recordMaterialMovement({
    required String traceCode,
    required UmkmMaterialMovementType type,
    required double quantity,
    required String unit,
    String? relatedObjectId,
    String? note,
  }) {
    final cleanCode = traceCode.trim().toUpperCase();
    if (cleanCode.isEmpty || quantity <= 0) return;
    final inventories = _materialInventoriesOrCreate();
    final index = inventories.indexWhere(
      (inventory) => inventory.traceCode == cleanCode,
    );
    if (index == -1) return;

    final current = inventories[index];
    final nextAvailable = switch (type) {
      UmkmMaterialMovementType.received => current.availableQuantity + quantity,
      UmkmMaterialMovementType.usedForProduction ||
      UmkmMaterialMovementType.waste => current.availableQuantity - quantity,
      UmkmMaterialMovementType.adjustment => quantity,
    };
    final clampedAvailable = nextAvailable < 0 ? 0.0 : nextAvailable;
    inventories[index] = current.copyWith(
      availableQuantity: clampedAvailable,
      status: clampedAvailable > 0
          ? UmkmMaterialInventoryStatus.tersedia
          : UmkmMaterialInventoryStatus.habis,
    );
    _materialMovementsOrCreate().insert(
      0,
      UmkmMaterialMovement(
        id: 'UMKM-MOV-${DateTime.now().millisecondsSinceEpoch}',
        inventoryId: current.id,
        traceCode: cleanCode,
        type: type,
        quantity: quantity,
        unit: unit,
        occurredAt: DateTime.now(),
        actorName: profile.name,
        relatedObjectId: relatedObjectId,
        note: note,
      ),
    );
  }

  void _ensureMaterialInventoryFromTraceCode(
    String traceCode, {
    required String fallbackProductName,
    required String fallbackSupplierName,
  }) {
    final cleanCode = traceCode.trim().toUpperCase();
    if (cleanCode.isEmpty ||
        (_materialInventories ?? <UmkmMaterialInventory>[]).any(
          (inventory) => inventory.traceCode == cleanCode,
        )) {
      return;
    }
    final batch = TraceabilityRepository.instance.findBatch(cleanCode);
    if (batch == null || batch.productForm == 'processed_product') return;
    _materialInventoriesOrCreate().insert(
      0,
      UmkmMaterialInventory(
        id: 'UMKM-INV-${DateTime.now().millisecondsSinceEpoch}',
        traceCode: cleanCode,
        publicTraceCode: _publicTraceCodeFor(cleanCode),
        sourceTraceCodes: _sourceTraceCodesFor(cleanCode),
        productName: fallbackProductName.isEmpty
            ? batch.productName
            : fallbackProductName,
        supplierName: fallbackSupplierName.isEmpty
            ? batch.originActorName
            : fallbackSupplierName,
        receivedQuantity: batch.quantityInitial,
        availableQuantity: batch.quantityCurrent,
        unit: batch.unit,
        status: batch.quantityCurrent > 0
            ? UmkmMaterialInventoryStatus.tersedia
            : UmkmMaterialInventoryStatus.habis,
        receivedAt: batch.createdAt,
        note: 'Dibentuk dari saldo trace batch lama.',
      ),
    );
  }

  List<String> _sourceTraceCodesFor(String traceCode) {
    return TraceabilityRepository.instance
        .parentsOf(traceCode.trim().toUpperCase())
        .map((relation) => relation.sourceBatchCode.trim().toUpperCase())
        .where((code) => code.isNotEmpty)
        .toList();
  }

  String _publicTraceCodeFor(String traceCode) {
    final cleanCode = traceCode.trim().toUpperCase();
    if (cleanCode.startsWith('DRN-')) return cleanCode;
    return _sourceTraceCodesFor(
      cleanCode,
    ).firstWhere((code) => code.startsWith('DRN-'), orElse: () => cleanCode);
  }

  void addStockOrder(UmkmStockOrder order) {
    _stockOrdersOrCreate().insert(0, order);
    _saveToLocal();
    notifyListeners();
  }

  List<HarvestBatch> get availableFarmerBatches {
    if (_incomingFarmerBatchesLoaded) {
      return List.unmodifiable(
        _incomingFarmerBatches.where(
          (batch) => batch.status == BatchStatus.created,
        ),
      );
    }
    return FarmerRepository.instance.batchesForReceiverVerification(
      role: BatchReceiverRole.umkm,
      userId: profile.umkmId,
    );
  }

  bool get isRefreshingFarmerBatches => _isRefreshingFarmerBatches ?? false;
  String? get farmerBatchesLoadError => _farmerBatchesLoadError;

  Future<void> refreshIncomingFarmerBatches() async {
    _isRefreshingFarmerBatches = true;
    _farmerBatchesLoadError = null;
    notifyListeners();
    try {
      final response = await BackendApiClient.instance.get('/umkm/batches');
      if (response.data is! List) {
        throw BackendApiException(
          'Respons daftar batch petani dari backend tidak valid.',
          statusCode: response.statusCode,
        );
      }
      _incomingFarmerBatches = (response.data as List)
          .whereType<Map>()
          .map((item) => HarvestBatch.fromJson(Map<String, dynamic>.from(item)))
          .toList();
      _incomingFarmerBatchesLoaded = true;
    } catch (error) {
      _farmerBatchesLoadError = error.toString();
      rethrow;
    } finally {
      _isRefreshingFarmerBatches = false;
      notifyListeners();
    }
  }

  HarvestBatch? findFarmerBatch(String code) {
    final cleanCode = code.trim().toUpperCase();
    if (_incomingFarmerBatchesLoaded) {
      for (final batch in _incomingFarmerBatches) {
        if (batch.code.toUpperCase() == cleanCode) return batch;
      }
      return null;
    }
    return FarmerRepository.instance.findBatchForReceiver(
      code: cleanCode,
      role: BatchReceiverRole.umkm,
      userId: profile.umkmId,
    );
  }

  void recordFarmerBatchScan(String code) {
    FarmerRepository.instance.recordBatchQrScan(
      code: code,
      receiverRole: BatchReceiverRole.umkm,
      actorName: profile.name,
      locationLabel: profile.location,
    );
  }

  List<CollectorShipmentBatch> get incomingCollectorShipments {
    final items = CollectorRepository.instance.allShipmentBatches
        .where(
          (shipment) =>
              shipment.destinationType == ShipmentDestinationType.umkm,
        )
        .toList();
    items.sort((a, b) => b.packagedAt.compareTo(a.packagedAt));
    return List.unmodifiable(items);
  }

  CollectorShipmentBatch? findCollectorShipment(String code) {
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

  CollectorDeliveryReceipt? deliveryReceiptForShipment(String shipmentCode) {
    final cleanCode = shipmentCode.trim().toUpperCase();
    try {
      return _collectorDeliveryReceipts.firstWhere(
        (receipt) =>
            receipt.shipmentCode.toUpperCase() == cleanCode &&
            receipt.receiverId == profile.umkmId &&
            receipt.receiverType == ShipmentDestinationType.umkm,
      );
    } catch (_) {
      return null;
    }
  }

  CollectorShipmentBatch? scanCollectorShipment(String code) {
    final shipment = findCollectorShipment(code);
    if (shipment == null) return null;
    if (shipment.status == CollectorShipmentStatus.readyToShip) {
      unawaited(CollectorRepository.instance.markShipmentSent(shipment.code));
      return findCollectorShipment(shipment.code);
    }
    return shipment;
  }

  List<DistributorHorizontalSale> get incomingDistributorSales {
    final items = DistributorRepository.instance.allHorizontalSales
        .where(
          (sale) => sale.status == DistributorHorizontalSaleStatus.initiated,
        )
        .toList();
    items.sort((a, b) => b.initiatedAt.compareTo(a.initiatedAt));
    return List.unmodifiable(items);
  }

  DistributorHorizontalSale? findDistributorSale(String code) {
    return DistributorRepository.instance.findHorizontalSaleByScanCode(code);
  }

  DistributorHorizontalSale? scanDistributorSale(String code) {
    final sale = findDistributorSale(code);
    if (sale == null ||
        sale.status != DistributorHorizontalSaleStatus.initiated) {
      return null;
    }
    return sale;
  }

  bool receiveDistributorSale({
    required String saleId,
    required double receivedWeightKg,
    required int receivedFruitCount,
    required DistributorReceiptCondition condition,
    required String destinationLocation,
    String? discrepancyNote,
    String? qualityNote,
  }) {
    final sale = findDistributorSale(saleId);
    if (sale == null ||
        sale.status != DistributorHorizontalSaleStatus.initiated) {
      return false;
    }

    final ok = DistributorRepository.instance.verifyHorizontalSaleByReceiver(
      saleId: sale.id,
      receiverId: profile.umkmId,
      receiverRole: TraceActorRole.umkm,
      receiverName: profile.name,
      receivedWeightKg: receivedWeightKg,
      receivedFruitCount: receivedFruitCount,
      condition: condition,
      destinationLocation: destinationLocation,
      discrepancyNote: discrepancyNote,
      qualityNote: qualityNote,
    );
    if (!ok) return false;

    final receivedAt = DateTime.now();
    final purchase = UmkmPurchase(
      id: 'PUR-${receivedAt.millisecondsSinceEpoch}',
      supplierName: sale.sellerName,
      productName: 'Durian ${sale.itemCode}',
      quantity: receivedWeightKg.round(),
      totalLabel: '-',
      createdAt: receivedAt,
      qrCodeData: sale.itemCode,
      note: qualityNote?.trim().isEmpty == true ? null : qualityNote?.trim(),
    );
    addPurchase(purchase);
    _recordMaterialReceived(
      traceCode: sale.itemCode,
      productName: purchase.productName,
      supplierName: purchase.supplierName,
      quantity: receivedWeightKg,
      unit: 'kg',
      receivedAt: receivedAt,
      relatedPurchaseId: purchase.id,
      note: purchase.note,
    );
    _saveToLocal();
    notifyListeners();
    return true;
  }

  bool rejectDistributorSale({
    required String saleId,
    required String reason,
    required String destinationLocation,
  }) {
    final sale = findDistributorSale(saleId);
    if (sale == null ||
        sale.status != DistributorHorizontalSaleStatus.initiated) {
      return false;
    }
    final ok = DistributorRepository.instance.rejectHorizontalSaleByReceiver(
      saleId: sale.id,
      receiverId: profile.umkmId,
      receiverRole: TraceActorRole.umkm,
      receiverName: profile.name,
      destinationLocation: destinationLocation,
      note: reason,
    );
    if (ok) {
      _saveToLocal();
      notifyListeners();
    }
    return ok;
  }

  Future<CollectorDeliveryReceipt?> receiveCollectorShipment({
    required String code,
    required double receivedWeightKg,
    required int receivedFruitCount,
    required CollectorDeliveryReceiptCondition condition,
    required String destinationLocation,
    String? discrepancyNote,
    String? qualityNote,
  }) async {
    final cleanCode = code.trim().toUpperCase();
    var shipment = scanCollectorShipment(cleanCode);
    if (shipment == null ||
        shipment.status != CollectorShipmentStatus.sent ||
        receivedWeightKg <= 0 ||
        receivedFruitCount <= 0 ||
        destinationLocation.trim().isEmpty ||
        deliveryReceiptForShipment(cleanCode) != null) {
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
    final completed = await CollectorRepository.instance.completeShipment(
      cleanCode,
      warehouseNote: cleanQualityNote?.isNotEmpty == true
          ? cleanQualityNote
          : 'Diterima dan divalidasi oleh UMKM.',
    );
    if (!completed) return null;
    shipment = findCollectorShipment(cleanCode) ?? shipment;

    final receipt = CollectorDeliveryReceipt(
      id: 'UMKM-RCP-${DateTime.now().millisecondsSinceEpoch}',
      shipmentCode: cleanCode,
      receiverId: profile.umkmId,
      receiverName: profile.name,
      receiverType: ShipmentDestinationType.umkm,
      expectedWeightKg: shipment.totalWeightKg,
      expectedFruitCount: shipment.totalFruitCount,
      receivedWeightKg: receivedWeightKg,
      receivedFruitCount: receivedFruitCount,
      condition: condition,
      decision: CollectorDeliveryReceiptDecision.accepted,
      checkedAt: DateTime.now(),
      destinationLocation: destinationLocation.trim(),
      discrepancyNote: cleanDiscrepancyNote?.isEmpty == true
          ? null
          : cleanDiscrepancyNote,
      qualityNote: cleanQualityNote?.isEmpty == true ? null : cleanQualityNote,
    );
    _collectorDeliveryReceipts.add(receipt);

    TraceabilityRepository.instance.recordReceiptVariance(
      batchCode: shipment.code,
      actorId: profile.umkmId,
      actorRole: TraceActorRole.umkm,
      actorName: profile.name,
      expectedQuantity: shipment.totalWeightKg,
      receivedQuantity: receivedWeightKg,
      unit: 'kg',
      expectedFruitCount: shipment.totalFruitCount,
      receivedFruitCount: receivedFruitCount,
      conditionLabel: condition.label,
      locationLabel: receipt.destinationLocation,
      relatedObjectId: receipt.id,
      note: cleanDiscrepancyNote?.isNotEmpty == true
          ? cleanDiscrepancyNote
          : cleanQualityNote,
    );

    final receivedAt = DateTime.now();
    final purchase = UmkmPurchase(
      id: 'PUR-${receivedAt.millisecondsSinceEpoch}',
      supplierName: 'Pengepul ${shipment.collectorId}',
      productName: 'Durian PGL ${shipment.code}',
      quantity: receivedWeightKg.round(),
      totalLabel: '-',
      createdAt: receivedAt,
      qrCodeData: shipment.code,
      note: cleanQualityNote,
    );
    addPurchase(purchase);
    _recordMaterialReceived(
      traceCode: shipment.code,
      productName: purchase.productName,
      supplierName: purchase.supplierName,
      quantity: receivedWeightKg,
      unit: 'kg',
      receivedAt: receivedAt,
      relatedPurchaseId: purchase.id,
      note: cleanQualityNote,
    );
    _saveToLocal();
    notifyListeners();
    return receipt;
  }

  CollectorDeliveryReceipt? rejectCollectorShipment({
    required String code,
    required String reason,
    required String destinationLocation,
  }) {
    final cleanCode = code.trim().toUpperCase();
    final cleanReason = reason.trim();
    var shipment = scanCollectorShipment(cleanCode);
    if (shipment == null ||
        cleanReason.isEmpty ||
        destinationLocation.trim().isEmpty ||
        deliveryReceiptForShipment(cleanCode) != null) {
      return null;
    }

    final rejected = CollectorRepository.instance.rejectShipment(
      cleanCode,
      reason: cleanReason,
    );
    if (!rejected) return null;
    shipment = findCollectorShipment(cleanCode) ?? shipment;

    final receipt = CollectorDeliveryReceipt(
      id: 'UMKM-RJT-${DateTime.now().millisecondsSinceEpoch}',
      shipmentCode: cleanCode,
      receiverId: profile.umkmId,
      receiverName: profile.name,
      receiverType: ShipmentDestinationType.umkm,
      expectedWeightKg: shipment.totalWeightKg,
      expectedFruitCount: shipment.totalFruitCount,
      decision: CollectorDeliveryReceiptDecision.rejected,
      checkedAt: DateTime.now(),
      destinationLocation: destinationLocation.trim(),
      rejectionReason: cleanReason,
    );
    _collectorDeliveryReceipts.add(receipt);

    TraceabilityRepository.instance.recordReceiptRejection(
      batchCode: shipment.code,
      actorId: profile.umkmId,
      actorRole: TraceActorRole.umkm,
      actorName: profile.name,
      expectedQuantity: shipment.totalWeightKg,
      unit: 'kg',
      expectedFruitCount: shipment.totalFruitCount,
      locationLabel: receipt.destinationLocation,
      relatedObjectId: receipt.id,
      reason: cleanReason,
    );
    _saveToLocal();
    notifyListeners();
    return receipt;
  }

  Future<bool> receiveFarmerBatch({
    required String code,
    required double receivedWeightKg,
    required int receivedFruitCount,
    required String conditionNote,
  }) async {
    final batch = findFarmerBatch(code);
    if (batch == null || batch.status != BatchStatus.created) return false;

    final response = await BackendApiClient.instance.post(
      '/umkm/batches/${Uri.encodeComponent(batch.code)}/receive',
      body: {
        'received_quantity_kg': receivedWeightKg,
        'received_fruit_count': receivedFruitCount,
        'quality_notes': conditionNote,
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
            status: BatchStatus.receivedByUmkm,
            receivedQuantity: receivedWeightKg,
            receivedFruitCount: receivedFruitCount,
            qualityNotes: conditionNote,
            verifiedBy: profile.name,
            verifiedByRole: BatchReceiverRole.umkm,
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
      receiverRole: BatchReceiverRole.umkm,
      receivedQuantity: receivedWeightKg,
      receivedFruitCount: receivedFruitCount,
      gradeBreakdown: [
        BatchGradeBreakdown(
          grade: batch.grade,
          weightKg: receivedWeightKg,
          fruitCount: receivedFruitCount,
        ),
      ],
      qualityNotes: conditionNote,
      receiverName: profile.name,
      receiverUserId: profile.umkmId,
    );

    TraceabilityRepository.instance.recordReceiptVariance(
      batchCode: code,
      actorId: profile.umkmId,
      actorRole: TraceActorRole.umkm,
      actorName: profile.name,
      expectedQuantity: batch.quantity,
      receivedQuantity: receivedWeightKg,
      unit: batch.unit,
      expectedFruitCount: batch.fruitCount,
      receivedFruitCount: receivedFruitCount,
      conditionLabel: conditionNote,
      locationLabel: profile.location,
      relatedObjectId: 'UMKM-DRN-$code',
      note: conditionNote,
    );

    final receivedAt = DateTime.now();
    final purchase = UmkmPurchase(
      id: 'PUR-${receivedAt.millisecondsSinceEpoch}',
      supplierName: 'Petani ${batch.farmerId}',
      productName: 'Durian ${batch.variety}',
      quantity: receivedWeightKg.round(),
      totalLabel: '-',
      createdAt: receivedAt,
      qrCodeData: code,
      note: conditionNote,
    );
    addPurchase(purchase);
    _recordMaterialReceived(
      traceCode: code,
      productName: purchase.productName,
      supplierName: purchase.supplierName,
      quantity: receivedWeightKg,
      unit: batch.unit,
      receivedAt: receivedAt,
      relatedPurchaseId: purchase.id,
      note: conditionNote,
    );
    _saveToLocal();
    notifyListeners();
    return true;
  }

  bool rejectFarmerBatch({required String code, required String reason}) {
    final ok = FarmerRepository.instance.rejectBatchByReceiver(
      code: code,
      reason: reason,
      receiverRole: BatchReceiverRole.umkm,
      rejectedBy: profile.name,
    );
    if (ok) {
      _saveToLocal();
      notifyListeners();
    }
    return ok;
  }

  void updateStockOrder(UmkmStockOrder updatedOrder) {
    final stockOrders = _stockOrdersOrCreate();
    final index = stockOrders.indexWhere(
      (order) => order.id == updatedOrder.id,
    );
    if (index == -1) return;
    stockOrders[index] = updatedOrder;
    _saveToLocal();
    notifyListeners();
  }

  void updateStockOffer(String offerId, UmkmStockOffer updatedOffer) {
    final stockOffers = _stockOffersOrCreate();
    final index = stockOffers.indexWhere((offer) => offer.id == offerId);
    if (index == -1) return;
    stockOffers[index] = updatedOffer;
    _saveToLocal();
    notifyListeners();
  }
}

class UmkmTraceMaterialStock {
  const UmkmTraceMaterialStock({
    required this.id,
    required this.traceCode,
    required this.publicTraceCode,
    required this.sourceTraceCodes,
    required this.productName,
    required this.supplierName,
    required this.initialQuantity,
    required this.remainingQuantity,
    required this.unit,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String traceCode;
  final String publicTraceCode;
  final List<String> sourceTraceCodes;
  final String productName;
  final String supplierName;
  final double initialQuantity;
  final double remainingQuantity;
  final String unit;
  final TraceBatchStatus status;
  final DateTime createdAt;

  double get usedQuantity {
    final used = initialQuantity - remainingQuantity;
    return used < 0 ? 0 : used;
  }

  bool get isAvailable =>
      remainingQuantity > 0 && status == TraceBatchStatus.active;

  String get remainingLabel {
    final value = remainingQuantity % 1 == 0
        ? remainingQuantity.toStringAsFixed(0)
        : remainingQuantity.toStringAsFixed(1);
    return '$value $unit tersisa';
  }

  String get usedLabel {
    final value = usedQuantity % 1 == 0
        ? usedQuantity.toStringAsFixed(0)
        : usedQuantity.toStringAsFixed(1);
    return '$value $unit dipakai';
  }

  String get initialLabel {
    final value = initialQuantity % 1 == 0
        ? initialQuantity.toStringAsFixed(0)
        : initialQuantity.toStringAsFixed(1);
    return '$value $unit awal';
  }

  String get sourceLabel =>
      sourceTraceCodes.isEmpty ? traceCode : sourceTraceCodes.join(', ');
}
