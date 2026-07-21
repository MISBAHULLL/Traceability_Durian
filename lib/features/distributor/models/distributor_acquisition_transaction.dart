// [DB - Model/Entity] Sumber akuisisi distributor pada flow T1 + T2.
// Collector berarti membeli manifest PGL; farmer berarti membeli batch DRN.
enum DistributorAcquisitionSource { collector, farmer }

extension DistributorAcquisitionSourceX on DistributorAcquisitionSource {
  String get label {
    switch (this) {
      case DistributorAcquisitionSource.collector:
        return 'Pengepul';
      case DistributorAcquisitionSource.farmer:
        return 'Petani';
    }
  }
}

// [DB - Model/Entity] Status transaksi akuisisi distributor.
// initiated = T1 dibuat, verified/rejected = T2 selesai.
enum DistributorAcquisitionStatus { initiated, verified, rejected }

extension DistributorAcquisitionStatusX on DistributorAcquisitionStatus {
  String get label {
    switch (this) {
      case DistributorAcquisitionStatus.initiated:
        return 'Menunggu T2';
      case DistributorAcquisitionStatus.verified:
        return 'T2 Terverifikasi';
      case DistributorAcquisitionStatus.rejected:
        return 'Ditolak';
    }
  }
}

// [DB - Model/Entity] Bukti T1/T2 akuisisi distributor.
// Model ini sengaja ringan agar dapat dipetakan ke endpoint/backend nanti.
class DistributorAcquisitionTransaction {
  const DistributorAcquisitionTransaction({
    required this.id,
    required this.distributorId,
    required this.source,
    required this.itemCode,
    required this.itemName,
    required this.originLabel,
    required this.supplierLabel,
    required this.expectedWeightKg,
    required this.expectedFruitCount,
    required this.initiatedAt,
    required this.status,
    this.closedAt,
    this.note,
  });

  final String id;
  final String distributorId;
  final DistributorAcquisitionSource source;
  final String itemCode;
  final String itemName;
  final String originLabel;
  final String supplierLabel;
  final double expectedWeightKg;
  final int expectedFruitCount;
  final DateTime initiatedAt;
  final DistributorAcquisitionStatus status;
  final DateTime? closedAt;
  final String? note;

  DistributorAcquisitionTransaction copyWith({
    DistributorAcquisitionStatus? status,
    DateTime? closedAt,
    String? note,
  }) {
    return DistributorAcquisitionTransaction(
      id: id,
      distributorId: distributorId,
      source: source,
      itemCode: itemCode,
      itemName: itemName,
      originLabel: originLabel,
      supplierLabel: supplierLabel,
      expectedWeightKg: expectedWeightKg,
      expectedFruitCount: expectedFruitCount,
      initiatedAt: initiatedAt,
      status: status ?? this.status,
      closedAt: closedAt ?? this.closedAt,
      note: note ?? this.note,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'distributorId': distributorId,
    'source': source.name,
    'itemCode': itemCode,
    'itemName': itemName,
    'originLabel': originLabel,
    'supplierLabel': supplierLabel,
    'expectedWeightKg': expectedWeightKg,
    'expectedFruitCount': expectedFruitCount,
    'initiatedAt': initiatedAt.toIso8601String(),
    'status': status.name,
    'closedAt': closedAt?.toIso8601String(),
    'note': note,
  };

  factory DistributorAcquisitionTransaction.fromJson(
    Map<String, dynamic> json,
  ) {
    return DistributorAcquisitionTransaction(
      id: json['id'] as String,
      distributorId: json['distributorId'] as String,
      source: DistributorAcquisitionSource.values.firstWhere(
        (value) => value.name == json['source'],
        orElse: () => DistributorAcquisitionSource.collector,
      ),
      itemCode: json['itemCode'] as String,
      itemName: json['itemName'] as String,
      originLabel: json['originLabel'] as String,
      supplierLabel: json['supplierLabel'] as String,
      expectedWeightKg: (json['expectedWeightKg'] as num).toDouble(),
      expectedFruitCount: (json['expectedFruitCount'] as num).toInt(),
      initiatedAt: DateTime.parse(json['initiatedAt'] as String),
      status: DistributorAcquisitionStatus.values.firstWhere(
        (value) => value.name == json['status'],
        orElse: () => DistributorAcquisitionStatus.initiated,
      ),
      closedAt: json['closedAt'] == null
          ? null
          : DateTime.parse(json['closedAt'] as String),
      note: json['note'] as String?,
    );
  }
}
