import 'collector_stock_summary.dart';

// [DB - Model/Entity] Enum ini merepresentasikan status batch pengiriman
// milik pengepul sebelum nanti dipindahkan ke state backend/blockchain.
enum CollectorShipmentStatus { readyToShip, sent, completed }

// [DB - Model/Entity] Enum ini membedakan penerima manifest agar pengiriman
// langsung ke UMKM tidak masuk ke antrean operasional distributor.
enum ShipmentDestinationType { umkm, distributor }

extension ShipmentDestinationTypeX on ShipmentDestinationType {
  String get label {
    switch (this) {
      case ShipmentDestinationType.umkm:
        return 'UMKM';
      case ShipmentDestinationType.distributor:
        return 'Distributor';
    }
  }
}

extension CollectorShipmentStatusX on CollectorShipmentStatus {
  String get label {
    switch (this) {
      case CollectorShipmentStatus.readyToShip:
        return 'Siap Dikirim';
      case CollectorShipmentStatus.sent:
        return 'Dikirim';
      case CollectorShipmentStatus.completed:
        return 'Selesai';
    }
  }
}

// [DB - Model/Entity] Model ini merepresentasikan batch hasil agregasi
// pengepul yang menyimpan provenance tree berupa daftar kode batch petani.
class CollectorShipmentBatch {
  const CollectorShipmentBatch({
    required this.code,
    required this.collectorId,
    required this.sourceBatchCodes,
    required this.totalWeightKg,
    required this.totalFruitCount,
    required this.gradeBreakdown,
    required this.varietyBreakdown,
    required this.packagedAt,
    required this.status,
    this.destinationType = ShipmentDestinationType.distributor,
    this.warehouseNote,
    this.sentAt,
    this.completedAt,
  });

  final String code;
  final String collectorId;
  final List<String> sourceBatchCodes;
  final double totalWeightKg;
  final int totalFruitCount;
  final List<CollectorStockBreakdown> gradeBreakdown;
  final List<CollectorStockBreakdown> varietyBreakdown;
  final DateTime packagedAt;
  final CollectorShipmentStatus status;
  final ShipmentDestinationType destinationType;
  final String? warehouseNote;
  final DateTime? sentAt;
  final DateTime? completedAt;

  // [DB - Model/Entity] copyWith dipakai repository untuk mengubah status
  // pengiriman tanpa membuat UI tahu detail struktur model.
  CollectorShipmentBatch copyWith({
    CollectorShipmentStatus? status,
    ShipmentDestinationType? destinationType,
    String? warehouseNote,
    DateTime? sentAt,
    DateTime? completedAt,
  }) {
    return CollectorShipmentBatch(
      code: code,
      collectorId: collectorId,
      sourceBatchCodes: sourceBatchCodes,
      totalWeightKg: totalWeightKg,
      totalFruitCount: totalFruitCount,
      gradeBreakdown: gradeBreakdown,
      varietyBreakdown: varietyBreakdown,
      packagedAt: packagedAt,
      status: status ?? this.status,
      destinationType: destinationType ?? this.destinationType,
      warehouseNote: warehouseNote ?? this.warehouseNote,
      sentAt: sentAt ?? this.sentAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'code': code,
    'collectorId': collectorId,
    'sourceBatchCodes': sourceBatchCodes,
    'totalWeightKg': totalWeightKg,
    'totalFruitCount': totalFruitCount,
    'gradeBreakdown': gradeBreakdown.map((e) => e.toJson()).toList(),
    'varietyBreakdown': varietyBreakdown.map((e) => e.toJson()).toList(),
    'packagedAt': packagedAt.toIso8601String(),
    'status': status.name,
    'destinationType': destinationType.name,
    'warehouseNote': warehouseNote,
    'sentAt': sentAt?.toIso8601String(),
    'completedAt': completedAt?.toIso8601String(),
  };

  factory CollectorShipmentBatch.fromJson(Map<String, dynamic> json) {
    return CollectorShipmentBatch(
      code: json['code'] as String,
      collectorId: json['collectorId'] as String,
      sourceBatchCodes: ((json['sourceBatchCodes'] as List<dynamic>?) ?? [])
          .map((e) => e.toString())
          .toList(),
      totalWeightKg: (json['totalWeightKg'] as num).toDouble(),
      totalFruitCount: (json['totalFruitCount'] as num).toInt(),
      gradeBreakdown: ((json['gradeBreakdown'] as List<dynamic>?) ?? [])
          .whereType<Map>()
          .map(
            (item) => CollectorStockBreakdown.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList(),
      varietyBreakdown: ((json['varietyBreakdown'] as List<dynamic>?) ?? [])
          .whereType<Map>()
          .map(
            (item) => CollectorStockBreakdown.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList(),
      packagedAt: DateTime.parse(json['packagedAt'] as String),
      status: CollectorShipmentStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => CollectorShipmentStatus.readyToShip,
      ),
      destinationType: ShipmentDestinationType.values.firstWhere(
        (e) => e.name == json['destinationType'],
        orElse: () => ShipmentDestinationType.distributor,
      ),
      warehouseNote: json['warehouseNote'] as String?,
      sentAt: json['sentAt'] == null
          ? null
          : DateTime.parse(json['sentAt'] as String),
      completedAt: json['completedAt'] == null
          ? null
          : DateTime.parse(json['completedAt'] as String),
    );
  }
}
