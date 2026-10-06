import '../../../core/network/backend_api_client.dart';

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
        code: backendString(json, const ['code']),
        name: backendString(json, const ['name']),
        category: ProductCategory.values.firstWhere(
          (e) => e.name == backendString(json, const ['category']),
          orElse: () => ProductCategory.durianSegar,
        ),
        weightRange: backendString(json, const ['weightRange'], '-'),
        taste: backendString(json, const ['taste'], '-'),
        fleshDescription: backendString(json, const ['fleshDescription'], '-'),
        location: backendString(json, const ['location']),
        harvestDate:
            backendDateTime(json, const ['harvestDate', 'harvest_date']) ??
            DateTime.now(),
        treeOwner: backendString(json, const ['treeOwner', 'tree_owner'], '-'),
        grade: backendNullableString(json, const ['grade', 'verifiedGrade', 'verified_grade']),
        fruitCount: backendInt(json, const ['fruitCount', 'fruit_count']),
        maturityLevel: backendNullableString(json, const ['maturityLevel', 'maturity_level']),
        shelfLifeEstimate: backendNullableString(json, const ['shelfLifeEstimate', 'shelf_life_estimate']),
        storageSuggestion: backendNullableString(json, const ['storageSuggestion', 'storage_suggestion']),
        imagePath: backendNullableString(json, const ['imagePath', 'photo_path']),
      );

  // [DB - Model/Entity] Equality berbasis kode+kategori membuat item dropdown
  // tetap dikenali meski repository membangun instance produk baru.
  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is CollectorProduct &&
            other.code == code &&
            other.category == category;
  }

  @override
  int get hashCode => Object.hash(code, category);
}

// [DB - Model/Entity] Model ini merepresentasikan profil pengepul yang login —
// dipakai oleh CollectorRepository sebagai data sesi mock.
/// Data profil pengepul yang login (mock untuk tahap FE).
class CollectorProfile {
  const CollectorProfile({
    required this.collectorId,
    required this.fullName,
    required this.roleLabel,
    this.businessName = '',
    this.contact = '',
    this.email = '',
    this.location = '',
    this.village = '',
    this.district = '',
    this.city = '',
    this.province = '',
    this.address = '',
    this.avatarPath,
  });

  /// ID unik pengepul — dipakai untuk isolasi data.
  final String collectorId;

  final String fullName;
  final String roleLabel;

  // [DB - Model/Entity] Field profil operasional ini menjadi identitas
  // pengepul saat verifikasi batch dan transaksi distribusi.
  final String businessName;
  final String contact;
  final String email;

  /// Lokasi operasi ringkas (opsional, ditampilkan di greeting bila ada).
  final String location;

  final String village;
  final String district;
  final String city;
  final String province;
  final String address;

  /// Path/URI foto profil (opsional). Null berarti pakai avatar inisial.
  final String? avatarPath;

  CollectorProfile copyWith({
    String? collectorId,
    String? fullName,
    String? roleLabel,
    String? businessName,
    String? contact,
    String? email,
    String? location,
    String? village,
    String? district,
    String? city,
    String? province,
    String? address,
    String? avatarPath,
  }) {
    return CollectorProfile(
      collectorId: collectorId ?? this.collectorId,
      fullName: fullName ?? this.fullName,
      roleLabel: roleLabel ?? this.roleLabel,
      businessName: businessName ?? this.businessName,
      contact: contact ?? this.contact,
      email: email ?? this.email,
      location: location ?? this.location,
      village: village ?? this.village,
      district: district ?? this.district,
      city: city ?? this.city,
      province: province ?? this.province,
      address: address ?? this.address,
      avatarPath: avatarPath ?? this.avatarPath,
    );
  }

  /// Serialisasi ke Map untuk penyimpanan lokal.
  Map<String, dynamic> toJson() => {
    'collectorId': collectorId,
    'fullName': fullName,
    'roleLabel': roleLabel,
    'businessName': businessName,
    'contact': contact,
    'email': email,
    'location': location,
    'village': village,
    'district': district,
    'city': city,
    'province': province,
    'address': address,
    'avatarPath': avatarPath,
  };

  /// Deserialisasi dari Map.
  factory CollectorProfile.fromJson(Map<String, dynamic> json) =>
      CollectorProfile(
        collectorId: backendString(json, const ['collectorId', 'id'], 'collector-unknown'),
        fullName: backendString(json, const ['fullName', 'full_name']),
        roleLabel: backendString(json, const ['roleLabel'], 'Pengepul'),
        businessName: backendString(json, const ['businessName'], ''),
        contact: backendString(json, const ['contact', 'phone']),
        email: backendString(json, const ['email'], ''),
        location: backendString(json, const ['location']),
        village: backendString(json, const ['village']),
        district: backendString(json, const ['district']),
        city: backendString(json, const ['city']),
        province: backendString(json, const ['province']),
        address: backendString(json, const ['address']),
        avatarPath: backendNullableString(json, const ['avatarPath', 'avatar_path']),
      );
}
