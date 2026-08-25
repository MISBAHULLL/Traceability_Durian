import 'package:flutter/material.dart';

import 'consumer_product.dart';

/// Status transaksi konsumen.
enum ConsumerTransactionStatus { processing, completed }

ConsumerTransactionStatus consumerTransactionStatusFromJson(Object? value) {
  return ConsumerTransactionStatus.values.firstWhere(
    (status) => status.name == value,
    orElse: () => ConsumerTransactionStatus.processing,
  );
}

extension ConsumerTransactionStatusX on ConsumerTransactionStatus {
  String get label {
    switch (this) {
      case ConsumerTransactionStatus.processing:
        return 'Diproses';
      case ConsumerTransactionStatus.completed:
        return 'Selesai';
    }
  }

  Color get color {
    switch (this) {
      case ConsumerTransactionStatus.processing:
        return const Color(0xFFB45309);
      case ConsumerTransactionStatus.completed:
        return const Color(0xFF296C11);
    }
  }

  Color get background => color.withValues(alpha: 0.12);
}

/// Status pembayaran transaksi konsumen.
enum ConsumerPaymentStatus { unpaid, processing, paid }

ConsumerPaymentStatus consumerPaymentStatusFromJson(Object? value) {
  return ConsumerPaymentStatus.values.firstWhere(
    (status) => status.name == value,
    orElse: () => ConsumerPaymentStatus.unpaid,
  );
}

extension ConsumerPaymentStatusX on ConsumerPaymentStatus {
  String get label {
    switch (this) {
      case ConsumerPaymentStatus.unpaid:
        return 'Belum Dibayar';
      case ConsumerPaymentStatus.processing:
        return 'Menunggu Verifikasi';
      case ConsumerPaymentStatus.paid:
        return 'Terverifikasi';
    }
  }

  Color get color {
    switch (this) {
      case ConsumerPaymentStatus.unpaid:
      case ConsumerPaymentStatus.processing:
        return const Color(0xFFB45309);
      case ConsumerPaymentStatus.paid:
        return const Color(0xFF296C11);
    }
  }

  Color get background => color.withValues(alpha: 0.12);
}

/// Transaksi pembelian produk UMKM oleh konsumen.
class ConsumerTransaction {
  const ConsumerTransaction({
    required this.id,
    required this.product,
    required this.status,
    required this.quantity,
    required this.totalLabel,
    required this.createdAt,
    required this.buyerAddress,
    required this.buyerCoordinates,
    required this.paymentMethod,
    this.paymentStatus,
    required this.qrCodeData,
    this.bankName,
    this.accountNumber,
    this.note,
  });

  final String id;
  final ConsumerProduct product;
  final ConsumerTransactionStatus status;
  final int quantity;
  final String totalLabel;
  final DateTime createdAt;
  final String buyerAddress;
  final String buyerCoordinates;
  final String paymentMethod;
  final ConsumerPaymentStatus? paymentStatus;
  final String qrCodeData;
  final String? bankName;
  final String? accountNumber;
  final String? note;

  ConsumerPaymentStatus get effectivePaymentStatus =>
      paymentStatus ?? ConsumerPaymentStatus.unpaid;

  /// Kode unik untuk produk yang sudah dibeli.
  ///
  /// Ini berbeda dari kode transaksi/pembayaran dan dipakai khusus setelah
  /// transaksi selesai.
  String get purchasedProductCode => 'PUR-${product.code}-$id';

  String get purchasedProductQrData => purchasedProductCode;

  ConsumerTransaction copyWith({
    ConsumerProduct? product,
    ConsumerTransactionStatus? status,
    int? quantity,
    String? totalLabel,
    DateTime? createdAt,
    String? buyerAddress,
    String? buyerCoordinates,
    String? paymentMethod,
    ConsumerPaymentStatus? paymentStatus,
    String? qrCodeData,
    String? bankName,
    String? accountNumber,
    String? note,
  }) {
    return ConsumerTransaction(
      id: id,
      product: product ?? this.product,
      status: status ?? this.status,
      quantity: quantity ?? this.quantity,
      totalLabel: totalLabel ?? this.totalLabel,
      createdAt: createdAt ?? this.createdAt,
      buyerAddress: buyerAddress ?? this.buyerAddress,
      buyerCoordinates: buyerCoordinates ?? this.buyerCoordinates,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      qrCodeData: qrCodeData ?? this.qrCodeData,
      bankName: bankName ?? this.bankName,
      accountNumber: accountNumber ?? this.accountNumber,
      note: note ?? this.note,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'product': product.toJson(),
    'status': status.name,
    'quantity': quantity,
    'totalLabel': totalLabel,
    'createdAt': createdAt.toIso8601String(),
    'buyerAddress': buyerAddress,
    'buyerCoordinates': buyerCoordinates,
    'paymentMethod': paymentMethod,
    'paymentStatus': paymentStatus?.name,
    'qrCodeData': qrCodeData,
    'bankName': bankName,
    'accountNumber': accountNumber,
    'note': note,
  };

  factory ConsumerTransaction.fromJson(Map<String, dynamic> json) {
    final rawProduct = json['product'];
    return ConsumerTransaction(
      id: json['id'] as String? ?? '',
      product: rawProduct is Map
          ? ConsumerProduct.fromJson(Map<String, dynamic>.from(rawProduct))
          : ConsumerProduct.fromJson(const {}),
      status: consumerTransactionStatusFromJson(json['status']),
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
      totalLabel: json['totalLabel'] as String? ?? '-',
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      buyerAddress: json['buyerAddress'] as String? ?? '',
      buyerCoordinates: json['buyerCoordinates'] as String? ?? '',
      paymentMethod: json['paymentMethod'] as String? ?? '-',
      paymentStatus: json['paymentStatus'] == null
          ? null
          : consumerPaymentStatusFromJson(json['paymentStatus']),
      qrCodeData: json['qrCodeData'] as String? ?? '',
      bankName: json['bankName'] as String?,
      accountNumber: json['accountNumber'] as String?,
      note: json['note'] as String?,
    );
  }
}
