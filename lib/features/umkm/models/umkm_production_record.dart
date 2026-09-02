import 'umkm_product.dart';

class UmkmProductionRecord {
  const UmkmProductionRecord({
    required this.id,
    required this.productCode,
    required this.productName,
    required this.lotNumber,
    required this.processMethod,
    required this.producedAt,
    required this.outputQuantity,
    required this.outputUnit,
    required this.inputWeightKg,
    required this.lossWeightKg,
    required this.sourceMaterials,
    this.expiryDate,
    this.note,
  });

  final String id;
  final String productCode;
  final String productName;
  final String lotNumber;
  final String processMethod;
  final DateTime producedAt;
  final int outputQuantity;
  final String outputUnit;
  final double inputWeightKg;
  final double lossWeightKg;
  final List<UmkmProductMaterial> sourceMaterials;
  final DateTime? expiryDate;
  final String? note;

  double get yieldWeightKg {
    final yield = inputWeightKg - lossWeightKg;
    return yield < 0 ? 0 : yield;
  }

  String get outputLabel => '$outputQuantity $outputUnit';
  String get inputWeightLabel => _formatWeight(inputWeightKg);
  String get lossWeightLabel => _formatWeight(lossWeightKg);
  String get yieldWeightLabel => _formatWeight(yieldWeightKg);

  static String _formatWeight(double value) {
    if (value % 1 == 0) return '${value.toStringAsFixed(0)} kg';
    return '${value.toStringAsFixed(1)} kg';
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'productCode': productCode,
    'productName': productName,
    'lotNumber': lotNumber,
    'processMethod': processMethod,
    'producedAt': producedAt.toIso8601String(),
    'outputQuantity': outputQuantity,
    'outputUnit': outputUnit,
    'inputWeightKg': inputWeightKg,
    'lossWeightKg': lossWeightKg,
    'sourceMaterials': sourceMaterials.map((item) => item.toJson()).toList(),
    'expiryDate': expiryDate?.toIso8601String(),
    'note': note,
  };

  factory UmkmProductionRecord.fromJson(Map<String, dynamic> json) {
    return UmkmProductionRecord(
      id: json['id'] as String? ?? '',
      productCode: json['productCode'] as String? ?? '',
      productName: json['productName'] as String? ?? 'Produk UMKM',
      lotNumber: json['lotNumber'] as String? ?? '-',
      processMethod: json['processMethod'] as String? ?? '-',
      producedAt:
          DateTime.tryParse(json['producedAt'] as String? ?? '') ??
          DateTime.now(),
      outputQuantity: (json['outputQuantity'] as num?)?.toInt() ?? 0,
      outputUnit: json['outputUnit'] as String? ?? 'unit',
      inputWeightKg: (json['inputWeightKg'] as num?)?.toDouble() ?? 0,
      lossWeightKg: (json['lossWeightKg'] as num?)?.toDouble() ?? 0,
      sourceMaterials: ((json['sourceMaterials'] as List<dynamic>?) ?? [])
          .whereType<Map>()
          .map(
            (item) =>
                UmkmProductMaterial.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList(),
      expiryDate: DateTime.tryParse(json['expiryDate'] as String? ?? ''),
      note: json['note'] as String?,
    );
  }
}
