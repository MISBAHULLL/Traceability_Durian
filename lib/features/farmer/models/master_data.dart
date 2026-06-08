// [CONFIG - Environment] Kelas ini menyimpan konstanta master data dropdown
// yang saat ini hardcoded — dirancang agar mudah diganti dengan pemanggilan
// API master data di masa depan.
/// Daftar opsi master data untuk dropdown pada form Tambah Batch Panen.
///
/// Konstanta ini mudah diganti dengan data dari API di masa depan (Req 2.2).
class FarmerMasterData {
  FarmerMasterData._();

  /// Varietas durian yang tersedia.
  static const List<String> varieties = [
    'Montong',
    'Bawor',
    'Petruk',
    'Musang King',
    'Bido',
    'Pelangi',
  ];

  /// Jenis pupuk yang tersedia.
  static const List<String> fertilizers = [
    'Organik Kompos',
    'NPK',
    'Kandang',
    'Hayati',
    'Tanpa Pupuk',
  ];

  /// Metode panen yang tersedia.
  static const List<String> harvestMethods = [
    'Jatuh Alami',
    'Petik Matang',
    'Petik Selektif',
  ];

  /// Grade/mutu durian yang tersedia.
  static const List<String> grades = ['A', 'B', 'C'];

  /// Tingkat kematangan durian saat dicatat oleh petani.
  static const List<String> maturityLevels = [
    'Mentah',
    'Setengah Matang',
    'Matang',
    'Matang Pohon',
  ];

  /// Estimasi masa simpan durian segar untuk informasi konsumen.
  static const List<String> shelfLifeEstimates = [
    '1 hari',
    '2-3 hari',
    '4-5 hari',
    'Lebih dari 5 hari',
  ];
}
