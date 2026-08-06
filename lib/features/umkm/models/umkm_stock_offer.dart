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
