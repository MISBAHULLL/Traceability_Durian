import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_top_bar.dart';
import '../../farmer/data/farmer_repository.dart';
import '../../farmer/models/harvest_batch.dart';
import '../../trace/screens/public_trace_screen.dart';
import '../consumer_routes.dart';
import 'consumer_create_transaction_screen.dart';
import '../models/consumer_product.dart';
import '../../../shared/widgets/primary_pill_button.dart';

/// Detail produk UMKM untuk konsumen.
///
/// Layar ini menampilkan informasi produk UMKM yang sudah siap jual,
/// ditambah ringkasan asal durian dari petani/pengepul sebagai konteks
/// kualitas, tanpa membuka trace publik.
class ConsumerProductDetailScreen extends StatelessWidget {
  const ConsumerProductDetailScreen({super.key, required this.product});

  final ConsumerProduct product;

  @override
  Widget build(BuildContext context) {
    final batch = product.sourceBatchCode == null
        ? null
        : FarmerRepository.instance.findPublicBatch(product.sourceBatchCode!);
    final hasPhoto = product.imagePath != null && product.imagePath!.isNotEmpty;
    final traceCode = product.code.startsWith('UMKM-P-')
        ? product.code
        : product.sourceBatchCode;

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            const AppTopBar(title: 'Detail Produk'),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _HeaderCard(product: product),
                    const SizedBox(height: 16),
                    if (hasPhoto) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.asset(
                          product.imagePath!,
                          width: double.infinity,
                          height: 210,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) =>
                              _FallbackImage(category: product.category),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    _SectionCard(
                      title: 'Informasi Produk',
                      children: [
                        _InfoRow(label: 'Nama Produk', value: product.name),
                        _InfoRow(
                          label: 'Kategori',
                          value: product.category.label,
                        ),
                        _InfoRow(
                          label: 'Status',
                          value: product.status.label,
                          valueColor: product.status.color,
                        ),
                        _InfoRow(label: 'Harga', value: product.priceLabel),
                        _InfoRow(label: 'Stok', value: product.stockLabel),
                        _InfoRow(
                          label: 'Rating',
                          value: product.rating.toStringAsFixed(1),
                        ),
                        _InfoRow(label: 'UMKM', value: product.umkmName),
                        _InfoRow(label: 'Lokasi UMKM', value: product.location),
                        _InfoRow(
                          label: 'Deskripsi',
                          value: product.shortDescription,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _SectionCard(
                      title: 'Asal Durian',
                      children: batch == null
                          ? const [
                              _InfoRow(
                                label: 'Status Sumber',
                                value: 'Data sumber belum tersedia',
                              ),
                            ]
                          : [
                              _InfoRow(
                                label: 'Status Batch',
                                value: batch.status.label,
                                valueColor: batch.status.color,
                              ),
                              _InfoRow(label: 'Kode Batch', value: batch.code),
                              _InfoRow(label: 'Varietas', value: batch.variety),
                              _InfoRow(
                                label: 'Grade Awal Petani',
                                value: 'Grade ${batch.grade}',
                              ),
                              if (batch.verifiedGrade != null &&
                                  batch.verifiedGrade!.isNotEmpty)
                                _InfoRow(
                                  label: 'Grade Pengepul',
                                  value: 'Grade ${batch.verifiedGrade}',
                                ),
                              _InfoRow(
                                label: 'Total Berat',
                                value:
                                    '${_formatWeight(batch.quantity)} ${batch.unit}',
                              ),
                              if (batch.receivedQuantity != null)
                                _InfoRow(
                                  label: 'Berat Diterima',
                                  value:
                                      '${_formatWeight(batch.receivedQuantity!)} ${batch.unit}',
                                ),
                              if (batch.fruitCount != null)
                                _InfoRow(
                                  label: 'Jumlah Buah',
                                  value: '${batch.fruitCount} butir',
                                ),
                              if (batch.receivedFruitCount != null)
                                _InfoRow(
                                  label: 'Jumlah Diterima',
                                  value: '${batch.receivedFruitCount} butir',
                                ),
                              _InfoRow(
                                label: 'Tanggal Panen',
                                value: _formatDate(batch.harvestDate),
                              ),
                              if (batch.maturityLevel != null &&
                                  batch.maturityLevel!.isNotEmpty)
                                _InfoRow(
                                  label: 'Kematangan',
                                  value: batch.maturityLevel!,
                                ),
                              if (batch.shelfLifeEstimate != null &&
                                  batch.shelfLifeEstimate!.isNotEmpty)
                                _InfoRow(
                                  label: 'Masa Simpan',
                                  value: batch.shelfLifeEstimate!,
                                ),
                              if (batch.harvestMethod != null &&
                                  batch.harvestMethod!.isNotEmpty)
                                _InfoRow(
                                  label: 'Metode Panen',
                                  value: batch.harvestMethod!,
                                ),
                              if (batch.verifiedBy != null &&
                                  batch.verifiedBy!.isNotEmpty)
                                _InfoRow(
                                  label: 'Diverifikasi Oleh',
                                  value: batch.verifiedBy!,
                                ),
                              if (batch.verifiedAt != null)
                                _InfoRow(
                                  label: 'Waktu Verifikasi',
                                  value: _formatDateTime(batch.verifiedAt!),
                                ),
                              if (batch.storageSuggestion != null &&
                                  batch.storageSuggestion!.isNotEmpty)
                                _InfoRow(
                                  label: 'Saran Simpan',
                                  value: batch.storageSuggestion!,
                                ),
                              if (batch.qualityNotes != null &&
                                  batch.qualityNotes!.isNotEmpty)
                                _InfoRow(
                                  label: 'Catatan Sortir',
                                  value: batch.qualityNotes!,
                                ),
                              if (batch.notes != null &&
                                  batch.notes!.isNotEmpty)
                                _InfoRow(label: 'Catatan', value: batch.notes!),
                            ],
                    ),
                    const SizedBox(height: 24),
                    if (traceCode != null && traceCode.isNotEmpty) ...[
                      OutlinedButton.icon(
                        onPressed: () {
                          ConsumerRoutes.push(
                            context,
                            PublicTraceScreen(batchCode: traceCode),
                          );
                        },
                        icon: const Icon(Icons.account_tree_outlined, size: 18),
                        label: const Text('LIHAT TRACE PRODUK'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(color: AppColors.primary),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    PrimaryPillButton(
                      label: 'BUAT TRANSAKSI',
                      onPressed: () {
                        ConsumerRoutes.push(
                          context,
                          ConsumerCreateTransactionScreen(product: product),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime d) {
    const months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  String _formatDateTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '${_formatDate(dt)}, $h:$m';
  }

  String _formatWeight(double value) {
    return value % 1 == 0 ? value.toStringAsFixed(0) : value.toStringAsFixed(2);
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.product});

  final ConsumerProduct product;

  @override
  Widget build(BuildContext context) {
    final statusLabel = product.status.label;
    final statusColor = product.status.color;
    final statusBg = product.status.background;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statusBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.verified_outlined, color: statusColor, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            product.name,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.black,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            product.umkmName,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.subtitle,
              letterSpacing: 0.2,
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
  const _InfoRow({required this.label, required this.value, this.valueColor});

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
            width: 128,
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

class _FallbackImage extends StatelessWidget {
  const _FallbackImage({required this.category});

  final ConsumerProductCategory category;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 210,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        category == ConsumerProductCategory.segar
            ? Icons.eco_outlined
            : Icons.storefront_outlined,
        size: 44,
        color: AppColors.primary,
      ),
    );
  }
}
