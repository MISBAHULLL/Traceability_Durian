// [DB - Model/Entity] Kondisi fisik PGL saat diterima pengepul lain.
enum CollectorIncomingReceiptCondition { good, minorDamage, damaged }

extension CollectorIncomingReceiptConditionX
    on CollectorIncomingReceiptCondition {
  String get label {
    switch (this) {
      case CollectorIncomingReceiptCondition.good:
        return 'Baik';
      case CollectorIncomingReceiptCondition.minorDamage:
        return 'Ada kerusakan ringan';
      case CollectorIncomingReceiptCondition.damaged:
        return 'Rusak / tidak sesuai';
    }
  }
}

// [DB - Model/Entity] Receipt penerimaan PGL antar pengepul. Data ini terpisah
// dari manifest pengirim agar jumlah kirim dan jumlah terima tetap auditabel.
class CollectorIncomingReceipt {
  const CollectorIncomingReceipt({
    required this.shipmentCode,
    required this.receiverCollectorId,
    required this.senderCollectorId,
    required this.expectedWeightKg,
    required this.expectedFruitCount,
    required this.receivedWeightKg,
    required this.receivedFruitCount,
    required this.condition,
    required this.receivedAt,
    required this.destinationWarehouseId,
    required this.destinationWarehouseName,
    required this.destinationLocation,
    this.discrepancyNote,
    this.qualityNote,
  });

  final String shipmentCode;
  final String receiverCollectorId;
  final String senderCollectorId;
  final double expectedWeightKg;
  final int expectedFruitCount;
  final double receivedWeightKg;
  final int receivedFruitCount;
  final CollectorIncomingReceiptCondition condition;
  final DateTime receivedAt;
  final String destinationWarehouseId;
  final String destinationWarehouseName;
  final String destinationLocation;
  final String? discrepancyNote;
  final String? qualityNote;

  double get weightDifferenceKg => receivedWeightKg - expectedWeightKg;
  int get fruitDifference => receivedFruitCount - expectedFruitCount;
  bool get hasDiscrepancy =>
      weightDifferenceKg.abs() > 0.01 || fruitDifference != 0;

  Map<String, dynamic> toJson() => {
    'shipmentCode': shipmentCode,
    'receiverCollectorId': receiverCollectorId,
    'senderCollectorId': senderCollectorId,
    'expectedWeightKg': expectedWeightKg,
    'expectedFruitCount': expectedFruitCount,
    'receivedWeightKg': receivedWeightKg,
    'receivedFruitCount': receivedFruitCount,
    'condition': condition.name,
    'receivedAt': receivedAt.toIso8601String(),
    'destinationWarehouseId': destinationWarehouseId,
    'destinationWarehouseName': destinationWarehouseName,
    'destinationLocation': destinationLocation,
    'discrepancyNote': discrepancyNote,
    'qualityNote': qualityNote,
  };

  factory CollectorIncomingReceipt.fromJson(Map<String, dynamic> json) {
    return CollectorIncomingReceipt(
      shipmentCode: json['shipmentCode'] as String,
      receiverCollectorId: json['receiverCollectorId'] as String,
      senderCollectorId: json['senderCollectorId'] as String? ?? '',
      expectedWeightKg: (json['expectedWeightKg'] as num).toDouble(),
      expectedFruitCount: (json['expectedFruitCount'] as num).toInt(),
      receivedWeightKg: (json['receivedWeightKg'] as num).toDouble(),
      receivedFruitCount: (json['receivedFruitCount'] as num).toInt(),
      condition: CollectorIncomingReceiptCondition.values.firstWhere(
        (value) => value.name == json['condition'],
        orElse: () => CollectorIncomingReceiptCondition.good,
      ),
      receivedAt: DateTime.parse(json['receivedAt'] as String),
      destinationWarehouseId: json['destinationWarehouseId'] as String? ?? '',
      destinationWarehouseName:
          json['destinationWarehouseName'] as String? ?? 'Gudang Pengepul',
      destinationLocation:
          json['destinationLocation'] as String? ?? 'Gudang Pengepul',
      discrepancyNote: json['discrepancyNote'] as String?,
      qualityNote: json['qualityNote'] as String?,
    );
  }
}
