// [DB - Model/Entity] DTO FE ini merepresentasikan ringkasan stok gudang
// pengepul; nantinya bisa disejajarkan dengan response API backend.
class CollectorStockOverview {
  const CollectorStockOverview({
    required this.activeBatchCount,
    required this.totalWeightKg,
    required this.totalFruitCount,
    required this.gradeBreakdown,
    required this.varietyBreakdown,
  });

  final int activeBatchCount;
  final double totalWeightKg;
  final int totalFruitCount;
  final List<CollectorStockBreakdown> gradeBreakdown;
  final List<CollectorStockBreakdown> varietyBreakdown;

  Map<String, dynamic> toJson() => {
    'activeBatchCount': activeBatchCount,
    'totalWeightKg': totalWeightKg,
    'totalFruitCount': totalFruitCount,
    'gradeBreakdown': gradeBreakdown.map((e) => e.toJson()).toList(),
    'varietyBreakdown': varietyBreakdown.map((e) => e.toJson()).toList(),
  };

  factory CollectorStockOverview.fromJson(Map<String, dynamic> json) {
    return CollectorStockOverview(
      activeBatchCount: (json['activeBatchCount'] as num).toInt(),
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
    );
  }
}

// [DB - Model/Entity] Bucket ini dipakai untuk stok per grade dan per
// varietas agar UI dan calon API memakai struktur data yang sama.
class CollectorStockBreakdown {
  const CollectorStockBreakdown({
    required this.key,
    required this.label,
    required this.totalWeightKg,
    required this.totalFruitCount,
    required this.batchCount,
  });

  final String key;
  final String label;
  final double totalWeightKg;
  final int totalFruitCount;
  final int batchCount;

  Map<String, dynamic> toJson() => {
    'key': key,
    'label': label,
    'totalWeightKg': totalWeightKg,
    'totalFruitCount': totalFruitCount,
    'batchCount': batchCount,
  };

  factory CollectorStockBreakdown.fromJson(Map<String, dynamic> json) {
    return CollectorStockBreakdown(
      key: json['key'] as String,
      label: json['label'] as String,
      totalWeightKg: (json['totalWeightKg'] as num).toDouble(),
      totalFruitCount: (json['totalFruitCount'] as num).toInt(),
      batchCount: (json['batchCount'] as num).toInt(),
    );
  }
}
