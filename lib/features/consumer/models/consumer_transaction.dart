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
    required this.qrCodeData,
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
  final String qrCodeData;
  final String? note;
}
