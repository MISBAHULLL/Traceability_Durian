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
}
