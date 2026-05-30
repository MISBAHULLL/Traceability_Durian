import 'package:flutter/foundation.dart';

import '../data/farmer_mock_data.dart';
import '../models/batch_event.dart';
import '../models/farm.dart';
import '../models/harvest_batch.dart';

// ─────────────────────────────────────────────────────────────────────────────
// FarmerRepository
// ─────────────────────────────────────────────────────────────────────────────

/// Repository in-memory untuk data petani (mock store, fase FE-only).
///
/// Mengimplementasikan [ChangeNotifier] agar widget yang bergantung padanya
/// (Beranda, dropdown kebun) dapat rebuild secara reaktif saat data berubah.
///
/// Semua getter batch/kebun dibatasi pada [currentFarmerId] sehingga UI
/// mustahil menampilkan data petani lain (Req 7.2).
///
/// Singleton diakses via [FarmerRepository.instance]. Pada task 13.3,
/// seed data dari [FarmerMockData] akan dipindahkan sepenuhnya ke sini.
class FarmerRepository extends ChangeNotifier {
  FarmerRepository._seed() {
    // Seed profil dari FarmerMockData
    _currentFarmerId = FarmerMockData.currentFarmerId;
    _profile = FarmerMockData.profile;

    // Seed kebun awal
    _farms = [
      const Farm(
        id: 'farm-001',
        farmerId: 'farmer-001',
        name: 'Kebun Pakis 1',
        province: 'Jawa Timur',
        city: 'Kabupaten Jember',
        district: 'Pakis',
        village: 'Pakis',
        address: 'Jl. Raya Pakis No. 1, Desa Pakis, Kec. Pakis, Kab. Jember',
      ),
      const Farm(
        id: 'farm-002',
        farmerId: 'farmer-001',
        name: 'Kebun Curah 2',
        province: 'Jawa Timur',
        city: 'Kabupaten Jember',
        district: 'Curah Nongko',
        village: 'Curah Nongko',
        address: 'Jl. Curah Nongko No. 2, Desa Curah Nongko, Kab. Jember',
      ),
    ];

    // Seed batch dari FarmerMockData (salinan mutable)
    _batches = List<HarvestBatch>.from(FarmerMockData.batches);

    // Inisialisasi counter kode batch dari batch yang sudah ada
    _batchCounter = _batches.length;
  }

  /// Singleton instance — diakses dari seluruh UI petani.
  static final FarmerRepository instance = FarmerRepository._seed();

  // ── State internal ──────────────────────────────────────────────────────────

  late String _currentFarmerId;
  late FarmerProfile _profile;
  late List<Farm> _farms;
  late List<HarvestBatch> _batches;
  late int _batchCounter;

  // ── Identitas sesi ──────────────────────────────────────────────────────────

  /// ID petani yang sedang login (mock).
  String get currentFarmerId => _currentFarmerId;

  /// Profil petani yang sedang login.
  FarmerProfile get profile => _profile;

  // ── Kebun (Req 7.2 — terbatas milik currentFarmerId) ───────────────────────

  /// Daftar kebun milik petani yang sedang login.
  List<Farm> get farms =>
      _farms.where((f) => f.farmerId == _currentFarmerId).toList();

  // ── Batch (Req 7.2 — terbatas milik currentFarmerId) ──────────────────────

  /// Daftar batch milik petani yang sedang login, diurutkan terbaru di atas.
  List<HarvestBatch> get batches {
    final owned =
        _batches.where((b) => b.farmerId == _currentFarmerId).toList();
    owned.sort((a, b) {
      final ta = a.createdAt ?? DateTime(0);
      final tb = b.createdAt ?? DateTime(0);
      return tb.compareTo(ta); // terbaru di atas
    });
    return owned;
  }

  /// Mencari satu batch berdasarkan [code].
  ///
  /// Mengembalikan `null` bila kode tidak ditemukan atau bukan milik petani
  /// yang sedang login.
  HarvestBatch? findBatch(String code) {
    try {
      return _batches.firstWhere(
        (b) => b.code == code && b.farmerId == _currentFarmerId,
      );
    } catch (_) {
      return null;
    }
  }

