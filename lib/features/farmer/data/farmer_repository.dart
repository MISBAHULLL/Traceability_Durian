import 'package:flutter/foundation.dart';

import '../../../core/storage/local_storage_service.dart';
import '../models/batch_event.dart';
import '../models/farm.dart';
import '../models/harvest_batch.dart';

// ─────────────────────────────────────────────────────────────────────────────
// FarmerRepository
// ─────────────────────────────────────────────────────────────────────────────

// [FE - State Management] Repository ini adalah satu-satunya sumber data
// (single source of truth) untuk seluruh layar petani pada fase FE-only.
// Menggunakan ChangeNotifier agar widget dapat rebuild secara reaktif.
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
    _loadFromLocal();
  }

  // [FE - State Management] Loader ini me-restore state mock dari
  // SharedPreferences; jika storage kosong, repository memakai seed default.
  void _loadFromLocal() {
    _currentFarmerId =
        LocalStorageService.loadString('farmer_current_id') ?? _kSeedFarmerId;

    final profileJson = LocalStorageService.loadJson('farmer_profile');
    if (profileJson != null) {
      _profile = FarmerProfile.fromJson(profileJson);
    } else {
      _profile = _kSeedProfile;
    }

    final farmsJsonList = LocalStorageService.loadJsonList('farmer_farms');
    if (farmsJsonList != null) {
      _farms = farmsJsonList.map((e) => Farm.fromJson(e)).toList();
    } else {
      _farms = _buildSeedFarms();
    }

    final batchesJsonList = LocalStorageService.loadJsonList('farmer_batches');
    if (batchesJsonList != null) {
      _batches = batchesJsonList.map((e) => HarvestBatch.fromJson(e)).toList();
    } else {
      _batches = _buildSeedBatches();
    }

    _batchCounter =
        LocalStorageService.loadInt('farmer_batch_counter') ?? _batches.length;
    _ensureSeedRejectedBatch();
  }

  // [FE - State Management] Migrasi seed ini menjaga data demo tetap lengkap
  // setelah struktur mock bertambah tanpa menghapus data lokal yang sudah ada.
  void _ensureSeedRejectedBatch() {
    if (_currentFarmerId != _kSeedFarmerId) return;
    if (_batches.any((b) => b.code == _kSeedRejectedBatchCode)) return;

    _batches.add(_buildSeedRejectedBatch());
    if (_batchCounter < _batches.length) {
      _batchCounter = _batches.length;
    }
    _saveToLocal();
  }

  // [FE - State Management] Saver ini menulis semua state penting petani ke
  // JSON lokal setiap ada mutasi agar data tetap ada setelah restart aplikasi.
  void _saveToLocal() {
    LocalStorageService.saveString('farmer_current_id', _currentFarmerId);
    LocalStorageService.saveJson('farmer_profile', _profile.toJson());
    LocalStorageService.saveJsonList(
      'farmer_farms',
      _farms.map((e) => e.toJson()).toList(),
    );
    LocalStorageService.saveJsonList(
      'farmer_batches',
      _batches.map((e) => e.toJson()).toList(),
    );
    LocalStorageService.saveInt('farmer_batch_counter', _batchCounter);
  }

  // [FE - State Management] Seed data dipindahkan dari FarmerMockData ke sini
  // (task 13.3) agar repository menjadi satu-satunya sumber data mock.
  // ── Konstanta seed (dipindahkan dari FarmerMockData — task 13.3) ───────────

  static const String _kSeedFarmerId = 'farmer-001';
  static const String _kSeedRejectedBatchCode = 'DRN-2026-000077';


  static const FarmerProfile _kSeedProfile = FarmerProfile(
    farmerId: _kSeedFarmerId,
    fullName: 'Risqi Firdaus Setiawan',
    roleLabel: 'Petani Durian',
    location: 'Desa Pakis, Kab. Jember',
    village: 'Pakis',
    district: 'Pakis',
    city: 'Kabupaten Jember',
    contact: '081234567890',
    email: 'risqi.petani@example.com',
  );

  static List<Farm> _buildSeedFarms() => [
        const Farm(
          id: 'farm-001',
          farmerId: _kSeedFarmerId,
          name: 'Kebun Pakis 1',
          province: 'Jawa Timur',
          city: 'Kabupaten Jember',
          district: 'Pakis',
          village: 'Pakis',
          address: 'Jl. Raya Pakis No. 1, Desa Pakis, Kec. Pakis, Kab. Jember',
        ),
        const Farm(
          id: 'farm-002',
          farmerId: _kSeedFarmerId,
          name: 'Kebun Curah 2',
          province: 'Jawa Timur',
          city: 'Kabupaten Jember',
          district: 'Curah Nongko',
          village: 'Curah Nongko',
          address: 'Jl. Curah Nongko No. 2, Desa Curah Nongko, Kab. Jember',
        ),
      ];

  static List<HarvestBatch> _buildSeedBatches() => [
        HarvestBatch(
          code: 'DRN-2026-000128',
          farmerId: _kSeedFarmerId,
          farmId: 'farm-001',
          variety: 'Montong',
          grade: 'A',
          quantity: 52,
          unit: 'kg',
          fruitCount: 18,
          harvestDate: DateTime(2026, 5, 24),
          farmName: 'Kebun Pakis 1',
          status: BatchStatus.created,
          fertilizer: 'Organik Kompos',
          harvestMethod: 'Jatuh Alami',
          maturityLevel: 'Matang Pohon',
          shelfLifeEstimate: '2-3 hari',
          storageSuggestion: 'Simpan di tempat sejuk dan kering.',
          notes: 'Kulit utuh, aroma kuat, siap disortir pengepul.',
          createdAt: DateTime(2026, 5, 24, 8, 30),
        ),
        HarvestBatch(
          code: 'DRN-2026-000119',
          farmerId: _kSeedFarmerId,
          farmId: 'farm-001',
          variety: 'Bawor',
          grade: 'B',
          quantity: 40,
          unit: 'kg',
          fruitCount: 14,
          harvestDate: DateTime(2026, 5, 20),
          farmName: 'Kebun Pakis 1',
          status: BatchStatus.verifiedByCollector,
          fertilizer: 'NPK',
          harvestMethod: 'Petik Matang',
          maturityLevel: 'Matang',
          shelfLifeEstimate: '2-3 hari',
          storageSuggestion: 'Hindari sinar matahari langsung.',
          notes: 'Sudah lolos sortir awal di kebun.',
          createdAt: DateTime(2026, 5, 20, 9, 0),
        ),
        HarvestBatch(
          code: 'DRN-2026-000103',
          farmerId: _kSeedFarmerId,
          farmId: 'farm-002',
          variety: 'Montong',
          grade: 'A',
          quantity: 65,
          unit: 'kg',
          fruitCount: 22,
          harvestDate: DateTime(2026, 5, 12),
          farmName: 'Kebun Curah 2',
          status: BatchStatus.inDistribution,
          fertilizer: 'Kandang',
          harvestMethod: 'Jatuh Alami',
          maturityLevel: 'Matang Pohon',
          shelfLifeEstimate: '1 hari',
          storageSuggestion: 'Segera distribusikan setelah diterima.',
          notes: 'Sebagian buah sangat matang.',
          createdAt: DateTime(2026, 5, 12, 7, 45),
        ),
        HarvestBatch(
          code: 'DRN-2026-000097',
          farmerId: _kSeedFarmerId,
          farmId: 'farm-002',
          variety: 'Petruk',
          grade: 'B',
          quantity: 38,
          unit: 'kg',
          fruitCount: 13,
          harvestDate: DateTime(2026, 5, 5),
          farmName: 'Kebun Curah 2',
          status: BatchStatus.receivedByUmkm,
          fertilizer: 'Hayati',
          harvestMethod: 'Petik Matang',
          maturityLevel: 'Matang',
          shelfLifeEstimate: '2-3 hari',
          storageSuggestion: 'Simpan di ruang berventilasi.',
          notes: 'Cocok untuk bahan olahan.',
          createdAt: DateTime(2026, 5, 5, 10, 15),
        ),
        HarvestBatch(
          code: 'DRN-2026-000088',
          farmerId: _kSeedFarmerId,
          farmId: 'farm-001',
          variety: 'Montong',
          grade: 'A',
          quantity: 70,
          unit: 'kg',
          fruitCount: 24,
          harvestDate: DateTime(2026, 4, 28),
          farmName: 'Kebun Pakis 1',
          status: BatchStatus.processed,
          fertilizer: 'Organik Kompos',
          harvestMethod: 'Jatuh Alami',
          maturityLevel: 'Matang Pohon',
          shelfLifeEstimate: '1 hari',
          storageSuggestion: 'Gunakan segera untuk menjaga aroma.',
          notes: 'Batch telah diproses UMKM.',
          createdAt: DateTime(2026, 4, 28, 8, 0),
        ),
        _buildSeedRejectedBatch(),
      ];

  // [FE - State Management] Seed ini menyediakan contoh batch ditolak agar
  // role petani bisa menguji filter, badge, timeline, dan alasan penolakan.
  static HarvestBatch _buildSeedRejectedBatch() => HarvestBatch(
        code: _kSeedRejectedBatchCode,
        farmerId: _kSeedFarmerId,
        farmId: 'farm-001',
        variety: 'Bawor',
        grade: 'B',
        quantity: 45,
        unit: 'kg',
        fruitCount: 16,
        harvestDate: DateTime(2026, 4, 20),
        farmName: 'Kebun Pakis 1',
        status: BatchStatus.rejected,
        fertilizer: 'Organik Kompos',
        harvestMethod: 'Petik Matang',
        maturityLevel: 'Matang',
        shelfLifeEstimate: '1-2 hari',
        storageSuggestion: 'Pisahkan dari batch siap jual.',
        notes: 'Contoh data untuk alur batch yang tidak lolos verifikasi.',
        createdAt: DateTime(2026, 4, 20, 8, 45),
        rejectionReason:
            'Beberapa buah retak dan tingkat kematangan tidak seragam.',
        rejectedBy: 'Pengepul Jember',
        rejectedAt: DateTime(2026, 4, 21, 10, 30),
      );

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

  // [FE - State Management] Lookup publik ini dipakai layar trace konsumen:
  // hanya membaca batch dari QR/code tanpa membuka akses edit milik petani.
  HarvestBatch? findPublicBatch(String code) {
    try {
      return _batches.firstWhere((b) => b.code == code);
    } catch (_) {
      return null;
    }
  }

  // ── Pembuatan kode batch (Req 2.7) ─────────────────────────────────────────

  // [UTIL - Helper Function] generateBatchCode menghasilkan kode unik
  // berformat DRN-YYYY-NNNNNN dengan counter monotetik agar tidak ada duplikat.
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

  // [UTIL - Helper Function] publicTraceUrl membangun URL publik yang
  // di-encode ke dalam QR Code — menjadi titik integrasi dengan sistem
  // telusur publik DurianTrace.
  /// Mengembalikan URL publik untuk menelusuri batch berdasarkan [code].
  ///
  /// Contoh: `https://duriantrace.id/trace/DRN-2026-000129`
  String publicTraceUrl(String code) => 'https://duriantrace.id/trace/$code';

  // ── Tambah batch (Req 2.7, 5.5, 5.6) ──────────────────────────────────────

  // [FE - State Management] addBatch adalah mutasi utama repository —
  // membuat batch baru, menyimpannya ke mock store, lalu notifikasi
  // semua listener agar UI ter-refresh secara reaktif.
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
    required int fruitCount,
    required DateTime harvestDate,
    required String maturityLevel,
    required String shelfLifeEstimate,
    String unit = 'kg',
    String? storageSuggestion,
    String? notes,
    String? photoPath,
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
      fruitCount: fruitCount,
      harvestDate: harvestDate,
      status: BatchStatus.created,
      createdAt: now,
      photoPath: photoPath,
      maturityLevel: maturityLevel,
      shelfLifeEstimate: shelfLifeEstimate,
      storageSuggestion: storageSuggestion,
      notes: notes,
    );
    _batches.add(batch);
    _saveToLocal();
    notifyListeners();
    return batch;
  }

  // ── Tambah kebun (Req 5.5, 5.6) ────────────────────────────────────────────

  // [FE - State Management] addFarm menyimpan kebun baru ke mock store
  // dan notifikasi listener — dropdown lokasi kebun di AddBatchScreen
  // akan otomatis ter-refresh tanpa perlu setState manual.
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
    _saveToLocal();
    notifyListeners();
    return farm;
  }

  // ── Guard edit batch (Req 3.8, 3.9, 7.3, 7.4) ─────────────────────────────

  /// Lama jendela koreksi setelah batch dibuat (status CREATED).
  ///
  /// Dalam rentang ini petani masih boleh memperbaiki data batch (mis. salah
  /// ketik jumlah). Ubah nilai ini untuk menyesuaikan kebijakan koreksi.
  static const Duration kEditWindow = Duration(minutes: 15);

  // [FE - State Management] canEditBatch & updateBatch menegakkan aturan
  // koreksi di sisi klien. Edit diizinkan bila:
  //   - status DRAFT (tanpa batas waktu), ATAU
  //   - status CREATED dan masih dalam jendela [kEditWindow] sejak dibuat.
  // Setelah batch diverifikasi pengepul (status naik dari CREATED), atau
  // jendela waktu habis, data terkunci demi integritas telusur.
  /// Mengembalikan `true` bila batch dengan [code] masih boleh diubah petani.
  bool canEditBatch(String code) {
    final batch = findBatch(code);
    if (batch == null) return false;

    // DRAFT selalu dapat diubah (alur masa depan).
    if (batch.status == BatchStatus.draft) return true;

    // CREATED dapat diubah hanya dalam jendela koreksi sejak dibuat.
    if (batch.status == BatchStatus.created) {
      return remainingEditTime(code) > Duration.zero;
    }

    // Status lain (sudah diverifikasi/distribusi/dst) terkunci.
    return false;
  }

  /// Sisa waktu jendela koreksi untuk batch CREATED dengan [code].
  ///
  /// Mengembalikan [Duration.zero] bila jendela sudah habis, batch tidak
  /// ditemukan, atau batch bukan berstatus CREATED. Untuk DRAFT mengembalikan
  /// [Duration.zero] juga (DRAFT tidak dibatasi waktu — gunakan [canEditBatch]).
  Duration remainingEditTime(String code) {
    final batch = findBatch(code);
    if (batch == null || batch.status != BatchStatus.created) {
      return Duration.zero;
    }
    final createdAt = batch.createdAt;
    if (createdAt == null) return Duration.zero;

    final elapsed = DateTime.now().difference(createdAt);
    final remaining = kEditWindow - elapsed;
    return remaining.isNegative ? Duration.zero : remaining;
  }

  /// Memperbarui data batch dengan [code] bila [canEditBatch] bernilai `true`.
  ///
  /// Bila batch tidak lagi dapat diubah (status terkunci atau jendela waktu
  /// habis), operasi ini adalah **no-op** dan mengembalikan `false` sebagai
  /// tanda penolakan (Req 7.4).
  bool updateBatch(
    String code, {
    Farm? farm,
    String? variety,
    String? fertilizer,
    String? harvestMethod,
    String? grade,
    double? quantity,
    String? unit,
    int? fruitCount,
    DateTime? harvestDate,
    String? maturityLevel,
    String? shelfLifeEstimate,
    String? storageSuggestion,
    String? notes,
    String? photoPath,
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
      fruitCount: fruitCount,
      harvestDate: harvestDate,
      maturityLevel: maturityLevel,
      shelfLifeEstimate: shelfLifeEstimate,
      storageSuggestion: storageSuggestion,
      notes: notes,
      photoPath: photoPath,
    );
    _saveToLocal();
    notifyListeners();
    return true;
  }

  // ── Statistik (Req 1.2) ────────────────────────────────────────────────────

  /// Total seluruh batch milik petani yang sedang login.
  int get totalBatch => batches.length;

  // [FE - State Management] Statistik ini menghitung batch yang baru dibuat
  // petani dan menunggu aksi/verifikasi dari pengepul.
  int get pendingVerificationBatch =>
      batches.where((b) => b.status == BatchStatus.created).length;

  /// Jumlah batch yang masih aktif berjalan di rantai pasok.
  int get activeBatch => batches.where((b) => b.status.isActive).length;

  /// Jumlah batch yang sudah diverifikasi pengepul.
  int get verifiedBatch =>
      batches.where((b) => b.status == BatchStatus.verifiedByCollector).length;

  // ── Timeline (Req 3.6) ─────────────────────────────────────────────────────

  // [FE - State Management] Getter ini membuka batch CREATED sebagai antrean
  // verifikasi pengepul tanpa memberi pengepul akses mengubah data panen.
  List<HarvestBatch> get batchesForCollectorVerification {
    final items = _batches.where((b) => b.status == BatchStatus.created).toList();
    items.sort((a, b) {
      final aDate = a.createdAt ?? a.harvestDate;
      final bDate = b.createdAt ?? b.harvestDate;
      return bDate.compareTo(aDate);
    });
    return List.unmodifiable(items);
  }

  // [FE - State Management] Mutasi ini menjadi transisi status dari petani
  // ke pengepul: CREATED -> VERIFIED_BY_COLLECTOR pada fase mock FE-only.
  bool verifyBatchByCollector({
    required String code,
    required double receivedQuantity,
    required String verifiedGrade,
    String? qualityNotes,
  }) {
    if (receivedQuantity <= 0 || verifiedGrade.trim().isEmpty) return false;

    final index = _batches.indexWhere((b) => b.code == code);
    if (index == -1) return false;

    final existing = _batches[index];
    if (existing.status != BatchStatus.created) return false;

    _batches[index] = existing.copyWith(status: BatchStatus.verifiedByCollector);
    _saveToLocal();
    notifyListeners();
    return true;
  }

  // [FE - State Management] Mutasi ini menjadi jalur penolakan batch dari
  // pengepul ke petani pada fase mock FE-only.
  bool rejectBatchByCollector({
    required String code,
    required String reason,
    String rejectedBy = 'Pengepul',
  }) {
    final cleanReason = reason.trim();
    if (cleanReason.isEmpty) return false;

    final index = _batches.indexWhere((b) => b.code == code);
    if (index == -1) return false;

    final existing = _batches[index];
    if (existing.status != BatchStatus.created) return false;

    _batches[index] = existing.copyWith(
      status: BatchStatus.rejected,
      rejectionReason: cleanReason,
      rejectedBy: rejectedBy.trim().isEmpty ? 'Pengepul' : rejectedBy.trim(),
      rejectedAt: DateTime.now(),
    );
    _saveToLocal();
    notifyListeners();
    return true;
  }

  // [FE - State Management] eventsFor membangkitkan timeline dari status
  // batch saat ini — pada fase FE-only ini bersifat deterministik;
  // di masa depan akan diganti dengan event nyata dari backend.
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
          title: 'Ditolak Pengepul',
          actorLabel: batch.rejectedBy ?? 'Pengepul',
          timestamp: batch.rejectedAt ?? createdAt.add(const Duration(days: 1)),
          status: BatchStatus.rejected,
        ));
    }

    // Urutkan kronologis (terlama di atas)
    events.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return events;
  }

  // ── Sesi (Req 6.4) ─────────────────────────────────────────────────────────

  // [FE - State Management] registerFarmer menjadikan akun yang baru
  // didaftarkan sebagai petani aktif — mengganti profil seed dengan data
  // input registrasi sehingga Beranda/Profil menampilkan identitas user
  // yang sebenarnya, bukan data contoh.
  //
  // Petani baru dimulai dengan keadaan bersih (tanpa batch/kebun). Data seed
  // contoh tetap ada di store namun otomatis tersembunyi karena terikat
  // farmerId yang berbeda (lihat getter [farms]/[batches]).
  /// Mendaftarkan dan mengaktifkan petani baru dari data form registrasi.
  ///
  /// Field alamat (desa/kecamatan/kabupaten/lokasi) sengaja dikosongkan
  /// karena belum dikumpulkan saat registrasi; UI menampilkan penanda
  /// "Belum dilengkapi" hingga petani melengkapinya.
  FarmerProfile registerFarmer({
    required String firstName,
    required String lastName,
    required String phone,
    required String email,
    String roleLabel = 'Petani Durian',
  }) {
    final id = 'farmer-${DateTime.now().millisecondsSinceEpoch}';
    final fullName = '$firstName $lastName'.trim();
    final profile = FarmerProfile(
      farmerId: id,
      fullName: fullName.isEmpty ? 'Petani' : fullName,
      roleLabel: roleLabel,
      location: '', // dilengkapi kemudian
      village: '',
      district: '',
      city: '',
      contact: phone.isEmpty ? '' : '+62 $phone',
      email: email.trim(),
    );

    _currentFarmerId = id;
    _profile = profile;
    _saveToLocal();
    notifyListeners();
    return profile;
  }

  // [FE - State Management] updateProfile memperbarui data profil petani
  // yang sedang login (mis. melengkapi alamat/kontak yang belum diisi saat
  // registrasi). Komponen lokasi ringkas (`location`) diturunkan otomatis
  // dari desa/kabupaten agar konsisten di Beranda & Detail Batch.
  /// Memperbarui profil petani yang sedang login dan menyimpannya ke store.
  FarmerProfile updateProfile({
    required String fullName,
    required String contact,
    required String email,
    required String village,
    required String district,
    required String city,
  }) {
    // Susun ringkasan lokasi dari komponen non-kosong (desa + kabupaten).
    final locationParts = <String>[
      if (village.trim().isNotEmpty) 'Desa ${village.trim()}',
      if (city.trim().isNotEmpty) city.trim(),
    ];
    final location = locationParts.join(', ');

    _profile = _profile.copyWith(
      fullName: fullName.trim(),
      contact: contact.trim(),
      village: village.trim(),
      district: district.trim(),
      city: city.trim(),
      location: location,
      email: email.trim(),
    );

    _saveToLocal();
    notifyListeners();
    return _profile;
  }

  // [FE - State Management] updateAvatar menyimpan path foto profil petani
  // ke profil aktif dan local storage agar avatar bertahan setelah restart.
  void updateAvatar(String? path) {
    _profile = _profile.copyWith(avatarPath: path);
    _saveToLocal();
    notifyListeners();
  }

  // [FE - State Management] Logout mock hanya memastikan state terakhir
  // tersimpan; reset data harus menjadi aksi terpisah agar testing tidak hilang.
  void logout() {
    _saveToLocal();
    notifyListeners();
  }
}
// [UTIL - Helper Function] searchAndFilterBatches adalah fungsi murni yang
// memisahkan logika filter dari UI — mudah diuji secara independen (PBT P2)
// dan dipakai ulang di mana pun daftar batch perlu difilter.
/// Menyaring [batches] berdasarkan [filter] chip dan [query] pencarian.
///
/// Fungsi ini **murni** (pure function): tidak mengubah state apapun dan
/// hasilnya hanya bergantung pada argumen yang diberikan.
///
/// - [filter]: chip aktif dari {Semua, Menunggu, Terverifikasi, Ditolak}.
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

