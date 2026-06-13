import 'package:flutter/material.dart';

import 'consumer_product.dart';

/// Status transaksi konsumen.
enum ConsumerTransactionStatus { processing, completed }

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

extension ConsumerPaymentStatusX on ConsumerPaymentStatus {
  String get label {
    switch (this) {
      case ConsumerPaymentStatus.unpaid:
        return 'Belum Dibayar';
      case ConsumerPaymentStatus.processing:
        return 'Diproses';
      case ConsumerPaymentStatus.paid:
        return 'Selesai';
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
  String get purchasedProductCode => 'PUR-${product.code}-${id}';

  String get purchasedProductQrData => purchasedProductCode;
}
