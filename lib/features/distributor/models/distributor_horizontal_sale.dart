import '../../../core/network/backend_api_client.dart';
import '../../farmer/models/harvest_batch.dart';
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
    this.recipientRole,
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
  final BatchReceiverRole? recipientRole;
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
      recipientRole: recipientRole,
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
    'buyerRole': recipientRole?.name,
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
      id: backendString(json, const ['id', 'code']),
      sellerDistributorId: backendString(
        json,
        const ['sellerDistributorId', 'seller_user_id'],
        '',
      ),
      sellerName: backendString(json, const ['sellerName', 'seller_name'], ''),
      buyerDistributorId: backendString(
        json,
        const ['buyerDistributorId', 'buyer_distributor_id'],
        '',
      ),
      buyerName: backendString(json, const ['buyerName', 'buyer_name'], ''),
      recipientRole: batchReceiverRoleFromJson(
        json['buyerRole'] ?? json['buyer_role'],
      ),
      sourceWarehouseId: backendString(
        json,
        const ['sourceWarehouseId', 'source_warehouse_id'],
        '',
      ),
      sourceWarehouseName: backendString(
        json,
        const ['sourceWarehouseName', 'source_warehouse_name'],
        '',
      ),
      destinationLocation: backendString(
        json,
        const ['destinationLocation', 'destination_location'],
        '',
      ),
      itemCode: backendString(json, const ['itemCode', 'item_code'], ''),
      expectedWeightKg: backendDouble(
        json,
        const ['expectedWeightKg', 'expected_weight_kg'],
      ),
      expectedFruitCount: backendInt(
        json,
        const ['expectedFruitCount', 'expected_fruit_count'],
      ),
      initiatedAt:
          backendDateTime(json, const ['initiatedAt', 'initiated_at']) ??
          DateTime.now(),
      status: DistributorHorizontalSaleStatus.values.firstWhere(
        (status) => status.name == backendString(json, const ['status']),
        orElse: () => DistributorHorizontalSaleStatus.initiated,
      ),
      verifiedAt: backendDateTime(json, const ['verifiedAt', 'verified_at']),
      receivedWeightKg: backendDouble(json, const ['receivedWeightKg', 'received_weight_kg']),
      receivedFruitCount: backendInt(json, const ['receivedFruitCount', 'received_fruit_count']),
      condition: backendNullableString(json, const ['condition']) == null
          ? null
          : DistributorReceiptCondition.values.firstWhere(
              (condition) => condition.name == backendString(json, const ['condition']),
              orElse: () => DistributorReceiptCondition.good,
            ),
      discrepancyNote: backendNullableString(
        json,
        const ['discrepancyNote', 'discrepancy_note'],
      ),
      qualityNote: backendNullableString(
        json,
        const ['qualityNote', 'quality_note'],
      ),
      rejectionNote: backendNullableString(
        json,
        const ['rejectionNote', 'rejection_note'],
      ),
    );
  }
}
