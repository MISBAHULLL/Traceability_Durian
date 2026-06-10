import 'collector_stock_summary.dart';

// [DB - Model/Entity] Enum ini merepresentasikan status batch pengiriman
// milik pengepul sebelum nanti dipindahkan ke state backend/blockchain.
enum CollectorShipmentStatus { readyToShip, sent, completed }

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
    this.warehouseNote,
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
  final String? warehouseNote;

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
        'warehouseNote': warehouseNote,
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
          .map((item) => CollectorStockBreakdown.fromJson(
                Map<String, dynamic>.from(item),
              ))
          .toList(),
      varietyBreakdown: ((json['varietyBreakdown'] as List<dynamic>?) ?? [])
          .whereType<Map>()
          .map((item) => CollectorStockBreakdown.fromJson(
                Map<String, dynamic>.from(item),
              ))
          .toList(),
      packagedAt: DateTime.parse(json['packagedAt'] as String),
      status: CollectorShipmentStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => CollectorShipmentStatus.readyToShip,
      ),
      warehouseNote: json['warehouseNote'] as String?,
    );
  }
}
