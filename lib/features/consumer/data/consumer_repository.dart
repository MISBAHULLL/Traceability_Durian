import 'package:flutter/foundation.dart';

import '../../../core/storage/local_storage_service.dart';
import '../../collector/data/collector_repository.dart';
import '../../collector/models/collector_delivery_receipt.dart';
import '../../collector/models/collector_shipment_batch.dart';
import '../../farmer/data/farmer_repository.dart';
import '../../farmer/models/harvest_batch.dart';
import '../../traceability/data/traceability_repository.dart';
import '../../traceability/models/traceability_models.dart';
import '../models/consumer_product.dart';
import '../models/consumer_transaction.dart';

/// Repository ringan untuk data konsumen.
///
/// Berisi profil mock yang bertahan lewat SharedPreferences serta daftar
/// produk UMKM seed yang ditampilkan di beranda.
class ConsumerRepository extends ChangeNotifier {
  ConsumerRepository._seed() {
    _loadFromLocal();
    _products = _buildSeedProducts();
    _transactions = _buildSeedTransactions(_products);
  }

  static final ConsumerRepository instance = ConsumerRepository._seed();

  static const String _kSeedConsumerId = 'consumer-001';

  static const ConsumerProfile _kSeedProfile = ConsumerProfile(
    consumerId: _kSeedConsumerId,
    fullName: 'Ayu Prameswari',
    roleLabel: 'Konsumen Durian',
    contact: '081234567890',
    email: 'konsumen@example.com',
    location: 'Kota Surabaya',
  );

  late String _currentConsumerId;
  late ConsumerProfile _profile;
  late List<ConsumerProduct> _products;
  late List<ConsumerTransaction> _transactions;
  late List<CollectorDeliveryReceipt> _collectorDeliveryReceipts;

  void _loadFromLocal() {
    _currentConsumerId =
        LocalStorageService.loadString('consumer_current_id') ??
        _kSeedConsumerId;

    final profileJson = LocalStorageService.loadJson('consumer_profile');
    if (profileJson != null) {
      _profile = ConsumerProfile.fromJson(profileJson);
    } else {
      _profile = _kSeedProfile;
    }

    final deliveryReceiptsJson = LocalStorageService.loadJsonList(
      'consumer_collector_delivery_receipts',
    );
    _collectorDeliveryReceipts = deliveryReceiptsJson == null
        ? <CollectorDeliveryReceipt>[]
        : deliveryReceiptsJson
              .map((json) => CollectorDeliveryReceipt.fromJson(json))
              .toList();
  }

  void _saveToLocal() {
    LocalStorageService.saveString('consumer_current_id', _currentConsumerId);
    LocalStorageService.saveJson('consumer_profile', _profile.toJson());
    LocalStorageService.saveJsonList(
      'consumer_collector_delivery_receipts',
      _collectorDeliveryReceipts.map((item) => item.toJson()).toList(),
    );
  }

