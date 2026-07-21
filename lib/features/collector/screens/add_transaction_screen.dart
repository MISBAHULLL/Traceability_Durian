import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_top_bar.dart';
import '../../../shared/widgets/batch_photo.dart';
import '../../../shared/widgets/primary_pill_button.dart';
import '../../../shared/widgets/top_notification_banner.dart';
import '../../farmer/models/harvest_batch.dart';
import '../data/collector_repository.dart';
import '../models/collector_product.dart';
import '../models/collector_warehouse.dart';

// [FE - Component Rendering] Layar ini adalah form "Tambah Transaksi" untuk
// pengepul — turunan dari prototype screen 4. Alur: pilih produk (batch petani)
// → input data verifikasi (grade hasil verifikasi, jumlah diterima, catatan
// kualitas) → kirim untuk verifikasi.
///
/// Sesuai Role Permission Matrix: pengepul TIDAK mengubah data panen petani.
/// Data deskriptif (varietas, lokasi, tanggal panen, pemilik) ditampilkan
/// read-only; pengepul hanya memasukkan hasil verifikasinya.
/// Layar Tambah Transaksi untuk role Pengepul.
///
/// Mengikuti alur Batch Validation Form (blueprint 08 sec 4.4): pilih produk
/// (simulasi scan QR) → input receivedQuantity, grade, qualityNotes → submit.
class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({
    super.key,
    this.initialBatchCode,
    this.initialTransactionId,
  });

  /// Kode batch hasil scan QR simulasi; jika valid, produk langsung terpilih.
  final String? initialBatchCode;

  /// Kode transaksi T1 yang dibuat saat QR dipindai oleh pengepul.
  final String? initialTransactionId;

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  static const List<String> _gradeKeys = ['A', 'B', 'C'];

  final _repo = CollectorRepository.instance;
  final _quantityCtrl = TextEditingController();
  final _fruitCountCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final Map<String, TextEditingController> _gradeWeightCtrls = {
    for (final grade in _gradeKeys) grade: TextEditingController(),
  };
  final Map<String, TextEditingController> _gradeFruitCtrls = {
    for (final grade in _gradeKeys) grade: TextEditingController(),
  };
  final _quantityFocus = FocusNode();
  final _fruitCountFocus = FocusNode();
  final _notesFocus = FocusNode();
  final _notif = TopNotification();

  CollectorProduct? _selectedProduct;
  String? _verificationPhotoPath;
  String? _selectedWarehouseId;

  // [FE - State Management] Flag submit/reject ini mengunci aksi paralel
  // agar satu batch tidak diverifikasi dan ditolak bersamaan.
  bool _isSubmitting = false;
  bool _isRejecting = false;

  @override
  void initState() {
    super.initState();
    _selectedWarehouseId = _repo.defaultWarehouse?.id;

    // [FE - State Management] Initial selection ini menghubungkan hasil scan
    // QR ke form verifikasi tanpa user memilih batch ulang dari dropdown.
    final initialCode = widget.initialBatchCode?.trim();
    if (initialCode != null && initialCode.isNotEmpty) {
      final product = _repo.findProduct(initialCode);
      if (product != null && product.category == ProductCategory.durianSegar) {
        _selectProduct(product);
      }
    }
  }

  @override
  void dispose() {
    _notif.dispose();
    _quantityCtrl.dispose();
    _fruitCountCtrl.dispose();
    _notesCtrl.dispose();
    for (final controller in _gradeWeightCtrls.values) {
      controller.dispose();
    }
    for (final controller in _gradeFruitCtrls.values) {
      controller.dispose();
    }
    _quantityFocus.dispose();
    _fruitCountFocus.dispose();
    _notesFocus.dispose();
    super.dispose();
  }

  // [FE - State Management] Helper ini memusatkan perubahan produk terpilih
  // dan prefill berat agar dropdown manual dan hasil scan memakai alur sama.
  void _selectProduct(CollectorProduct? product) {
    _selectedProduct = product;
    if (product != null) {
      _quantityCtrl.text = product.weightRange.split(' ')[0];
      _fruitCountCtrl.text = product.fruitCount?.toString() ?? '';
    } else {
      _quantityCtrl.clear();
      _fruitCountCtrl.clear();
    }
    _verificationPhotoPath = null;
    _clearGradeInputs();
  }

  Future<void> _pickVerificationPhoto() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        return SafeArea(
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
        );
      },
    );

    if (!mounted || source == null) return;

    try {
      final picker = ImagePicker();
      final file = await picker.pickImage(
        source: source,
        maxWidth: 1280,
        imageQuality: 80,
      );
      if (file != null && mounted) {
        setState(() => _verificationPhotoPath = file.path);
      }
    } catch (_) {
      if (!mounted) return;
      _notif.show(
        context,
        'Gagal mengambil foto verifikasi. Coba lagi.',
        isError: true,
      );
    }
  }

  void _removeVerificationPhoto() {
    setState(() => _verificationPhotoPath = null);
  }

  // [FE - State Management] Helper ini mengosongkan input sortir saat batch
  // berubah agar data grade dari batch sebelumnya tidak ikut tersubmit.
  void _clearGradeInputs() {
    for (final controller in _gradeWeightCtrls.values) {
      controller.clear();
    }
    for (final controller in _gradeFruitCtrls.values) {
      controller.clear();
    }
  }

  double? _parseDouble(String text) => double.tryParse(text.trim());

  int? _parseInt(String text) => int.tryParse(text.trim());

  double? _farmerWeight(CollectorProduct product) {
    final match = RegExp(r'\d+([.,]\d+)?').firstMatch(product.weightRange);
    if (match == null) return null;
    return double.tryParse(match.group(0)!.replaceAll(',', '.'));
  }

  // [FE - State Management] Builder ini mengubah input Grade A/B/C menjadi
  // struktur data verifikasi yang bisa disimpan ke mock repository.
  List<BatchGradeBreakdown> _buildGradeBreakdown() {
    return _gradeKeys.map((grade) {
      return BatchGradeBreakdown(
        grade: grade,
        weightKg: _parseDouble(_gradeWeightCtrls[grade]!.text) ?? 0,
        fruitCount: _parseInt(_gradeFruitCtrls[grade]!.text) ?? 0,
      );
    }).toList();
  }

  // [FE - Event Handler] _handleSubmit memvalidasi input lalu membuat event
  // verifikasi batch (BATCH_VERIFIED) — pada fase FE-only, menampilkan
  // notifikasi sukses; integrasi API adalah future work.
  Future<void> _handleSubmit() async {
    FocusScope.of(context).unfocus();

    // Validasi field wajib
    if (_selectedProduct == null) {
      _notif.show(
        context,
        'Pilih batch panen yang akan diverifikasi terlebih dahulu.',
        isError: true,
      );
      return;
    }

    final selectedProduct = _selectedProduct!;
    if (_selectedWarehouseId == null || _selectedWarehouseId!.isEmpty) {
      _notif.show(
        context,
        'Pilih gudang penyimpanan untuk batch diterima.',
        isError: true,
      );
      return;
    }
    if (_verificationPhotoPath == null || _verificationPhotoPath!.isEmpty) {
      _notif.show(
        context,
        'Foto verifikasi fisik wajib ditambahkan.',
        isError: true,
      );
      return;
    }

    final quantityText = _quantityCtrl.text.trim();
    if (quantityText.isEmpty) {
      _notif.show(context, 'Berat diterima wajib diisi.', isError: true);
      return;
    }

    final quantity = double.tryParse(quantityText);
    if (quantity == null || quantity <= 0) {
      _notif.show(
        context,
        'Berat diterima harus berupa angka lebih dari nol.',
        isError: true,
      );
      return;
    }

    final fruitCountText = _fruitCountCtrl.text.trim();
    if (fruitCountText.isEmpty) {
      _notif.show(context, 'Jumlah diterima wajib diisi.', isError: true);
      return;
    }

    final receivedFruitCount = int.tryParse(fruitCountText);
    if (receivedFruitCount == null || receivedFruitCount <= 0) {
      _notif.show(
        context,
        'Jumlah diterima harus berupa angka bulat lebih dari nol.',
        isError: true,
      );
      return;
    }

    final farmerWeight = _farmerWeight(selectedProduct);
    if (farmerWeight != null && quantity > farmerWeight) {
      _notif.show(
        context,
        'Berat diterima tidak boleh melebihi berat panen petani.',
        isError: true,
      );
      return;
    }

    final farmerFruitCount = selectedProduct.fruitCount;
    if (farmerFruitCount != null && receivedFruitCount > farmerFruitCount) {
      _notif.show(
        context,
        'Jumlah diterima tidak boleh melebihi jumlah buah petani.',
        isError: true,
      );
      return;
    }

    // [ERROR - Exception Handling] Validasi mass balance ini memastikan total
    // hasil sortir Grade A/B/C sama dengan stok fisik yang diterima pengepul.
    final gradeBreakdown = _buildGradeBreakdown();
    final totalGradeWeight = gradeBreakdown.fold<double>(
      0,
      (sum, item) => sum + item.weightKg,
    );
    final totalGradeFruit = gradeBreakdown.fold<int>(
      0,
      (sum, item) => sum + item.fruitCount,
    );
    final hasInvalidGrade = gradeBreakdown.any((item) {
      final hasWeight = item.weightKg > 0;
      final hasFruit = item.fruitCount > 0;
      return hasWeight != hasFruit;
    });

    if (gradeBreakdown.where((item) => item.hasValue).isEmpty) {
      _notif.show(context, 'Isi minimal satu komposisi grade.', isError: true);
      return;
    }

    if (hasInvalidGrade) {
      _notif.show(
        context,
        'Setiap grade yang diisi wajib memiliki kg dan butir.',
        isError: true,
      );
      return;
    }

    if ((totalGradeWeight - quantity).abs() > 0.01) {
      _notif.show(
        context,
        'Total kg Grade A/B/C harus sama dengan berat diterima.',
        isError: true,
      );
      return;
    }

    if (totalGradeFruit != receivedFruitCount) {
      _notif.show(
        context,
        'Total butir Grade A/B/C harus sama dengan jumlah diterima.',
        isError: true,
      );
      return;
    }

    setState(() => _isSubmitting = true);

    // Simulasi delay submit — ganti dengan API call POST /trace-events/verify-batch
    await Future.delayed(const Duration(milliseconds: 800));

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    final ok = _repo.verifyFreshBatch(
      code: selectedProduct.code,
      receivedQuantity: quantity,
      receivedFruitCount: receivedFruitCount,
      gradeBreakdown: gradeBreakdown,
      warehouseId: _selectedWarehouseId,
      verificationPhotoPath: _verificationPhotoPath,
      qualityNotes: _notesCtrl.text.trim(),
      transactionId: widget.initialTransactionId,
    );

    if (!ok) {
      _notif.show(
        context,
        'Batch sudah tidak tersedia untuk diverifikasi.',
        isError: true,
      );
      return;
    }

    setState(() {
      _selectedProduct = null;
      _quantityCtrl.clear();
      _fruitCountCtrl.clear();
      _clearGradeInputs();
      _verificationPhotoPath = null;
      _notesCtrl.clear();
    });

    _notif.show(
      context,
      'Transaksi verifikasi untuk ${selectedProduct.name} berhasil disimpan.',
    );

    // [FE - Event Handler] Kirim sinyal sukses ke caller; layar scan akan
    // membuka Stok Saya agar batch terverifikasi terlihat sebagai stok.
    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;
    Navigator.pop(context, true);
  }

  // [FE - Event Handler] _handleReject memvalidasi pilihan batch, meminta
  // alasan penolakan, lalu mengirim transisi status ke repository pengepul.
  Future<void> _handleReject() async {
    FocusScope.of(context).unfocus();

    final selectedProduct = _selectedProduct;
    if (selectedProduct == null) {
      _notif.show(
        context,
        'Pilih batch panen yang akan ditolak terlebih dahulu.',
        isError: true,
      );
      return;
    }

    final reason = await _showRejectReasonDialog(selectedProduct);
    if (reason == null || reason.trim().isEmpty) return;
    if (!mounted) return;

    setState(() => _isRejecting = true);

    // Simulasi delay submit; ganti dengan API call POST /trace-events/reject-batch.
    await Future.delayed(const Duration(milliseconds: 600));

    if (!mounted) return;

    final ok = _repo.rejectFreshBatch(
      code: selectedProduct.code,
      reason: reason,
      transactionId: widget.initialTransactionId,
    );

    setState(() => _isRejecting = false);

    if (!ok) {
      _notif.show(
        context,
        'Batch sudah tidak tersedia untuk ditolak.',
        isError: true,
      );
      return;
    }

    setState(() {
      _selectedProduct = null;
      _quantityCtrl.clear();
      _fruitCountCtrl.clear();
      _clearGradeInputs();
      _verificationPhotoPath = null;
      _notesCtrl.clear();
    });

    _notif.show(context, 'Batch ${selectedProduct.name} berhasil ditolak.');

    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;
    Navigator.pop(context);
  }

  // [FE - Component Rendering] Dialog ini menjadi pintu input alasan reject
  // agar penolakan memiliki konteks audit yang bisa dibaca petani.
  Future<String?> _showRejectReasonDialog(CollectorProduct product) async {
    final controller = TextEditingController();
    String? errorText;

    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.white,
              title: const Text(
                'Tolak Batch',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.black,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.code,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: controller,
                    maxLines: 4,
                    textInputAction: TextInputAction.done,
                    decoration: InputDecoration(
                      hintText: 'Contoh: buah retak, busuk, atau tidak matang',
                      errorText: errorText,
                      filled: true,
                      fillColor: AppColors.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFFD64545),
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Batal'),
                ),
                TextButton(
                  onPressed: () {
                    final value = controller.text.trim();
                    if (value.isEmpty) {
                      setDialogState(() {
                        errorText = 'Alasan penolakan wajib diisi.';
                      });
                      return;
                    }
                    Navigator.pop(dialogContext, value);
                  },
                  child: const Text(
                    'Tolak',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: Color(0xFFD64545),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    controller.dispose();
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final products = _repo.products
        .where((p) => p.category == ProductCategory.durianSegar)
        .toList();
    final isBatchLockedFromScan =
        widget.initialBatchCode?.trim().isNotEmpty == true &&
        _selectedProduct != null;

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            const AppTopBar(title: 'Verifikasi Batch'),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Pilih Produk ─────────────────────────────────────
                    // [FE - Component Rendering] Pengepul memilih identitas
                    // batch DRN, bukan memilih atau mengubah varietas durian.
                    const _SectionLabel(label: 'Pilih Batch Panen'),
                    const SizedBox(height: 8),
                    if (isBatchLockedFromScan)
                      _ScannedBatchField(
                        batch: _selectedProduct!,
                        transactionId: widget.initialTransactionId,
                      )
                    else
                      _BatchDropdown(
                        batches: products,
                        selected: _selectedProduct,
                        onChanged: (p) => setState(() {
                          _selectProduct(p);
                        }),
                      ),

                    // ── Info Produk (read-only) ──────────────────────────
                    if (_selectedProduct != null) ...[
                      const SizedBox(height: 20),
                      _ProductInfo(product: _selectedProduct!),
                    ],

                    const SizedBox(height: 24),

                    // ── Data Verifikasi Pengepul ─────────────────────────
                    const _SectionLabel(label: 'Data Verifikasi'),
                    const SizedBox(height: 8),
                    _WarehouseDropdown(
                      warehouses: _repo.warehouses,
                      selectedId: _selectedWarehouseId,
                      onChanged: (id) {
                        setState(() => _selectedWarehouseId = id);
                      },
                    ),
                    const SizedBox(height: 16),
                    _VerificationPhotoField(
                      photoPath: _verificationPhotoPath,
                      onPick: _pickVerificationPhoto,
                      onRemove: _removeVerificationPhoto,
                    ),
                    const SizedBox(height: 16),

                    // [FE - Component Rendering] Field ini menyimpan berat
                    // fisik yang benar-benar diterima setelah timbang ulang.
                    const _FieldLabel(label: 'Berat Diterima (kg)'),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _quantityCtrl,
                      focusNode: _quantityFocus,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      textInputAction: TextInputAction.next,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'^\d+\.?\d{0,2}'),
                        ),
                      ],
                      onSubmitted: (_) =>
                          FocusScope.of(context).requestFocus(_fruitCountFocus),
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.black,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Masukkan berat diterima',
                        hintStyle: const TextStyle(
                          fontSize: 14,
                          color: AppColors.placeholder,
                        ),
                        filled: true,
                        fillColor: AppColors.surface,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFFE5E7EB),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFFE5E7EB),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppColors.primaryContainer,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // [FE - Component Rendering] Field ini menjadi pasangan
                    // berat untuk rekonsiliasi jumlah buah yang diterima.
                    const _FieldLabel(label: 'Jumlah Diterima (butir)'),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _fruitCountCtrl,
                      focusNode: _fruitCountFocus,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.next,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      onSubmitted: (_) =>
                          FocusScope.of(context).requestFocus(_notesFocus),
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.black,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Masukkan jumlah buah diterima',
                        hintStyle: const TextStyle(
                          fontSize: 14,
                          color: AppColors.placeholder,
                        ),
                        filled: true,
                        fillColor: AppColors.surface,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFFE5E7EB),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFFE5E7EB),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppColors.primaryContainer,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    const _FieldLabel(label: 'Komposisi Grade Riil'),
                    const SizedBox(height: 6),
                    _GradeCompositionInput(
                      grades: _gradeKeys,
                      weightControllers: _gradeWeightCtrls,
                      fruitControllers: _gradeFruitCtrls,
                    ),
                    const SizedBox(height: 16),

                    // Catatan Kualitas (opsional)
                    const _FieldLabel(label: 'Catatan Kualitas (opsional)'),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _notesCtrl,
                      focusNode: _notesFocus,
                      maxLines: 3,
                      textInputAction: TextInputAction.done,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.black,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Tambahkan catatan kualitas produk...',
                        hintStyle: const TextStyle(
                          fontSize: 14,
                          color: AppColors.placeholder,
                        ),
                        filled: true,
                        fillColor: AppColors.surface,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFFE5E7EB),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFFE5E7EB),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppColors.primaryContainer,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // ── Tombol KIRIM ─────────────────────────────────────
                    PrimaryPillButton(
                      label: 'KONFIRMASI & TERIMA BATCH',
                      onPressed: _isRejecting ? null : _handleSubmit,
                      isLoading: _isSubmitting,
                    ),
                    if (_selectedProduct != null) ...[
                      const SizedBox(height: 12),
                      // [FE - Component Rendering] Tombol reject menjadi aksi
                      // alternatif pengepul selain verifikasi batch.
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _isSubmitting || _isRejecting
                              ? null
                              : _handleReject,
                          icon: _isRejecting
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Color(0xFFD64545),
                                    ),
                                  ),
                                )
                              : const Icon(Icons.close_rounded),
                          label: Text(
                            _isRejecting ? 'MENOLAK...' : 'TOLAK BATCH',
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFD64545),
                            side: const BorderSide(color: Color(0xFFD64545)),
                            shape: const StadiumBorder(),
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            textStyle: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
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

