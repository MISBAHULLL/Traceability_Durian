import 'package:flutter/foundation.dart';

import '../models/collector_product.dart';

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
    _currentCollectorId = _kSeedCollectorId;
    _profile = _kSeedProfile;
    _products = _buildSeedProducts();
  }

  // ── Konstanta seed ─────────────────────────────────────────────────────────

  static const String _kSeedCollectorId = 'collector-001';

  static const CollectorProfile _kSeedProfile = CollectorProfile(
    collectorId: _kSeedCollectorId,
    fullName: 'Risqi Firdaus Setiawan',
    roleLabel: 'Pengepul Durian',
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
          fleshDescription: 'Berwarna kuning keemasan, teksturnya lembut, '
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
          fleshDescription: 'Berwarna oranye hingga kuning keemasan, tebal, '
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
          fleshDescription: 'Olahan daging durian dimasak hingga kalis, '
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
          fleshDescription: 'Bibit hasil okulasi unggul, batang kokoh, '
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

  // ── Identitas sesi ──────────────────────────────────────────────────────────

  /// ID pengepul yang sedang login (mock).
  String get currentCollectorId => _currentCollectorId;

  /// Profil pengepul yang sedang login.
  CollectorProfile get profile => _profile;

  // ── Produk ──────────────────────────────────────────────────────────────────

  /// Seluruh produk yang tersedia untuk dibeli/diverifikasi pengepul.
  List<CollectorProduct> get products => List.unmodifiable(_products);

  /// Mencari satu produk berdasarkan [code].
  CollectorProduct? findProduct(String code) {
    try {
      return _products.firstWhere((p) => p.code == code);
    } catch (_) {
      return null;
    }
  }

  // ── Sesi ─────────────────────────────────────────────────────────────────────

  // [FE - State Management] registerCollector menjadikan akun yang baru
  // didaftarkan sebagai pengepul aktif — mengganti profil seed dengan data
  // input registrasi sehingga Beranda/Profil menampilkan identitas user.
  /// Mendaftarkan dan mengaktifkan pengepul baru dari data form registrasi.
  CollectorProfile registerCollector({
    required String firstName,
    required String lastName,
    String roleLabel = 'Pengepul Durian',
  }) {
    final id = 'collector-${DateTime.now().millisecondsSinceEpoch}';
    final fullName = '$firstName $lastName'.trim();
    final profile = CollectorProfile(
      collectorId: id,
      fullName: fullName.isEmpty ? 'Pengepul' : fullName,
      roleLabel: roleLabel,
    );

    _currentCollectorId = id;
    _profile = profile;
    notifyListeners();
    return profile;
  }

  // [FE - State Management] updateAvatar menyimpan path foto profil baru dan
  // notifikasi listener agar header Beranda dan drawer langsung ter-refresh.
  /// Memperbarui foto profil pengepul yang sedang login.
  void updateAvatar(String? path) {
    _profile = _profile.copyWith(avatarPath: path);
    notifyListeners();
  }

  // [FE - State Management] logout mereset seluruh state mock ke kondisi awal
  // seed — memastikan tidak ada data sesi yang bocor ke sesi berikutnya.
  /// Mereset seluruh state sesi mock dan menyemai ulang data awal.
  void logout() {
    _currentCollectorId = _kSeedCollectorId;
    _profile = _kSeedProfile;
    _products = _buildSeedProducts();
    notifyListeners();
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
List<CollectorProduct> searchAndFilterProducts(
  List<CollectorProduct> products,
  ProductCategory category,
  String query,
) {
  final q = query.trim().toLowerCase();
  return products.where((p) {
    final matchCategory = p.category == category;
    final matchQuery = q.isEmpty ||
        p.code.toLowerCase().contains(q) ||
        p.name.toLowerCase().contains(q);
    return matchCategory && matchQuery;
  }).toList();
}
