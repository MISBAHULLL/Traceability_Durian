// [DB - Model/Entity] Riwayat transfer stok antar gudang pengepul.
// Transfer saat ini bersifat per-batch utuh agar jumlah dan trace tidak pecah
// tanpa proses split batch yang formal.
class CollectorWarehouseTransfer {
  const CollectorWarehouseTransfer({
    required this.id,
    required this.collectorId,
    required this.batchCode,
    required this.fromWarehouseId,
    required this.fromWarehouseName,
    required this.toWarehouseId,
    required this.toWarehouseName,
    required this.weightKg,
    required this.fruitCount,
    required this.reason,
    required this.actorName,
    required this.transferredAt,
  });

  final String id;
  final String collectorId;
  final String batchCode;
  final String fromWarehouseId;
  final String fromWarehouseName;
  final String toWarehouseId;
  final String toWarehouseName;
  final double weightKg;
  final int fruitCount;
  final String reason;
  final String actorName;
  final DateTime transferredAt;

  Map<String, dynamic> toJson() => {
    'id': id,
    'collectorId': collectorId,
    'batchCode': batchCode,
    'fromWarehouseId': fromWarehouseId,
    'fromWarehouseName': fromWarehouseName,
    'toWarehouseId': toWarehouseId,
    'toWarehouseName': toWarehouseName,
    'weightKg': weightKg,
    'fruitCount': fruitCount,
    'reason': reason,
    'actorName': actorName,
    'transferredAt': transferredAt.toIso8601String(),
  };

  factory CollectorWarehouseTransfer.fromJson(Map<String, dynamic> json) {
    return CollectorWarehouseTransfer(
      id: json['id'] as String,
      collectorId: json['collectorId'] as String,
      batchCode: json['batchCode'] as String,
      fromWarehouseId: json['fromWarehouseId'] as String,
      fromWarehouseName: json['fromWarehouseName'] as String,
      toWarehouseId: json['toWarehouseId'] as String,
      toWarehouseName: json['toWarehouseName'] as String,
      weightKg: (json['weightKg'] as num).toDouble(),
      fruitCount: (json['fruitCount'] as num?)?.toInt() ?? 0,
      reason: json['reason'] as String? ?? '',
      actorName: json['actorName'] as String? ?? 'Pengepul',
      transferredAt: DateTime.parse(json['transferredAt'] as String),
    );
  }
}
