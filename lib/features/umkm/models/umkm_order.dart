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

UmkmOrderStatus umkmOrderStatusFromJson(Object? value) {
  return UmkmOrderStatus.values.firstWhere(
    (status) => status.name == value,
    orElse: () => UmkmOrderStatus.diproses,
  );
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

  Map<String, dynamic> toJson() => {
    'id': id,
    'productName': productName,
    'buyerName': buyerName,
    'quantity': quantity,
    'totalLabel': totalLabel,
    'status': status.name,
    'createdAt': createdAt.toIso8601String(),
    'qrCodeData': qrCodeData,
    'productCode': productCode,
    'completedAt': completedAt?.toIso8601String(),
    'note': note,
  };

  factory UmkmOrder.fromJson(Map<String, dynamic> json) {
    return UmkmOrder(
      id: json['id'] as String? ?? '',
      productName: json['productName'] as String? ?? 'Produk UMKM',
      buyerName: json['buyerName'] as String? ?? 'Konsumen',
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
      totalLabel: json['totalLabel'] as String? ?? '-',
      status: umkmOrderStatusFromJson(json['status']),
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      qrCodeData: json['qrCodeData'] as String? ?? '',
      productCode: json['productCode'] as String?,
      completedAt: DateTime.tryParse(json['completedAt'] as String? ?? ''),
      note: json['note'] as String?,
    );
  }
}
