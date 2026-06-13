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
      imageBytes: imageBytes == _unset ? this.imageBytes : imageBytes as Uint8List?,
    );
  }
}
