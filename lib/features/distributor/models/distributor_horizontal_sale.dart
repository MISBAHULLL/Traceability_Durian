import 'distributor_receipt.dart';

enum DistributorHorizontalSaleStatus { initiated, verified, rejected }

extension DistributorHorizontalSaleStatusX on DistributorHorizontalSaleStatus {
  String get label {
    switch (this) {
      case DistributorHorizontalSaleStatus.initiated:
        return 'Menunggu Validasi';
      case DistributorHorizontalSaleStatus.verified:
        return 'Terverifikasi';
      case DistributorHorizontalSaleStatus.rejected:
        return 'Ditolak';
    }
  }
}

class DistributorPartner {
  const DistributorPartner({
    required this.id,
    required this.name,
    required this.city,
    required this.address,
  });

  final String id;
  final String name;
  final String city;
  final String address;
}

class DistributorHorizontalSale {
  const DistributorHorizontalSale({
    required this.id,
    required this.sellerDistributorId,
    required this.sellerName,
    required this.buyerDistributorId,
    required this.buyerName,
    required this.sourceWarehouseId,
    required this.sourceWarehouseName,
    required this.destinationLocation,
    required this.itemCode,
    required this.expectedWeightKg,
    required this.expectedFruitCount,
    required this.initiatedAt,
    required this.status,
    this.verifiedAt,
    this.receivedWeightKg,
    this.receivedFruitCount,
    this.condition,
    this.discrepancyNote,
    this.qualityNote,
    this.rejectionNote,
  });

  final String id;
  final String sellerDistributorId;
  final String sellerName;
  final String buyerDistributorId;
  final String buyerName;
  final String sourceWarehouseId;
  final String sourceWarehouseName;
  final String destinationLocation;
  final String itemCode;
  final double expectedWeightKg;
  final int expectedFruitCount;
  final DateTime initiatedAt;
  final DistributorHorizontalSaleStatus status;
  final DateTime? verifiedAt;
  final double? receivedWeightKg;
  final int? receivedFruitCount;
  final DistributorReceiptCondition? condition;
  final String? discrepancyNote;
  final String? qualityNote;
  final String? rejectionNote;

  double? get weightDifferenceKg =>
      receivedWeightKg == null ? null : receivedWeightKg! - expectedWeightKg;

  int? get fruitDifference => receivedFruitCount == null
      ? null
      : receivedFruitCount! - expectedFruitCount;

  bool get hasDiscrepancy {
    final weightDiff = weightDifferenceKg;
    final fruitDiff = fruitDifference;
    return (weightDiff?.abs() ?? 0) > 0.01 || (fruitDiff ?? 0) != 0;
  }

  DistributorHorizontalSale copyWith({
    DistributorHorizontalSaleStatus? status,
    DateTime? verifiedAt,
    double? receivedWeightKg,
    int? receivedFruitCount,
    DistributorReceiptCondition? condition,
    String? discrepancyNote,
    String? qualityNote,
    String? rejectionNote,
  }) {
    return DistributorHorizontalSale(
      id: id,
      sellerDistributorId: sellerDistributorId,
      sellerName: sellerName,
      buyerDistributorId: buyerDistributorId,
      buyerName: buyerName,
      sourceWarehouseId: sourceWarehouseId,
      sourceWarehouseName: sourceWarehouseName,
      destinationLocation: destinationLocation,
      itemCode: itemCode,
      expectedWeightKg: expectedWeightKg,
      expectedFruitCount: expectedFruitCount,
      initiatedAt: initiatedAt,
      status: status ?? this.status,
      verifiedAt: verifiedAt ?? this.verifiedAt,
      receivedWeightKg: receivedWeightKg ?? this.receivedWeightKg,
      receivedFruitCount: receivedFruitCount ?? this.receivedFruitCount,
      condition: condition ?? this.condition,
      discrepancyNote: discrepancyNote ?? this.discrepancyNote,
      qualityNote: qualityNote ?? this.qualityNote,
      rejectionNote: rejectionNote ?? this.rejectionNote,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'sellerDistributorId': sellerDistributorId,
    'sellerName': sellerName,
    'buyerDistributorId': buyerDistributorId,
    'buyerName': buyerName,
    'sourceWarehouseId': sourceWarehouseId,
    'sourceWarehouseName': sourceWarehouseName,
    'destinationLocation': destinationLocation,
    'itemCode': itemCode,
    'expectedWeightKg': expectedWeightKg,
    'expectedFruitCount': expectedFruitCount,
    'initiatedAt': initiatedAt.toIso8601String(),
    'status': status.name,
    'verifiedAt': verifiedAt?.toIso8601String(),
    'receivedWeightKg': receivedWeightKg,
    'receivedFruitCount': receivedFruitCount,
    'condition': condition?.name,
    'discrepancyNote': discrepancyNote,
    'qualityNote': qualityNote,
    'rejectionNote': rejectionNote,
  };

  factory DistributorHorizontalSale.fromJson(Map<String, dynamic> json) {
    return DistributorHorizontalSale(
      id: json['id'] as String,
      sellerDistributorId: json['sellerDistributorId'] as String,
      sellerName: json['sellerName'] as String,
      buyerDistributorId: json['buyerDistributorId'] as String,
      buyerName: json['buyerName'] as String,
      sourceWarehouseId: json['sourceWarehouseId'] as String,
      sourceWarehouseName: json['sourceWarehouseName'] as String,
      destinationLocation: json['destinationLocation'] as String,
      itemCode: json['itemCode'] as String,
      expectedWeightKg: (json['expectedWeightKg'] as num).toDouble(),
      expectedFruitCount: (json['expectedFruitCount'] as num).toInt(),
      initiatedAt: DateTime.parse(json['initiatedAt'] as String),
      status: DistributorHorizontalSaleStatus.values.firstWhere(
        (status) => status.name == json['status'],
        orElse: () => DistributorHorizontalSaleStatus.initiated,
      ),
      verifiedAt: json['verifiedAt'] == null
          ? null
          : DateTime.parse(json['verifiedAt'] as String),
      receivedWeightKg: (json['receivedWeightKg'] as num?)?.toDouble(),
      receivedFruitCount: (json['receivedFruitCount'] as num?)?.toInt(),
      condition: json['condition'] == null
          ? null
          : DistributorReceiptCondition.values.firstWhere(
              (condition) => condition.name == json['condition'],
              orElse: () => DistributorReceiptCondition.good,
            ),
      discrepancyNote: json['discrepancyNote'] as String?,
      qualityNote: json['qualityNote'] as String?,
      rejectionNote: json['rejectionNote'] as String?,
    );
  }
}
