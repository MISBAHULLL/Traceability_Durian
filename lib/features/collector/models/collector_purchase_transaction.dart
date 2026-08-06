// [DB - Model/Entity] Status transaksi T1 penerimaan dari petani.
// T1 dimulai saat QR batch dipindai, lalu ditutup oleh verifikasi fisik T2.
enum CollectorPurchaseStatus { initiated, verified, rejected }

extension CollectorPurchaseStatusX on CollectorPurchaseStatus {
  String get label {
    switch (this) {
      case CollectorPurchaseStatus.initiated:
        return 'Menunggu Verifikasi';
      case CollectorPurchaseStatus.verified:
        return 'Terverifikasi';
      case CollectorPurchaseStatus.rejected:
        return 'Ditolak';
    }
  }
}

// [DB - Model/Entity] Transaksi T1 membuktikan pengepul menerima inisiasi
// batch dari petani tanpa menyimpan harga, pembayaran, atau data gudang penuh.
class CollectorPurchaseTransaction {
  const CollectorPurchaseTransaction({
    required this.id,
    required this.collectorId,
    required this.batchCode,
    required this.batchName,
    required this.originLabel,
    required this.farmerLabel,
    required this.initiatedAt,
    required this.status,
    this.closedAt,
  });

  final String id;
  final String collectorId;
  final String batchCode;
  final String batchName;
  final String originLabel;
  final String farmerLabel;
  final DateTime initiatedAt;
  final CollectorPurchaseStatus status;
  final DateTime? closedAt;

  CollectorPurchaseTransaction copyWith({
    CollectorPurchaseStatus? status,
    DateTime? closedAt,
  }) {
    return CollectorPurchaseTransaction(
      id: id,
      collectorId: collectorId,
      batchCode: batchCode,
      batchName: batchName,
      originLabel: originLabel,
      farmerLabel: farmerLabel,
      initiatedAt: initiatedAt,
      status: status ?? this.status,
      closedAt: closedAt ?? this.closedAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'collectorId': collectorId,
    'batchCode': batchCode,
    'batchName': batchName,
    'originLabel': originLabel,
    'farmerLabel': farmerLabel,
    'initiatedAt': initiatedAt.toIso8601String(),
    'status': status.name,
    'closedAt': closedAt?.toIso8601String(),
  };

  factory CollectorPurchaseTransaction.fromJson(Map<String, dynamic> json) {
    return CollectorPurchaseTransaction(
      id: json['id'] as String,
      collectorId: json['collectorId'] as String,
      batchCode: json['batchCode'] as String,
      batchName: json['batchName'] as String,
      originLabel: json['originLabel'] as String,
      farmerLabel: json['farmerLabel'] as String,
      initiatedAt: DateTime.parse(json['initiatedAt'] as String),
      status: CollectorPurchaseStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => CollectorPurchaseStatus.initiated,
      ),
      closedAt: json['closedAt'] == null
          ? null
          : DateTime.parse(json['closedAt'] as String),
    );
  }
}
