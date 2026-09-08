import '../../../core/network/backend_api_client.dart';

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
      id: backendString(json, const ['id', 'code']),
      productName: backendString(json, const ['productName', 'product_name'], 'Produk UMKM'),
      buyerName: backendString(json, const ['buyerName', 'buyer_name'], 'Konsumen'),
      quantity: backendInt(json, const ['quantity']),
      totalLabel: backendString(json, const ['totalLabel', 'total_label'], '-'),
      status: umkmOrderStatusFromJson(json['status']),
      createdAt:
          backendDateTime(json, const ['createdAt', 'created_at']) ??
          DateTime.now(),
      qrCodeData: backendString(json, const ['qrCodeData', 'qr_code_data']),
      productCode: backendNullableString(json, const ['productCode', 'product_code']),
      completedAt: backendDateTime(json, const ['completedAt', 'completed_at']),
      note: backendNullableString(json, const ['note']),
    );
  }
}
