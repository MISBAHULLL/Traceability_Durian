class UmkmProfile {
  const UmkmProfile({
    required this.umkmId,
    required this.name,
    required this.ownerName,
    required this.contact,
    required this.email,
    required this.location,
    required this.about,
  });

  final String umkmId;
  final String name;
  final String ownerName;
  final String contact;
  final String email;
  final String location;
  final String about;

  UmkmProfile copyWith({
    String? name,
    String? ownerName,
    String? contact,
    String? email,
    String? location,
    String? about,
  }) {
    return UmkmProfile(
      umkmId: umkmId,
      name: name ?? this.name,
      ownerName: ownerName ?? this.ownerName,
      contact: contact ?? this.contact,
      email: email ?? this.email,
      location: location ?? this.location,
      about: about ?? this.about,
    );
  }
}
