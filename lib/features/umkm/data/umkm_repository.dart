import 'package:flutter/foundation.dart';

import '../../farmer/data/farmer_repository.dart';
import '../../farmer/models/harvest_batch.dart';
import '../models/umkm_order.dart';
import '../models/umkm_product.dart';
import '../models/umkm_profile.dart';
import '../models/umkm_purchase.dart';
import '../models/umkm_stock_offer.dart';
import '../models/umkm_stock_order.dart';

class UmkmRepository extends ChangeNotifier {
  UmkmRepository._seed() {
    _profile = _seedProfile;
    _products = _buildSeedProducts();
    _orders = _buildSeedOrders();
    _purchases = _buildSeedPurchases();
    _stockOffers = _buildSeedStockOffers();
    _stockOrders = _buildSeedStockOrders();
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
  List<UmkmStockOffer>? _stockOffers;
  List<UmkmStockOrder>? _stockOrders;

  UmkmProfile get profile => _profile ??= _seedProfile;
  List<UmkmProduct> get products =>
      List.unmodifiable(_products ??= _buildSeedProducts());
  List<UmkmOrder> get orders =>
      List.unmodifiable(_orders ??= _buildSeedOrders());
  List<UmkmPurchase> get purchases =>
      List.unmodifiable(_purchases ??= _buildSeedPurchases());
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
  List<UmkmStockOffer> _stockOffersOrCreate() =>
      _stockOffers ??= <UmkmStockOffer>[];
  List<UmkmStockOrder> _stockOrdersOrCreate() =>
      _stockOrders ??= <UmkmStockOrder>[];

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

  void updateProfile(UmkmProfile profile) {
    _profile = profile;
    notifyListeners();
  }

  void addProduct(UmkmProduct product) {
    _productsOrCreate().insert(0, product);
    notifyListeners();
  }

  void addOrder(UmkmOrder order) {
    _ordersOrCreate().insert(0, order);
    notifyListeners();
  }

  void updateOrder(UmkmOrder updatedOrder) {
    final orders = _ordersOrCreate();
    final index = orders.indexWhere((order) => order.id == updatedOrder.id);
    if (index == -1) return;
    orders[index] = updatedOrder;
    notifyListeners();
  }

  void deleteOrder(String orderId) {
    final orders = _ordersOrCreate();
    final beforeLength = orders.length;
    orders.removeWhere((order) => order.id == orderId);
    if (orders.length == beforeLength) return;
    notifyListeners();
  }

  void addPurchase(UmkmPurchase purchase) {
    _purchasesOrCreate().insert(0, purchase);
    notifyListeners();
  }

  void addStockOrder(UmkmStockOrder order) {
    _stockOrdersOrCreate().insert(0, order);
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

    addPurchase(
      UmkmPurchase(
        id: 'PUR-${DateTime.now().millisecondsSinceEpoch}',
        supplierName: 'Petani ${batch.farmerId}',
        productName: 'Durian ${batch.variety}',
        quantity: receivedWeightKg.round(),
        totalLabel: '-',
        createdAt: DateTime.now(),
        qrCodeData: code,
        note: conditionNote,
      ),
    );
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
    if (ok) notifyListeners();
    return ok;
  }

  void updateStockOrder(UmkmStockOrder updatedOrder) {
    final stockOrders = _stockOrdersOrCreate();
    final index = stockOrders.indexWhere(
      (order) => order.id == updatedOrder.id,
    );
    if (index == -1) return;
    stockOrders[index] = updatedOrder;
    notifyListeners();
  }

  void updateStockOffer(String offerId, UmkmStockOffer updatedOffer) {
    final stockOffers = _stockOffersOrCreate();
    final index = stockOffers.indexWhere((offer) => offer.id == offerId);
    if (index == -1) return;
    stockOffers[index] = updatedOffer;
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
