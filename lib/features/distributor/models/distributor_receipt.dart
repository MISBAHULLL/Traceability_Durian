// [DB - Model/Entity] Enum ini merepresentasikan kondisi fisik umum saat
// manifest pengepul tiba dan diperiksa oleh distributor.
enum DistributorReceiptCondition { good, minorDamage, damaged }

extension DistributorReceiptConditionX on DistributorReceiptCondition {
  String get label {
    switch (this) {
      case DistributorReceiptCondition.good:
        return 'Baik';
      case DistributorReceiptCondition.minorDamage:
        return 'Ada kerusakan ringan';
      case DistributorReceiptCondition.damaged:
        return 'Rusak / tidak sesuai';
    }
  }
}

// [DB - Model/Entity] Receipt ini menjadi bukti penerimaan distributor yang
// terpisah dari manifest pengepul agar nilai kirim dan nilai terima auditabel.
class DistributorReceipt {
  const DistributorReceipt({
    required this.shipmentCode,
    required this.distributorId,
    required this.expectedWeightKg,
    required this.expectedFruitCount,
    required this.receivedWeightKg,
    required this.receivedFruitCount,
    required this.condition,
    required this.receivedAt,
    required this.destinationLocation,
    this.discrepancyNote,
    this.qualityNote,
  });

  final String shipmentCode;
  final String distributorId;
  final double expectedWeightKg;
  final int expectedFruitCount;
  final double receivedWeightKg;
  final int receivedFruitCount;
  final DistributorReceiptCondition condition;
  final DateTime receivedAt;
  final String destinationLocation;
  final String? discrepancyNote;
  final String? qualityNote;

  double get weightDifferenceKg => receivedWeightKg - expectedWeightKg;
  int get fruitDifference => receivedFruitCount - expectedFruitCount;
  bool get hasDiscrepancy =>
      weightDifferenceKg.abs() > 0.01 || fruitDifference != 0;

  Map<String, dynamic> toJson() => {
    'shipmentCode': shipmentCode,
    'distributorId': distributorId,
    'expectedWeightKg': expectedWeightKg,
    'expectedFruitCount': expectedFruitCount,
    'receivedWeightKg': receivedWeightKg,
    'receivedFruitCount': receivedFruitCount,
    'condition': condition.name,
    'receivedAt': receivedAt.toIso8601String(),
    'destinationLocation': destinationLocation,
    'discrepancyNote': discrepancyNote,
    'qualityNote': qualityNote,
  };

  factory DistributorReceipt.fromJson(Map<String, dynamic> json) {
    return DistributorReceipt(
      shipmentCode: json['shipmentCode'] as String,
      distributorId: json['distributorId'] as String,
      expectedWeightKg: (json['expectedWeightKg'] as num).toDouble(),
      expectedFruitCount: (json['expectedFruitCount'] as num).toInt(),
      receivedWeightKg: (json['receivedWeightKg'] as num).toDouble(),
      receivedFruitCount: (json['receivedFruitCount'] as num).toInt(),
      condition: DistributorReceiptCondition.values.firstWhere(
        (value) => value.name == json['condition'],
        orElse: () => DistributorReceiptCondition.good,
      ),
      receivedAt: DateTime.parse(json['receivedAt'] as String),
      destinationLocation:
          json['destinationLocation'] as String? ?? 'Gudang Distributor',
      discrepancyNote: json['discrepancyNote'] as String?,
      qualityNote: json['qualityNote'] as String?,
    );
  }
}
