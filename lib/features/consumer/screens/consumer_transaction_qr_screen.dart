import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_top_bar.dart';
import '../models/consumer_transaction.dart';

class ConsumerTransactionQrScreen extends StatelessWidget {
  const ConsumerTransactionQrScreen({
    super.key,
    required this.transaction,
  });

  final ConsumerTransaction transaction;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            const AppTopBar(title: 'QR Transaksi'),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: QrImageView(
                        data: transaction.qrCodeData,
                        version: QrVersions.auto,
                        size: 220,
                        backgroundColor: AppColors.white,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Kode Transaksi: ',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.subtitle,
                          ),
                        ),
                        Text(
                          transaction.id,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Status Transaksi',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.placeholder,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            transaction.status.label,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: transaction.status.color,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),
                    _MiniInfoRow(label: 'Jumlah', value: '${transaction.quantity} pcs'),
                    const SizedBox(height: 10),
                    _MiniInfoRow(label: 'Total', value: transaction.totalLabel),
                    const SizedBox(height: 10),
                    _MiniInfoRow(label: 'Alamat', value: transaction.buyerAddress),
                    const SizedBox(height: 10),
                    _MiniInfoRow(label: 'Koordinat', value: transaction.buyerCoordinates),
                    const SizedBox(height: 10),
                    _MiniInfoRow(label: 'Pembayaran', value: transaction.paymentMethod),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniInfoRow extends StatelessWidget {
  const _MiniInfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            '$label',
            style: const TextStyle(fontSize: 12, color: AppColors.placeholder),
          ),
        ),
        Expanded(
          flex: 2,
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.black,
            ),
          ),
        ),
      ],
    );
  }
}
