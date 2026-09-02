import 'package:flutter/foundation.dart';

import '../../../core/storage/local_storage_service.dart';
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
  UmkmRepository._seed() {
    _loadFromLocal();
  }

  static final UmkmRepository instance = UmkmRepository._seed();

  static const UmkmProfile _seedProfile = UmkmProfile(
    umkmId: 'umkm-001',
    name: 'UMKM Sari Durian Jember',
    ownerName: 'Ayu Prameswari',
    contact: '+62 812-3456-7890',
    email: 'umkm@example.com',
    location: 'Kabupaten Jember, Jawa Timur',
    about: 'UMKM spesialis durian segar dan olahan khas Jember.',
    imagePath: null,
    imageBytes: null,
  );

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

  static const _profileKey = 'umkm_profile';
  static const _productsKey = 'umkm_products';
  static const _ordersKey = 'umkm_orders';
  static const _purchasesKey = 'umkm_purchases';
  static const _materialInventoriesKey = 'umkm_material_inventories';
  static const _materialMovementsKey = 'umkm_material_movements';
  static const _productionRecordsKey = 'umkm_production_records';
  static const _stockOffersKey = 'umkm_stock_offers';
  static const _stockOrdersKey = 'umkm_stock_orders';
  static const _collectorDeliveryReceiptsKey =
      'umkm_collector_delivery_receipts';

  UmkmProfile get profile => _profile ??= _seedProfile;
  List<UmkmProduct> get products =>
      List.unmodifiable(_products ??= _buildSeedProducts());
  List<UmkmOrder> get orders =>
      List.unmodifiable(_orders ??= _buildSeedOrders());
  List<UmkmPurchase> get purchases =>
      List.unmodifiable(_purchases ??= _buildSeedPurchases());
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
    final offers = _stockOffers ??= _buildSeedStockOffers();
    if (!_isValidStockOffers(offers)) {
      _stockOffers = _buildSeedStockOffers();
    }
    return List.unmodifiable(_stockOffers!);
  }

  List<UmkmStockOrder> get stockOrders =>
      List.unmodifiable(_stockOrders ??= _buildSeedStockOrders());

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
    _profile = _loadObject(_profileKey, UmkmProfile.fromJson) ?? _seedProfile;
    _products = _loadList(_productsKey, UmkmProduct.fromJson);
    _orders = _loadList(_ordersKey, UmkmOrder.fromJson);
    _purchases = _loadList(_purchasesKey, UmkmPurchase.fromJson);
    _materialInventories = _loadList(
      _materialInventoriesKey,
      UmkmMaterialInventory.fromJson,
    );
    _materialMovements = _loadList(
      _materialMovementsKey,
      UmkmMaterialMovement.fromJson,
    );
    _productionRecords = _loadList(
      _productionRecordsKey,
      UmkmProductionRecord.fromJson,
    );
    _stockOffers = _loadList(_stockOffersKey, UmkmStockOffer.fromJson);
    _stockOrders = _loadList(_stockOrdersKey, UmkmStockOrder.fromJson);
    _collectorDeliveryReceipts
      ..clear()
      ..addAll(
        _loadList(
              _collectorDeliveryReceiptsKey,
              CollectorDeliveryReceipt.fromJson,
            ) ??
            const <CollectorDeliveryReceipt>[],
      );
  }

  T? _loadObject<T>(
    String key,
    T Function(Map<String, dynamic> json) fromJson,
  ) {
    final json = LocalStorageService.loadJson(key);
    if (json == null) return null;
    try {
      return fromJson(json);
    } catch (_) {
      return null;
    }
  }

  List<T>? _loadList<T>(
    String key,
    T Function(Map<String, dynamic> json) fromJson,
  ) {
    final raw = LocalStorageService.loadJsonList(key);
    if (raw == null) return null;
    final items = <T>[];
    for (final item in raw) {
      try {
        items.add(fromJson(item));
      } catch (_) {
        return null;
      }
    }
    return items;
  }

  void _saveToLocal() {
    LocalStorageService.saveJson(_profileKey, profile.toJson());
    LocalStorageService.saveJsonList(
      _productsKey,
      products.map((item) => item.toJson()).toList(),
    );
    LocalStorageService.saveJsonList(
      _ordersKey,
      orders.map((item) => item.toJson()).toList(),
    );
    LocalStorageService.saveJsonList(
      _purchasesKey,
      purchases.map((item) => item.toJson()).toList(),
    );
    LocalStorageService.saveJsonList(
      _materialInventoriesKey,
      materialInventories.map((item) => item.toJson()).toList(),
    );
    LocalStorageService.saveJsonList(
      _materialMovementsKey,
      materialMovements.map((item) => item.toJson()).toList(),
    );
    LocalStorageService.saveJsonList(
      _productionRecordsKey,
      productionRecords.map((item) => item.toJson()).toList(),
    );
    LocalStorageService.saveJsonList(
      _stockOffersKey,
      stockOffers.map((item) => item.toJson()).toList(),
    );
    LocalStorageService.saveJsonList(
      _stockOrdersKey,
      stockOrders.map((item) => item.toJson()).toList(),
    );
    LocalStorageService.saveJsonList(
      _collectorDeliveryReceiptsKey,
      _collectorDeliveryReceipts.map((item) => item.toJson()).toList(),
    );
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

  void updateProfile(UmkmProfile profile) {
    _profile = profile;
    _saveToLocal();
    notifyListeners();
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

  void addProduct(
    UmkmProduct product, {
    UmkmProductionRecord? productionRecord,
  }) {
    _productsOrCreate().insert(0, product);
    if (productionRecord != null) {
      _productionRecordsOrCreate().insert(0, productionRecord);
    }
    for (final material in product.sourceMaterials) {
      _ensureMaterialInventoryFromTraceCode(
        material.traceCode,
        fallbackProductName: material.productName,
        fallbackSupplierName: material.supplierName,
      );
    }
    final processingRecorded = _recordProductProcessing(
      product,
      productionRecord: productionRecord,
    );
    if (processingRecorded) {
      _recordMaterialUsageForProduct(
        product,
        productionRecord: productionRecord,
      );
    }
    _saveToLocal();
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

  void updateOrder(UmkmOrder updatedOrder) {
    final orders = _ordersOrCreate();
    final index = orders.indexWhere((order) => order.id == updatedOrder.id);
    if (index == -1) return;
    final previousOrder = orders[index];
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

  void deleteOrder(String orderId) {
    final orders = _ordersOrCreate();
    final beforeLength = orders.length;
    orders.removeWhere((order) => order.id == orderId);
    if (orders.length == beforeLength) return;
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

  List<HarvestBatch> get availableFarmerBatches =>
      FarmerRepository.instance.batchesForCollectorVerification;

  HarvestBatch? findFarmerBatch(String code) {
    return FarmerRepository.instance.findPublicBatch(code);
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
      CollectorRepository.instance.markShipmentSent(shipment.code);
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

  CollectorDeliveryReceipt? receiveCollectorShipment({
    required String code,
    required double receivedWeightKg,
    required int receivedFruitCount,
    required CollectorDeliveryReceiptCondition condition,
    required String destinationLocation,
    String? discrepancyNote,
    String? qualityNote,
  }) {
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
    final completed = CollectorRepository.instance.completeShipment(
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

  bool receiveFarmerBatch({
    required String code,
    required double receivedWeightKg,
    required int receivedFruitCount,
    required String conditionNote,
  }) {
    final batch = FarmerRepository.instance.findPublicBatch(code);
    if (batch == null || batch.status != BatchStatus.created) return false;

    final ok = FarmerRepository.instance.verifyBatchByReceiver(
      code: code,
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
    );
    if (!ok) return false;

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

  List<UmkmProduct> _buildSeedProducts() {
    return const [
      UmkmProduct(
        id: 'p-001',
        code: 'UMKM-P-001',
        name: 'Pancake Durian Premium',
        category: 'Olahan',
        priceLabel: 'Rp 68.000',
        stockLabel: 'Stok 24 paket',
        description: 'Pancake durian lembut dengan isian krim khas UMKM.',
        status: UmkmProductStatus.aktif,
        qrCodeData: 'UMKM-P-001',
        imagePath: 'assets/images/durian.png',
      ),
      UmkmProduct(
        id: 'p-002',
        code: 'UMKM-P-002',
        name: 'Dodol Durian Lembut',
        category: 'Olahan',
        priceLabel: 'Rp 42.000',
        stockLabel: 'Stok 36 bungkus',
        description: 'Dodol legit durian untuk oleh-oleh khas Jember.',
        status: UmkmProductStatus.aktif,
        qrCodeData: 'UMKM-P-002',
        imagePath: 'assets/images/durian.png',
      ),
    ];
  }

  List<UmkmOrder> _buildSeedOrders() {
    return [
      UmkmOrder(
        id: 'ORD-2026-0001',
        productName: 'Pancake Durian Premium',
        buyerName: 'Rina Saputri',
        quantity: 2,
        totalLabel: 'Rp 136.000',
        status: UmkmOrderStatus.diproses,
        createdAt: DateTime(2026, 6, 10, 10, 30),
        qrCodeData: 'ORD-2026-0001',
        productCode: 'UMKM-P-001',
        note: 'Bayar di tempat.',
      ),
      UmkmOrder(
        id: 'ORD-2026-0002',
        productName: 'Dodol Durian Lembut',
        buyerName: 'Budi Santoso',
        quantity: 3,
        totalLabel: 'Rp 126.000',
        status: UmkmOrderStatus.selesai,
        createdAt: DateTime(2026, 6, 8, 15, 45),
        qrCodeData: 'ORD-2026-0002',
        productCode: 'UMKM-P-002',
        completedAt: DateTime(2026, 6, 8, 16, 20),
        note: 'Sudah dikirim.',
      ),
    ];
  }

  List<UmkmPurchase> _buildSeedPurchases() {
    return [
      UmkmPurchase(
        id: 'PUR-2026-0001',
        supplierName: 'Pengepul Durian Jaya',
        productName: 'Durian Segar 10 kg',
        quantity: 10,
        totalLabel: 'Rp 1.250.000',
        createdAt: DateTime(2026, 6, 9, 13, 0),
        qrCodeData: 'PUR-2026-0001',
        note: 'Ambil besok pagi.',
      ),
    ];
  }

  List<UmkmStockOffer> _buildSeedStockOffers() {
    return [
      UmkmStockOffer(
        id: 'SO-001',
        traceCode: 'TRACE-SO-001',
        name: 'Durian Montong Grade A',
        supplierName: 'Pengepul Durian Jaya',
        supplierType: UmkmSupplierType.pengepul,
        pricePerKg: 52000,
        stockKg: 120,
        description: 'Durian segar pilihan untuk olahan dan jual ulang.',
        status: UmkmStockOfferStatus.aktif,
        createdAt: DateTime(2026, 6, 11, 9, 30),
        imagePath: 'assets/images/durian.png',
      ),
      UmkmStockOffer(
        id: 'SO-002',
        traceCode: 'TRACE-SO-002',
        name: 'Durian Kupas Premium',
        supplierName: 'CV Nusantara Fresh',
        supplierType: UmkmSupplierType.distributor,
        pricePerKg: 68000,
        stockKg: 80,
        description:
            'Sudah disortir, cocok untuk produksi pancake dan dessert.',
        status: UmkmStockOfferStatus.aktif,
        createdAt: DateTime(2026, 6, 11, 10, 0),
        imagePath: 'assets/images/durian.png',
      ),
      UmkmStockOffer(
        id: 'SO-003',
        traceCode: 'TRACE-SO-003',
        name: 'Durian Musang King Lokal',
        supplierName: 'Petani Muda Jember',
        supplierType: UmkmSupplierType.petani,
        pricePerKg: 74000,
        stockKg: 56,
        description: 'Panen kebun langsung dengan aroma kuat dan daging tebal.',
        status: UmkmStockOfferStatus.aktif,
        createdAt: DateTime(2026, 6, 11, 11, 0),
        imagePath: 'assets/images/durian.png',
      ),
      UmkmStockOffer(
        id: 'SO-004',
        traceCode: 'TRACE-SO-004',
        name: 'Durian Kuning Manis',
        supplierName: 'Pengepul Durian Jaya',
        supplierType: UmkmSupplierType.pengepul,
        pricePerKg: 48000,
        stockKg: 0,
        description: 'Stok habis sementara, menunggu kiriman berikutnya.',
        status: UmkmStockOfferStatus.habis,
        createdAt: DateTime(2026, 6, 9, 8, 15),
        imagePath: 'assets/images/durian.png',
      ),
    ];
  }

  List<UmkmStockOrder> _buildSeedStockOrders() {
    return [
      UmkmStockOrder(
        id: 'SPO-2026-0002',
        offerId: 'SO-003',
        offerName: 'Durian Musang King Lokal',
        supplierName: 'Petani Muda Jember',
        supplierType: UmkmSupplierType.petani,
        traceCode: 'TRACE-SO-003',
        quantityKg: 12,
        pricePerKg: 74000,
        totalAmount: 888000,
        paymentMethod: UmkmStockPaymentMethod.transfer,
        status: UmkmStockOrderStatus.diproses,
        createdAt: DateTime(2026, 6, 12, 9, 45),
        bankName: 'BCA',
        accountNumber: '1234567890',
        note: 'Kirim siang.',
      ),
      UmkmStockOrder(
        id: 'SPO-2026-0001',
        offerId: 'SO-002',
        offerName: 'Durian Kupas Premium',
        supplierName: 'CV Nusantara Fresh',
        supplierType: UmkmSupplierType.distributor,
        traceCode: 'TRACE-SO-002',
        quantityKg: 8,
        pricePerKg: 68000,
        totalAmount: 544000,
        paymentMethod: UmkmStockPaymentMethod.cod,
        status: UmkmStockOrderStatus.selesai,
        createdAt: DateTime(2026, 6, 10, 14, 20),
        note: 'Sudah diterima.',
      ),
    ];
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
