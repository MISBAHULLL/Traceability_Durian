import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_top_bar.dart';
import '../../../shared/widgets/primary_pill_button.dart';
import '../../../shared/widgets/top_notification_banner.dart';
import '../data/collector_repository.dart';
import '../models/collector_product.dart';

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
  const AddTransactionScreen({super.key});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _repo = CollectorRepository.instance;
  final _quantityCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _quantityFocus = FocusNode();
  final _notesFocus = FocusNode();
  final _notif = TopNotification();

  CollectorProduct? _selectedProduct;
  String? _verifiedGrade;

  // [FE - State Management] Flag submit/reject ini mengunci aksi paralel
  // agar satu batch tidak diverifikasi dan ditolak bersamaan.
  bool _isSubmitting = false;
  bool _isRejecting = false;

  @override
  void dispose() {
    _notif.dispose();
    _quantityCtrl.dispose();
    _notesCtrl.dispose();
    _quantityFocus.dispose();
    _notesFocus.dispose();
    super.dispose();
  }

  // [FE - Event Handler] _handleSubmit memvalidasi input lalu membuat event
  // verifikasi batch (BATCH_VERIFIED) — pada fase FE-only, menampilkan
  // notifikasi sukses; integrasi API adalah future work.
  Future<void> _handleSubmit() async {
    FocusScope.of(context).unfocus();

    // Validasi field wajib
    if (_selectedProduct == null) {
      _notif.show(context, 'Pilih produk yang akan dibeli terlebih dahulu.',
          isError: true);
      return;
    }

    final quantityText = _quantityCtrl.text.trim();
    if (quantityText.isEmpty) {
      _notif.show(context, 'Jumlah yang diterima wajib diisi.', isError: true);
      return;
    }

    final quantity = double.tryParse(quantityText);
    if (quantity == null || quantity <= 0) {
      _notif.show(
        context,
        'Jumlah yang diterima harus berupa angka lebih dari nol.',
        isError: true,
      );
      return;
    }

    if (_verifiedGrade == null || _verifiedGrade!.isEmpty) {
      _notif.show(context, 'Pilih grade/mutu hasil verifikasi.', isError: true);
      return;
    }

    setState(() => _isSubmitting = true);

    // Simulasi delay submit — ganti dengan API call POST /trace-events/verify-batch
    await Future.delayed(const Duration(milliseconds: 800));

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    final selectedProduct = _selectedProduct!;
    final ok = _repo.verifyFreshBatch(
      code: selectedProduct.code,
      receivedQuantity: quantity,
      verifiedGrade: _verifiedGrade!,
      qualityNotes: _notesCtrl.text.trim(),
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
      _verifiedGrade = null;
      _quantityCtrl.clear();
      _notesCtrl.clear();
    });

    _notif.show(
      context,
      'Transaksi verifikasi untuk ${selectedProduct.name} berhasil disimpan.',
    );

    // Kembali ke beranda setelah sukses
    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;
    Navigator.pop(context);
  }

  // [FE - Event Handler] _handleReject memvalidasi pilihan batch, meminta
  // alasan penolakan, lalu mengirim transisi status ke repository pengepul.
  Future<void> _handleReject() async {
    FocusScope.of(context).unfocus();

    final selectedProduct = _selectedProduct;
    if (selectedProduct == null) {
      _notif.show(
        context,
        'Pilih produk yang akan ditolak terlebih dahulu.',
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
      _verifiedGrade = null;
      _quantityCtrl.clear();
      _notesCtrl.clear();
    });

    _notif.show(
      context,
      'Batch ${selectedProduct.name} berhasil ditolak.',
    );

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

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            const AppTopBar(title: 'Tambah Transaksi'),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Pilih Produk ─────────────────────────────────────
                    const _SectionLabel(label: 'Pilih Produk'),
                    const SizedBox(height: 8),
                    _ProductDropdown(
                      products: products,
                      selected: _selectedProduct,
                      onChanged: (p) => setState(() {
                        _selectedProduct = p;
                        // Pre-fill quantity dengan nilai produk
                        if (p != null) {
                          _quantityCtrl.text = p.weightRange.split(' ')[0];
                        }
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

                    // Jumlah Diterima
                    const _FieldLabel(label: 'Jumlah Diterima (kg)'),
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
                          FocusScope.of(context).requestFocus(_notesFocus),
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.black,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Masukkan jumlah yang diterima',
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

                    // Grade Hasil Verifikasi
                    const _FieldLabel(label: 'Grade/Mutu Hasil Verifikasi'),
                    const SizedBox(height: 6),
                    _GradeDropdown(
                      selected: _verifiedGrade,
                      onChanged: (g) => setState(() => _verifiedGrade = g),
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
                      label: 'KIRIM',
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
class _ProductDropdown extends StatelessWidget {
  const _ProductDropdown({
    required this.products,
    required this.selected,
    required this.onChanged,
  });

  final List<CollectorProduct> products;
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
            'Pilih produk durian',
            style: TextStyle(fontSize: 14, color: AppColors.placeholder),
          ),
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded,
              color: AppColors.placeholder),
          items: products.map((p) {
            return DropdownMenuItem(
              value: p,
              child: Text(
                p.name,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.black,
                ),
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
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
            _InfoRow(
              label: 'Kematangan',
              value: product.maturityLevel!,
            ),
          if (product.shelfLifeEstimate != null &&
              product.shelfLifeEstimate!.isNotEmpty)
            _InfoRow(
              label: 'Masa Simpan',
              value: product.shelfLifeEstimate!,
            ),
          if (product.storageSuggestion != null &&
              product.storageSuggestion!.isNotEmpty)
            _InfoRow(
              label: 'Saran Simpan',
              value: product.storageSuggestion!,
            ),
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

// [FE - Component Rendering] _GradeDropdown menampilkan dropdown grade hasil
// verifikasi pengepul (A / B / C).
class _GradeDropdown extends StatelessWidget {
  const _GradeDropdown({
    required this.selected,
    required this.onChanged,
  });

  final String? selected;
  final ValueChanged<String?> onChanged;

  static const List<String> _grades = ['A', 'B', 'C'];

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
        child: DropdownButton<String>(
          value: selected,
          hint: const Text(
            'Pilih grade hasil verifikasi',
            style: TextStyle(fontSize: 14, color: AppColors.placeholder),
          ),
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded,
              color: AppColors.placeholder),
          items: _grades.map((g) {
            return DropdownMenuItem(
              value: g,
              child: Text(
                'Grade $g',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.black,
                ),
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
