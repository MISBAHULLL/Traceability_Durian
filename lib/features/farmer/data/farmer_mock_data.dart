import '../models/harvest_batch.dart';

/// Sumber data dummy untuk Beranda Petani selama tahap FE-only.
///
/// Semua nilai di sini akan diganti dengan response API saat backend siap.
/// Pada task 13.3, seed data ini akan dipindahkan ke dalam [FarmerRepository].
class FarmerMockData {
  FarmerMockData._();

  /// ID petani yang sedang login (mock).
  static const String currentFarmerId = 'farmer-001';

  /// Profil petani yang sedang login.
  static const FarmerProfile profile = FarmerProfile(
    farmerId: currentFarmerId,
    fullName: 'Risqi Firdaus Setiawan',
    roleLabel: 'Petani Durian',
    location: 'Desa Pakis, Kab. Jember',
    village: 'Pakis',
    district: 'Pakis',
    city: 'Kabupaten Jember',
    contact: '081234567890',
  );

  /// Daftar batch panen milik petani (paling baru di atas).
  static final List<HarvestBatch> batches = [
    HarvestBatch(
      code: 'DRN-2026-000128',
      farmerId: currentFarmerId,
      farmId: 'farm-001',
      variety: 'Montong',
      grade: 'A',
      quantity: 52,
      unit: 'kg',
      harvestDate: DateTime(2026, 5, 24),
      farmName: 'Kebun Pakis 1',
      status: BatchStatus.created,
      fertilizer: 'Organik Kompos',
      harvestMethod: 'Jatuh Alami',
      createdAt: DateTime(2026, 5, 24, 8, 30),
    ),
    HarvestBatch(
      code: 'DRN-2026-000119',
      farmerId: currentFarmerId,
      farmId: 'farm-001',
      variety: 'Bawor',
      grade: 'B',
      quantity: 40,
      unit: 'kg',
      harvestDate: DateTime(2026, 5, 20),
      farmName: 'Kebun Pakis 1',
      status: BatchStatus.verifiedByCollector,
      fertilizer: 'NPK',
      harvestMethod: 'Petik Matang',
      createdAt: DateTime(2026, 5, 20, 9, 0),
    ),
    HarvestBatch(
      code: 'DRN-2026-000103',
      farmerId: currentFarmerId,
      farmId: 'farm-002',
      variety: 'Montong',
      grade: 'A',
      quantity: 65,
      unit: 'kg',
      harvestDate: DateTime(2026, 5, 12),
      farmName: 'Kebun Curah 2',
      status: BatchStatus.inDistribution,
      fertilizer: 'Kandang',
      harvestMethod: 'Jatuh Alami',
      createdAt: DateTime(2026, 5, 12, 7, 45),
    ),
    HarvestBatch(
      code: 'DRN-2026-000097',
      farmerId: currentFarmerId,
      farmId: 'farm-002',
      variety: 'Petruk',
      grade: 'B',
      quantity: 38,
      unit: 'kg',
      harvestDate: DateTime(2026, 5, 5),
      farmName: 'Kebun Curah 2',
      status: BatchStatus.receivedByUmkm,
      fertilizer: 'Hayati',
      harvestMethod: 'Petik Matang',
      createdAt: DateTime(2026, 5, 5, 10, 15),
    ),
    HarvestBatch(
      code: 'DRN-2026-000088',
      farmerId: currentFarmerId,
      farmId: 'farm-001',
      variety: 'Montong',
      grade: 'A',
      quantity: 70,
      unit: 'kg',
      harvestDate: DateTime(2026, 4, 28),
      farmName: 'Kebun Pakis 1',
      status: BatchStatus.processed,
      fertilizer: 'Organik Kompos',
      harvestMethod: 'Jatuh Alami',
      createdAt: DateTime(2026, 4, 28, 8, 0),
    ),
  ];

  /// Total seluruh batch yang pernah dibuat petani.
  static int get totalBatch => batches.length;

  /// Jumlah batch yang masih aktif berjalan di rantai pasok.
  static int get activeBatch =>
      batches.where((b) => b.status.isActive).length;

  /// Jumlah batch yang sudah diverifikasi pengepul.
  static int get verifiedBatch => batches
      .where((b) => b.status == BatchStatus.verifiedByCollector)
      .length;
}
