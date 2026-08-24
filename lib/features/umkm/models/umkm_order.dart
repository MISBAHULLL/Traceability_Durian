enum UmkmOrderStatus { diproses, selesai }

extension UmkmOrderStatusLabel on UmkmOrderStatus {
  String get label {
    switch (this) {
      case UmkmOrderStatus.diproses:
        return 'Diproses';
      case UmkmOrderStatus.selesai:
        return 'Selesai';
    }
  }
}

class UmkmOrder {
  const UmkmOrder({
    required this.id,
    required this.productName,
    required this.buyerName,
    required this.quantity,
    required this.totalLabel,
    required this.status,
    required this.createdAt,
    required this.qrCodeData,
    this.productCode,
    this.completedAt,
    this.note,
  });

  final String id;
  final String productName;
  final String buyerName;
  final int quantity;
  final String totalLabel;
  final UmkmOrderStatus status;
  final DateTime createdAt;
  final String qrCodeData;
  final String? productCode;
  final DateTime? completedAt;
  final String? note;

  UmkmOrder copyWith({
    UmkmOrderStatus? status,
    String? productCode,
    DateTime? completedAt,
    String? note,
  }) {
    return UmkmOrder(
      id: id,
      productName: productName,
      buyerName: buyerName,
      quantity: quantity,
      totalLabel: totalLabel,
      status: status ?? this.status,
      createdAt: createdAt,
      qrCodeData: qrCodeData,
      productCode: productCode ?? this.productCode,
      completedAt: completedAt ?? this.completedAt,
      note: note ?? this.note,
    );
  }
}
