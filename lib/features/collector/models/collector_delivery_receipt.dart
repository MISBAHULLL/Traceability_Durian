import 'collector_shipment_batch.dart';

enum CollectorDeliveryReceiptCondition { good, minorDamage, damaged }

extension CollectorDeliveryReceiptConditionX
    on CollectorDeliveryReceiptCondition {
  String get label {
    switch (this) {
      case CollectorDeliveryReceiptCondition.good:
        return 'Baik';
      case CollectorDeliveryReceiptCondition.minorDamage:
        return 'Ada kerusakan ringan';
      case CollectorDeliveryReceiptCondition.damaged:
        return 'Rusak / tidak sesuai';
    }
  }
}

enum CollectorDeliveryReceiptDecision { accepted, rejected }

extension CollectorDeliveryReceiptDecisionX
    on CollectorDeliveryReceiptDecision {
  String get label {
    switch (this) {
      case CollectorDeliveryReceiptDecision.accepted:
        return 'Diterima';
      case CollectorDeliveryReceiptDecision.rejected:
        return 'Ditolak';
    }
  }
}

class CollectorDeliveryReceipt {
  const CollectorDeliveryReceipt({
    required this.id,
    required this.shipmentCode,
    required this.receiverId,
    required this.receiverName,
    required this.receiverType,
    required this.expectedWeightKg,
    required this.expectedFruitCount,
    required this.decision,
    required this.checkedAt,
    required this.destinationLocation,
    this.receivedWeightKg,
    this.receivedFruitCount,
    this.condition,
    this.discrepancyNote,
    this.qualityNote,
    this.rejectionReason,
  });

  final String id;
  final String shipmentCode;
  final String receiverId;
  final String receiverName;
  final ShipmentDestinationType receiverType;
  final double expectedWeightKg;
  final int expectedFruitCount;
  final double? receivedWeightKg;
  final int? receivedFruitCount;
  final CollectorDeliveryReceiptCondition? condition;
  final CollectorDeliveryReceiptDecision decision;
  final DateTime checkedAt;
  final String destinationLocation;
  final String? discrepancyNote;
  final String? qualityNote;
  final String? rejectionReason;

  double get weightDifferenceKg => (receivedWeightKg ?? 0) - expectedWeightKg;
  int get fruitDifference => (receivedFruitCount ?? 0) - expectedFruitCount;
  bool get hasDiscrepancy =>
      decision == CollectorDeliveryReceiptDecision.accepted &&
      (weightDifferenceKg.abs() > 0.01 || fruitDifference != 0);

  Map<String, dynamic> toJson() => {
    'id': id,
    'shipmentCode': shipmentCode,
    'receiverId': receiverId,
    'receiverName': receiverName,
    'receiverType': receiverType.name,
    'expectedWeightKg': expectedWeightKg,
    'expectedFruitCount': expectedFruitCount,
    'receivedWeightKg': receivedWeightKg,
    'receivedFruitCount': receivedFruitCount,
    'condition': condition?.name,
    'decision': decision.name,
    'checkedAt': checkedAt.toIso8601String(),
    'destinationLocation': destinationLocation,
    'discrepancyNote': discrepancyNote,
    'qualityNote': qualityNote,
    'rejectionReason': rejectionReason,
  };

  factory CollectorDeliveryReceipt.fromJson(Map<String, dynamic> json) {
    return CollectorDeliveryReceipt(
      id: json['id'] as String,
      shipmentCode: json['shipmentCode'] as String,
      receiverId: json['receiverId'] as String? ?? '',
      receiverName: json['receiverName'] as String? ?? '-',
      receiverType: ShipmentDestinationType.values.firstWhere(
        (value) => value.name == json['receiverType'],
        orElse: () => ShipmentDestinationType.umkm,
      ),
      expectedWeightKg: (json['expectedWeightKg'] as num).toDouble(),
      expectedFruitCount: (json['expectedFruitCount'] as num).toInt(),
      receivedWeightKg: (json['receivedWeightKg'] as num?)?.toDouble(),
      receivedFruitCount: (json['receivedFruitCount'] as num?)?.toInt(),
      condition: json['condition'] == null
          ? null
          : CollectorDeliveryReceiptCondition.values.firstWhere(
              (value) => value.name == json['condition'],
              orElse: () => CollectorDeliveryReceiptCondition.good,
            ),
      decision: CollectorDeliveryReceiptDecision.values.firstWhere(
        (value) => value.name == json['decision'],
        orElse: () => CollectorDeliveryReceiptDecision.accepted,
      ),
      checkedAt: DateTime.parse(json['checkedAt'] as String),
      destinationLocation: json['destinationLocation'] as String? ?? '',
      discrepancyNote: json['discrepancyNote'] as String?,
      qualityNote: json['qualityNote'] as String?,
      rejectionReason: json['rejectionReason'] as String?,
    );
  }
}