  static List<ConsumerProduct> _buildSeedProducts() {
    final farmerRepo = FarmerRepository.instance;
    HarvestBatch? source(String code) => farmerRepo.findPublicBatch(code);

    return [
      ConsumerProduct(
        code: 'UMKM-001',
        name: 'Pancake Durian Premium',
        category: ConsumerProductCategory.paket,
        status: ConsumerProductStatus.readyToSell,
        priceLabel: 'Rp 68.000',
        shortDescription:
            'Paket isi 4 potong dengan isian durian lembut dan kulit tipis.',
        umkmName: 'UMKM Sari Durian Jember',
        location: 'Kabupaten Jember, Jawa Timur',
        rating: 4.9,
        stockLabel: 'Stok 24 paket',
        sourceBatchCode: 'DRN-2026-000119',
        sourceVariety: source('DRN-2026-000119')?.variety,
        sourceGrade: source('DRN-2026-000119')?.grade,
        sourceOriginFarm: source('DRN-2026-000119')?.farmName,
        sourceHarvestDate: source('DRN-2026-000119')?.harvestDate,
        sourceHarvestMethod: source('DRN-2026-000119')?.harvestMethod,
        sourceMaturityLevel: source('DRN-2026-000119')?.maturityLevel,
        sourceShelfLifeEstimate: source('DRN-2026-000119')?.shelfLifeEstimate,
        sourceVerifiedBy: source('DRN-2026-000119')?.verifiedBy,
        sourceVerifiedAt: source('DRN-2026-000119')?.verifiedAt,
        sourceReceivedQuantity: source('DRN-2026-000119')?.receivedQuantity,
        sourceReceivedFruitCount: source('DRN-2026-000119')?.receivedFruitCount,
        sourceQualityNotes: source('DRN-2026-000119')?.qualityNotes,
        sourceNotes: source('DRN-2026-000119')?.notes,
      ),
      ConsumerProduct(
        code: 'UMKM-002',
        name: 'Dodol Durian Lembut',
        category: ConsumerProductCategory.olahan,
        status: ConsumerProductStatus.readyToSell,
        priceLabel: 'Rp 42.000',
        shortDescription:
            'Olahan legit dengan tekstur kenyal, cocok untuk oleh-oleh.',
        umkmName: 'UMKM Manis Jaya',
        location: 'Kabupaten Jember, Jawa Timur',
        rating: 4.8,
        stockLabel: 'Stok 36 bungkus',
        sourceBatchCode: 'DRN-2026-000103',
        sourceVariety: source('DRN-2026-000103')?.variety,
        sourceGrade: source('DRN-2026-000103')?.grade,
        sourceOriginFarm: source('DRN-2026-000103')?.farmName,
        sourceHarvestDate: source('DRN-2026-000103')?.harvestDate,
        sourceHarvestMethod: source('DRN-2026-000103')?.harvestMethod,
        sourceMaturityLevel: source('DRN-2026-000103')?.maturityLevel,
        sourceShelfLifeEstimate: source('DRN-2026-000103')?.shelfLifeEstimate,
        sourceVerifiedBy: source('DRN-2026-000103')?.verifiedBy,
        sourceVerifiedAt: source('DRN-2026-000103')?.verifiedAt,
        sourceReceivedQuantity: source('DRN-2026-000103')?.receivedQuantity,
        sourceReceivedFruitCount: source('DRN-2026-000103')?.receivedFruitCount,
        sourceQualityNotes: source('DRN-2026-000103')?.qualityNotes,
        sourceNotes: source('DRN-2026-000103')?.notes,
      ),
      ConsumerProduct(
        code: 'UMKM-003',
        name: 'Es Krim Durian Cup',
        category: ConsumerProductCategory.minuman,
        status: ConsumerProductStatus.readyToSell,
        priceLabel: 'Rp 22.000',
        shortDescription:
            'Dessert dingin dengan rasa durian yang lembut dan segar.',
        umkmName: 'UMKM Dingin Segar',
        location: 'Kabupaten Jember, Jawa Timur',
        rating: 4.7,
        stockLabel: 'Stok 18 cup',
        sourceBatchCode: 'DRN-2026-000097',
        sourceVariety: source('DRN-2026-000097')?.variety,
        sourceGrade: source('DRN-2026-000097')?.grade,
        sourceOriginFarm: source('DRN-2026-000097')?.farmName,
        sourceHarvestDate: source('DRN-2026-000097')?.harvestDate,
        sourceHarvestMethod: source('DRN-2026-000097')?.harvestMethod,
        sourceMaturityLevel: source('DRN-2026-000097')?.maturityLevel,
        sourceShelfLifeEstimate: source('DRN-2026-000097')?.shelfLifeEstimate,
        sourceVerifiedBy: source('DRN-2026-000097')?.verifiedBy,
        sourceVerifiedAt: source('DRN-2026-000097')?.verifiedAt,
        sourceReceivedQuantity: source('DRN-2026-000097')?.receivedQuantity,
        sourceReceivedFruitCount: source('DRN-2026-000097')?.receivedFruitCount,
        sourceQualityNotes: source('DRN-2026-000097')?.qualityNotes,
        sourceNotes: source('DRN-2026-000097')?.notes,
      ),
      ConsumerProduct(
        code: 'UMKM-004',
        name: 'Durian Kupas Fresh Pack',
        category: ConsumerProductCategory.segar,
        status: ConsumerProductStatus.readyToSell,
        priceLabel: 'Rp 95.000',
        shortDescription:
            'Daging durian kupas pilihan, siap santap dan dikirim cepat.',
        umkmName: 'UMKM Segar Pagi',
        location: 'Kabupaten Jember, Jawa Timur',
        rating: 4.9,
        stockLabel: 'Stok 12 pack',
        sourceBatchCode: 'DRN-2026-000128',
        sourceVariety: source('DRN-2026-000128')?.variety,
        sourceGrade: source('DRN-2026-000128')?.grade,
        sourceOriginFarm: source('DRN-2026-000128')?.farmName,
        sourceHarvestDate: source('DRN-2026-000128')?.harvestDate,
        sourceHarvestMethod: source('DRN-2026-000128')?.harvestMethod,
        sourceMaturityLevel: source('DRN-2026-000128')?.maturityLevel,
        sourceShelfLifeEstimate: source('DRN-2026-000128')?.shelfLifeEstimate,
        sourceVerifiedBy: source('DRN-2026-000128')?.verifiedBy,
        sourceVerifiedAt: source('DRN-2026-000128')?.verifiedAt,
        sourceReceivedQuantity: source('DRN-2026-000128')?.receivedQuantity,
        sourceReceivedFruitCount: source('DRN-2026-000128')?.receivedFruitCount,
        sourceQualityNotes: source('DRN-2026-000128')?.qualityNotes,
        sourceNotes: source('DRN-2026-000128')?.notes,
      ),
    ];
  }

