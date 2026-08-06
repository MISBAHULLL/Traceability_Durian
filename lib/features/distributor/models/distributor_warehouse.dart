// [DB - Model/Entity] Gudang operasional distributor untuk fase FE-only.
class DistributorWarehouse {
  const DistributorWarehouse({
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

  DistributorWarehouse copyWith({
    String? id,
    String? name,
    String? location,
    String? note,
    bool? isDefault,
    DateTime? createdAt,
  }) {
    return DistributorWarehouse(
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

  factory DistributorWarehouse.fromJson(Map<String, dynamic> json) {
    return DistributorWarehouse(
      id: json['id'] as String,
      name: json['name'] as String,
      location: json['location'] as String? ?? '',
      note: json['note'] as String?,
      isDefault: json['isDefault'] as bool? ?? false,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
    );
  }
}

// [DB - Model/Entity] Catatan transfer stok antar gudang internal distributor.
class DistributorWarehouseTransfer {
  const DistributorWarehouseTransfer({
    required this.id,
    required this.distributorId,
    required this.fromWarehouseId,
    required this.toWarehouseId,
    required this.itemCode,
    required this.weightKg,
    required this.fruitCount,
    required this.transferredAt,
    this.note,
  });

  final String id;
  final String distributorId;
  final String fromWarehouseId;
  final String toWarehouseId;
  final String itemCode;
  final double weightKg;
  final int fruitCount;
  final DateTime transferredAt;
  final String? note;

  Map<String, dynamic> toJson() => {
    'id': id,
    'distributorId': distributorId,
    'fromWarehouseId': fromWarehouseId,
    'toWarehouseId': toWarehouseId,
    'itemCode': itemCode,
    'weightKg': weightKg,
    'fruitCount': fruitCount,
    'transferredAt': transferredAt.toIso8601String(),
    'note': note,
  };

  factory DistributorWarehouseTransfer.fromJson(Map<String, dynamic> json) {
    return DistributorWarehouseTransfer(
      id: json['id'] as String,
      distributorId: json['distributorId'] as String,
      fromWarehouseId: json['fromWarehouseId'] as String,
      toWarehouseId: json['toWarehouseId'] as String,
      itemCode: json['itemCode'] as String,
      weightKg: (json['weightKg'] as num).toDouble(),
      fruitCount: (json['fruitCount'] as num).toInt(),
      transferredAt: DateTime.parse(json['transferredAt'] as String),
      note: json['note'] as String?,
    );
  }
}
