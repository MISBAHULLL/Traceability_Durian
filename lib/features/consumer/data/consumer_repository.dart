import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/network/backend_api_client.dart';
import '../../../core/storage/local_storage_service.dart';
import '../../collector/data/collector_repository.dart';
import '../../collector/models/collector_delivery_receipt.dart';
import '../../collector/models/collector_shipment_batch.dart';
import '../../farmer/data/farmer_repository.dart';
import '../../traceability/data/traceability_repository.dart';
import '../../traceability/models/traceability_models.dart';
import '../../umkm/data/umkm_repository.dart';
import '../../umkm/models/umkm_order.dart';
import '../../umkm/models/umkm_product.dart';
import '../models/consumer_audit_entry.dart';
import '../models/consumer_product.dart';
import '../models/consumer_transaction.dart';

/// Repository data konsumen yang disinkronkan dengan backend.
class ConsumerRepository extends ChangeNotifier {
  ConsumerRepository._() {
    _loadFromLocal();
    UmkmRepository.instance.addListener(_onCatalogChanged);
    TraceabilityRepository.instance.addListener(_onCatalogChanged);
    unawaited(refreshFromBackend());
  }

  static final ConsumerRepository instance = ConsumerRepository._();

  late String _currentConsumerId;
  late ConsumerProfile _profile;
  late List<ConsumerProduct> _products;
  List<ConsumerTransaction>? _transactions;
  late List<CollectorDeliveryReceipt> _collectorDeliveryReceipts;
  late List<ConsumerAuditEntry> _auditLogs;

  static const _currentConsumerIdKey = 'consumer_current_id';
  static const _profileKey = 'consumer_profile';
  static const _collectorDeliveryReceiptsKey =
      'consumer_collector_delivery_receipts';
  static const _transactionsKey = 'consumer_transactions';
  static const _auditLogsKey = 'consumer_audit_logs';

  void _onCatalogChanged() {
    _syncTransactionsFromUmkmOrders();
    notifyListeners();
  }

  void _syncTransactionsFromUmkmOrders() {
    final transactions = _transactions;
    if (transactions == null || transactions.isEmpty) return;

    var changed = false;
    final umkmOrders = UmkmRepository.instance.orders;
    for (var i = 0; i < transactions.length; i++) {
      final transaction = transactions[i];
      if (transaction.status == ConsumerTransactionStatus.completed) continue;
      final matchingOrders = umkmOrders.where(
        (order) => order.id == transaction.id,
      );
      if (matchingOrders.isEmpty) continue;
      final order = matchingOrders.first;
      if (order.status != UmkmOrderStatus.selesai) continue;
      transactions[i] = transaction.copyWith(
        status: ConsumerTransactionStatus.completed,
        paymentStatus: ConsumerPaymentStatus.paid,
        note: order.note ?? transaction.note,
      );
      _recordAudit(
        type: ConsumerAuditEventType.orderCompleted,
        title: 'Order selesai',
        referenceCode: order.id,
        batchCode: order.productCode,
        description: '${order.productName} diterima konsumen.',
        metadata: {
          'Produk': order.productName,
          'Jumlah': '${order.quantity} pcs',
          'Total': order.totalLabel,
        },
        save: false,
      );
      changed = true;
    }

    if (changed) {
      _saveToLocal();
    }
  }

