import '../models/harvest_batch.dart';

/// Sumber data dummy untuk Beranda Petani selama tahap FE-only.
///
/// Semua nilai di sini akan diganti dengan response API saat backend siap.
class FarmerMockData {
  FarmerMockData._();

  /// Profil petani yang sedang login.
  static const FarmerProfile profile = FarmerProfile(
    fullName: 'Risqi Firdaus Setiawan',
    roleLabel: 'Petani Durian',
    location: 'Desa Pakis, Kab. Jember',
  );

  /// Daftar batch panen milik petani (paling baru di atas).
  static final List<HarvestBatch> batches = [
    HarvestBatch(
      code: 'DRN-2026-000128',
      variety: 'Montong',
      grade: 'A',
      quantity: 52,
      unit: 'kg',
      harvestDate: DateTime(2026, 5, 24),
      farmName: 'Kebun Pakis 1',
      status: BatchStatus.created,
    ),
    HarvestBatch(
      code: 'DRN-2026-000119',
      variety: 'Bawor',
      grade: 'B',
      quantity: 40,
      unit: 'kg',
      harvestDate: DateTime(2026, 5, 20),
      farmName: 'Kebun Pakis 1',
      status: BatchStatus.verifiedByCollector,
    ),
    HarvestBatch(
      code: 'DRN-2026-000103',
      variety: 'Montong',
      grade: 'A',
      quantity: 65,
      unit: 'kg',
      harvestDate: DateTime(2026, 5, 12),
      farmName: 'Kebun Curah 2',
      status: BatchStatus.inDistribution,
    ),
    HarvestBatch(
      code: 'DRN-2026-000097',
      variety: 'Petruk',
      grade: 'B',
      quantity: 38,
      unit: 'kg',
      harvestDate: DateTime(2026, 5, 5),
      farmName: 'Kebun Curah 2',
      status: BatchStatus.receivedByUmkm,
    ),
    HarvestBatch(
      code: 'DRN-2026-000088',
      variety: 'Montong',
      grade: 'A',
      quantity: 70,
      unit: 'kg',
      harvestDate: DateTime(2026, 4, 28),
      farmName: 'Kebun Pakis 1',
      status: BatchStatus.processed,
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