  // ── Pembuatan kode batch (Req 2.7) ─────────────────────────────────────────

  /// Menghasilkan kode batch unik berformat `DRN-YYYY-NNNNNN`.
  ///
  /// Kode bersifat monotetik: counter bertambah setiap pemanggilan sehingga
  /// tidak ada duplikat selama sesi berlangsung.
  String generateBatchCode() {
    _batchCounter++;
    final year = DateTime.now().year;
    final seq = _batchCounter.toString().padLeft(6, '0');
    return 'DRN-$year-$seq';
  }

  /// Mengembalikan URL publik untuk menelusuri batch berdasarkan [code].
  ///
  /// Contoh: `https://duriantrace.id/trace/DRN-2026-000129`
  String publicTraceUrl(String code) => 'https://duriantrace.id/trace/$code';

  // ── Tambah batch (Req 2.7, 5.5, 5.6) ──────────────────────────────────────

  /// Membuat [HarvestBatch] baru berstatus [BatchStatus.created] dengan kode
  /// unik, terikat pada [currentFarmerId] dan [farm.id].
  ///
  /// Memanggil [notifyListeners] agar Beranda dan dropdown ter-refresh.
  HarvestBatch addBatch({
    required Farm farm,
    required String variety,
    required String fertilizer,
    required String harvestMethod,
    required String grade,
    required double quantity,
    required DateTime harvestDate,
    String unit = 'kg',
  }) {
    final code = generateBatchCode();
    final now = DateTime.now();
    final batch = HarvestBatch(
      code: code,
      farmerId: _currentFarmerId,
      farmId: farm.id,
      farmName: farm.name,
      variety: variety,
      fertilizer: fertilizer,
      harvestMethod: harvestMethod,
      grade: grade,
      quantity: quantity,
      unit: unit,
      harvestDate: harvestDate,
      status: BatchStatus.created,
      createdAt: now,
    );
    _batches.add(batch);
    notifyListeners();
    return batch;
  }

  // ── Tambah kebun (Req 5.5, 5.6) ────────────────────────────────────────────

  /// Menambahkan [Farm] baru milik [currentFarmerId] ke mock store.
  ///
  /// Memanggil [notifyListeners] agar dropdown lokasi kebun ter-refresh.
  Farm addFarm({
    required String name,
    required String province,
    required String city,
    required String district,
    required String village,
    required String address,
    double? latitude,
    double? longitude,
  }) {
    final id = 'farm-${DateTime.now().millisecondsSinceEpoch}';
    final farm = Farm(
      id: id,
      farmerId: _currentFarmerId,
      name: name,
      province: province,
      city: city,
      district: district,
      village: village,
      address: address,
      latitude: latitude,
      longitude: longitude,
    );
    _farms.add(farm);
    notifyListeners();
    return farm;
  }

  // ── Guard edit batch (Req 3.8, 3.9, 7.3, 7.4) ─────────────────────────────

  /// Mengembalikan `true` jika dan hanya jika batch dengan [code] berstatus
  /// [BatchStatus.draft] — satu-satunya status yang boleh diedit petani.
  bool canEditBatch(String code) {
    final batch = findBatch(code);
    return batch?.status == BatchStatus.draft;
  }

  /// Memperbarui data batch dengan [code] bila [canEditBatch] bernilai `true`.
  ///
  /// Bila status bukan DRAFT, operasi ini adalah **no-op** dan mengembalikan
  /// `false` sebagai tanda penolakan (Req 7.4).
  bool updateBatch(
    String code, {
    Farm? farm,
    String? variety,
    String? fertilizer,
    String? harvestMethod,
    String? grade,
    double? quantity,
    String? unit,
    DateTime? harvestDate,
  }) {
    if (!canEditBatch(code)) return false;

    final index = _batches.indexWhere(
      (b) => b.code == code && b.farmerId == _currentFarmerId,
    );
    if (index == -1) return false;

    final existing = _batches[index];
    _batches[index] = existing.copyWith(
      farmId: farm?.id,
      farmName: farm?.name,
      variety: variety,
      fertilizer: fertilizer,
      harvestMethod: harvestMethod,
      grade: grade,
      quantity: quantity,
      unit: unit,
      harvestDate: harvestDate,
    );
    notifyListeners();
    return true;
  }

