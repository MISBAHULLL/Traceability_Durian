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

UmkmProductStatus umkmProductStatusFromJson(Object? value) {
  return UmkmProductStatus.values.firstWhere(
    (status) => status.name == value,
    orElse: () => UmkmProductStatus.aktif,
  );
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

  Map<String, dynamic> toJson() => {
    'id': id,
    'code': code,
    'name': name,
    'category': category,
    'priceLabel': priceLabel,
    'stockLabel': stockLabel,
    'description': description,
    'status': status.name,
    'qrCodeData': qrCodeData,
    'imagePath': imagePath,
    'sourceMaterials': sourceMaterials.map((item) => item.toJson()).toList(),
  };

  factory UmkmProduct.fromJson(Map<String, dynamic> json) {
    return UmkmProduct(
      id: json['id'] as String? ?? '',
      code: json['code'] as String? ?? '',
      name: json['name'] as String? ?? 'Produk UMKM',
      category: json['category'] as String? ?? 'Olahan',
      priceLabel: json['priceLabel'] as String? ?? '-',
      stockLabel: json['stockLabel'] as String? ?? 'Stok belum ditentukan',
      description: json['description'] as String? ?? '',
      status: umkmProductStatusFromJson(json['status']),
      qrCodeData:
          json['qrCodeData'] as String? ?? json['code'] as String? ?? '',
      imagePath: json['imagePath'] as String?,
      sourceMaterials: ((json['sourceMaterials'] as List<dynamic>?) ?? [])
          .whereType<Map>()
          .map(
            (item) =>
                UmkmProductMaterial.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList(),
    );
  }
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

  Map<String, dynamic> toJson() => {
    'purchaseId': purchaseId,
    'traceCode': traceCode,
    'supplierName': supplierName,
    'productName': productName,
    'quantityKg': quantityKg,
  };

  factory UmkmProductMaterial.fromJson(Map<String, dynamic> json) {
    return UmkmProductMaterial(
      purchaseId: json['purchaseId'] as String? ?? '',
      traceCode: json['traceCode'] as String? ?? '',
      supplierName: json['supplierName'] as String? ?? '-',
      productName: json['productName'] as String? ?? 'Durian',
      quantityKg: (json['quantityKg'] as num?)?.toDouble() ?? 0,
    );
  }
}
