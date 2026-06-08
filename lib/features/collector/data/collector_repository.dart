import 'package:flutter/foundation.dart';

import '../../../core/storage/local_storage_service.dart';
import '../../farmer/data/farmer_repository.dart';
import '../../farmer/models/harvest_batch.dart';
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
    _loadFromLocal();
    _products = _buildSeedProducts();
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
  }

  // [FE - State Management] Saver ini menulis state profil pengepul ke JSON
  // lokal setiap ada mutasi identitas, lokasi, atau avatar.
  void _saveToLocal() {
    LocalStorageService.saveString('collector_current_id', _currentCollectorId);
    LocalStorageService.saveJson('collector_profile', _profile.toJson());
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
    required String verifiedGrade,
    String? qualityNotes,
  }) {
    return _farmerRepo.verifyBatchByCollector(
      code: code,
      receivedQuantity: receivedQuantity,
      verifiedGrade: verifiedGrade,
      qualityNotes: qualityNotes,
      verifiedBy: _profile.fullName,
    );
  }

  // [FE - Event Handler] Submit penolakan pengepul meneruskan alasan reject
  // ke FarmerRepository sebagai state utama rantai pasok.
  bool rejectFreshBatch({
    required String code,
    required String reason,
  }) {
    return _farmerRepo.rejectBatchByCollector(
      code: code,
      reason: reason,
      rejectedBy: _profile.fullName,
    );
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
