class UmkmPurchase {
  const UmkmPurchase({
    required this.id,
    required this.supplierName,
    required this.productName,
    required this.quantity,
    required this.totalLabel,
    required this.createdAt,
    required this.qrCodeData,
    this.note,
  });

  final String id;
  final String supplierName;
  final String productName;
  final int quantity;
  final String totalLabel;
  final DateTime createdAt;
  final String qrCodeData;
  final String? note;

  Map<String, dynamic> toJson() => {
    'id': id,
    'supplierName': supplierName,
    'productName': productName,
    'quantity': quantity,
    'totalLabel': totalLabel,
    'createdAt': createdAt.toIso8601String(),
    'qrCodeData': qrCodeData,
    'note': note,
  };

  factory UmkmPurchase.fromJson(Map<String, dynamic> json) {
    return UmkmPurchase(
      id: json['id'] as String? ?? '',
      supplierName: json['supplierName'] as String? ?? '-',
      productName: json['productName'] as String? ?? 'Durian',
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
      totalLabel: json['totalLabel'] as String? ?? '-',
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      qrCodeData: json['qrCodeData'] as String? ?? '',
      note: json['note'] as String?,
    );
  }
}