// ─────────────────────────────────────────────────────────────────────────────
// Sub-widgets
// ─────────────────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: AppColors.black,
      ),
    );
  }
}

class _VerificationPhotoField extends StatelessWidget {
  const _VerificationPhotoField({
    required this.photoPath,
    required this.onPick,
    required this.onRemove,
  });

  final String? photoPath;
  final VoidCallback onPick;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final hasPhoto = photoPath != null && photoPath!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _FieldLabel(label: 'Foto Verifikasi Fisik'),
        const SizedBox(height: 6),
        if (hasPhoto)
          Stack(
            children: [
              BatchPhoto(
                path: photoPath,
                width: double.infinity,
                height: 160,
                borderRadius: BorderRadius.circular(12),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Row(
                  children: [
                    _PhotoActionButton(
                      icon: Icons.edit_outlined,
                      onTap: onPick,
                    ),
                    const SizedBox(width: 8),
                    _PhotoActionButton(
                      icon: Icons.close_rounded,
                      onTap: onRemove,
                      color: const Color(0xFFD64545),
                    ),
                  ],
                ),
              ),
            ],
          )
        else
          InkWell(
            onTap: onPick,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: double.infinity,
              height: 118,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_a_photo_outlined,
                    size: 30,
                    color: AppColors.placeholder,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Tambahkan foto kondisi aktual',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.placeholder,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'Wajib untuk konfirmasi penerimaan',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.placeholder,
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

class _WarehouseDropdown extends StatelessWidget {
  const _WarehouseDropdown({
    required this.warehouses,
    required this.selectedId,
    required this.onChanged,
  });

  final List<CollectorWarehouse> warehouses;
  final String? selectedId;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _FieldLabel(label: 'Gudang Penyimpanan'),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          initialValue: warehouses.any((warehouse) => warehouse.id == selectedId)
              ? selectedId
              : null,
          items: warehouses.map((warehouse) {
            return DropdownMenuItem<String>(
              value: warehouse.id,
              child: Text(
                warehouse.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: 'Pilih gudang penerimaan',
            filled: true,
            fillColor: AppColors.surface,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppColors.primaryContainer,
                width: 2,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PhotoActionButton extends StatelessWidget {
  const _PhotoActionButton({
    required this.icon,
    required this.onTap,
    this.color,
  });

  final IconData icon;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white.withValues(alpha: 0.94),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 34,
          height: 34,
          child: Icon(icon, size: 18, color: color ?? AppColors.subtitle),
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.subtitle,
      ),
    );
  }
}

// [FE - Component Rendering] _ProductDropdown menampilkan daftar produk durian
// segar yang dapat dibeli/diverifikasi pengepul — simulasi hasil scan QR.
// [FE - Component Rendering] Dropdown ini menampilkan antrean batch DRN
// petani yang masih tersedia untuk verifikasi manual oleh pengepul.
class _BatchDropdown extends StatelessWidget {
  const _BatchDropdown({
    required this.batches,
    required this.selected,
    required this.onChanged,
  });

  final List<CollectorProduct> batches;
  final CollectorProduct? selected;
  final ValueChanged<CollectorProduct?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<CollectorProduct>(
          value: selected,
          hint: const Text(
            'Pilih kode batch petani',
            style: TextStyle(fontSize: 14, color: AppColors.placeholder),
          ),
          isExpanded: true,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: AppColors.placeholder,
          ),
          items: batches.map((batch) {
            return DropdownMenuItem(
              value: batch,
              child: Text(
                '${batch.code} • ${batch.name}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 14, color: AppColors.black),
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

// [FE - Component Rendering] Hasil scan QR dikunci sebagai batch read-only
// agar pengepul tidak berpindah ke DRN lain setelah memindai barang fisik.
class _ScannedBatchField extends StatelessWidget {
  const _ScannedBatchField({required this.batch, this.transactionId});

  final CollectorProduct batch;
  final String? transactionId;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.qr_code_2_rounded,
            size: 21,
            color: AppColors.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  batch.code,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: AppColors.black,
                  ),
                ),
                if (transactionId?.trim().isNotEmpty == true) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Transaksi T1: ${transactionId!.trim()}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ],
                const SizedBox(height: 2),
                Text(
                  batch.name,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.subtitle,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// [FE - Component Rendering] _ProductInfo menampilkan data produk dari petani
// secara read-only (nama, kode, lokasi, tanggal panen, pemilik) — pengepul
// tidak boleh mengubah data ini sesuai Role Permission Matrix.
class _ProductInfo extends StatelessWidget {
  const _ProductInfo({required this.product});

  final CollectorProduct product;

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

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            product.name,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.black,
            ),
          ),
          const SizedBox(height: 8),
          _InfoRow(label: 'Kode', value: product.code),
          _InfoRow(label: 'Rentang Berat', value: product.weightRange),
          if (product.fruitCount != null)
            _InfoRow(
              label: 'Jumlah Buah',
              value: '${product.fruitCount} butir',
            ),
          _InfoRow(label: 'Lokasi', value: product.location),
          _InfoRow(
            label: 'Tanggal Panen',
            value: _formatDate(product.harvestDate),
          ),
          _InfoRow(label: 'Pemilik Pohon', value: product.treeOwner),
          // [FE - Component Rendering] Metadata opsional ini berasal dari
          // batch petani dan membantu pengepul memverifikasi kualitas awal.
          if (product.grade != null && product.grade!.isNotEmpty)
            _InfoRow(
              label: 'Grade Awal Petani',
              value: 'Grade ${product.grade}',
            ),
          if (product.maturityLevel != null &&
              product.maturityLevel!.isNotEmpty)
            _InfoRow(label: 'Kematangan', value: product.maturityLevel!),
          if (product.shelfLifeEstimate != null &&
              product.shelfLifeEstimate!.isNotEmpty)
            _InfoRow(label: 'Masa Simpan', value: product.shelfLifeEstimate!),
          if (product.storageSuggestion != null &&
              product.storageSuggestion!.isNotEmpty)
            _InfoRow(label: 'Saran Simpan', value: product.storageSuggestion!),
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
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.placeholder,
              ),
            ),
          ),
          const Text(
            ': ',
            style: TextStyle(fontSize: 12, color: AppColors.placeholder),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// [FE - Component Rendering] Komponen ini menangkap hasil sortir fisik
// pengepul per grade sebagai dasar stok dan mass balance.
class _GradeCompositionInput extends StatelessWidget {
  const _GradeCompositionInput({
    required this.grades,
    required this.weightControllers,
    required this.fruitControllers,
  });

  final List<String> grades;
  final Map<String, TextEditingController> weightControllers;
  final Map<String, TextEditingController> fruitControllers;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: grades.map((grade) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 62,
                  child: Text(
                    'Grade $grade',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppColors.black,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _GradeNumberField(
                    controller: weightControllers[grade]!,
                    hintText: 'kg',
                    decimal: true,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _GradeNumberField(
                    controller: fruitControllers[grade]!,
                    hintText: 'butir',
                    decimal: false,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

// [FE - Component Rendering] Field angka kecil ini dipakai ulang oleh setiap
// baris grade agar format input kg dan butir konsisten.
class _GradeNumberField extends StatelessWidget {
  const _GradeNumberField({
    required this.controller,
    required this.hintText,
    required this.decimal,
  });

  final TextEditingController controller;
  final String hintText;
  final bool decimal;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.numberWithOptions(decimal: decimal),
      inputFormatters: [
        if (decimal)
          FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))
        else
          FilteringTextInputFormatter.digitsOnly,
      ],
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: AppColors.black,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(fontSize: 12, color: AppColors.placeholder),
        filled: true,
        fillColor: AppColors.white,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 11,
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
          borderSide: const BorderSide(
            color: AppColors.primaryContainer,
            width: 2,
          ),
        ),
      ),
    );
  }
}
