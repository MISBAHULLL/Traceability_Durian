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
  final String about;
  final String? imagePath;
  final Uint8List? imageBytes;

  UmkmProfile copyWith({
    String? name,
    String? ownerName,
    String? contact,
    String? email,
    String? location,
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
    'about': about,
    'imagePath': imagePath,
    'imageBytes': imageBytes?.toList(),
  };

  factory UmkmProfile.fromJson(Map<String, dynamic> json) {
    final rawBytes = json['imageBytes'];
    return UmkmProfile(
      umkmId: json['umkmId'] as String? ?? 'umkm-001',
      name: json['name'] as String? ?? 'UMKM Durian',
      ownerName: json['ownerName'] as String? ?? '-',
      contact: json['contact'] as String? ?? '',
      email: json['email'] as String? ?? '',
      location: json['location'] as String? ?? '',
      about: json['about'] as String? ?? '',
      imagePath: json['imagePath'] as String?,
      imageBytes: rawBytes is List
          ? Uint8List.fromList(
              rawBytes.whereType<num>().map((item) => item.toInt()).toList(),
            )
          : null,
    );
  }
}
