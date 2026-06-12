import 'package:flutter/foundation.dart';

import '../../../core/storage/local_storage_service.dart';
import '../../farmer/data/farmer_repository.dart';
import '../../farmer/models/harvest_batch.dart';
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
  }

  void _saveToLocal() {
    LocalStorageService.saveString('consumer_current_id', _currentConsumerId);
    LocalStorageService.saveJson('consumer_profile', _profile.toJson());
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
          sourceShelfLifeEstimate:
              source('DRN-2026-000119')?.shelfLifeEstimate,
          sourceVerifiedBy: source('DRN-2026-000119')?.verifiedBy,
          sourceVerifiedAt: source('DRN-2026-000119')?.verifiedAt,
          sourceReceivedQuantity: source('DRN-2026-000119')?.receivedQuantity,
          sourceReceivedFruitCount:
              source('DRN-2026-000119')?.receivedFruitCount,
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
          sourceShelfLifeEstimate:
              source('DRN-2026-000103')?.shelfLifeEstimate,
          sourceVerifiedBy: source('DRN-2026-000103')?.verifiedBy,
          sourceVerifiedAt: source('DRN-2026-000103')?.verifiedAt,
          sourceReceivedQuantity: source('DRN-2026-000103')?.receivedQuantity,
          sourceReceivedFruitCount:
              source('DRN-2026-000103')?.receivedFruitCount,
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
          sourceShelfLifeEstimate:
              source('DRN-2026-000097')?.shelfLifeEstimate,
          sourceVerifiedBy: source('DRN-2026-000097')?.verifiedBy,
          sourceVerifiedAt: source('DRN-2026-000097')?.verifiedAt,
          sourceReceivedQuantity: source('DRN-2026-000097')?.receivedQuantity,
          sourceReceivedFruitCount:
              source('DRN-2026-000097')?.receivedFruitCount,
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
          sourceShelfLifeEstimate:
              source('DRN-2026-000128')?.shelfLifeEstimate,
          sourceVerifiedBy: source('DRN-2026-000128')?.verifiedBy,
          sourceVerifiedAt: source('DRN-2026-000128')?.verifiedAt,
          sourceReceivedQuantity: source('DRN-2026-000128')?.receivedQuantity,
          sourceReceivedFruitCount:
              source('DRN-2026-000128')?.receivedFruitCount,
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
        paymentMethod: 'Transfer Bank',
        qrCodeData: 'TRX-2026-0001',
        note: 'Menunggu konfirmasi UMKM.',
      ),
      ConsumerTransaction(
        id: 'TRX-2026-0002',
        product: readyProducts[1],
        status: ConsumerTransactionStatus.completed,
        quantity: 2,
        totalLabel: 'Rp 84.000',
        createdAt: DateTime(2026, 6, 8, 10, 15),
        buyerAddress: 'Gg. Melati, Jl. A. Yani, Kota Surabaya',
        buyerCoordinates: '-7.2575, 112.7521',
        paymentMethod: 'Cash on Delivery',
        qrCodeData: 'TRX-2026-0002',
        note: 'Pesanan sudah selesai.',
      ),
    ];
  }

  ConsumerProfile get profile => _profile;

  List<ConsumerProduct> get products => List.unmodifiable(
        _products
            .where((product) =>
                product.status == ConsumerProductStatus.readyToSell)
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
      final matchQuery = q.isEmpty ||
          product.code.toLowerCase().contains(q) ||
          product.name.toLowerCase().contains(q) ||
          product.umkmName.toLowerCase().contains(q);
      return matchFilter && matchQuery;
    }).toList();
  }

  ConsumerProduct? findProduct(String code) {
    try {
      return products.firstWhere(
        (product) =>
            product.code == code,
      );
    } catch (_) {
      return null;
    }
  }

  ConsumerTransaction addTransaction(
    ConsumerProduct product, {
    required int quantity,
    required String buyerAddress,
    required String buyerCoordinates,
    required String paymentMethod,
    String? note,
  }) {
    final now = DateTime.now();
    final id = 'TRX-${now.year}-${(_transactions.length + 1).toString().padLeft(4, '0')}';
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
      qrCodeData: id,
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
