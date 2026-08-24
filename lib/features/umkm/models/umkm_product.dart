enum UmkmProductStatus { aktif, habis }

extension UmkmProductStatusLabel on UmkmProductStatus {
  String get label {
    switch (this) {
      case UmkmProductStatus.aktif:
        return 'Aktif';
      case UmkmProductStatus.habis:
        return 'Habis';
    }
  }
}

class UmkmProduct {
  const UmkmProduct({
    required this.id,
    required this.code,
    required this.name,
    required this.category,
    required this.priceLabel,
    required this.stockLabel,
    required this.description,
    required this.status,
    required this.qrCodeData,
    this.imagePath,
    this.sourceMaterials = const [],
  });

  final String id;
  final String code;
  final String name;
  final String category;
  final String priceLabel;
  final String stockLabel;
  final String description;
  final UmkmProductStatus status;
  final String qrCodeData;
  final String? imagePath;
  final List<UmkmProductMaterial> sourceMaterials;

  List<String> get sourceTraceCodes =>
      sourceMaterials.map((item) => item.traceCode).toList();

  String get sourceMaterialLabel {
    if (sourceMaterials.isEmpty) return 'Belum tersambung bahan baku';
    return sourceMaterials.map((item) => item.traceCode).join(', ');
  }

  double get sourceWeightKg =>
      sourceMaterials.fold<double>(0, (total, item) => total + item.quantityKg);
}

class UmkmProductMaterial {
  const UmkmProductMaterial({
    required this.purchaseId,
    required this.traceCode,
    required this.supplierName,
    required this.productName,
    required this.quantityKg,
  });

  final String purchaseId;
  final String traceCode;
  final String supplierName;
  final String productName;
  final double quantityKg;

  String get quantityLabel {
    if (quantityKg % 1 == 0) return '${quantityKg.toStringAsFixed(0)} kg';
    return '${quantityKg.toStringAsFixed(1)} kg';
  }
}
