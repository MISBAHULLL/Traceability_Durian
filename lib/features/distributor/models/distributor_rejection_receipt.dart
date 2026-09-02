import 'distributor_acquisition_transaction.dart';

// [DB - Model/Entity] Bukti formal ketika distributor menolak stok masuk.
// Receipt ini melengkapi DistributorReceipt yang khusus untuk penerimaan sukses.
class DistributorRejectionReceipt {
  const DistributorRejectionReceipt({
    required this.id,
    required this.transactionId,
    required this.itemCode,
    required this.distributorId,
    required this.source,
    required this.supplierLabel,
    required this.expectedWeightKg,
    required this.expectedFruitCount,
    required this.rejectedAt,
    required this.rejectedBy,
    required this.rejectionLocation,
    required this.reason,
  });

  final String id;
  final String transactionId;
  final String itemCode;
  final String distributorId;
  final DistributorAcquisitionSource source;
  final String supplierLabel;
  final double expectedWeightKg;
  final int expectedFruitCount;
  final DateTime rejectedAt;
  final String rejectedBy;
  final String rejectionLocation;
  final String reason;

  Map<String, dynamic> toJson() => {
    'id': id,
    'transactionId': transactionId,
    'itemCode': itemCode,
    'distributorId': distributorId,
    'source': source.name,
    'supplierLabel': supplierLabel,
    'expectedWeightKg': expectedWeightKg,
    'expectedFruitCount': expectedFruitCount,
    'rejectedAt': rejectedAt.toIso8601String(),
    'rejectedBy': rejectedBy,
    'rejectionLocation': rejectionLocation,
    'reason': reason,
  };

  factory DistributorRejectionReceipt.fromJson(Map<String, dynamic> json) {
    return DistributorRejectionReceipt(
      id: json['id'] as String,
      transactionId: json['transactionId'] as String,
      itemCode: json['itemCode'] as String,
      distributorId: json['distributorId'] as String,
      source: DistributorAcquisitionSource.values.firstWhere(
        (value) => value.name == json['source'],
        orElse: () => DistributorAcquisitionSource.collector,
      ),
      supplierLabel: json['supplierLabel'] as String? ?? '-',
      expectedWeightKg: (json['expectedWeightKg'] as num).toDouble(),
      expectedFruitCount: (json['expectedFruitCount'] as num).toInt(),
      rejectedAt: DateTime.parse(json['rejectedAt'] as String),
      rejectedBy: json['rejectedBy'] as String? ?? '-',
      rejectionLocation: json['rejectionLocation'] as String? ?? '-',
      reason: json['reason'] as String? ?? '-',
    );
  }
}
