import 'umkm_stock_offer.dart';

enum UmkmStockOrderStatus { diproses, selesai }

extension UmkmStockOrderStatusLabel on UmkmStockOrderStatus {
  String get label {
    switch (this) {
      case UmkmStockOrderStatus.diproses:
        return 'Diproses';
      case UmkmStockOrderStatus.selesai:
        return 'Selesai';
    }
  }
}

enum UmkmStockPaymentMethod { cod, transfer }

extension UmkmStockPaymentMethodLabel on UmkmStockPaymentMethod {
  String get label {
    switch (this) {
      case UmkmStockPaymentMethod.cod:
        return 'Cash on Delivery';
      case UmkmStockPaymentMethod.transfer:
        return 'Transfer Bank';
    }
  }
}

class UmkmStockOrder {
  const UmkmStockOrder({
    required this.id,
    required this.offerId,
    required this.offerName,
    required this.supplierName,
    required this.supplierType,
    required this.traceCode,
    required this.quantityKg,
    required this.pricePerKg,
    required this.totalAmount,
    required this.paymentMethod,
    required this.status,
    required this.createdAt,
    this.bankName,
    this.accountNumber,
    this.note,
  });

  final String id;
  final String offerId;
  final String offerName;
  final String supplierName;
  final UmkmSupplierType supplierType;
  final String traceCode;
  final int quantityKg;
  final int pricePerKg;
  final int totalAmount;
  final UmkmStockPaymentMethod paymentMethod;
  final UmkmStockOrderStatus status;
  final DateTime createdAt;
  final String? bankName;
  final String? accountNumber;
  final String? note;

  String get totalLabel => 'Rp ${_formatCurrency(totalAmount)}';

  UmkmStockOrder copyWith({
    UmkmStockOrderStatus? status,
    String? note,
  }) {
    return UmkmStockOrder(
      id: id,
      offerId: offerId,
      offerName: offerName,
      supplierName: supplierName,
      supplierType: supplierType,
      traceCode: traceCode,
      quantityKg: quantityKg,
      pricePerKg: pricePerKg,
      totalAmount: totalAmount,
      paymentMethod: paymentMethod,
      status: status ?? this.status,
      createdAt: createdAt,
      bankName: bankName,
      accountNumber: accountNumber,
      note: note ?? this.note,
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
