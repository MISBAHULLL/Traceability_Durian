import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_top_bar.dart';
import '../../../shared/widgets/primary_pill_button.dart';
import '../../../shared/widgets/qr_preview.dart';
import '../data/umkm_repository.dart';
import '../models/umkm_production_record.dart';
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
  final _lotCtrl = TextEditingController(
    text:
        'LOT-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
  );
  final _methodCtrl = TextEditingController(text: 'Kupas dan olah');
  final _outputQtyCtrl = TextEditingController(text: '0');
  final _outputUnitCtrl = TextEditingController(text: 'unit');
  final _lossCtrl = TextEditingController(text: '0');
  final _productionNoteCtrl = TextEditingController();
  final _repo = UmkmRepository.instance;
  final _imagePicker = ImagePicker();

  bool _isSaving = false;
  bool _isPickingImage = false;
  int _stock = 0;
  String _category = 'Olahan';
  String? _selectedImagePath;
  DateTime _producedAt = DateTime.now();
  DateTime? _expiryDate = DateTime.now().add(const Duration(days: 3));
  final Map<String, double> _materialQuantities = {};
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
    _lotCtrl.dispose();
    _methodCtrl.dispose();
    _outputQtyCtrl.dispose();
    _outputUnitCtrl.dispose();
    _lossCtrl.dispose();
    _productionNoteCtrl.dispose();
    super.dispose();
  }

  // [FE - Event Handler] Picker ini menyediakan kamera dan galeri untuk
  // foto produk UMKM, sehingga form tidak bergantung pada flow web saja.
  Future<void> _pickImage() async {
    if (_isPickingImage) return;

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(
                Icons.photo_camera_outlined,
                color: AppColors.primary,
              ),
              title: const Text('Ambil dari Kamera'),
              onTap: () => Navigator.pop(sheetContext, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(
                Icons.photo_library_outlined,
                color: AppColors.primary,
              ),
              title: const Text('Pilih dari Galeri'),
              onTap: () => Navigator.pop(sheetContext, ImageSource.gallery),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (!mounted || source == null) return;

    setState(() => _isPickingImage = true);
    try {
      final image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1024,
        imageQuality: 85,
      );
      if (!mounted) return;
      if (image == null) return;
      setState(() => _selectedImagePath = image.path);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal mengambil foto produk.')),
        );
      }
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

  List<UmkmTraceMaterialStock> get _availableMaterials =>
      _repo.traceableMaterialStocks;

  List<UmkmTraceMaterialStock> get _selectedMaterials => _availableMaterials
      .where((material) => _materialQuantities.containsKey(material.traceCode))
      .toList();

  double get _selectedMaterialWeightKg => _selectedMaterials.fold<double>(
    0,
    (total, material) => total + (_materialQuantities[material.traceCode] ?? 0),
  );

  void _toggleMaterial(UmkmTraceMaterialStock material) {
    setState(() {
      if (_materialQuantities.containsKey(material.traceCode)) {
        _materialQuantities.remove(material.traceCode);
      } else {
        _materialQuantities[material.traceCode] = material.remainingQuantity;
      }
    });
  }

  void _setMaterialQuantity(UmkmTraceMaterialStock material, String value) {
    final parsed = double.tryParse(value.trim().replaceAll(',', '.'));
    if (parsed == null) return;
    final next = parsed.clamp(0.0, material.remainingQuantity).toDouble();
    setState(() {
      if (next <= 0) {
        _materialQuantities.remove(material.traceCode);
      } else {
        _materialQuantities[material.traceCode] = next;
      }
    });
  }

  Future<void> _pickProducedAt() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _producedAt,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked == null || !mounted) return;
    setState(() => _producedAt = picked);
  }

  Future<void> _pickExpiryDate() async {
    final initialDate =
        _expiryDate != null && !_expiryDate!.isBefore(_producedAt)
        ? _expiryDate!
        : _producedAt;
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: _producedAt,
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (picked == null || !mounted) return;
    setState(() => _expiryDate = picked);
  }

  String _formatDate(DateTime date) {
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
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  Future<void> _submit() async {
    if (_nameCtrl.text.trim().isEmpty || _priceCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama produk dan harga wajib diisi.')),
      );
      return;
    }
    if (_selectedMaterials.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih minimal satu bahan baku traceable.'),
        ),
      );
      return;
    }
    if (_lotCtrl.text.trim().isEmpty || _methodCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nomor lot dan metode proses wajib diisi.'),
        ),
      );
      return;
    }
    final outputQuantity = int.tryParse(_outputQtyCtrl.text.trim()) ?? 0;
    if (outputQuantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Jumlah hasil produksi wajib diisi.')),
      );
      return;
    }
    final lossWeight =
        double.tryParse(_lossCtrl.text.trim().replaceAll(',', '.')) ?? 0;
    if (lossWeight < 0 || lossWeight > _selectedMaterialWeightKg) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Loss/waste tidak boleh melebihi bahan baku dipakai.'),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    final now = DateTime.now();
    final id = 'P-${now.millisecondsSinceEpoch}';
    final code = 'UMKM-P-${now.millisecondsSinceEpoch.toString().substring(7)}';
    final stockValue = _stock;
    final stockLabel = stockValue > 0
        ? 'Stok $stockValue unit'
        : 'Stok belum ditentukan';

    final sourceMaterials = _selectedMaterials
        .map(
          (material) => UmkmProductMaterial(
            purchaseId: material.id,
            traceCode: material.traceCode.trim().toUpperCase(),
            supplierName: material.supplierName,
            productName: material.productName,
            quantityKg: _materialQuantities[material.traceCode] ?? 0,
          ),
        )
        .toList();

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
      status: stockValue <= 0
          ? UmkmProductStatus.habis
          : UmkmProductStatus.aktif,
      qrCodeData: code,
      imagePath: _selectedImagePath,
      sourceMaterials: sourceMaterials,
    );
    final productionRecord = UmkmProductionRecord(
      id: 'PRD-${now.millisecondsSinceEpoch}',
      productCode: code,
      productName: product.name,
      lotNumber: _lotCtrl.text.trim(),
      processMethod: _methodCtrl.text.trim(),
      producedAt: _producedAt,
      expiryDate: _expiryDate,
      outputQuantity: outputQuantity,
      outputUnit: _outputUnitCtrl.text.trim().isEmpty
          ? 'unit'
          : _outputUnitCtrl.text.trim(),
      inputWeightKg: _selectedMaterialWeightKg,
      lossWeightKg: lossWeight,
      sourceMaterials: sourceMaterials,
      note: _productionNoteCtrl.text.trim().isEmpty
          ? null
          : _productionNoteCtrl.text.trim(),
    );

    await Future.delayed(const Duration(milliseconds: 500));
    _repo.addProduct(product, productionRecord: productionRecord);
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
                          hintText:
                              'Jelaskan produk secara singkat dan menarik',
                          maxLines: 4,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _SectionCard(
                      title: 'Bahan Baku Trace',
                      children: [
                        _MaterialSelector(
                          materials: _availableMaterials,
                          quantitiesByTraceCode: _materialQuantities,
                          selectedWeightKg: _selectedMaterialWeightKg,
                          onToggle: _toggleMaterial,
                          onQuantityChanged: _setMaterialQuantity,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _SectionCard(
                      title: 'Catatan Produksi',
                      children: [
                        _buildField(
                          label: 'Nomor Lot',
                          controller: _lotCtrl,
                          hintText: 'Contoh: LOT-2026-001',
                        ),
                        const SizedBox(height: 14),
                        _buildField(
                          label: 'Metode Proses',
                          controller: _methodCtrl,
                          hintText: 'Contoh: Kupas, sortasi, bekukan',
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: _buildDateSelector(
                                label: 'Tanggal Produksi',
                                value: _formatDate(_producedAt),
                                onTap: _pickProducedAt,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildDateSelector(
                                label: 'Kedaluwarsa',
                                value: _expiryDate == null
                                    ? 'Belum diisi'
                                    : _formatDate(_expiryDate!),
                                onTap: _pickExpiryDate,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: _buildField(
                                label: 'Hasil Produksi',
                                controller: _outputQtyCtrl,
                                hintText: 'Contoh: 24',
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildField(
                                label: 'Satuan',
                                controller: _outputUnitCtrl,
                                hintText: 'paket / botol / unit',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        _buildField(
                          label: 'Loss/Waste',
                          controller: _lossCtrl,
                          hintText: 'Contoh: 1.5',
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'^\d*[,.]?\d{0,2}'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        _buildField(
                          label: 'Catatan Produksi',
                          controller: _productionNoteCtrl,
                          hintText: 'Contoh: Daging durian matang, aroma kuat',
                          maxLines: 3,
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
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
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
                                border: Border.all(
                                  color: const Color(0xFFE5E7EB),
                                ),
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
    const categoryOptions = <String>['Segar', 'Olahan', 'Minuman', 'Paket'];

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
          initialValue: categoryOptions.contains(_category)
              ? _category
              : categoryOptions.first,
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
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
            hintStyle: const TextStyle(
              fontSize: 13,
              color: AppColors.placeholder,
            ),
            prefixText: prefixText == null ? null : '$prefixText ',
            filled: true,
            fillColor: AppColors.surface,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateSelector({
    required String label,
    required String value,
    required VoidCallback onTap,
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
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_today_outlined,
                  size: 16,
                  color: AppColors.placeholder,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.black,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _MaterialSelector extends StatelessWidget {
  const _MaterialSelector({
    required this.materials,
    required this.quantitiesByTraceCode,
    required this.selectedWeightKg,
    required this.onToggle,
    required this.onQuantityChanged,
  });

  final List<UmkmTraceMaterialStock> materials;
  final Map<String, double> quantitiesByTraceCode;
  final double selectedWeightKg;
  final ValueChanged<UmkmTraceMaterialStock> onToggle;
  final void Function(UmkmTraceMaterialStock material, String value)
  onQuantityChanged;

  @override
  Widget build(BuildContext context) {
    if (materials.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFBEB),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFFDE68A)),
        ),
        child: const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.info_outline_rounded,
              size: 18,
              color: Color(0xFFB45309),
            ),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Belum ada saldo bahan baku traceable yang tersisa. Stok lama akan tampil di sini selama saldonya belum habis.',
                style: TextStyle(
                  fontSize: 12,
                  height: 1.4,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF92400E),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            quantitiesByTraceCode.isEmpty
                ? 'Belum ada bahan baku dipilih'
                : '${quantitiesByTraceCode.length} bahan baku dipilih / ${_formatWeight(selectedWeightKg)} dipakai',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
            ),
          ),
        ),
        const SizedBox(height: 10),
        ...materials.map(
          (purchase) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _MaterialTile(
              material: purchase,
              selectedQuantity: quantitiesByTraceCode[purchase.traceCode],
              onTap: () => onToggle(purchase),
              onQuantityChanged: (value) => onQuantityChanged(purchase, value),
            ),
          ),
        ),
      ],
    );
  }

  String _formatWeight(double value) {
    if (value % 1 == 0) return '${value.toStringAsFixed(0)} kg';
    return '${value.toStringAsFixed(1)} kg';
  }
}

class _MaterialTile extends StatelessWidget {
  const _MaterialTile({
    required this.material,
    required this.selectedQuantity,
    required this.onTap,
    required this.onQuantityChanged,
  });

  final UmkmTraceMaterialStock material;
  final double? selectedQuantity;
  final VoidCallback onTap;
  final ValueChanged<String> onQuantityChanged;

  @override
  Widget build(BuildContext context) {
    final selected = selectedQuantity != null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.08)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.primary : const Color(0xFFE5E7EB),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              selected
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              size: 22,
              color: selected ? AppColors.primary : AppColors.placeholder,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    material.productName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.25,
                      fontWeight: FontWeight.w900,
                      color: AppColors.black,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    material.supplierName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.placeholder,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _MaterialChip(label: material.traceCode),
                      _MaterialChip(label: material.remainingLabel),
                    ],
                  ),
                  if (selected) ...[
                    const SizedBox(height: 10),
                    _MaterialQuantityInput(
                      initialValue: selectedQuantity!,
                      unit: material.unit,
                      maxQuantity: material.remainingQuantity,
                      onChanged: onQuantityChanged,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MaterialChip extends StatelessWidget {
  const _MaterialChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: AppColors.subtitle,
        ),
      ),
    );
  }
}

class _MaterialQuantityInput extends StatefulWidget {
  const _MaterialQuantityInput({
    required this.initialValue,
    required this.unit,
    required this.maxQuantity,
    required this.onChanged,
  });

  final double initialValue;
  final String unit;
  final double maxQuantity;
  final ValueChanged<String> onChanged;

  @override
  State<_MaterialQuantityInput> createState() => _MaterialQuantityInputState();
}

class _MaterialQuantityInputState extends State<_MaterialQuantityInput> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: _formatNumber(widget.initialValue),
    );
  }

  @override
  void didUpdateWidget(covariant _MaterialQuantityInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialValue != widget.initialValue &&
        _controller.text != _formatNumber(widget.initialValue)) {
      _controller.text = _formatNumber(widget.initialValue);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Dipakai dari stok ini, maksimal ${_formatNumber(widget.maxQuantity)} ${widget.unit}',
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: AppColors.placeholder,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*[,.]?\d{0,2}')),
          ],
          decoration: InputDecoration(
            suffixText: widget.unit,
            filled: true,
            fillColor: AppColors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.primary),
            ),
          ),
          onChanged: widget.onChanged,
        ),
      ],
    );
  }

  String _formatNumber(double value) {
    if (value % 1 == 0) return value.toStringAsFixed(0);
    return value.toStringAsFixed(1);
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
                ? kIsWeb
                      ? Image.network(
                          imagePath!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => const _ImagePlaceholder(),
                        )
                      : Image.file(
                          File(imagePath!),
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => const _ImagePlaceholder(),
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
            style: TextStyle(fontSize: 12, color: AppColors.placeholder),
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
              _StepButton(icon: Icons.remove_rounded, onTap: onDecrement),
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
              _StepButton(icon: Icons.add_rounded, onTap: onIncrement),
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