  void _loadFromLocal() {
    _currentConsumerId = '';
    _profile = ConsumerProfile.fromJson(const <String, dynamic>{});
    _products = <ConsumerProduct>[];
    _transactions = <ConsumerTransaction>[];
    _collectorDeliveryReceipts = <CollectorDeliveryReceipt>[];
    _auditLogs = <ConsumerAuditEntry>[];
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
        continue;
      }
    }
    return items;
  }

  void _saveToLocal() {
    return;
  }

  Future<void> refreshFromBackend() async {
    try {
      final profileResponse = await BackendApiClient.instance.get(
        '/consumer/profile',
      );
      final productsResponse = await BackendApiClient.instance.get(
        '/consumer/products',
      );
      final transactionsResponse = await BackendApiClient.instance.get(
        '/consumer/transactions',
      );

      if (profileResponse.data is Map) {
        final data = Map<String, dynamic>.from(profileResponse.data as Map);
        final user = Map<String, dynamic>.from(
          data['user'] as Map? ?? const {},
        );
        final profile = Map<String, dynamic>.from(
          data['profile'] as Map? ?? const {},
        );
        _profile = ConsumerProfile.fromJson({
          'consumerId':
              user['id']?.toString() ??
              profile['user_id']?.toString() ??
              _profile.consumerId,
          'fullName':
              profile['display_name'] ??
              user['full_name'] ??
              '${user['first_name'] ?? ''} ${user['last_name'] ?? ''}'.trim(),
          'roleLabel': 'Konsumen Durian',
          'contact': profile['phone'] ?? user['phone'] ?? '',
          'email': user['email'] ?? '',
          'location': profile['address'] ?? '',
          'village': profile['village'] ?? '',
          'district': profile['district'] ?? '',
          'city': profile['city'] ?? '',
          'province': profile['province'] ?? '',
          'avatarPath': profile['avatar_path'],
        });
      }

      if (productsResponse.data is List) {
        _products = (productsResponse.data as List)
            .whereType<Map>()
            .map(
              (item) =>
                  ConsumerProduct.fromJson(Map<String, dynamic>.from(item)),
            )
            .toList();
      }

      if (transactionsResponse.data is List) {
        _transactions = (transactionsResponse.data as List)
            .whereType<Map>()
            .map(
              (item) =>
                  ConsumerTransaction.fromJson(Map<String, dynamic>.from(item)),
            )
            .toList();
      }

      _currentConsumerId = _profile.consumerId;
      _saveToLocal();
      notifyListeners();
    } on BackendApiException catch (_) {
      // Gunakan cache lokal jika backend belum tersedia.
    } catch (_) {
      // Gunakan cache lokal jika backend belum tersedia.
    }
  }

  ConsumerProfile get profile => _profile;

  List<ConsumerProduct> get products {
    final realProducts = _buildProductsFromUmkm();
    final source = realProducts.isEmpty ? _products : realProducts;
    return List.unmodifiable(
      source
          .where(
            (product) => product.status == ConsumerProductStatus.readyToSell,
          )
          .toList(),
    );
  }

  List<ConsumerProduct> _buildProductsFromUmkm() {
    final umkmRepo = UmkmRepository.instance;
    return umkmRepo.products
        .where((product) => product.status == UmkmProductStatus.aktif)
        .map((product) => _consumerProductFromUmkm(product, umkmRepo))
        .toList();
  }

  ConsumerProduct _consumerProductFromUmkm(
    UmkmProduct product,
    UmkmRepository umkmRepo,
  ) {
    final sourceCode = _preferredSourceCode(product);
    final sourceBatch = sourceCode == null
        ? null
        : FarmerRepository.instance.findPublicBatch(sourceCode);
    final traceBatch = TraceabilityRepository.instance.findBatch(product.code);
    return ConsumerProduct(
      code: product.code,
      name: product.name,
      category: _consumerCategoryFor(product.category),
      status: product.status == UmkmProductStatus.aktif
          ? ConsumerProductStatus.readyToSell
          : ConsumerProductStatus.soldOut,
      priceLabel: product.priceLabel,
      shortDescription: product.description,
      umkmName: umkmRepo.profile.name,
      location:
          traceBatch?.publicLocationLabel ??
          traceBatch?.locationLabel ??
          umkmRepo.profile.location,
      rating: 4.8,
      stockLabel: product.stockLabel,
      sourceBatchCode: sourceCode ?? product.code,
      sourceVariety: sourceBatch?.variety,
      sourceGrade: sourceBatch?.grade,
      sourceOriginFarm: sourceBatch?.farmName,
      sourceHarvestDate: sourceBatch?.harvestDate,
      sourceHarvestMethod: sourceBatch?.harvestMethod,
      sourceMaturityLevel: sourceBatch?.maturityLevel,
      sourceShelfLifeEstimate: sourceBatch?.shelfLifeEstimate,
      sourceVerifiedBy: sourceBatch?.verifiedBy,
      sourceVerifiedAt: sourceBatch?.verifiedAt,
      sourceReceivedQuantity: sourceBatch?.receivedQuantity,
      sourceReceivedFruitCount: sourceBatch?.receivedFruitCount,
      sourceQualityNotes: sourceBatch?.qualityNotes,
      sourceNotes: sourceBatch?.notes,
      imagePath: product.imagePath,
    );
  }

  String? _preferredSourceCode(UmkmProduct product) {
    if (product.sourceTraceCodes.isEmpty) return product.code;
    return product.sourceTraceCodes.firstWhere(
      (code) => code.startsWith('DRN-'),
      orElse: () => product.sourceTraceCodes.first,
    );
  }

  ConsumerProductCategory _consumerCategoryFor(String category) {
    switch (category.trim().toLowerCase()) {
      case 'segar':
        return ConsumerProductCategory.segar;
      case 'minuman':
        return ConsumerProductCategory.minuman;
      case 'paket':
        return ConsumerProductCategory.paket;
      default:
        return ConsumerProductCategory.olahan;
    }
  }

  List<ConsumerTransaction> get transactions {
    final items = List<ConsumerTransaction>.from(
      _transactions ?? <ConsumerTransaction>[],
    );
    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return List.unmodifiable(items);
  }

  int get processingTransactionCount =>
      (_transactions ?? <ConsumerTransaction>[])
          .where((item) => item.status == ConsumerTransactionStatus.processing)
          .length;

  int get completedTransactionCount =>
      (_transactions ?? <ConsumerTransaction>[])
          .where((item) => item.status == ConsumerTransactionStatus.completed)
          .length;

  List<ConsumerAuditEntry> get auditEntries {
    final entries = <ConsumerAuditEntry>[..._auditLogs];
    final existingKeys = entries
        .map(
          (entry) =>
              '${entry.type.name}|${entry.referenceCode ?? ''}|${entry.batchCode ?? ''}',
        )
        .toSet();

    void addDerived(ConsumerAuditEntry entry) {
      final key =
          '${entry.type.name}|${entry.referenceCode ?? ''}|${entry.batchCode ?? ''}';
      if (existingKeys.contains(key)) return;
      existingKeys.add(key);
      entries.add(entry);
    }

    for (final transaction in _transactions ?? <ConsumerTransaction>[]) {
      addDerived(
        ConsumerAuditEntry(
          id: 'AUD-DER-TRX-${transaction.id}',
          type: ConsumerAuditEventType.transactionCreated,
          title: 'Transaksi dibuat',
          actorName: profile.fullName,
          occurredAt: transaction.createdAt,
          referenceCode: transaction.id,
          batchCode: transaction.product.code,
          description: transaction.product.name,
          metadata: {
            'Produk': transaction.product.name,
            'UMKM': transaction.product.umkmName,
            'Jumlah': '${transaction.quantity} pcs',
            'Total': transaction.totalLabel,
            'Pembayaran': transaction.paymentMethod,
            'Status bayar': transaction.effectivePaymentStatus.label,
          },
        ),
      );
      if (transaction.effectivePaymentStatus == ConsumerPaymentStatus.paid) {
        addDerived(
          ConsumerAuditEntry(
            id: 'AUD-DER-PAY-${transaction.id}',
            type: ConsumerAuditEventType.paymentVerified,
            title: 'Pembayaran terverifikasi',
            actorName: profile.fullName,
            occurredAt: transaction.createdAt,
            referenceCode: transaction.id,
            batchCode: transaction.product.code,
            description: 'Order siap diproses UMKM.',
            metadata: {
              'Produk': transaction.product.name,
              'Metode': transaction.paymentMethod,
              'Total': transaction.totalLabel,
            },
          ),
        );
      }
      if (transaction.status == ConsumerTransactionStatus.completed) {
        addDerived(
          ConsumerAuditEntry(
            id: 'AUD-DER-DONE-${transaction.id}',
            type: ConsumerAuditEventType.orderCompleted,
            title: 'Order selesai',
            actorName: profile.fullName,
            occurredAt: transaction.createdAt,
            referenceCode: transaction.id,
            batchCode: transaction.product.code,
            description: '${transaction.product.name} selesai diterima.',
            metadata: {
              'Produk': transaction.product.name,
              'Jumlah': '${transaction.quantity} pcs',
              'Total': transaction.totalLabel,
            },
          ),
        );
      }
    }

    for (final receipt in _collectorDeliveryReceipts) {
      final accepted =
          receipt.decision == CollectorDeliveryReceiptDecision.accepted;
      addDerived(
        ConsumerAuditEntry(
          id: 'AUD-DER-RCP-${receipt.id}',
          type: accepted
              ? ConsumerAuditEventType.receiptAccepted
              : ConsumerAuditEventType.receiptRejected,
          title: accepted ? 'Pengiriman diterima' : 'Pengiriman ditolak',
          actorName: receipt.receiverName,
          occurredAt: receipt.checkedAt,
          referenceCode: receipt.id,
          batchCode: receipt.shipmentCode,
          description: accepted
              ? 'PGL diterima dan divalidasi konsumen.'
              : receipt.rejectionReason,
          metadata: {
            'PGL': receipt.shipmentCode,
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

  void recordScanAudit({
    required String code,
    required bool success,
    required String title,
    String? batchCode,
    String? description,
  }) async {
    _recordAudit(
      type: ConsumerAuditEventType.scan,
      title: title,
      referenceCode: code.trim().toUpperCase(),
      batchCode: batchCode?.trim().toUpperCase(),
      description: description,
      metadata: {'Hasil': success ? 'Berhasil' : 'Gagal'},
      dedupe: false,
    );
  }

  void _recordAudit({
    required ConsumerAuditEventType type,
    required String title,
    String? referenceCode,
    String? batchCode,
    String? description,
    Map<String, String> metadata = const {},
    bool save = true,
    bool dedupe = true,
  }) {
    final cleanReference = referenceCode?.trim();
    final cleanBatch = batchCode?.trim();
    if (dedupe) {
      final exists = _auditLogs.any(
        (entry) =>
            entry.type == type &&
            entry.referenceCode == cleanReference &&
            entry.batchCode == cleanBatch,
      );
      if (exists) return;
    }
    _auditLogs.insert(
      0,
      ConsumerAuditEntry(
        id: 'CON-AUD-${DateTime.now().millisecondsSinceEpoch}-${_auditLogs.length + 1}',
        type: type,
        title: title,
        actorName: profile.fullName,
        occurredAt: DateTime.now(),
        referenceCode: cleanReference?.isEmpty == true ? null : cleanReference,
        batchCode: cleanBatch?.isEmpty == true ? null : cleanBatch,
        description: description,
        metadata: metadata,
      ),
    );
    if (save) {
      _saveToLocal();
      notifyListeners();
    }
  }

  List<ConsumerProduct> filteredProducts(
    ConsumerProductFilter filter,
    String query,
  ) {
    final q = query.trim().toLowerCase();
    return products.where((product) {
      final matchFilter =
          filter == ConsumerProductFilter.semua ||
          product.category.label.toLowerCase() == filter.label.toLowerCase();
      final matchQuery =
          q.isEmpty ||
          product.code.toLowerCase().contains(q) ||
          product.name.toLowerCase().contains(q) ||
          product.umkmName.toLowerCase().contains(q);
      return matchFilter && matchQuery;
    }).toList();
  }

  ConsumerProduct? findProduct(String code) {
    try {
      return products.firstWhere((product) => product.code == code);
    } catch (_) {
      return null;
    }
  }

  List<CollectorShipmentBatch> get incomingCollectorShipments {
    final items = CollectorRepository.instance.allShipmentBatches
        .where(
          (shipment) =>
              shipment.destinationType == ShipmentDestinationType.consumer,
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
            receipt.receiverId == profile.consumerId &&
            receipt.receiverType == ShipmentDestinationType.consumer,
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
          : 'Diterima dan divalidasi oleh konsumen.',
    );
    if (!completed) return null;
    shipment = findCollectorShipment(cleanCode) ?? shipment;

    final receipt = CollectorDeliveryReceipt(
      id: 'CON-RCP-${DateTime.now().millisecondsSinceEpoch}',
      shipmentCode: cleanCode,
      receiverId: profile.consumerId,
      receiverName: profile.fullName,
      receiverType: ShipmentDestinationType.consumer,
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
    _recordAudit(
      type: ConsumerAuditEventType.receiptAccepted,
      title: 'Pengiriman diterima',
      referenceCode: receipt.id,
      batchCode: receipt.shipmentCode,
      description: 'PGL diterima dan divalidasi konsumen.',
      metadata: {
        'Ekspektasi':
            '${receipt.expectedWeightKg.toStringAsFixed(0)} kg / ${receipt.expectedFruitCount} butir',
        'Diterima':
            '${receivedWeightKg.toStringAsFixed(0)} kg / $receivedFruitCount butir',
        'Kondisi': condition.label,
        'Lokasi': receipt.destinationLocation,
      },
      save: false,
    );

    TraceabilityRepository.instance.recordReceiptVariance(
      batchCode: shipment.code,
      actorId: profile.consumerId,
      actorRole: TraceActorRole.consumer,
      actorName: profile.fullName,
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
      id: 'CON-RJT-${DateTime.now().millisecondsSinceEpoch}',
      shipmentCode: cleanCode,
      receiverId: profile.consumerId,
      receiverName: profile.fullName,
      receiverType: ShipmentDestinationType.consumer,
      expectedWeightKg: shipment.totalWeightKg,
      expectedFruitCount: shipment.totalFruitCount,
      decision: CollectorDeliveryReceiptDecision.rejected,
      checkedAt: DateTime.now(),
      destinationLocation: destinationLocation.trim(),
      rejectionReason: cleanReason,
    );
    _collectorDeliveryReceipts.add(receipt);
    _recordAudit(
      type: ConsumerAuditEventType.receiptRejected,
      title: 'Pengiriman ditolak',
      referenceCode: receipt.id,
      batchCode: receipt.shipmentCode,
      description: cleanReason,
      metadata: {
        'Ekspektasi':
            '${receipt.expectedWeightKg.toStringAsFixed(0)} kg / ${receipt.expectedFruitCount} butir',
        'Lokasi': receipt.destinationLocation,
        'Alasan': cleanReason,
      },
      save: false,
    );

    TraceabilityRepository.instance.recordReceiptRejection(
      batchCode: shipment.code,
      actorId: profile.consumerId,
      actorRole: TraceActorRole.consumer,
      actorName: profile.fullName,
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

  Future<ConsumerTransaction?> addTransaction(
    ConsumerProduct product, {
    required int quantity,
    required String buyerAddress,
    required String buyerCoordinates,
    required String paymentMethod,
    ConsumerPaymentStatus paymentStatus = ConsumerPaymentStatus.unpaid,
    String? bankName,
    String? accountNumber,
    String? note,
  }) async {
    final now = DateTime.now();
    BackendApiResponse response;
    try {
      response = await BackendApiClient.instance.post(
        '/consumer/transactions',
        body: {
          'product_code': product.code,
          'quantity': quantity,
          'buyer_address': buyerAddress,
          'buyer_coordinates': buyerCoordinates,
          'payment_method': paymentMethod,
          'payment_status': paymentStatus.name,
          'bank_name': bankName,
          'account_number': accountNumber,
          'note': note,
        },
      );
    } on BackendApiException {
      return null;
    }
    final payload = response.data is Map
        ? Map<String, dynamic>.from(response.data as Map)
        : const <String, dynamic>{};
    final transactions = _transactions ??= <ConsumerTransaction>[];
    final id = backendString(payload, const ['id', 'code']);
    if (id.isEmpty) return null;
    final transaction = ConsumerTransaction(
      id: id,
      product: product,
      status: ConsumerTransactionStatus.values.firstWhere(
        (status) => status.name == backendString(payload, const ['status']),
        orElse: () => ConsumerTransactionStatus.processing,
      ),
      quantity: quantity,
      totalLabel: product.priceLabel,
      createdAt: now,
      buyerAddress: buyerAddress,
      buyerCoordinates: buyerCoordinates,
      paymentMethod: paymentMethod,
      paymentStatus: ConsumerPaymentStatus.values.firstWhere(
        (status) =>
            status.name == backendString(payload, const ['payment_status']),
        orElse: () => paymentStatus,
      ),
      qrCodeData: backendString(payload, const ['qr_code_data'], id),
      bankName: bankName,
      accountNumber: accountNumber,
      note: note,
    );
    transactions.add(transaction);
    _recordAudit(
      type: ConsumerAuditEventType.transactionCreated,
      title: 'Transaksi dibuat',
      referenceCode: transaction.id,
      batchCode: product.code,
      description: product.name,
      metadata: {
        'Produk': product.name,
        'UMKM': product.umkmName,
        'Jumlah': '$quantity pcs',
        'Total': product.priceLabel,
        'Pembayaran': paymentMethod,
        'Status bayar': transaction.effectivePaymentStatus.label,
      },
      save: false,
    );
    notifyListeners();
    return transaction;
  }

  ConsumerTransaction? findTransaction(String id) {
    final cleanId = id.trim().toUpperCase();
    if (cleanId.isEmpty) return null;
    try {
      return (_transactions ?? <ConsumerTransaction>[]).firstWhere(
        (transaction) => transaction.id.toUpperCase() == cleanId,
      );
    } catch (_) {
      return null;
    }
  }

  ConsumerTransaction? confirmPayment(String transactionId) {
    final current = findTransaction(transactionId);
    if (current == null ||
        current.paymentMethod == 'Cash on Delivery' ||
        current.effectivePaymentStatus != ConsumerPaymentStatus.unpaid) {
      return null;
    }
    final updated = _updatePaymentStatus(
      transactionId,
      paymentStatus: ConsumerPaymentStatus.processing,
      note: 'Pembayaran dikonfirmasi konsumen, menunggu verifikasi.',
    );
    if (updated != null) {
      _recordAudit(
        type: ConsumerAuditEventType.paymentConfirmed,
        title: 'Pembayaran dikonfirmasi',
        referenceCode: updated.id,
        batchCode: updated.product.code,
        description: 'Menunggu verifikasi pembayaran.',
        metadata: {
          'Produk': updated.product.name,
          'Metode': updated.paymentMethod,
          'Total': updated.totalLabel,
        },
      );
    }
    return updated;
  }

  ConsumerTransaction? verifyPayment(String transactionId) {
    final current = findTransaction(transactionId);
    if (current == null ||
        current.paymentMethod == 'Cash on Delivery' ||
        current.effectivePaymentStatus != ConsumerPaymentStatus.processing) {
      return null;
    }
    final transaction = _updatePaymentStatus(
      transactionId,
      paymentStatus: ConsumerPaymentStatus.paid,
      note: 'Pembayaran terverifikasi, order dikirim ke UMKM.',
    );
    if (transaction != null) {
      _recordAudit(
        type: ConsumerAuditEventType.paymentVerified,
        title: 'Pembayaran terverifikasi',
        referenceCode: transaction.id,
        batchCode: transaction.product.code,
        description: 'Order diteruskan ke UMKM.',
        metadata: {
          'Produk': transaction.product.name,
          'Metode': transaction.paymentMethod,
          'Total': transaction.totalLabel,
        },
      );
      _createUmkmOrderForTransaction(transaction);
    }
    return transaction;
  }

  ConsumerTransaction? _updatePaymentStatus(
    String transactionId, {
    required ConsumerPaymentStatus paymentStatus,
    required String note,
  }) {
    final transactions = _transactions;
    if (transactions == null || transactions.isEmpty) return null;
    final cleanId = transactionId.trim().toUpperCase();
    final index = transactions.indexWhere(
      (transaction) => transaction.id.toUpperCase() == cleanId,
    );
    if (index == -1) return null;
    final current = transactions[index];
    final updated = current.copyWith(paymentStatus: paymentStatus, note: note);
    transactions[index] = updated;
    _saveToLocal();
    notifyListeners();
    return updated;
  }

  bool _canCreateUmkmOrderFromTransaction(ConsumerTransaction transaction) {
    return transaction.effectivePaymentStatus == ConsumerPaymentStatus.paid ||
        transaction.paymentMethod == 'Cash on Delivery';
  }

  void _createUmkmOrderForTransaction(ConsumerTransaction transaction) {
    final umkmRepo = UmkmRepository.instance;
    final hasExistingOrder = umkmRepo.orders.any(
      (order) => order.id == transaction.id,
    );
    if (hasExistingOrder) return;

    umkmRepo.addOrder(
      UmkmOrder(
        id: transaction.id,
        productName: transaction.product.name,
        buyerName: profile.fullName,
        quantity: transaction.quantity,
        totalLabel: transaction.totalLabel,
        status: UmkmOrderStatus.diproses,
        createdAt: transaction.createdAt,
        qrCodeData: transaction.qrCodeData,
        productCode: transaction.product.code,
        note: _orderNoteForTransaction(transaction),
      ),
    );
  }

  String _orderNoteForTransaction(ConsumerTransaction transaction) {
    final parts = <String>[
      'Dibuat dari transaksi konsumen ${transaction.id}.',
      if (transaction.buyerAddress.trim().isNotEmpty)
        'Alamat: ${transaction.buyerAddress.trim()}',
      if (transaction.buyerCoordinates.trim().isNotEmpty)
        'Koordinat: ${transaction.buyerCoordinates.trim()}',
      'Pembayaran: ${transaction.paymentMethod} (${transaction.effectivePaymentStatus.label})',
      if (transaction.note != null && transaction.note!.trim().isNotEmpty)
        transaction.note!.trim(),
    ];
    return parts.join(' ');
  }

  ConsumerProfile registerConsumer({
    required String firstName,
    required String lastName,
    String phone = '',
    String email = '',
    String roleLabel = 'Konsumen Durian',
    String village = '',
    String district = '',
    String city = '',
    String province = '',
  }) {
    final id = 'consumer-${DateTime.now().millisecondsSinceEpoch}';
    final fullName = '$firstName $lastName'.trim();
    final profile = ConsumerProfile(
      consumerId: id,
      fullName: fullName.isEmpty ? 'Konsumen' : fullName,
      roleLabel: roleLabel,
      contact: phone.isEmpty ? '' : '+62 $phone',
      email: email.trim(),
      location: [
        village,
        district,
        city,
        province,
      ].map((part) => part.trim()).where((part) => part.isNotEmpty).join(', '),
      village: village.trim(),
      district: district.trim(),
      city: city.trim(),
      province: province.trim(),
    );

    _currentConsumerId = id;
    _profile = profile;
    _saveToLocal();
    notifyListeners();
    return profile;
  }

  Future<ConsumerProfile> updateProfile({
    required String fullName,
    required String contact,
    required String email,
    required String location,
    required String village,
    required String district,
    required String city,
    required String province,
  }) async {
    final normalizedLocation = [
      village.trim(),
      district.trim(),
      city.trim(),
      province.trim(),
    ].where((value) => value.isNotEmpty).join(', ');
    _profile = _profile.copyWith(
      fullName: fullName.trim(),
      contact: contact.trim(),
      email: email.trim(),
      location: normalizedLocation.isEmpty
          ? location.trim()
          : normalizedLocation,
      village: village.trim(),
      district: district.trim(),
      city: city.trim(),
      province: province.trim(),
    );
    _saveToLocal();
    notifyListeners();
    try {
      await BackendApiClient.instance.put(
        '/consumer/profile',
        body: {
          'full_name': _profile.fullName,
          'phone': _profile.contact,
          'email': _profile.email,
          'address': _profile.location,
          'village': _profile.village,
          'district': _profile.district,
          'city': _profile.city,
          'province': _profile.province,
        },
      );
    } on BackendApiException {
      // Local state remains available when the backend is temporarily offline.
    }
    return _profile;
  }

  void updateAvatar(String? path) {
    _profile = _profile.copyWith(avatarPath: path);
    _saveToLocal();
    notifyListeners();
  }

  void logout() {
    _saveToLocal();
    notifyListeners();
  }
}
