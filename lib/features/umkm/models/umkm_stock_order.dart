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

UmkmStockOrderStatus umkmStockOrderStatusFromJson(Object? value) {
  return UmkmStockOrderStatus.values.firstWhere(
    (status) => status.name == value,
    orElse: () => UmkmStockOrderStatus.diproses,
  );
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

UmkmStockPaymentMethod umkmStockPaymentMethodFromJson(Object? value) {
  return UmkmStockPaymentMethod.values.firstWhere(
    (method) => method.name == value,
    orElse: () => UmkmStockPaymentMethod.cod,
  );
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

  UmkmStockOrder copyWith({UmkmStockOrderStatus? status, String? note}) {
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

  Map<String, dynamic> toJson() => {
    'id': id,
    'offerId': offerId,
    'offerName': offerName,
    'supplierName': supplierName,
    'supplierType': supplierType.name,
    'traceCode': traceCode,
    'quantityKg': quantityKg,
    'pricePerKg': pricePerKg,
    'totalAmount': totalAmount,
    'paymentMethod': paymentMethod.name,
    'status': status.name,
    'createdAt': createdAt.toIso8601String(),
    'bankName': bankName,
    'accountNumber': accountNumber,
    'note': note,
  };

  factory UmkmStockOrder.fromJson(Map<String, dynamic> json) {
    return UmkmStockOrder(
      id: json['id'] as String? ?? '',
      offerId: json['offerId'] as String? ?? '',
      offerName: json['offerName'] as String? ?? 'Durian',
      supplierName: json['supplierName'] as String? ?? '-',
      supplierType: umkmSupplierTypeFromJson(json['supplierType']),
      traceCode: json['traceCode'] as String? ?? '',
      quantityKg: (json['quantityKg'] as num?)?.toInt() ?? 0,
      pricePerKg: (json['pricePerKg'] as num?)?.toInt() ?? 0,
      totalAmount: (json['totalAmount'] as num?)?.toInt() ?? 0,
      paymentMethod: umkmStockPaymentMethodFromJson(json['paymentMethod']),
      status: umkmStockOrderStatusFromJson(json['status']),
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      bankName: json['bankName'] as String?,
      accountNumber: json['accountNumber'] as String?,
      note: json['note'] as String?,
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
