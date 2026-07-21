// [DB - Model/Entity] Model gudang pengepul untuk fase FE-only. Data ini
// hanya menyimpan lokasi penyimpanan ringan, bukan manajemen gudang penuh.
class CollectorWarehouse {
  const CollectorWarehouse({
    required this.id,
    required this.name,
    required this.location,
    this.note,
    this.isDefault = false,
    this.createdAt,
  });

  final String id;
  final String name;
  final String location;
  final String? note;
  final bool isDefault;
  final DateTime? createdAt;

  CollectorWarehouse copyWith({
    String? id,
    String? name,
    String? location,
    String? note,
    bool? isDefault,
    DateTime? createdAt,
  }) {
    return CollectorWarehouse(
      id: id ?? this.id,
      name: name ?? this.name,
      location: location ?? this.location,
      note: note ?? this.note,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'location': location,
        'note': note,
        'isDefault': isDefault,
        'createdAt': createdAt?.toIso8601String(),
      };

  factory CollectorWarehouse.fromJson(Map<String, dynamic> json) {
    return CollectorWarehouse(
      id: json['id'] as String,
      name: json['name'] as String,
      location: json['location'] as String? ?? '',
      note: json['note'] as String?,
      isDefault: json['isDefault'] as bool? ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
    );
  }
}
