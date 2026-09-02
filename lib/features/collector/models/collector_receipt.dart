import '../../farmer/models/harvest_batch.dart';

enum CollectorReceiptStatus { accepted, rejected }

extension CollectorReceiptStatusX on CollectorReceiptStatus {
  String get label {
    switch (this) {
      case CollectorReceiptStatus.accepted:
        return 'Diterima';
      case CollectorReceiptStatus.rejected:
        return 'Ditolak';
    }
  }
}

class CollectorReceipt {
  const CollectorReceipt({
    required this.id,
    required this.collectorId,
    required this.batchCode,
    required this.farmerLabel,
    required this.farmName,
    required this.variety,
    required this.expectedWeightKg,
    required this.unit,
    required this.status,
    required this.checkedAt,
    required this.actorName,
    this.expectedFruitCount,
    this.receivedWeightKg,
    this.receivedFruitCount,
    this.warehouseId,
    this.warehouseName,
    this.warehouseLocation,
    this.conditionNote,
    this.rejectionReason,
    this.verificationPhotoPath,
    this.transactionId,
    this.gradeBreakdown = const [],
  });

  final String id;
  final String collectorId;
  final String batchCode;
  final String farmerLabel;
  final String farmName;
  final String variety;
  final double expectedWeightKg;
  final int? expectedFruitCount;
  final double? receivedWeightKg;
  final int? receivedFruitCount;
  final String unit;
  final CollectorReceiptStatus status;
  final DateTime checkedAt;
  final String actorName;
  final String? warehouseId;
  final String? warehouseName;
  final String? warehouseLocation;
  final String? conditionNote;
  final String? rejectionReason;
  final String? verificationPhotoPath;
  final String? transactionId;
  final List<BatchGradeBreakdown> gradeBreakdown;

  double get weightDifferenceKg => (receivedWeightKg ?? 0) - expectedWeightKg;
  int get fruitDifference => expectedFruitCount == null
      ? 0
      : (receivedFruitCount ?? 0) - expectedFruitCount!;
  bool get hasDiscrepancy =>
      status == CollectorReceiptStatus.accepted &&
      (weightDifferenceKg.abs() > 0.01 || fruitDifference != 0);

  Map<String, dynamic> toJson() => {
    'id': id,
    'collectorId': collectorId,
    'batchCode': batchCode,
    'farmerLabel': farmerLabel,
    'farmName': farmName,
    'variety': variety,
    'expectedWeightKg': expectedWeightKg,
    'expectedFruitCount': expectedFruitCount,
    'receivedWeightKg': receivedWeightKg,
    'receivedFruitCount': receivedFruitCount,
    'unit': unit,
    'status': status.name,
    'checkedAt': checkedAt.toIso8601String(),
    'actorName': actorName,
    'warehouseId': warehouseId,
    'warehouseName': warehouseName,
    'warehouseLocation': warehouseLocation,
    'conditionNote': conditionNote,
    'rejectionReason': rejectionReason,
    'verificationPhotoPath': verificationPhotoPath,
    'transactionId': transactionId,
    'gradeBreakdown': gradeBreakdown.map((item) => item.toJson()).toList(),
  };

  factory CollectorReceipt.fromJson(Map<String, dynamic> json) {
    return CollectorReceipt(
      id: json['id'] as String,
      collectorId: json['collectorId'] as String? ?? '',
      batchCode: json['batchCode'] as String,
      farmerLabel: json['farmerLabel'] as String? ?? 'Petani',
      farmName: json['farmName'] as String? ?? '-',
      variety: json['variety'] as String? ?? '-',
      expectedWeightKg: (json['expectedWeightKg'] as num).toDouble(),
      expectedFruitCount: (json['expectedFruitCount'] as num?)?.toInt(),
      receivedWeightKg: (json['receivedWeightKg'] as num?)?.toDouble(),
      receivedFruitCount: (json['receivedFruitCount'] as num?)?.toInt(),
      unit: json['unit'] as String? ?? 'kg',
      status: CollectorReceiptStatus.values.firstWhere(
        (value) => value.name == json['status'],
        orElse: () => CollectorReceiptStatus.accepted,
      ),
      checkedAt: DateTime.parse(json['checkedAt'] as String),
      actorName: json['actorName'] as String? ?? 'Pengepul',
      warehouseId: json['warehouseId'] as String?,
      warehouseName: json['warehouseName'] as String?,
      warehouseLocation: json['warehouseLocation'] as String?,
      conditionNote: json['conditionNote'] as String?,
      rejectionReason: json['rejectionReason'] as String?,
      verificationPhotoPath: json['verificationPhotoPath'] as String?,
      transactionId: json['transactionId'] as String?,
      gradeBreakdown: ((json['gradeBreakdown'] as List<dynamic>?) ?? [])
          .whereType<Map>()
          .map(
            (item) =>
                BatchGradeBreakdown.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList(),
    );
  }
}
