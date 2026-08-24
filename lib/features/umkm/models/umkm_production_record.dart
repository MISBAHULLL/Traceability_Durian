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
}
