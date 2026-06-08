// [DB - Model/Entity] Enum ini merepresentasikan kategori produk yang
// ditampilkan sebagai chip filter di Beranda Pengepul (mengikuti prototype:
// Durian Segar, Durian Olahan, Bibit Durian).
/// Kategori produk pada Beranda Pengepul.
///
/// Sesuai prototype "Beranda — Pengepul Durian", produk dikelompokkan ke
/// dalam tiga kategori yang ditampilkan sebagai chip filter horizontal.
enum ProductCategory { durianSegar, durianOlahan, bibitDurian }

// [FE - Component Rendering] Extension ini menyediakan label tampilan untuk
// tiap kategori — dikonsumsi langsung oleh widget chip filter.
/// Label tampilan untuk tiap [ProductCategory].
extension ProductCategoryX on ProductCategory {
  String get label {
    switch (this) {
      case ProductCategory.durianSegar:
        return 'Durian Segar';
      case ProductCategory.durianOlahan:
        return 'Durian Olahan';
      case ProductCategory.bibitDurian:
        return 'Bibit Durian';
    }
  }
}

// [DB - Model/Entity] Model ini merepresentasikan satu produk durian yang
// tersedia untuk dibeli pengepul. Datanya berasal dari batch panen petani
// (warisan, read-only bagi pengepul) sesuai Role Permission Matrix —
// pengepul tidak boleh mengubah data panen.
/// Model satu produk durian yang dapat dibeli/diverifikasi pengepul.
///
/// Field deskriptif (berat, rasa, daging buah, lokasi, tanggal panen, pemilik
/// pohon) berasal dari data panen petani dan ditampilkan apa adanya pada kartu
/// produk Beranda Pengepul — mengikuti prototype.
class CollectorProduct {
  const CollectorProduct({
    required this.code,
    required this.name,
    required this.category,
    required this.weightRange,
    required this.taste,
    required this.fleshDescription,
    required this.location,
    required this.harvestDate,
    required this.treeOwner,
    this.grade,
    this.fruitCount,
    this.maturityLevel,
    this.shelfLifeEstimate,
    this.storageSuggestion,
    this.imagePath,
  });

  /// Kode unik produk, contoh: DRN-2026-000128 — dipakai untuk pencarian.
  final String code;

  /// Nama produk, contoh: "Durian Montong".
  final String name;

  /// Kategori produk (segar/olahan/bibit).
  final ProductCategory category;

  /// Rentang berat, contoh: "3 - 6 Kg".
  final String weightRange;

  /// Deskripsi rasa, contoh: "Manis legit dan intens".
  final String taste;

  /// Deskripsi daging buah.
  final String fleshDescription;

  /// Lokasi asal dalam tingkat desa/kecamatan/kabupaten.
  final String location;

  /// Tanggal panen.
  final DateTime harvestDate;

  /// Pemilik pohon (petani), contoh: "Bapak Rusdi".
  final String treeOwner;

  // [DB - Model/Entity] Metadata ini diwariskan dari HarvestBatch petani agar
  // pengepul membaca kualitas awal tanpa mengubah data sumber batch.
  final String? grade;
  final int? fruitCount;
  final String? maturityLevel;
  final String? shelfLifeEstimate;
  final String? storageSuggestion;

  /// Path/URI gambar produk (opsional). Null berarti pakai aset fallback.
  final String? imagePath;

  /// Serialisasi ke Map untuk penyimpanan lokal.
  Map<String, dynamic> toJson() => {
    'code': code,
    'name': name,
    'category': category.name,
    'weightRange': weightRange,
    'taste': taste,
    'fleshDescription': fleshDescription,
    'location': location,
    'harvestDate': harvestDate.toIso8601String(),
    'treeOwner': treeOwner,
    'grade': grade,
    'fruitCount': fruitCount,
    'maturityLevel': maturityLevel,
    'shelfLifeEstimate': shelfLifeEstimate,
    'storageSuggestion': storageSuggestion,
    'imagePath': imagePath,
  };

  /// Deserialisasi dari Map.
  factory CollectorProduct.fromJson(Map<String, dynamic> json) =>
      CollectorProduct(
        code: json['code'] as String,
        name: json['name'] as String,
        category: ProductCategory.values.firstWhere(
          (e) => e.name == json['category'],
          orElse: () => ProductCategory.durianSegar,
        ),
        weightRange: json['weightRange'] as String,
        taste: json['taste'] as String,
        fleshDescription: json['fleshDescription'] as String,
        location: json['location'] as String,
        harvestDate: DateTime.parse(json['harvestDate'] as String),
        treeOwner: json['treeOwner'] as String,
        grade: json['grade'] as String?,
        fruitCount: (json['fruitCount'] as num?)?.toInt(),
        maturityLevel: json['maturityLevel'] as String?,
        shelfLifeEstimate: json['shelfLifeEstimate'] as String?,
        storageSuggestion: json['storageSuggestion'] as String?,
        imagePath: json['imagePath'] as String?,
      );
}

// [DB - Model/Entity] Model ini merepresentasikan profil pengepul yang login —
// dipakai oleh CollectorRepository sebagai data sesi mock.
/// Data profil pengepul yang login (mock untuk tahap FE).
class CollectorProfile {
  const CollectorProfile({
    required this.collectorId,
    required this.fullName,
    required this.roleLabel,
    this.location = '',
    this.avatarPath,
  });

  /// ID unik pengepul — dipakai untuk isolasi data.
  final String collectorId;

  final String fullName;
  final String roleLabel;

  /// Lokasi operasi ringkas (opsional, ditampilkan di greeting bila ada).
  final String location;

  /// Path/URI foto profil (opsional). Null berarti pakai avatar inisial.
  final String? avatarPath;

  CollectorProfile copyWith({
    String? collectorId,
    String? fullName,
    String? roleLabel,
    String? location,
    String? avatarPath,
  }) {
    return CollectorProfile(
      collectorId: collectorId ?? this.collectorId,
      fullName: fullName ?? this.fullName,
      roleLabel: roleLabel ?? this.roleLabel,
      location: location ?? this.location,
      avatarPath: avatarPath ?? this.avatarPath,
    );
  }

  /// Serialisasi ke Map untuk penyimpanan lokal.
  Map<String, dynamic> toJson() => {
    'collectorId': collectorId,
    'fullName': fullName,
    'roleLabel': roleLabel,
    'location': location,
    'avatarPath': avatarPath,
  };

  /// Deserialisasi dari Map.
  factory CollectorProfile.fromJson(Map<String, dynamic> json) =>
      CollectorProfile(
        collectorId: json['collectorId'] as String,
        fullName: json['fullName'] as String,
        roleLabel: json['roleLabel'] as String,
        location: (json['location'] as String?) ?? '',
        avatarPath: json['avatarPath'] as String?,
      );
}
