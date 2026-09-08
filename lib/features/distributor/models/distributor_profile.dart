import '../../../core/network/backend_api_client.dart';

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
        distributorId: backendString(json, const ['distributorId', 'id'], 'distributor-unknown'),
        fullName: backendString(json, const ['fullName', 'full_name']),
        roleLabel: backendString(json, const ['roleLabel'], 'Distributor Durian'),
        businessName: backendString(json, const ['businessName'], ''),
        contact: backendString(json, const ['contact', 'phone']),
        email: backendString(json, const ['email'], ''),
        location: backendString(json, const ['location']),
        village: backendString(json, const ['village']),
        district: backendString(json, const ['district']),
        city: backendString(json, const ['city']),
        address: backendString(json, const ['address']),
        avatarPath: backendNullableString(json, const ['avatarPath', 'avatar_path']),
      );
}
