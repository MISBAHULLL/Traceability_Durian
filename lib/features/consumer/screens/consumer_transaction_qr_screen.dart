import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_top_bar.dart';
import '../consumer_routes.dart';
import '../data/consumer_repository.dart';
import '../models/consumer_transaction.dart';
import 'consumer_home_screen.dart';

class ConsumerTransactionQrScreen extends StatefulWidget {
  const ConsumerTransactionQrScreen({super.key, required this.transaction});

  final ConsumerTransaction transaction;

  @override
  State<ConsumerTransactionQrScreen> createState() =>
      _ConsumerTransactionQrScreenState();
}

class _ConsumerTransactionQrScreenState
    extends State<ConsumerTransactionQrScreen> {
  final _repo = ConsumerRepository.instance;
  late ConsumerTransaction _transaction;

  @override
  void initState() {
    super.initState();
    _transaction = widget.transaction;
    _repo.addListener(_syncTransaction);
    _syncTransaction();
  }

  @override
  void dispose() {
    _repo.removeListener(_syncTransaction);
    super.dispose();
  }

  void _syncTransaction() {
    final latest = _repo.findTransaction(widget.transaction.id);
    if (latest == null || latest == _transaction || !mounted) return;
    setState(() => _transaction = latest);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.primary),
    );
  }

  void _confirmPayment() {
    final updated = _repo.confirmPayment(_transaction.id);
    if (updated == null) return;
    setState(() => _transaction = updated);
    _showMessage('Pembayaran dikirim untuk verifikasi.');
  }

  void _verifyPayment() {
    final updated = _repo.verifyPayment(_transaction.id);
    if (updated == null) return;
    setState(() => _transaction = updated);
    _showMessage('Pembayaran terverifikasi. Order masuk ke UMKM.');
  }

  @override
  Widget build(BuildContext context) {
    final transaction = _transaction;
    final isQris = transaction.paymentMethod == 'QRIS';
    final isCod = transaction.paymentMethod == 'Cash on Delivery';
    final isTransferBank = transaction.paymentMethod == 'Transfer Bank';
    final paymentStatus = transaction.effectivePaymentStatus;
    final showQr = isQris && paymentStatus == ConsumerPaymentStatus.unpaid;
    final statusLabel = paymentStatus.label;
    final showConfirmPayment =
        !isCod && paymentStatus == ConsumerPaymentStatus.unpaid;
    final showVerifyPayment =
        !isCod && paymentStatus == ConsumerPaymentStatus.processing;

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            AppTopBar(
              title: showQr ? 'QR Bayar' : 'Detail Pembayaran',
              onBack: () => ConsumerRoutes.replaceAll(
                context,
                const ConsumerHomeScreen(),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 6),
                    if (showQr)
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
                      )
                    else
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Detail Pembayaran',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: AppColors.black,
                              ),
                            ),
                            const SizedBox(height: 14),
                            if (isQris) ...[
                              _MiniInfoRow(label: 'Status', value: statusLabel),
                              const SizedBox(height: 10),
                              _MiniInfoRow(
                                label: 'Kode Transaksi',
                                value: transaction.id,
                              ),
                            ] else if (isTransferBank) ...[
                              _MiniInfoRow(
                                label: 'Bank',
                                value: transaction.bankName ?? '-',
                              ),
                              const SizedBox(height: 10),
                              _MiniInfoRow(
                                label: 'Nomor Rekening',
                                value: transaction.accountNumber ?? '-',
                              ),
                              const SizedBox(height: 10),
                              _MiniInfoRow(label: 'Status', value: statusLabel),
                            ] else ...[
                              _MiniInfoRow(
                                label: 'Metode',
                                value: transaction.paymentMethod,
                              ),
                              const SizedBox(height: 10),
                              _MiniInfoRow(label: 'Status', value: statusLabel),
                              const SizedBox(height: 10),
                              const _MiniInfoRow(
                                label: 'Catatan',
                                value: 'Bayar saat produk diterima.',
                              ),
                            ],
                          ],
                        ),
                      ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          showQr ? 'Kode Transaksi: ' : 'Status Pembayaran: ',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.subtitle,
                          ),
                        ),
                        Text(
                          showQr ? transaction.id : statusLabel,
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            showQr ? 'Status Pembayaran' : 'Status Pembayaran',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.placeholder,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            statusLabel,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: paymentStatus.color,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),
                    _MiniInfoRow(
                      label: 'Jumlah',
                      value: '${transaction.quantity} pcs',
                    ),
                    const SizedBox(height: 10),
                    _MiniInfoRow(label: 'Total', value: transaction.totalLabel),
                    const SizedBox(height: 10),
                    _MiniInfoRow(
                      label: 'Alamat',
                      value: transaction.buyerAddress,
                    ),
                    const SizedBox(height: 10),
                    _MiniInfoRow(
                      label: 'Koordinat',
                      value: transaction.buyerCoordinates,
                    ),
                    const SizedBox(height: 10),
                    _MiniInfoRow(
                      label: 'Pembayaran',
                      value: transaction.paymentMethod,
                    ),
                    if (transaction.bankName != null &&
                        transaction.bankName!.isNotEmpty)
                      _MiniInfoRow(label: 'Bank', value: transaction.bankName!),
                    if (transaction.accountNumber != null &&
                        transaction.accountNumber!.isNotEmpty)
                      _MiniInfoRow(
                        label: 'Rekening',
                        value: transaction.accountNumber!,
                      ),
                    if (showConfirmPayment || showVerifyPayment) ...[
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: showConfirmPayment
                              ? _confirmPayment
                              : _verifyPayment,
                          icon: Icon(
                            showConfirmPayment
                                ? Icons.payments_rounded
                                : Icons.verified_rounded,
                            size: 18,
                          ),
                          label: Text(
                            showConfirmPayment
                                ? 'Konfirmasi Pembayaran'
                                : 'Verifikasi Pembayaran',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
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
            label,
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
