import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_top_bar.dart';
import '../../../shared/widgets/primary_pill_button.dart';
import '../../../shared/widgets/qr_preview.dart';
import '../data/umkm_repository.dart';
import '../models/umkm_product.dart';

class UmkmAddProductScreen extends StatefulWidget {
  const UmkmAddProductScreen({super.key});

  @override
  State<UmkmAddProductScreen> createState() => _UmkmAddProductScreenState();
}

class _UmkmAddProductScreenState extends State<UmkmAddProductScreen> {
  final _nameCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _stockCtrl = TextEditingController(text: '0');
  final _descriptionCtrl = TextEditingController();
  final _repo = UmkmRepository.instance;
  final _imagePicker = ImagePicker();

  bool _isSaving = false;
  bool _isPickingImage = false;
  int _stock = 0;
  String _category = 'Olahan';
  String? _selectedImagePath;
  UmkmProduct? _createdProduct;

  @override
  void initState() {
    super.initState();
    _stockCtrl.addListener(_handleStockInput);
  }

  @override
  void dispose() {
    _stockCtrl.removeListener(_handleStockInput);
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    _stockCtrl.dispose();
    _descriptionCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    if (_isPickingImage) return;

    setState(() => _isPickingImage = true);
    try {
      final image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (!mounted) return;
      if (image == null) return;
      setState(() => _selectedImagePath = image.path);
    } finally {
      if (mounted) {
        setState(() => _isPickingImage = false);
      }
    }
  }

  void _setStock(int value) {
    final next = value < 0 ? 0 : value;
    setState(() {
      _stock = next;
      _stockCtrl.text = next.toString();
    });
  }

  void _incrementStock() => _setStock(_stock + 1);

  void _decrementStock() => _setStock(_stock - 1);

  void _syncStockText(String value) {
    final raw = value.trim();
    if (raw.isEmpty) {
      setState(() => _stock = 0);
      return;
    }
    if (!RegExp(r'^\d+$').hasMatch(raw)) return;
    final parsed = int.tryParse(raw) ?? 0;
    setState(() => _stock = parsed < 0 ? 0 : parsed);
  }

  void _handleStockInput() {
    final raw = _stockCtrl.text.trim();
    if (raw.isEmpty) {
      if (_stock != 0) {
        setState(() => _stock = 0);
      }
      return;
    }

    if (!RegExp(r'^\d+$').hasMatch(raw)) return;

    final next = int.tryParse(raw) ?? 0;
    if (next != _stock) {
      setState(() => _stock = next < 0 ? 0 : next);
    }
  }

  Future<void> _submit() async {
    if (_nameCtrl.text.trim().isEmpty || _priceCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama produk dan harga wajib diisi.')),
      );
      return;
    }

    setState(() => _isSaving = true);
    final now = DateTime.now();
    final id = 'P-${now.millisecondsSinceEpoch}';
    final code = 'UMKM-P-${now.millisecondsSinceEpoch.toString().substring(7)}';
    final stockValue = _stock;
    final stockLabel = stockValue > 0 ? 'Stok $stockValue unit' : 'Stok belum ditentukan';

    final product = UmkmProduct(
      id: id,
      code: code,
      name: _nameCtrl.text.trim(),
      category: _category,
      priceLabel: 'Rp ${_priceCtrl.text.trim()}',
      stockLabel: stockLabel,
      description: _descriptionCtrl.text.trim().isEmpty
          ? 'Deskripsi produk belum ditambahkan.'
          : _descriptionCtrl.text.trim(),
      status: stockValue <= 0 ? UmkmProductStatus.habis : UmkmProductStatus.aktif,
      qrCodeData: code,
      imagePath: _selectedImagePath,
    );