// [ERROR - Exception Handling] FarmerValidator memusatkan semua aturan
// validasi form sebagai fungsi murni — memisahkan logika validasi dari UI
// agar dapat diuji secara independen (PBT P4, P5, P6).
/// Kumpulan validator murni untuk form Tambah Batch Panen dan Buat Kebun.
///
/// Setiap method mengembalikan pesan error berbahasa Indonesia, atau `null`
/// bila input valid. Tidak ada side-effect.
class FarmerValidator {
  FarmerValidator._();

  // ── Tambah Batch Panen ─────────────────────────────────────────────────────

  // [ERROR - Exception Handling] validateAddBatch adalah entry point validasi
  // form Tambah Batch — mengembalikan pesan error pertama yang ditemukan
  // agar UI dapat langsung menampilkannya via TopNotification.
  /// Memvalidasi seluruh field form Tambah Batch Panen.
  ///
  /// Mengembalikan pesan error pertama yang ditemukan, atau `null` bila valid.
  static String? validateAddBatch({
    required Farm? farm,
    required String? variety,
    required String? grade,
    required String? maturityLevel,
    required String? shelfLifeEstimate,
    required String? harvestMethod,
    required DateTime? harvestDate,
    required String quantityText,
    required String fruitCountText,
    required String? photoPath,
  }) {
    if (farm == null) {
      return 'Silakan pilih lokasi kebun terlebih dahulu.';
    }
    // [ERROR - Exception Handling] Foto menjadi bukti visual awal batch,
    // sehingga form ditolak bila petani belum menambahkan gambar durian.
    if (photoPath == null || photoPath.isEmpty) {
      return 'Tambahkan foto durian terlebih dahulu.';
    }
    if (variety == null || variety.isEmpty) {
      return 'Silakan pilih varietas durian.';
    }
    if (grade == null || grade.isEmpty) {
      return 'Silakan pilih grade awal estimasi petani.';
    }
    if (maturityLevel == null || maturityLevel.isEmpty) {
      return 'Silakan pilih tingkat kematangan durian.';
    }
    if (shelfLifeEstimate == null || shelfLifeEstimate.isEmpty) {
      return 'Silakan pilih estimasi masa simpan durian.';
    }
    if (harvestMethod == null || harvestMethod.isEmpty) {
      return 'Silakan pilih metode panen.';
    }
    if (harvestDate == null) {
      return 'Silakan pilih tanggal panen.';
    }
    return validateHarvestDate(harvestDate) ??
        validateQuantity(quantityText) ??
        validateFruitCount(fruitCountText);
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

  // [ERROR - Exception Handling] Validator ini memastikan jumlah buah per
  // batch berupa bilangan bulat positif karena satuannya adalah butir.
  static String? validateFruitCount(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      return 'Jumlah buah wajib diisi.';
    }
    final value = int.tryParse(trimmed);
    if (value == null || value <= 0) {
      return 'Jumlah buah harus berupa angka bulat lebih dari nol.';
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

  // [ERROR - Exception Handling] validateCreateFarm adalah entry point
  // validasi form Buat Kebun — field wajib dicek berurutan, koordinat
  // opsional hanya divalidasi bila diisi.
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
