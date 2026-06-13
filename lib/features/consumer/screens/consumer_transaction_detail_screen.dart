import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_top_bar.dart';
import '../models/consumer_product.dart';
import '../models/consumer_transaction.dart';

/// Detail transaksi konsumen.
class ConsumerTransactionDetailScreen extends StatelessWidget {
  const ConsumerTransactionDetailScreen({
    super.key,
    required this.transaction,
  });

  final ConsumerTransaction transaction;

  @override
  Widget build(BuildContext context) {
    final product = transaction.product;
    final isQris = transaction.paymentMethod == 'QRIS';
    final paymentStatus = transaction.effectivePaymentStatus;
    final showQr = isQris && paymentStatus == ConsumerPaymentStatus.unpaid;
    final showDeliveryFlow = paymentStatus != ConsumerPaymentStatus.unpaid;
    final paymentStatusLabel = paymentStatus.label;

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            const AppTopBar(title: 'Detail Transaksi'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                children: [
                  const SizedBox(height: 8),
                  Text(
                    'Profil UMKM Durian',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.black,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundImage: null,
                        backgroundColor: AppColors.surface,
                        child: const Icon(Icons.person, color: AppColors.primary),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product.sourceVerifiedBy ?? product.umkmName,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: AppColors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Peta Lokasi :',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 120,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: const Center(
                      child: Text(
                        'Map placeholder',
                        style: TextStyle(color: AppColors.placeholder),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Product information card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 84,
                          height: 84,
                          child: product.imagePath != null && product.imagePath!.isNotEmpty
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.asset(product.imagePath!, fit: BoxFit.cover),
                                )
                              : Image.asset('assets/images/durian.png', fit: BoxFit.contain),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                product.name,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.black,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                product.priceLabel,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                product.shortDescription,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.placeholder,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _ProductInfoCard(product: product),
                  if (showQr) ...[
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'QR Transaksi',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.black,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Center(
                            child: QrImageView(
                              data: transaction.qrCodeData,
                              version: QrVersions.auto,
                              size: 160,
                              backgroundColor: AppColors.white,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Center(
                            child: Text(
                              transaction.id,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                                letterSpacing: 0.6,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (showDeliveryFlow) ...[
                    const SizedBox(height: 16),
                    _DeliveryTimeline(status: transaction.status),
                  ],
                  if (transaction.status == ConsumerTransactionStatus.completed) ...[
                    const SizedBox(height: 16),
                    _PurchasedProductQrCard(transaction: transaction),
                  ],
                  const SizedBox(height: 16),

                  _SectionCard(
                    title: 'Informasi Transaksi',
                    children: [
                      _InfoRow(label: 'Kode', value: transaction.id),
                      if (showDeliveryFlow)
                        _InfoRow(
                          label: 'Status',
                          value: transaction.status.label,
                          valueColor: transaction.status.color,
                        ),
                      _InfoRow(
                        label: 'Tanggal',
                        value: _formatDateTime(transaction.createdAt),
                      ),
                      _InfoRow(
                        label: 'Jumlah',
                        value: '${transaction.quantity} pcs',
                      ),
                      _InfoRow(label: 'Total', value: transaction.totalLabel),
                      _InfoRow(label: 'Alamat', value: transaction.buyerAddress),
                      _InfoRow(label: 'Koordinat', value: transaction.buyerCoordinates),
                      _InfoRow(
                        label: 'Status Pembayaran',
                        value: paymentStatusLabel,
                        valueColor: paymentStatus.color,
                      ),
                      if (transaction.status == ConsumerTransactionStatus.completed)
                        _InfoRow(
                          label: 'Kode Produk',
                          value: transaction.purchasedProductCode,
                        ),
                      _InfoRow(label: 'Pembayaran', value: transaction.paymentMethod),
                      if (transaction.bankName != null && transaction.bankName!.isNotEmpty)
                        _InfoRow(label: 'Bank', value: transaction.bankName!),
                      if (transaction.accountNumber != null &&
                          transaction.accountNumber!.isNotEmpty)
                        _InfoRow(label: 'Rekening', value: transaction.accountNumber!),
                      if (transaction.note != null && transaction.note!.isNotEmpty)
                        _InfoRow(label: 'Catatan', value: transaction.note!),
                    ],
                  ),

                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}, $h:$m';
  }
}



class _DeliveryTimeline extends StatelessWidget {
  const _DeliveryTimeline({required this.status});

  final ConsumerTransactionStatus status;

  @override
  Widget build(BuildContext context) {
    final steps = [
      {
        'title': 'UMKM',
        'subtitle': 'Produk diproses dan disiapkan oleh UMKM.',
        'active': status == ConsumerTransactionStatus.processing || status == ConsumerTransactionStatus.completed,
      },
      {
        'title': 'Pengiriman',
        'subtitle': 'Produk sedang dikirim, bisa di DC atau langsung ke lokasi.',
        'active': status == ConsumerTransactionStatus.completed,
      },
      {
        'title': 'Konsumen',
        'subtitle': 'Produk sampai ke tangan konsumen.',
        'active': status == ConsumerTransactionStatus.completed,
      },
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Perjalanan Produk',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppColors.black,
            ),
          ),
          const SizedBox(height: 16),
          ...List.generate(steps.length, (index) {
            final step = steps[index];
            final bool isActive = step['active'] as bool;
            final bool isLast = index == steps.length - 1;
            return Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 18),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 28,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            color: isActive ? AppColors.primary : AppColors.white,
                            border: Border.all(
                              color: isActive ? AppColors.primary : AppColors.placeholder,
                              width: 2,
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: isActive
                              ? const Center(
                                  child: SizedBox(
                                    width: 8,
                                    height: 8,
                                    child: DecoratedBox(
                                      decoration: BoxDecoration(
                                        color: AppColors.white,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                                )
                              : const SizedBox.shrink(),
                        ),
                        if (!isLast)
                          Container(
                            margin: const EdgeInsets.only(top: 6),
                            width: 2,
                            height: 28,
                            color: AppColors.placeholder.withOpacity(0.24),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          step['title'] as String,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: isActive ? AppColors.black : AppColors.subtitle,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          step['subtitle'] as String,
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.placeholder,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _ProductInfoCard extends StatelessWidget {
  const _ProductInfoCard({required this.product});

  final ConsumerProduct product;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Informasi Produk',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppColors.black,
            ),
          ),
          const SizedBox(height: 10),
          _InfoRow(label: 'Nama Produk', value: product.name),
          _InfoRow(label: 'Kategori', value: product.category.label),
          _InfoRow(
            label: 'Status',
            value: product.status.label,
            valueColor: product.status.color,
          ),
          _InfoRow(label: 'Harga', value: product.priceLabel),
          _InfoRow(label: 'Stok', value: product.stockLabel),
          _InfoRow(label: 'Rating', value: product.rating.toStringAsFixed(1)),
          _InfoRow(label: 'UMKM', value: product.umkmName),
          _InfoRow(label: 'Lokasi UMKM', value: product.location),
          _InfoRow(label: 'Deskripsi', value: product.shortDescription),
        ],
      ),
    );
  }
}

class _PurchasedProductQrCard extends StatelessWidget {
  const _PurchasedProductQrCard({required this.transaction});

  final ConsumerTransaction transaction;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'QR Produk Pembelian',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.black,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Kode unik ini menandai produk yang sudah berhasil dibeli.',
            style: TextStyle(
              fontSize: 11,
              color: AppColors.placeholder,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),
          Center(
            child: QrImageView(
              data: transaction.purchasedProductQrData,
              version: QrVersions.auto,
              size: 160,
              backgroundColor: AppColors.white,
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              transaction.purchasedProductCode,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
                letterSpacing: 0.6,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppColors.black,
            ),
          ),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 122,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.placeholder,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12,
                height: 1.35,
                fontWeight: FontWeight.w700,
                color: valueColor ?? AppColors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
