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

  @override
  String toString() => name;
}