  // ── Statistik (Req 1.2) ────────────────────────────────────────────────────

  /// Total seluruh batch milik petani yang sedang login.
  int get totalBatch => batches.length;

  /// Jumlah batch yang masih aktif berjalan di rantai pasok.
  int get activeBatch => batches.where((b) => b.status.isActive).length;

  /// Jumlah batch yang sudah diverifikasi pengepul.
  int get verifiedBatch =>
      batches.where((b) => b.status == BatchStatus.verifiedByCollector).length;

  // ── Timeline (Req 3.6) ─────────────────────────────────────────────────────

  /// Mengembalikan daftar [BatchEvent] untuk batch dengan [code], diurutkan
  /// kronologis (terlama di atas).
  ///
  /// Pada fase FE-only, event dibangkitkan dari status batch saat ini.
  /// Integrasi event nyata dari backend adalah future work.
  List<BatchEvent> eventsFor(String code) {
    final batch = findBatch(code);
    if (batch == null) return [];

    final events = <BatchEvent>[];
    final actorName = _profile.fullName;
    final createdAt = batch.createdAt ?? batch.harvestDate;

    // Event "Batch Dibuat" selalu ada
    events.add(BatchEvent(
      title: 'Batch Dibuat',
      actorLabel: 'Petani — $actorName',
      timestamp: createdAt,
      status: BatchStatus.created,
    ));

    // Tambahkan event lanjutan berdasarkan status saat ini
    switch (batch.status) {
      case BatchStatus.draft:
      case BatchStatus.created:
        break; // hanya event dibuat
      case BatchStatus.verifiedByCollector:
        events.add(BatchEvent(
          title: 'Terverifikasi Pengepul',
          actorLabel: 'Pengepul',
          timestamp: createdAt.add(const Duration(days: 1)),
          status: BatchStatus.verifiedByCollector,
        ));
      case BatchStatus.inDistribution:
        events.add(BatchEvent(
          title: 'Terverifikasi Pengepul',
          actorLabel: 'Pengepul',
          timestamp: createdAt.add(const Duration(days: 1)),
          status: BatchStatus.verifiedByCollector,
        ));
        events.add(BatchEvent(
          title: 'Dalam Distribusi',
          actorLabel: 'Pengepul',
          timestamp: createdAt.add(const Duration(days: 2)),
          status: BatchStatus.inDistribution,
        ));
      case BatchStatus.receivedByUmkm:
        events.add(BatchEvent(
          title: 'Terverifikasi Pengepul',
          actorLabel: 'Pengepul',
          timestamp: createdAt.add(const Duration(days: 1)),
          status: BatchStatus.verifiedByCollector,
        ));
        events.add(BatchEvent(
          title: 'Dalam Distribusi',
          actorLabel: 'Pengepul',
          timestamp: createdAt.add(const Duration(days: 2)),
          status: BatchStatus.inDistribution,
        ));
        events.add(BatchEvent(
          title: 'Diterima UMKM',
          actorLabel: 'UMKM',
          timestamp: createdAt.add(const Duration(days: 3)),
          status: BatchStatus.receivedByUmkm,
        ));
      case BatchStatus.processed:
        events.add(BatchEvent(
          title: 'Terverifikasi Pengepul',
          actorLabel: 'Pengepul',
          timestamp: createdAt.add(const Duration(days: 1)),
          status: BatchStatus.verifiedByCollector,
        ));
        events.add(BatchEvent(
          title: 'Dalam Distribusi',
          actorLabel: 'Pengepul',
          timestamp: createdAt.add(const Duration(days: 2)),
          status: BatchStatus.inDistribution,
        ));
        events.add(BatchEvent(
          title: 'Diterima UMKM',
          actorLabel: 'UMKM',
          timestamp: createdAt.add(const Duration(days: 3)),
          status: BatchStatus.receivedByUmkm,
        ));
        events.add(BatchEvent(
          title: 'Sedang Diolah',
          actorLabel: 'UMKM',
          timestamp: createdAt.add(const Duration(days: 4)),
          status: BatchStatus.processed,
        ));
      case BatchStatus.sold:
        events.add(BatchEvent(
          title: 'Terverifikasi Pengepul',
          actorLabel: 'Pengepul',
          timestamp: createdAt.add(const Duration(days: 1)),
          status: BatchStatus.verifiedByCollector,
        ));
        events.add(BatchEvent(
          title: 'Dalam Distribusi',
          actorLabel: 'Pengepul',
          timestamp: createdAt.add(const Duration(days: 2)),
          status: BatchStatus.inDistribution,
        ));
        events.add(BatchEvent(
          title: 'Diterima UMKM',
          actorLabel: 'UMKM',
          timestamp: createdAt.add(const Duration(days: 3)),
          status: BatchStatus.receivedByUmkm,
        ));
        events.add(BatchEvent(
          title: 'Sedang Diolah',
          actorLabel: 'UMKM',
          timestamp: createdAt.add(const Duration(days: 4)),
          status: BatchStatus.processed,
        ));
        events.add(BatchEvent(
          title: 'Terjual',
          actorLabel: 'UMKM',
          timestamp: createdAt.add(const Duration(days: 5)),
          status: BatchStatus.sold,
        ));
      case BatchStatus.rejected:
        events.add(BatchEvent(
          title: 'Ditolak',
          actorLabel: 'Pengepul / Admin',
          timestamp: createdAt.add(const Duration(days: 1)),
          status: BatchStatus.rejected,
        ));
    }

    // Urutkan kronologis (terlama di atas)
    events.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return events;
  }

