enum UmkmSupplierType { pengepul, distributor, petani }

extension UmkmSupplierTypeLabel on UmkmSupplierType {
  String get label {
    switch (this) {
      case UmkmSupplierType.pengepul:
        return 'Pengepul';
      case UmkmSupplierType.distributor:
        return 'Distributor';
      case UmkmSupplierType.petani:
        return 'Petani';
    }
  }
}

UmkmSupplierType umkmSupplierTypeFromJson(Object? value) {
  return UmkmSupplierType.values.firstWhere(
    (type) => type.name == value,
    orElse: () => UmkmSupplierType.pengepul,
  );
}

enum UmkmStockOfferStatus { aktif, habis }

extension UmkmStockOfferStatusLabel on UmkmStockOfferStatus {
  String get label {
    switch (this) {
      case UmkmStockOfferStatus.aktif:
        return 'Aktif';
      case UmkmStockOfferStatus.habis:
        return 'Habis';
    }
  }
}

UmkmStockOfferStatus umkmStockOfferStatusFromJson(Object? value) {
  return UmkmStockOfferStatus.values.firstWhere(
    (status) => status.name == value,
    orElse: () => UmkmStockOfferStatus.aktif,
  );
}

class UmkmStockOffer {
  const UmkmStockOffer({
    required this.id,
    required this.traceCode,
    required this.name,
    required this.supplierName,
    required this.supplierType,
    required this.pricePerKg,
    required this.stockKg,
    required this.description,
    required this.status,
    required this.createdAt,
    this.imagePath,
  });

  final String id;
  final String traceCode;
  final String name;
  final String supplierName;
  final UmkmSupplierType supplierType;
  final int pricePerKg;
  final int stockKg;
  final String description;
  final UmkmStockOfferStatus status;
  final DateTime createdAt;
  final String? imagePath;

  String get priceLabel => 'Rp ${_formatCurrency(pricePerKg)} / kg';
  String get stockLabel => 'Stok $stockKg kg';

  UmkmStockOffer copyWith({int? stockKg, UmkmStockOfferStatus? status}) {
    return UmkmStockOffer(
      id: id,
      traceCode: traceCode,
      name: name,
      supplierName: supplierName,
      supplierType: supplierType,
      pricePerKg: pricePerKg,
      stockKg: stockKg ?? this.stockKg,
      description: description,
      status: status ?? this.status,
      createdAt: createdAt,
      imagePath: imagePath,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'traceCode': traceCode,
    'name': name,
    'supplierName': supplierName,
    'supplierType': supplierType.name,
    'pricePerKg': pricePerKg,
    'stockKg': stockKg,
    'description': description,
    'status': status.name,
    'createdAt': createdAt.toIso8601String(),
    'imagePath': imagePath,
  };

  factory UmkmStockOffer.fromJson(Map<String, dynamic> json) {
    return UmkmStockOffer(
      id: json['id'] as String? ?? '',
      traceCode: json['traceCode'] as String? ?? '',
      name: json['name'] as String? ?? 'Durian',
      supplierName: json['supplierName'] as String? ?? '-',
      supplierType: umkmSupplierTypeFromJson(json['supplierType']),
      pricePerKg: (json['pricePerKg'] as num?)?.toInt() ?? 0,
      stockKg: (json['stockKg'] as num?)?.toInt() ?? 0,
      description: json['description'] as String? ?? '',
      status: umkmStockOfferStatusFromJson(json['status']),
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      imagePath: json['imagePath'] as String?,
    );
  }
}

String _formatCurrency(int value) {
  final text = value.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < text.length; i++) {
    final remaining = text.length - i;
    buffer.write(text[i]);
    if (remaining > 1 && remaining % 3 == 1) {
      buffer.write('.');
    }
  }
  return buffer.toString();
}
