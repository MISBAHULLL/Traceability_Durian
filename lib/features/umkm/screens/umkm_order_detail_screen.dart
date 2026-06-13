import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_top_bar.dart';
import '../../../shared/widgets/qr_preview.dart';
import '../data/umkm_repository.dart';
import '../models/umkm_order.dart';
import '../models/umkm_product.dart';

class UmkmOrderDetailScreen extends StatefulWidget {
  const UmkmOrderDetailScreen({super.key, required this.order});

  final UmkmOrder order;

  @override
  State<UmkmOrderDetailScreen> createState() => _UmkmOrderDetailScreenState();
}

class _UmkmOrderDetailScreenState extends State<UmkmOrderDetailScreen> {
  final _repo = UmkmRepository.instance;
  late UmkmOrder _order;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _order = widget.order;
  }

  Future<void> _updateStatus(UmkmOrderStatus status) async {
    setState(() => _isSaving = true);
    await Future.delayed(const Duration(milliseconds: 500));
    _order = _order.copyWith(status: status);
    _repo.updateOrder(_order);
    if (!mounted) return;
    setState(() => _isSaving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Status pesanan diubah menjadi ${status.label}.')),
    );
  }

  Future<void> _cancelOrder() async {
    final shouldCancel = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Batalkan pesanan?'),
          content: const Text(
            'Pesanan akan dihapus dari daftar pesanan aktif dan tidak bisa dikembalikan.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Tidak'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Ya, batalkan'),
            ),
          ],
        );
      },
    );

    if (shouldCancel != true) return;

    setState(() => _isSaving = true);
    await Future.delayed(const Duration(milliseconds: 300));
    _repo.deleteOrder(_order.id);
    if (!mounted) return;
    setState(() => _isSaving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Pesanan dibatalkan.')),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final product = _findProductByName(_order.productName);
    final imagePath = product?.imagePath ?? 'assets/images/durian.png';

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            const AppTopBar(title: 'Detail Pesanan'),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _HeaderCard(order: _order),
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(
                        imagePath,
                        width: double.infinity,
                        height: 210,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Container(
                          height: 210,
                          color: AppColors.surface,
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.image_outlined,
                            color: AppColors.placeholder,
                            size: 32,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _SectionCard(
                      title: 'Informasi Pesanan',
                      children: [
                        _InfoRow(label: 'Kode Pesanan', value: _order.id),
                        _InfoRow(label: 'Produk', value: _order.productName),
                        _InfoRow(label: 'Pembeli', value: _order.buyerName),
                        _InfoRow(label: 'Jumlah', value: '${_order.quantity}'),
                        _InfoRow(label: 'Total', value: _order.totalLabel),
                        _InfoRow(label: 'Status', value: _order.status.label),
                        _InfoRow(label: 'Catatan', value: _order.note ?? 'Tidak ada catatan'),
                      ],
                    ),
                    
                    const SizedBox(height: 24),
                    if (_order.status == UmkmOrderStatus.diproses) ...[
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _isSaving ? null : () => _updateStatus(UmkmOrderStatus.selesai),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryContainer,
                                disabledBackgroundColor: AppColors.primaryContainer.withValues(alpha: 0.35),
                                foregroundColor: AppColors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                              child: _isSaving
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.4,
                                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
                                      ),
                                    )
                                  : const Text('selesai'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _isSaving ? null : _cancelOrder,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFFDC2626),
                                side: const BorderSide(color: Color(0xFFFECACA)),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                backgroundColor: const Color(0xFFFFF5F5),
                              ),
                              child: const Text('Batalkan Pesanan'),
                            ),
                          ),
                        ],
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

  UmkmProduct? _findProductByName(String productName) {
    try {
      return _repo.products.firstWhere((product) => product.name == productName);
    } catch (_) {
      return null;
    }
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.order});

  final UmkmOrder order;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  order.productName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.black,
                  ),
                ),
              ),
              _StatusBadge(status: order.status.label),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            order.buyerName,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.placeholder,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            order.totalLabel,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
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
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.placeholder,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.black,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
        ),
      ),
    );
  }
}
