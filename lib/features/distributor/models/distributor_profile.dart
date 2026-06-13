// [DB - Model/Entity] Model ini merepresentasikan data profil distributor
// yang disimpan secara lokal di SharedPreferences pada fase FE-only.
class DistributorProfile {
  const DistributorProfile({
    required this.distributorId,
    required this.fullName,
    required this.roleLabel,
    this.businessName = '',
    this.contact = '',
    this.email = '',
    this.location = '',
    this.village = '',
    this.district = '',
    this.city = '',
    this.address = '',
    this.avatarPath,
  });

  /// ID unik distributor.
  final String distributorId;

  final String fullName;
  final String roleLabel;

  final String businessName;
  final String contact;
  final String email;

  /// Lokasi operasi ringkas (opsional, ditampilkan di greeting bila ada).
  final String location;

  final String village;
  final String district;
  final String city;
  final String address;

  /// Path/URI foto profil (opsional). Null berarti pakai avatar inisial.
  final String? avatarPath;

  DistributorProfile copyWith({
    String? distributorId,
    String? fullName,
    String? roleLabel,
    String? businessName,
    String? contact,
    String? email,
    String? location,
    String? village,
    String? district,
    String? city,
    String? address,
    String? avatarPath,
  }) {
    return DistributorProfile(
      distributorId: distributorId ?? this.distributorId,
      fullName: fullName ?? this.fullName,
      roleLabel: roleLabel ?? this.roleLabel,
      businessName: businessName ?? this.businessName,
      contact: contact ?? this.contact,
      email: email ?? this.email,
      location: location ?? this.location,
      village: village ?? this.village,
      district: district ?? this.district,
      city: city ?? this.city,
      address: address ?? this.address,
      avatarPath: avatarPath ?? this.avatarPath,
    );
  }

  /// Serialisasi ke Map untuk penyimpanan lokal.
  Map<String, dynamic> toJson() => {
    'distributorId': distributorId,
    'fullName': fullName,
    'roleLabel': roleLabel,
    'businessName': businessName,
    'contact': contact,
    'email': email,
    'location': location,
    'village': village,
    'district': district,
    'city': city,
    'address': address,
    'avatarPath': avatarPath,
  };

  /// Deserialisasi dari Map.
  factory DistributorProfile.fromJson(Map<String, dynamic> json) =>
      DistributorProfile(
        distributorId: json['distributorId'] as String,
        fullName: json['fullName'] as String,
        roleLabel: json['roleLabel'] as String,
        businessName: (json['businessName'] as String?) ?? '',
        contact: (json['contact'] as String?) ?? '',
        email: (json['email'] as String?) ?? '',
        location: (json['location'] as String?) ?? '',
        village: (json['village'] as String?) ?? '',
        district: (json['district'] as String?) ?? '',
        city: (json['city'] as String?) ?? '',
        address: (json['address'] as String?) ?? '',
        avatarPath: json['avatarPath'] as String?,
      );
}