  // ── Sesi (Req 6.4) ─────────────────────────────────────────────────────────

  /// Mereset seluruh state sesi mock dan menyemai ulang data awal.
  ///
  /// Dipanggil saat petani menekan "Keluar" di Layar Profil.
  void logout() {
    _currentFarmerId = FarmerMockData.currentFarmerId;
    _profile = FarmerMockData.profile;
    _farms = [
      const Farm(
        id: 'farm-001',
        farmerId: 'farmer-001',
        name: 'Kebun Pakis 1',
        province: 'Jawa Timur',
        city: 'Kabupaten Jember',
        district: 'Pakis',
        village: 'Pakis',
        address: 'Jl. Raya Pakis No. 1, Desa Pakis, Kec. Pakis, Kab. Jember',
      ),
      const Farm(
        id: 'farm-002',
        farmerId: 'farmer-001',
        name: 'Kebun Curah 2',
        province: 'Jawa Timur',
        city: 'Kabupaten Jember',
        district: 'Curah Nongko',
        village: 'Curah Nongko',
        address: 'Jl. Curah Nongko No. 2, Desa Curah Nongko, Kab. Jember',
      ),
    ];
    _batches = List<HarvestBatch>.from(FarmerMockData.batches);
    _batchCounter = _batches.length;
    notifyListeners();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// searchAndFilterBatches — helper murni (Req 1.4, 1.5, 1.6)
// ─────────────────────────────────────────────────────────────────────────────

/// Menyaring [batches] berdasarkan [filter] chip dan [query] pencarian.
///
/// Fungsi ini **murni** (pure function): tidak mengubah state apapun dan
/// hasilnya hanya bergantung pada argumen yang diberikan.
///
/// - [filter]: chip aktif dari {Semua, Menunggu, Terverifikasi, Distribusi}.
/// - [query]: teks pencarian; pencocokan case-insensitive pada [HarvestBatch.code]
///   dan [HarvestBatch.variety]. String kosong berarti tidak ada filter teks.
///
/// Batch yang dikembalikan memenuhi **kedua** kriteria (chip AND query).
List<HarvestBatch> searchAndFilterBatches(
  List<HarvestBatch> batches,
  BatchFilter filter,
  String query,
) {
  final q = query.trim().toLowerCase();
  return batches.where((b) {
    final matchFilter = filter.matches(b.status);
    final matchQuery = q.isEmpty ||
        b.code.toLowerCase().contains(q) ||
        b.variety.toLowerCase().contains(q);
    return matchFilter && matchQuery;
  }).toList();
}

// ─────────────────────────────────────────────────────────────────────────────
// FarmerValidator — validator form murni (Req 2.4, 2.5, 2.6, 5.4)
// ─────────────────────────────────────────────────────────────────────────────

/// Kumpulan validator murni untuk form Tambah Batch Panen dan Buat Kebun.
///
/// Setiap method mengembalikan pesan error berbahasa Indonesia, atau `null`
/// bila input valid. Tidak ada side-effect.
class FarmerValidator {
  FarmerValidator._();

  // ── Tambah Batch Panen ─────────────────────────────────────────────────────

  /// Memvalidasi seluruh field form Tambah Batch Panen.
  ///
  /// Mengembalikan pesan error pertama yang ditemukan, atau `null` bila valid.
  static String? validateAddBatch({
    required Farm? farm,
    required String? variety,
    required String? grade,
    required DateTime? harvestDate,
    required String quantityText,
  }) {
    if (farm == null) {
      return 'Silakan pilih lokasi kebun terlebih dahulu.';
    }
    if (variety == null || variety.isEmpty) {
      return 'Silakan pilih varietas durian.';
    }
    if (grade == null || grade.isEmpty) {
      return 'Silakan pilih grade/mutu durian.';
    }
    if (harvestDate == null) {
      return 'Silakan pilih tanggal panen.';
    }
    return validateHarvestDate(harvestDate) ??
        validateQuantity(quantityText);
  }

  /// Memvalidasi jumlah panen.
  ///
  /// Mengembalikan pesan error bila [text] kosong, bukan angka, atau ≤ 0.
  static String? validateQuantity(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      return 'Jumlah panen wajib diisi.';
    }
    final value = double.tryParse(trimmed);
    if (value == null || value <= 0) {
      return 'Jumlah panen harus berupa angka lebih dari nol.';
    }
    return null;
  }

  /// Memvalidasi tanggal panen.
  ///
  /// Mengembalikan pesan error bila [date] melampaui hari ini.
  static String? validateHarvestDate(DateTime date) {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final inputDate = DateTime(date.year, date.month, date.day);
    if (inputDate.isAfter(todayDate)) {
      return 'Tanggal panen tidak boleh melebihi hari ini.';
    }
    return null;
  }

  // ── Buat Kebun ─────────────────────────────────────────────────────────────

  /// Memvalidasi seluruh field form Buat Kebun.
  ///
  /// Mengembalikan pesan error pertama yang ditemukan, atau `null` bila valid.
  static String? validateCreateFarm({
    required String name,
    required String province,
    required String city,
    required String district,
    required String village,
    required String address,
    String? latitudeText,
    String? longitudeText,
  }) {
    final requiredFields = <String, String>{
      'nama kebun': name,
      'provinsi': province,
      'kota/kabupaten': city,
      'kecamatan': district,
      'desa': village,
      'alamat': address,
    };

    for (final entry in requiredFields.entries) {
      if (entry.value.trim().isEmpty) {
        return 'Lengkapi data kebun: ${entry.key} wajib diisi.';
      }
    }

    // Validasi koordinat opsional — bila diisi harus berupa angka
    if (latitudeText != null && latitudeText.trim().isNotEmpty) {
      if (double.tryParse(latitudeText.trim()) == null) {
        return 'Koordinat harus berupa angka yang valid.';
      }
    }
    if (longitudeText != null && longitudeText.trim().isNotEmpty) {
      if (double.tryParse(longitudeText.trim()) == null) {
        return 'Koordinat harus berupa angka yang valid.';
      }
    }

    return null;
  }
}
