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
    'Petik Mentah',
  ];

  /// Grade/mutu durian yang tersedia.
  static const List<String> grades = ['A', 'B', 'C'];

  /// Satuan berat yang tersedia.
  static const List<String> units = ['kg'];
}
