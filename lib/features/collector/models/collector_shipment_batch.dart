import '../../../core/network/backend_api_client.dart';
import 'collector_stock_summary.dart';

// [DB - Model/Entity] Enum ini merepresentasikan status batch pengiriman
// milik pengepul sebelum nanti dipindahkan ke state backend/blockchain.
enum CollectorShipmentStatus { readyToShip, sent, completed, rejected }

// [DB - Model/Entity] Enum ini membedakan penerima manifest agar pengiriman
// langsung ke UMKM tidak masuk ke antrean operasional distributor.
enum ShipmentDestinationType { umkm, distributor, consumer, collector }

extension ShipmentDestinationTypeX on ShipmentDestinationType {
  String get label {
    switch (this) {
      case ShipmentDestinationType.umkm:
        return 'UMKM';
      case ShipmentDestinationType.distributor:
        return 'Distributor';
      case ShipmentDestinationType.consumer:
        return 'Konsumen';
      case ShipmentDestinationType.collector:
        return 'Pengepul Lain';
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
      case CollectorShipmentStatus.rejected:
        return 'Ditolak';
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
    this.destinationName,
    this.destinationLocation,
    this.warehouseNote,
    this.sentAt,
    this.completedAt,
    this.rejectedAt,
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
  final String? destinationName;
  final String? destinationLocation;
  final String? warehouseNote;
  final DateTime? sentAt;
  final DateTime? completedAt;
  final DateTime? rejectedAt;

  // [DB - Model/Entity] copyWith dipakai repository untuk mengubah status
  // pengiriman tanpa membuat UI tahu detail struktur model.
  CollectorShipmentBatch copyWith({
    CollectorShipmentStatus? status,
    ShipmentDestinationType? destinationType,
    String? destinationName,
    String? destinationLocation,
    String? warehouseNote,
    DateTime? sentAt,
    DateTime? completedAt,
    DateTime? rejectedAt,
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
      destinationName: destinationName ?? this.destinationName,
      destinationLocation: destinationLocation ?? this.destinationLocation,
      warehouseNote: warehouseNote ?? this.warehouseNote,
      sentAt: sentAt ?? this.sentAt,
      completedAt: completedAt ?? this.completedAt,
      rejectedAt: rejectedAt ?? this.rejectedAt,
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
    'destinationName': destinationName,
    'destinationLocation': destinationLocation,
    'warehouseNote': warehouseNote,
    'sentAt': sentAt?.toIso8601String(),
    'completedAt': completedAt?.toIso8601String(),
    'rejectedAt': rejectedAt?.toIso8601String(),
  };

  factory CollectorShipmentBatch.fromJson(Map<String, dynamic> json) {
    final sourceBatchCodes = ((json['sourceBatchCodes'] as List<dynamic>?) ??
            (json['source_batch_codes'] as List<dynamic>?) ??
            [])
        .map((e) => e.toString())
        .toList();

    return CollectorShipmentBatch(
      code: backendString(json, const ['code']),
      collectorId: backendString(json, const ['collectorId', 'collector_id'], ''),
      sourceBatchCodes: sourceBatchCodes,
      totalWeightKg: backendDouble(json, const ['totalWeightKg', 'total_weight_kg']),
      totalFruitCount: backendInt(json, const ['totalFruitCount', 'total_fruit_count']),
      gradeBreakdown: ((json['gradeBreakdown'] as List<dynamic>?) ??
              (json['grade_breakdown'] as List<dynamic>?) ??
              [])
          .whereType<Map>()
          .map(
            (item) => CollectorStockBreakdown.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList(),
      varietyBreakdown: ((json['varietyBreakdown'] as List<dynamic>?) ??
              (json['variety_breakdown'] as List<dynamic>?) ??
              [])
          .whereType<Map>()
          .map(
            (item) => CollectorStockBreakdown.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList(),
      packagedAt:
          backendDateTime(json, const ['packagedAt', 'packaged_at']) ??
          DateTime.now(),
      status: CollectorShipmentStatus.values.firstWhere(
        (e) => e.name == backendString(json, const ['status']),
        orElse: () => CollectorShipmentStatus.readyToShip,
      ),
      destinationType: ShipmentDestinationType.values.firstWhere(
        (e) => e.name == backendString(json, const ['destinationType', 'destination_type']),
        orElse: () => ShipmentDestinationType.distributor,
      ),
      destinationName: backendNullableString(json, const ['destinationName', 'destination_name']),
      destinationLocation: backendNullableString(json, const ['destinationLocation', 'destination_location']),
      warehouseNote: backendNullableString(json, const ['warehouseNote', 'warehouse_note']),
      sentAt: backendDateTime(json, const ['sentAt', 'sent_at']),
      completedAt: backendDateTime(json, const ['completedAt', 'completed_at']),
      rejectedAt: backendDateTime(json, const ['rejectedAt', 'rejected_at']),
    );
  }
}
