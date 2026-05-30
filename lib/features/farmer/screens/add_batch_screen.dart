import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_top_bar.dart';
import '../../../shared/widgets/labeled_dropdown_field.dart';
import '../../../shared/widgets/primary_pill_button.dart';
import '../../../shared/widgets/top_notification_banner.dart';
import '../data/farmer_repository.dart';
import '../farmer_routes.dart';
import '../models/farm.dart';
import '../models/master_data.dart';
import 'batch_qr_screen.dart';
import 'create_farm_screen.dart';

// [FE - Component Rendering] Screen ini adalah form pencatatan batch baru —
// menggabungkan validasi, state loading, dan navigasi ke QR setelah sukses.
/// Layar form untuk mencatat batch panen baru.
///
/// Menampilkan lima dropdown (kebun, varietas, pupuk, metode panen, grade),
/// date picker tanggal panen, dan input numerik jumlah, diakhiri tombol KIRIM.
///
/// Alur submit (Req 2.4–2.9):
/// 1. Validasi via [FarmerValidator.validateAddBatch].
/// 2. Bila gagal → tampilkan [TopNotification] error.
/// 3. Bila valid → set loading, panggil [FarmerRepository.addBatch],
///    tampilkan banner sukses, lalu buka [BatchQrScreen] dengan
///    `openedAfterCreate: true`.
///
/// Empty-state kebun (Req 2.3): bila [FarmerRepository.farms] kosong,
/// dropdown lokasi menampilkan ajakan + tombol menuju [CreateFarmScreen].
class AddBatchScreen extends StatefulWidget {
  const AddBatchScreen({super.key});

  @override
  State<AddBatchScreen> createState() => _AddBatchScreenState();
}

class _AddBatchScreenState extends State<AddBatchScreen> {
  final _repo = FarmerRepository.instance;
  final _notification = TopNotification();
  final _quantityController = TextEditingController();

