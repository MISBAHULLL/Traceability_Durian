import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_top_bar.dart';
import '../../../shared/widgets/batch_photo.dart';
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
// Mendukung dua mode: tambah (default) dan ubah (bila [editBatchCode] diisi).
/// Layar form untuk mencatat batch panen baru, atau mengubah batch DRAFT.
///
/// Menampilkan lima dropdown (kebun, varietas, pupuk, metode panen, grade),
/// date picker tanggal panen, dan input numerik jumlah, diakhiri tombol KIRIM.
///
/// Mode TAMBAH (default): membuat batch baru → buka QR.
/// Mode UBAH (bila [editBatchCode] diisi): field di-prefill dari batch yang
/// ada; simpan memanggil [FarmerRepository.updateBatch] lalu pop ke Detail.
///
/// Alur submit (Req 2.4–2.9):
/// 1. Validasi via [FarmerValidator.validateAddBatch].
/// 2. Bila gagal → tampilkan [TopNotification] error.
/// 3. Bila valid → set loading, simpan, tampilkan banner sukses, lalu navigasi.
///
/// Empty-state kebun (Req 2.3): bila [FarmerRepository.farms] kosong,
/// dropdown lokasi menampilkan ajakan + tombol menuju [CreateFarmScreen].
class AddBatchScreen extends StatefulWidget {
  const AddBatchScreen({super.key, this.editBatchCode});

  /// Bila diisi, layar berjalan dalam mode UBAH untuk batch dengan kode ini.
  /// Bila `null`, layar berjalan dalam mode TAMBAH (batch baru).
  final String? editBatchCode;

  /// `true` bila layar sedang dalam mode ubah.
  bool get isEditMode => editBatchCode != null;

  @override
  State<AddBatchScreen> createState() => _AddBatchScreenState();
}

class _AddBatchScreenState extends State<AddBatchScreen> {
  final _repo = FarmerRepository.instance;
  final _notification = TopNotification();
  final _quantityController = TextEditingController();
  // [FE - State Management] Controller ini menyimpan input opsional yang
  // menjadi metadata traceability batch sebelum dikirim ke repository.
  final _storageSuggestionController = TextEditingController();
  final _notesController = TextEditingController();

