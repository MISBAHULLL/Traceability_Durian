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
}
