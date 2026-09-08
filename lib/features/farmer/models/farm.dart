import '../../../core/network/backend_api_client.dart';

// [DB - Model/Entity] Model ini merepresentasikan kebun durian milik petani
// sebagai entitas lokasi yang direlasikan ke HarvestBatch.
/// Model kebun durian milik petani.
///
/// Dipakai sebagai sumber opsi dropdown "Pilih Lokasi Kebun" pada
/// Layar Tambah Batch Panen (Req 5.3, 7.2).
class Farm {
  const Farm({
    required this.id,
    required this.farmerId,
    required this.name,
    required this.province,
    required this.city,
    required this.district,
    required this.village,
    required this.address,
    this.latitude,
    this.longitude,
  });

  /// ID unik kebun.
  final String id;

  /// ID petani pemilik kebun — dipakai untuk isolasi data (Req 7.2).
  final String farmerId;

  /// Nama kebun, contoh: "Kebun Pak Risqi".
  final String name;

  /// Provinsi, contoh: "Jawa Timur".
  final String province;

  /// Kota/kabupaten, contoh: "Kabupaten Malang".
  final String city;

  /// Kecamatan, contoh: "Tumpang".
  final String district;

  /// Desa, contoh: "Malangsuko".
  final String village;

  /// Alamat lengkap.
  final String address;

  /// Koordinat lintang (opsional).
  final double? latitude;

  /// Koordinat bujur (opsional).
  final double? longitude;

  /// Membuat salinan kebun dengan field yang diubah.
  Farm copyWith({
    String? id,
    String? farmerId,
    String? name,
    String? province,
    String? city,
    String? district,
    String? village,
    String? address,
    double? latitude,
    double? longitude,
  }) {
    return Farm(
      id: id ?? this.id,
      farmerId: farmerId ?? this.farmerId,
      name: name ?? this.name,
      province: province ?? this.province,
      city: city ?? this.city,
      district: district ?? this.district,
      village: village ?? this.village,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }

  // [DB - Model/Entity] Serialisasi ini mengubah entitas kebun menjadi JSON
  // lokal agar pilihan lokasi tetap tersimpan setelah aplikasi restart.
  Map<String, dynamic> toJson() => {
    'id': id,
    'farmerId': farmerId,
    'name': name,
    'province': province,
    'city': city,
    'district': district,
    'village': village,
    'address': address,
    'latitude': latitude,
    'longitude': longitude,
  };

  // [DB - Model/Entity] Factory ini membangun kembali entitas kebun dari JSON
  // lokal yang dibaca oleh FarmerRepository.
  factory Farm.fromJson(Map<String, dynamic> json) => Farm(
    id: backendString(json, const ['id']),
    farmerId: backendString(json, const ['farmerId', 'farmer_id', 'farmerUserId']),
    name: backendString(json, const ['name']),
    province: backendString(json, const ['province']),
    city: backendString(json, const ['city']),
    district: backendString(json, const ['district']),
    village: backendString(json, const ['village']),
    address: backendString(json, const ['address']),
    latitude: backendDouble(json, const ['latitude']),
    longitude: backendDouble(json, const ['longitude']),
  );

  @override
  String toString() => name;
}
