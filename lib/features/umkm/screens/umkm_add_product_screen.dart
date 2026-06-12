import 'package:flutter/material.dart';
import '../../../shared/widgets/qr_preview.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_top_bar.dart';
import '../../../shared/widgets/primary_pill_button.dart';
import '../data/umkm_repository.dart';
import '../models/umkm_product.dart';

class UmkmAddProductScreen extends StatefulWidget {
  const UmkmAddProductScreen({super.key});

  @override
  State<UmkmAddProductScreen> createState() => _UmkmAddProductScreenState();
}

class _UmkmAddProductScreenState extends State<UmkmAddProductScreen> {
  final _nameCtrl = TextEditingController();
  final _categoryCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _stockCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _repo = UmkmRepository.instance;
  bool _isSaving = false;
  UmkmProduct? _createdProduct;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _categoryCtrl.dispose();
    _priceCtrl.dispose();
    _stockCtrl.dispose();
    _descriptionCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_nameCtrl.text.trim().isEmpty || _priceCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama produk dan harga wajib diisi.')),
      );
      return;
    }

    setState(() => _isSaving = true);
    final id = 'P-${DateTime.now().millisecondsSinceEpoch}';
    final code = 'UMKM-P-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';
    final product = UmkmProduct(
      id: id,
      code: code,
      name: _nameCtrl.text.trim(),
      category: _categoryCtrl.text.trim().isEmpty ? 'Umum' : _categoryCtrl.text.trim(),
      priceLabel: 'Rp ${_priceCtrl.text.trim()}',
      stockLabel: _stockCtrl.text.trim().isEmpty ? 'Stok belum ditentukan' : 'Stok ${_stockCtrl.text.trim()} unit',
      description: _descriptionCtrl.text.trim().isEmpty ? 'Deskripsi produk belum ditambahkan.' : _descriptionCtrl.text.trim(),
      status: UmkmProductStatus.aktif,
      qrCodeData: code,
    );

    await Future.delayed(const Duration(milliseconds: 600));
    _repo.addProduct(product);
    if (!mounted) return;
    setState(() {
      _isSaving = false;
      _createdProduct = product;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Produk berhasil ditambahkan.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const PreferredSize(
        preferredSize: Size.fromHeight(72),
        child: AppTopBar(title: 'Tambah Produk UMKM'),
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
                'Form Produk Baru',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.black),
              ),
              const SizedBox(height: 6),
              const Text(
                'Masukkan data produk durian atau olahan UMKM Anda untuk membuat kode produk dan QR otomatis.',
                style: TextStyle(fontSize: 12, color: AppColors.placeholder, height: 1.5),
              ),
              const SizedBox(height: 20),
              _buildField(label: 'Nama Produk', controller: _nameCtrl),
              const SizedBox(height: 14),
              _buildField(label: 'Kategori', controller: _categoryCtrl),
              const SizedBox(height: 14),
              _buildField(label: 'Harga', controller: _priceCtrl, keyboardType: TextInputType.number),
              const SizedBox(height: 14),
              _buildField(label: 'Stok', controller: _stockCtrl, keyboardType: TextInputType.number),
              const SizedBox(height: 14),
              _buildField(label: 'Deskripsi', controller: _descriptionCtrl, maxLines: 4),
              const SizedBox(height: 24),
              PrimaryPillButton(
                label: 'Simpan Produk',
                isLoading: _isSaving,
                onPressed: _isSaving ? null : _submit,
              ),
              if (_createdProduct != null) ...[
                const SizedBox(height: 24),
                const Text(
                  'QR Produk',
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
                    child: QrPreview(data: _createdProduct!.qrCodeData, size: 180),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Kode: ${_createdProduct!.code}',
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
