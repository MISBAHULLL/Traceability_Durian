import 'package:flutter/foundation.dart';

import '../models/umkm_order.dart';
import '../models/umkm_product.dart';
import '../models/umkm_profile.dart';
import '../models/umkm_purchase.dart';

class UmkmRepository extends ChangeNotifier {
  UmkmRepository._seed() {
    _profile = const UmkmProfile(
      umkmId: 'umkm-001',
      name: 'UMKM Sari Durian Jember',
      ownerName: 'Ayu Prameswari',
      contact: '+62 812-3456-7890',
      email: 'umkm@example.com',
      location: 'Kabupaten Jember, Jawa Timur',
      about: 'UMKM spesialis durian segar dan olahan khas Jember.',
    );
    _products = _buildSeedProducts();
    _orders = _buildSeedOrders();
    _purchases = _buildSeedPurchases();
  }

  static final UmkmRepository instance = UmkmRepository._seed();

  late UmkmProfile _profile;
  late List<UmkmProduct> _products;
  late List<UmkmOrder> _orders;
  late List<UmkmPurchase> _purchases;

  UmkmProfile get profile => _profile;
  List<UmkmProduct> get products => List.unmodifiable(_products);
  List<UmkmOrder> get orders => List.unmodifiable(_orders);
  List<UmkmPurchase> get purchases => List.unmodifiable(_purchases);

  void updateProfile(UmkmProfile profile) {
    _profile = profile;
    notifyListeners();
  }

  void addProduct(UmkmProduct product) {
    _products.insert(0, product);
    notifyListeners();
  }

  void addOrder(UmkmOrder order) {
    _orders.insert(0, order);
    notifyListeners();
  }

  void updateOrder(UmkmOrder updatedOrder) {
    final index = _orders.indexWhere((order) => order.id == updatedOrder.id);
    if (index == -1) return;
    _orders[index] = updatedOrder;
    notifyListeners();
  }

  void addPurchase(UmkmPurchase purchase) {
    _purchases.insert(0, purchase);
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
}