  Farm? _selectedFarm;
  String? _variety;
  String? _fertilizer;
  String? _harvestMethod;
  String? _grade;
  String? _unit = FarmerMasterData.units.first;
  // [FE - State Management] State ini menyimpan pilihan kualitas durian yang
  // dipakai UI form dan diteruskan ke model HarvestBatch.
  String? _maturityLevel;
  String? _shelfLifeEstimate;
  DateTime? _harvestDate;
  String? _photoPath;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // Prefill field bila dalam mode ubah (sebelum memasang listener).
    if (widget.isEditMode) {
      _prefillFromExistingBatch();
    }
    // Dengarkan perubahan repo agar dropdown kebun ter-refresh bila
    // pengguna baru saja membuat kebun dari CreateFarmScreen.
    _repo.addListener(_onRepoChanged);
  }

  // [FE - State Management] Mengisi field form dari batch yang akan diubah,
  // mencocokkan Farm berdasarkan id agar nilai dropdown valid.
  void _prefillFromExistingBatch() {
    final batch = _repo.findBatch(widget.editBatchCode!);
    if (batch == null) return;

    // Cari instance Farm dari repo agar identik dengan item dropdown.
    Farm? farm;
    for (final f in _repo.farms) {
      if (f.id == batch.farmId) {
        farm = f;
        break;
      }
    }

    _selectedFarm = farm;
    _variety = batch.variety;
    _fertilizer = (batch.fertilizer?.isEmpty ?? true) ? null : batch.fertilizer;
    _harvestMethod =
        (batch.harvestMethod?.isEmpty ?? true) ? null : batch.harvestMethod;
    _grade = batch.grade;
    _unit = batch.unit;
    _maturityLevel =
        (batch.maturityLevel?.isEmpty ?? true) ? null : batch.maturityLevel;
    _shelfLifeEstimate = (batch.shelfLifeEstimate?.isEmpty ?? true)
        ? null
        : batch.shelfLifeEstimate;
    _harvestDate = batch.harvestDate;
    _quantityController.text = batch.quantity.toStringAsFixed(0);
    _storageSuggestionController.text = batch.storageSuggestion ?? '';
    _notesController.text = batch.notes ?? '';
    _photoPath = batch.photoPath;
  }

  @override
  void dispose() {
    _repo.removeListener(_onRepoChanged);
    _notification.dispose();
    _quantityController.dispose();
    _storageSuggestionController.dispose();
    _notesController.dispose();
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

  // ── Foto durian ──────────────────────────────────────────────────────────

  // [FE - Event Handler] _pickPhoto membuka pilihan sumber (kamera/galeri)
  // lalu menyimpan path foto terpilih ke state untuk dipakai saat simpan.
  Future<void> _pickPhoto() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetCtx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined,
                    color: AppColors.primary),
                title: const Text('Ambil dari Kamera'),
                onTap: () => Navigator.pop(sheetCtx, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined,
                    color: AppColors.primary),
                title: const Text('Pilih dari Galeri'),
                onTap: () => Navigator.pop(sheetCtx, ImageSource.gallery),
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
      final XFile? file = await picker.pickImage(
        source: source,
        maxWidth: 1280,
        imageQuality: 80,
      );
      if (file != null && mounted) {
        setState(() => _photoPath = file.path);
      }
    } catch (e) {
      if (mounted) {
        _notification.show(
          context,
          'Gagal mengambil foto. Coba lagi.',
          isError: true,
        );
      }
    }
  }

  void _removePhoto() {
    setState(() => _photoPath = null);
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

  // [FE - Event Handler] _submit menangani aksi simpan. Pada mode tambah:
  // validasi → addBatch → buka QR. Pada mode ubah: validasi → updateBatch
  // (guard DRAFT di repository) → pop kembali ke Detail.
  Future<void> _submit() async {
    // Validasi semua field
    final error = FarmerValidator.validateAddBatch(
      farm: _selectedFarm,
      variety: _variety,
      grade: _grade,
      unit: _unit,
      maturityLevel: _maturityLevel,
      shelfLifeEstimate: _shelfLifeEstimate,
      harvestMethod: _harvestMethod,
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

    if (widget.isEditMode) {
      await _saveEdit();
    } else {
      await _saveNew();
    }
  }

  // [FE - Event Handler] Menyimpan batch baru lalu membuka layar QR.
  Future<void> _saveNew() async {
    final batch = _repo.addBatch(
      farm: _selectedFarm!,
      variety: _variety!,
      fertilizer: _fertilizer ?? '',
      harvestMethod: _harvestMethod ?? '',
      grade: _grade!,
      quantity: double.parse(_quantityController.text.trim()),
      unit: _unit!,
      harvestDate: _harvestDate!,
      maturityLevel: _maturityLevel!,
      shelfLifeEstimate: _shelfLifeEstimate!,
      storageSuggestion: _storageSuggestionController.text.trim(),
      notes: _notesController.text.trim(),
      photoPath: _photoPath,
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

  // [FE - Event Handler] Menyimpan perubahan batch DRAFT. Repository menolak
  // (no-op) bila status bukan DRAFT — kasus itu ditangani sebagai error.
  Future<void> _saveEdit() async {
    final ok = _repo.updateBatch(
      widget.editBatchCode!,
      farm: _selectedFarm,
      variety: _variety,
      fertilizer: _fertilizer ?? '',
      harvestMethod: _harvestMethod ?? '',
      grade: _grade,
      quantity: double.parse(_quantityController.text.trim()),
      unit: _unit,
      harvestDate: _harvestDate,
      maturityLevel: _maturityLevel,
      shelfLifeEstimate: _shelfLifeEstimate,
      storageSuggestion: _storageSuggestionController.text.trim(),
      notes: _notesController.text.trim(),
      photoPath: _photoPath,
    );

    setState(() => _isSubmitting = false);

    if (!ok) {
      // Guard state-machine menolak (Req 7.4).
      _notification.show(
        context,
        'Batch yang sudah dikirim tidak dapat diubah.',
        isError: true,
      );
      return;
    }

    _notification.show(
      context,
      'Perubahan batch berhasil disimpan.',
      isError: false,
    );

    // Beri jeda agar banner sukses sempat terlihat sebelum kembali ke Detail.
    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) Navigator.maybePop(context);
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
            AppTopBar(
              title: widget.isEditMode ? 'Ubah Batch Panen' : 'Tambah Batch Panen',
            ),

            // Form scrollable
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── 0. Foto Durian (opsional) ─────────────────────────
                    _PhotoPickerField(
                      photoPath: _photoPath,
                      onPick: _pickPhoto,
                      onRemove: _removePhoto,
                    ),
                    const SizedBox(height: 16),

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

                    // [FE - Component Rendering] Bagian ini menyusun input
                    // utama batch agar data panen siap dipakai role berikutnya.
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
                    const SizedBox(height: 16),

                    // [FE - Component Rendering] Field tambahan ini menjadi
                    // metadata traceability yang dibawa dari petani ke role
                    // pengepul, UMKM, retailer, dan konsumen.
                    LabeledDropdownField<String>(
                      label: 'Pilih Satuan Panen',
                      hint: 'Pilih satuan',
                      value: _unit,
                      items: FarmerMasterData.units,
                      itemLabel: (u) => u,
                      onChanged: (u) => setState(() => _unit = u),
                    ),
                    const SizedBox(height: 16),

                    LabeledDropdownField<String>(
                      label: 'Pilih Grade/Mutu Durian',
                      hint: 'Pilih grade',
                      value: _grade,
                      items: FarmerMasterData.grades,
                      itemLabel: (g) => 'Grade $g',
                      onChanged: (g) => setState(() => _grade = g),
                    ),
                    const SizedBox(height: 16),

                    LabeledDropdownField<String>(
                      label: 'Pilih Tingkat Kematangan',
                      hint: 'Pilih tingkat kematangan',
                      value: _maturityLevel,
                      items: FarmerMasterData.maturityLevels,
                      itemLabel: (m) => m,
                      onChanged: (m) => setState(() => _maturityLevel = m),
                    ),
                    const SizedBox(height: 16),

                    LabeledDropdownField<String>(
                      label: 'Pilih Estimasi Masa Simpan',
                      hint: 'Pilih masa simpan',
                      value: _shelfLifeEstimate,
                      items: FarmerMasterData.shelfLifeEstimates,
                      itemLabel: (s) => s,
                      onChanged: (s) => setState(() => _shelfLifeEstimate = s),
                    ),
                    const SizedBox(height: 16),

                    LabeledDropdownField<String>(
                      label: 'Pilih Metode Panen',
                      hint: 'Pilih metode panen',
                      value: _harvestMethod,
                      items: FarmerMasterData.harvestMethods,
                      itemLabel: (m) => m,
                      onChanged: (m) => setState(() => _harvestMethod = m),
                    ),
                    const SizedBox(height: 16),

                    LabeledDropdownField<String>(
                      label: 'Pilih Pupuk yang Digunakan (opsional)',
                      hint: 'Pilih pupuk',
                      value: _fertilizer,
                      items: FarmerMasterData.fertilizers,
                      itemLabel: (f) => f,
                      onChanged: (f) => setState(() => _fertilizer = f),
                    ),
                    const SizedBox(height: 16),

                    _TextAreaField(
                      label: 'Saran Penyimpanan (opsional)',
                      hint: 'Contoh: Simpan di tempat sejuk dan kering',
                      controller: _storageSuggestionController,
                    ),
                    const SizedBox(height: 16),

                    _TextAreaField(
                      label: 'Catatan Panen (opsional)',
                      hint: 'Contoh: Buah sudah disortir awal di kebun',
                      controller: _notesController,
                    ),
                    const SizedBox(height: 32),

                    // ── Tombol KIRIM / SIMPAN (Req 2.9) ────────────────────
                    PrimaryPillButton(
                      label: widget.isEditMode ? 'SIMPAN PERUBAHAN' : 'KIRIM',
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
// Foto picker field
// ─────────────────────────────────────────────────────────────────────────────

// [FE - Component Rendering] _PhotoPickerField menampilkan preview foto durian
// (atau placeholder dashed bila kosong) dan tombol untuk ambil/ganti/hapus foto.
class _PhotoPickerField extends StatelessWidget {
  const _PhotoPickerField({
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
        const Text(
          'Foto Durian (opsional)',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.subtitle,
          ),
        ),
        const SizedBox(height: 6),
        if (hasPhoto)
          // Preview foto + tombol ganti/hapus
          Stack(
            children: [
              BatchPhoto(
                path: photoPath,
                width: double.infinity,
                height: 180,
                borderRadius: BorderRadius.circular(12),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Row(
                  children: [
                    _CircleAction(
                      icon: Icons.edit_outlined,
                      onTap: onPick,
                    ),
                    const SizedBox(width: 8),
                    _CircleAction(
                      icon: Icons.close_rounded,
                      onTap: onRemove,
                      color: const Color(0xFFDC2626),
                    ),
                  ],
                ),
              ),
            ],
          )
        else
          // Placeholder dashed-style yang dapat ditekan
          GestureDetector(
            onTap: onPick,
            behavior: HitTestBehavior.opaque,
            child: Container(
              width: double.infinity,
              height: 140,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFD1D5DB)),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_a_photo_outlined,
                    size: 32,
                    color: AppColors.placeholder,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Tambahkan foto durian',
                    style: TextStyle(
                      fontSize: 13,
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

/// Tombol bulat kecil untuk aksi di atas preview foto (ganti/hapus).
class _CircleAction extends StatelessWidget {
  const _CircleAction({
    required this.icon,
    required this.onTap,
    this.color,
  });

  final IconData icon;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: AppColors.white.withValues(alpha: 0.92),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, size: 18, color: color ?? AppColors.subtitle),
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

// [FE - Component Rendering] _TextAreaField menyediakan input teks panjang
// untuk metadata opsional batch tanpa mencampur logika form utama.
class _TextAreaField extends StatelessWidget {
  const _TextAreaField({
    required this.label,
    required this.hint,
    required this.controller,
  });

  final String label;
  final String hint;
  final TextEditingController controller;

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
        TextField(
          controller: controller,
          maxLines: 3,
          textInputAction: TextInputAction.newline,
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.black,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
              fontSize: 14,
              color: AppColors.placeholder,
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

/// Input numerik untuk jumlah panen; satuannya dipilih lewat dropdown terpisah.
class _QuantityField extends StatelessWidget {
  const _QuantityField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Masukan Jumlah Panen',
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
