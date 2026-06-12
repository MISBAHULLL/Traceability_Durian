import 'package:flutter/material.dart';
import '../../../shared/widgets/qr_preview.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_top_bar.dart';
import '../../../shared/widgets/primary_pill_button.dart';
import '../data/umkm_repository.dart';
import '../models/umkm_purchase.dart';

class UmkmAddPurchaseScreen extends StatefulWidget {
  const UmkmAddPurchaseScreen({super.key});

  @override
  State<UmkmAddPurchaseScreen> createState() => _UmkmAddPurchaseScreenState();
}

class _UmkmAddPurchaseScreenState extends State<UmkmAddPurchaseScreen> {
  final _supplierCtrl = TextEditingController();
  final _productCtrl = TextEditingController();
  final _quantityCtrl = TextEditingController();
  final _totalCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  final _repo = UmkmRepository.instance;
  bool _isSaving = false;
  UmkmPurchase? _createdPurchase;

  @override
  void dispose() {
    _supplierCtrl.dispose();
    _productCtrl.dispose();
    _quantityCtrl.dispose();
    _totalCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_supplierCtrl.text.trim().isEmpty || _productCtrl.text.trim().isEmpty || _totalCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pengepul, produk, dan total pembelian wajib diisi.')),
      );
      return;
    }

    setState(() => _isSaving = true);
    final id = 'PUR-${DateTime.now().millisecondsSinceEpoch}';
    final code = 'PUR-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';
    final purchase = UmkmPurchase(
      id: id,
      supplierName: _supplierCtrl.text.trim(),
      productName: _productCtrl.text.trim(),
      quantity: int.tryParse(_quantityCtrl.text.trim()) ?? 1,
      totalLabel: 'Rp ${_totalCtrl.text.trim()}',
      createdAt: DateTime.now(),
      qrCodeData: code,
      note: _noteCtrl.text.trim().isEmpty ? 'Tidak ada catatan.' : _noteCtrl.text.trim(),
    );

    await Future.delayed(const Duration(milliseconds: 600));
    _repo.addPurchase(purchase);
    if (!mounted) return;
    setState(() {
      _isSaving = false;
      _createdPurchase = purchase;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Pembelian berhasil direkam.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const PreferredSize(
        preferredSize: Size.fromHeight(72),
        child: AppTopBar(title: 'Beli Stok Durian'),
      ),
      backgroundColor: AppColors.white,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Form Pembelian',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.black),
              ),
              const SizedBox(height: 6),
              const Text(
                'Rekam transaksi pembelian dari pengepul dan buat QR transaksi untuk bukti pembayaran.',
                style: TextStyle(fontSize: 12, color: AppColors.placeholder, height: 1.5),
              ),
              const SizedBox(height: 20),
              _buildField(label: 'Nama Pengepul', controller: _supplierCtrl),
              const SizedBox(height: 14),
              _buildField(label: 'Produk yang Dibeli', controller: _productCtrl),
              const SizedBox(height: 14),
              _buildField(label: 'Jumlah', controller: _quantityCtrl, keyboardType: TextInputType.number),
              const SizedBox(height: 14),
              _buildField(label: 'Total Harga', controller: _totalCtrl, keyboardType: TextInputType.number),
              const SizedBox(height: 14),
              _buildField(label: 'Catatan', controller: _noteCtrl, maxLines: 3),
              const SizedBox(height: 24),
              PrimaryPillButton(
                label: 'Simpan Pembelian',
                isLoading: _isSaving,
                onPressed: _isSaving ? null : _submit,
              ),
              if (_createdPurchase != null) ...[
                const SizedBox(height: 24),
                const Text(
                  'QR Transaksi',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.black),
                ),
                const SizedBox(height: 12),
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: QrPreview(data: _createdPurchase!.qrCodeData, size: 180),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Kode: ${_createdPurchase!.qrCodeData}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12, color: AppColors.subtitle),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.black)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          decoration: const InputDecoration(
            filled: true,
            fillColor: AppColors.surface,
            border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(14)), borderSide: BorderSide.none),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }
}
