import '../../../core/network/backend_api_client.dart';
import 'dart:typed_data';

class UmkmProfile {
  static const Object _unset = Object();

  const UmkmProfile({
    required this.umkmId,
    required this.name,
    required this.ownerName,
    required this.contact,
    required this.email,
    required this.location,
    this.village = '',
    this.district = '',
    this.city = '',
    this.province = '',
    required this.about,
    this.imagePath,
    this.imageBytes,
  });

  final String umkmId;
  final String name;
  final String ownerName;
  final String contact;
  final String email;
  final String location;
  final String village;
  final String district;
  final String city;
  final String province;
  final String about;
  final String? imagePath;
  final Uint8List? imageBytes;

  UmkmProfile copyWith({
    String? name,
    String? ownerName,
    String? contact,
    String? email,
    String? location,
    String? village,
    String? district,
    String? city,
    String? province,
    String? about,
    Object? imagePath = _unset,
    Object? imageBytes = _unset,
  }) {
    return UmkmProfile(
      umkmId: umkmId,
      name: name ?? this.name,
      ownerName: ownerName ?? this.ownerName,
      contact: contact ?? this.contact,
      email: email ?? this.email,
      location: location ?? this.location,
      village: village ?? this.village,
      district: district ?? this.district,
      city: city ?? this.city,
      province: province ?? this.province,
      about: about ?? this.about,
      imagePath: imagePath == _unset ? this.imagePath : imagePath as String?,
      imageBytes: imageBytes == _unset
          ? this.imageBytes
          : imageBytes as Uint8List?,
    );
  }

  Map<String, dynamic> toJson() => {
    'umkmId': umkmId,
    'name': name,
    'ownerName': ownerName,
    'contact': contact,
    'email': email,
    'location': location,
    'village': village,
    'district': district,
    'city': city,
    'province': province,
    'about': about,
    'imagePath': imagePath,
    'imageBytes': imageBytes?.toList(),
  };

  factory UmkmProfile.fromJson(Map<String, dynamic> json) {
    final rawBytes = json['imageBytes'];
    return UmkmProfile(
      umkmId: backendString(json, const ['umkmId', 'id'], 'umkm-001'),
      name: backendString(json, const ['name'], 'UMKM Durian'),
      ownerName: backendString(json, const ['ownerName', 'owner_name'], '-'),
      contact: backendString(json, const ['contact', 'phone']),
      email: backendString(json, const ['email']),
      location: backendString(json, const ['location', 'address']),
      village: backendString(json, const ['village']),
      district: backendString(json, const ['district']),
      city: backendString(json, const ['city']),
      province: backendString(json, const ['province']),
      about: backendString(json, const ['about']),
      imagePath: backendNullableString(json, const ['imagePath', 'image_path']),
      imageBytes: rawBytes is List
          ? Uint8List.fromList(
              rawBytes.whereType<num>().map((item) => item.toInt()).toList(),
            )
          : null,
    );
  }
}
