import 'package:flutter/material.dart';
import '../../../shared/widgets/qr_preview.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_top_bar.dart';
import '../models/umkm_purchase.dart';

class UmkmPurchaseDetailScreen extends StatelessWidget {
  const UmkmPurchaseDetailScreen({super.key, required this.purchase});

  final UmkmPurchase purchase;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const PreferredSize(
        preferredSize: Size.fromHeight(72),
        child: AppTopBar(title: 'Detail Pembelian'),
      ),
      backgroundColor: AppColors.white,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: QrPreview(data: purchase.qrCodeData, size: 180),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  'Kode Transaksi: ${purchase.qrCodeData}',
                  style: const TextStyle(fontSize: 12, color: AppColors.subtitle),
                ),
              ),
              const SizedBox(height: 24),
              _DetailTile(label: 'Pengepul', value: purchase.supplierName),
              const SizedBox(height: 12),
              _DetailTile(label: 'Produk', value: purchase.productName),
              const SizedBox(height: 12),
              _DetailTile(label: 'Jumlah', value: '${purchase.quantity}'),
              const SizedBox(height: 12),
              _DetailTile(label: 'Total', value: purchase.totalLabel),
              const SizedBox(height: 12),
              _DetailTile(label: 'Catatan', value: purchase.note ?? 'Tidak ada catatan'),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailTile extends StatelessWidget {
  const _DetailTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.black)),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 13, color: AppColors.subtitle, height: 1.5)),
        ],
      ),
    );
  }
}