  Farm? _selectedFarm;
  String? _variety;
  String? _fertilizer;
  String? _harvestMethod;
  String? _grade;
  DateTime? _harvestDate;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // Dengarkan perubahan repo agar dropdown kebun ter-refresh bila
    // pengguna baru saja membuat kebun dari CreateFarmScreen.
    _repo.addListener(_onRepoChanged);
  }

  @override
  void dispose() {
    _repo.removeListener(_onRepoChanged);
    _notification.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  void _onRepoChanged() {
    if (mounted) setState(() {});
  }

  // ── Date picker ────────────────────────────────────────────────────────────

  Future<void> _pickDate() async {
    final today = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _harvestDate ?? today,
      firstDate: DateTime(2000),
      lastDate: today,
      locale: const Locale('id', 'ID'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primaryContainer,
              onPrimary: AppColors.white,
              onSurface: AppColors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _harvestDate = picked);
    }
  }

  // ── Format tanggal ─────────────────────────────────────────────────────────

  String _formatDate(DateTime d) {
    const months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  // ── Submit ─────────────────────────────────────────────────────────────────

  // [FE - Event Handler] _submit menangani aksi KIRIM: validasi → error banner
  // atau loading + addBatch + sukses banner + navigasi ke QR screen.
  Future<void> _submit() async {
    // Validasi semua field
    final error = FarmerValidator.validateAddBatch(
      farm: _selectedFarm,
      variety: _variety,
      grade: _grade,
      harvestDate: _harvestDate,
      quantityText: _quantityController.text,
    );

    if (error != null) {
      _notification.show(context, error, isError: true);
      return;
    }

    // Semua valid — mulai proses simpan
    setState(() => _isSubmitting = true);

    // Simulasi async (mock store sebenarnya sinkron, tapi kita tetap
    // memberi jeda singkat agar indikator loading terlihat — Req 2.9).
    await Future.delayed(const Duration(milliseconds: 600));

    if (!mounted) return;

    final batch = _repo.addBatch(
      farm: _selectedFarm!,
      variety: _variety!,
      fertilizer: _fertilizer ?? '',
      harvestMethod: _harvestMethod ?? '',
      grade: _grade!,
      quantity: double.parse(_quantityController.text.trim()),
      harvestDate: _harvestDate!,
    );

    setState(() => _isSubmitting = false);

    // Banner sukses (Req 2.8)
    _notification.show(
      context,
      'Batch panen berhasil dicatat dengan kode ${batch.code}.',
      isError: false,
    );

    // Buka QR screen — back dari sini kembali ke Beranda (Req 4.6)
    if (mounted) {
      await FarmerRoutes.push(
        context,
        BatchQrScreen(batchCode: batch.code, openedAfterCreate: true),
      );
    }
  }

  // ── Navigasi ke buat kebun ─────────────────────────────────────────────────

  Future<void> _goToCreateFarm() async {
    await FarmerRoutes.push(context, const CreateFarmScreen());
    // Setelah kembali, _onRepoChanged sudah dipanggil via listener
    // sehingga dropdown kebun otomatis ter-refresh.
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final farms = _repo.farms;

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar dengan tombol back (Req 2.1)
            const AppTopBar(title: 'Tambah Batch Panen'),

            // Form scrollable
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── 1. Lokasi Kebun (Req 2.2, 2.3, 2.10) ──────────────
                    LabeledDropdownField<Farm>(
                      label: 'Pilih Lokasi Kebun Durian',
                      hint: 'Pilih kebun',
                      value: _selectedFarm,
                      items: farms,
                      itemLabel: (f) => f.name,
                      onChanged: (f) => setState(() => _selectedFarm = f),
                      emptyState: _FarmEmptyState(
                        onCreateFarm: _goToCreateFarm,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── 2. Varietas (Req 2.2) ──────────────────────────────
                    LabeledDropdownField<String>(
                      label: 'Pilih Varietas Durian',
                      hint: 'Pilih varietas',
                      value: _variety,
                      items: FarmerMasterData.varieties,
                      itemLabel: (v) => v,
                      onChanged: (v) => setState(() => _variety = v),
                    ),
                    const SizedBox(height: 16),

                    // ── 3. Pupuk (Req 2.2) ─────────────────────────────────
                    LabeledDropdownField<String>(
                      label: 'Pilih Pupuk yang Digunakan',
                      hint: 'Pilih pupuk',
                      value: _fertilizer,
                      items: FarmerMasterData.fertilizers,
                      itemLabel: (f) => f,
                      onChanged: (f) => setState(() => _fertilizer = f),
                    ),
                    const SizedBox(height: 16),

                    // ── 4. Metode Panen (Req 2.2) ──────────────────────────
                    LabeledDropdownField<String>(
                      label: 'Pilih Metode Panen',
                      hint: 'Pilih metode panen',
                      value: _harvestMethod,
                      items: FarmerMasterData.harvestMethods,
                      itemLabel: (m) => m,
                      onChanged: (m) => setState(() => _harvestMethod = m),
                    ),
                    const SizedBox(height: 16),

                    // ── 5. Grade (Req 2.2) ─────────────────────────────────
                    LabeledDropdownField<String>(
                      label: 'Pilih Grade/Mutu Durian',
                      hint: 'Pilih grade',
                      value: _grade,
                      items: FarmerMasterData.grades,
                      itemLabel: (g) => 'Grade $g',
                      onChanged: (g) => setState(() => _grade = g),
                    ),
                    const SizedBox(height: 16),

                    // ── 6. Tanggal Panen (Req 2.2) ─────────────────────────
                    _DatePickerField(
                      label: 'Pilih Tanggal Panen',
                      hint: 'Pilih tanggal',
                      value: _harvestDate != null
                          ? _formatDate(_harvestDate!)
                          : null,
                      onTap: _pickDate,
                    ),
                    const SizedBox(height: 16),

                    // ── 7. Jumlah Panen (Req 2.2) ──────────────────────────
                    _QuantityField(controller: _quantityController),
                    const SizedBox(height: 32),

                    // ── Tombol KIRIM (Req 2.9) ─────────────────────────────
                    PrimaryPillButton(
                      label: 'KIRIM',
                      onPressed: _isSubmitting ? null : _submit,
                      isLoading: _isSubmitting,
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
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty state dropdown kebun (Req 2.3)
// ─────────────────────────────────────────────────────────────────────────────

/// Ditampilkan di dalam [LabeledDropdownField] saat petani belum punya kebun.
///
/// Menampilkan pesan ajakan dan tombol untuk membuat kebun baru.
class _FarmEmptyState extends StatelessWidget {
  const _FarmEmptyState({required this.onCreateFarm});

  final VoidCallback onCreateFarm;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline_rounded,
            size: 18,
            color: AppColors.placeholder,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Anda belum memiliki kebun. Buat kebun terlebih dahulu.',
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.subtitle,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: onCreateFarm,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Buat Kebun',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Date picker field
// ─────────────────────────────────────────────────────────────────────────────

/// Field tanggal bergaya dropdown (tap untuk membuka date picker).
class _DatePickerField extends StatelessWidget {
  const _DatePickerField({
    required this.label,
    required this.hint,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String hint;
  final String? value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.subtitle,
          ),
        ),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value ?? hint,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight:
                          value != null ? FontWeight.w500 : FontWeight.normal,
                      color: value != null
                          ? AppColors.black
                          : AppColors.placeholder,
                    ),
                  ),
                ),
                const Icon(
                  Icons.calendar_today_outlined,
                  size: 18,
                  color: AppColors.placeholder,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Quantity input field
// ─────────────────────────────────────────────────────────────────────────────

/// Input numerik untuk jumlah panen (dalam kg).
class _QuantityField extends StatelessWidget {
  const _QuantityField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Masukan Jumlah (kg)',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.subtitle,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            // Izinkan angka dan satu titik desimal
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
          ],
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.black,
          ),
          decoration: InputDecoration(
            hintText: 'Contoh: 150',
            hintStyle: const TextStyle(
              fontSize: 14,
              color: AppColors.placeholder,
            ),
            suffixText: 'kg',
            suffixStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.subtitle,
            ),
            filled: true,
            fillColor: AppColors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
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
        ),
      ],
    );
  }
}