    await Future.delayed(const Duration(milliseconds: 500));
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
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            const AppTopBar(title: 'Tambah Produk UMKM'),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Form Produk Baru',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.black,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Lengkapi data produk, tambah foto, lalu atur stok dengan tombol atau ketik langsung.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.placeholder,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _SectionCard(
                      title: 'Foto Produk',
                      children: [
                        _ImagePickerCard(
                          imagePath: _selectedImagePath,
                          isLoading: _isPickingImage,
                          onPick: _pickImage,
                          onClear: _selectedImagePath == null
                              ? null
                              : () => setState(() => _selectedImagePath = null),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _SectionCard(
                      title: 'Detail Produk',
                      children: [
                        _buildField(
                          label: 'Nama Produk',
                          controller: _nameCtrl,
                          hintText: 'Contoh: Pancake Durian Premium',
                        ),
                        const SizedBox(height: 14),
                        _buildDropdown(),
                        const SizedBox(height: 14),
                        _buildField(
                          label: 'Deskripsi',
                          controller: _descriptionCtrl,
                          hintText: 'Jelaskan produk secara singkat dan menarik',
                          maxLines: 4,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _SectionCard(
                      title: 'Harga & Stok',
                      children: [
                        _buildField(
                          label: 'Harga',
                          controller: _priceCtrl,
                          hintText: 'Contoh: 68.000',
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          prefixText: 'Rp',
                        ),
                        const SizedBox(height: 14),
                        _StockControl(
                          stock: _stock,
                          controller: _stockCtrl,
                          onIncrement: _incrementStock,
                          onDecrement: _decrementStock,
                          onChanged: _syncStockText,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    PrimaryPillButton(
                      label: 'SIMPAN PRODUK',
                      isLoading: _isSaving,
                      onPressed: _isSaving ? null : _submit,
                    ),
                    if (_createdProduct != null) ...[
                      const SizedBox(height: 24),
                      _SectionCard(
                        title: 'QR Produk',
                        children: [
                          Center(
                            child: Container(
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(color: const Color(0xFFE5E7EB)),
                              ),
                              child: QrPreview(
                                data: _createdProduct!.qrCodeData,
                                size: 180,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Center(
                            child: Text(
                              'Kode: ${_createdProduct!.code}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.subtitle,
                              ),
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

  Widget _buildDropdown() {
    const categoryOptions = <String>[
      'Segar',
      'Olahan',
      'Minuman',
      'Paket',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Kategori',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.black,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: categoryOptions.contains(_category) ? _category : categoryOptions.first,
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          items: categoryOptions
              .map((item) => DropdownMenuItem(value: item, child: Text(item)))
              .toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() => _category = value);
            }
          },
        ),
      ],
    );
  }

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    required String hintText,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    int maxLines = 1,
    String? prefixText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.black,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          maxLines: maxLines,
          onChanged: label == 'Stok' ? _syncStockText : null,
          textAlignVertical: TextAlignVertical.center,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(fontSize: 13, color: AppColors.placeholder),
            prefixText: prefixText == null ? null : '$prefixText ',
            filled: true,
            fillColor: AppColors.surface,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
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
        borderRadius: BorderRadius.circular(14),
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

class _ImagePickerCard extends StatelessWidget {
  const _ImagePickerCard({
    required this.imagePath,
    required this.isLoading,
    required this.onPick,
    required this.onClear,
  });

  final String? imagePath;
  final bool? isLoading;
  final VoidCallback onPick;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            height: 160,
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            clipBehavior: Clip.antiAlias,
            child: imagePath != null && imagePath!.isNotEmpty
                ? Image.file(
                    File(imagePath!),
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const _ImagePlaceholder(),
                  )
                : const _ImagePlaceholder(),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: isLoading == true ? null : onPick,
                  icon: isLoading == true
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.photo_library_outlined, size: 18),
                  label: Text(isLoading == true ? 'Memuat...' : 'Pilih Foto'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: Color(0xFFE5E7EB)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              if (onClear != null) ...[
                const SizedBox(width: 10),
                IconButton(
                  onPressed: onClear,
                  icon: const Icon(Icons.delete_outline_rounded),
                  color: const Color(0xFFB91C1C),
                  splashRadius: 22,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.image_outlined, size: 42, color: AppColors.placeholder),
          SizedBox(height: 8),
          Text(
            'Tambahkan foto produk',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.placeholder,
            ),
          ),
        ],
      ),
    );
  }
}

class _StockControl extends StatelessWidget {
  const _StockControl({
    required this.stock,
    required this.controller,
    required this.onIncrement,
    required this.onDecrement,
    required this.onChanged,
  });

  final int? stock;
  final TextEditingController controller;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final currentStock = stock ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Stok',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.black,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Row(
            children: [
              _StepButton(
                icon: Icons.remove_rounded,
                onTap: onDecrement,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  textAlign: TextAlign.center,
                  onChanged: onChanged,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.black,
                  ),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppColors.white,
                    hintText: '0',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              _StepButton(
                icon: Icons.add_rounded,
                onTap: onIncrement,
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Stok saat ini: $currentStock unit',
          style: const TextStyle(fontSize: 11, color: AppColors.placeholder),
        ),
      ],
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.primaryContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: Icon(icon, color: AppColors.white),
      ),
    );
  }
}