  static List<ConsumerTransaction> _buildSeedTransactions(
    List<ConsumerProduct> products,
  ) {
    final readyProducts = products
        .where((product) => product.status == ConsumerProductStatus.readyToSell)
        .toList();
    if (readyProducts.length < 2) return const [];

    return [
      ConsumerTransaction(
        id: 'TRX-2026-0001',
        product: readyProducts[0],
        status: ConsumerTransactionStatus.processing,
        quantity: 1,
        totalLabel: readyProducts[0].priceLabel,
        createdAt: DateTime(2026, 6, 10, 14, 20),
        buyerAddress: 'Desa Pakis, Kec. Panti, Kab. Jember',
        buyerCoordinates: '-8.2285, 113.6204',
        paymentMethod: 'QRIS',
        paymentStatus: ConsumerPaymentStatus.unpaid,
        qrCodeData: 'TRX-2026-0001',
        note: 'Menunggu pembayaran dari konsumen.',
      ),
      ConsumerTransaction(
        id: 'TRX-2026-0002',
        product: readyProducts[1],
        status: ConsumerTransactionStatus.processing,
        quantity: 2,
        totalLabel: 'Rp 84.000',
        createdAt: DateTime(2026, 6, 8, 10, 15),
        buyerAddress: 'Gg. Melati, Jl. A. Yani, Kota Surabaya',
        buyerCoordinates: '-7.2575, 112.7521',
        paymentMethod: 'Transfer Bank',
        paymentStatus: ConsumerPaymentStatus.processing,
        qrCodeData: 'TRX-2026-0002',
        bankName: 'BNI',
        accountNumber: '9876543210',
        note: 'Menunggu konfirmasi UMKM.',
      ),
      ConsumerTransaction(
        id: 'TRX-2026-0003',
        product: readyProducts[0],
        status: ConsumerTransactionStatus.completed,
        quantity: 2,
        totalLabel: 'Rp 136.000',
        createdAt: DateTime(2026, 6, 6, 9, 45),
        buyerAddress: 'Perumahan Tegal Besar, Jember',
        buyerCoordinates: '-8.1834, 113.7002',
        paymentMethod: 'Cash on Delivery',
        paymentStatus: ConsumerPaymentStatus.paid,
        qrCodeData: 'TRX-2026-0003',
        note: 'Pesanan sudah selesai.',
      ),
    ];
  }

  ConsumerProfile get profile => _profile;

  List<ConsumerProduct> get products => List.unmodifiable(
    _products
        .where((product) => product.status == ConsumerProductStatus.readyToSell)
        .toList(),
  );

  List<ConsumerTransaction> get transactions {
    final items = List<ConsumerTransaction>.from(_transactions);
    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return List.unmodifiable(items);
  }

  int get processingTransactionCount => _transactions
      .where((item) => item.status == ConsumerTransactionStatus.processing)
      .length;

  int get completedTransactionCount => _transactions
      .where((item) => item.status == ConsumerTransactionStatus.completed)
      .length;

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
      CollectorRepository.instance.markShipmentSent(shipment.code);
      return findCollectorShipment(shipment.code);
    }
    return shipment;
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

  ConsumerTransaction addTransaction(
    ConsumerProduct product, {
    required int quantity,
    required String buyerAddress,
    required String buyerCoordinates,
    required String paymentMethod,
    ConsumerPaymentStatus paymentStatus = ConsumerPaymentStatus.unpaid,
    String? bankName,
    String? accountNumber,
    String? note,
  }) {
    final now = DateTime.now();
    final id =
        'TRX-${now.year}-${(_transactions.length + 1).toString().padLeft(4, '0')}';
    final transaction = ConsumerTransaction(
      id: id,
      product: product,
      status: ConsumerTransactionStatus.processing,
      quantity: quantity,
      totalLabel: product.priceLabel,
      createdAt: now,
      buyerAddress: buyerAddress,
      buyerCoordinates: buyerCoordinates,
      paymentMethod: paymentMethod,
      paymentStatus: paymentStatus,
      qrCodeData: id,
      bankName: bankName,
      accountNumber: accountNumber,
      note: note,
    );
    _transactions.add(transaction);
    notifyListeners();
    return transaction;
  }

  ConsumerProfile registerConsumer({
    required String firstName,
    required String lastName,
    String phone = '',
    String email = '',
    String roleLabel = 'Konsumen Durian',
  }) {
    final id = 'consumer-${DateTime.now().millisecondsSinceEpoch}';
    final fullName = '$firstName $lastName'.trim();
    final profile = ConsumerProfile(
      consumerId: id,
      fullName: fullName.isEmpty ? 'Konsumen' : fullName,
      roleLabel: roleLabel,
      contact: phone.isEmpty ? '' : '+62 $phone',
      email: email.trim(),
    );

    _currentConsumerId = id;
    _profile = profile;
    _saveToLocal();
    notifyListeners();
    return profile;
  }

  ConsumerProfile updateProfile({
    required String fullName,
    required String contact,
    required String email,
    required String location,
  }) {
    _profile = _profile.copyWith(
      fullName: fullName.trim(),
      contact: contact.trim(),
      email: email.trim(),
      location: location.trim(),
    );
    _saveToLocal();
    notifyListeners();
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
