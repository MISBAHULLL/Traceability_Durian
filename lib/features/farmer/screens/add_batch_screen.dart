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
import '../models/batch_recipient.dart';
import '../models/harvest_batch.dart';
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
  // [FE - State Management] Controller ini menyimpan jumlah buah per batch
  // dalam satuan butir untuk melengkapi total panen berbasis kg/buah.
  final _fruitCountController = TextEditingController();
  // [FE - State Management] Controller ini menyimpan input opsional yang
  // menjadi metadata traceability batch sebelum dikirim ke repository.
  final _storageSuggestionController = TextEditingController();
  final _notesController = TextEditingController();

  Farm? _selectedFarm;
  String? _variety;
  String? _fertilizer;
  String? _harvestMethod;
  String? _grade;
  // [FE - State Management] State ini menyimpan pilihan kualitas durian yang
  // dipakai UI form dan diteruskan ke model HarvestBatch.
  String? _maturityLevel;
  String? _shelfLifeEstimate;
  DateTime? _harvestDate;
  String? _photoPath;
  bool _isSubmitting = false;
  bool _isLoadingRecipients = false;
  String? _recipientLoadError;
  List<BatchRecipient> _recipients = const [];
  BatchRecipient? _selectedRecipient;

  @override
  void initState() {
    super.initState();
    // Prefill field bila dalam mode ubah (sebelum memasang listener).
    if (widget.isEditMode) {
      _prefillFromExistingBatch();
    } else {
      _loadBatchRecipients();
    }

    // Dengarkan perubahan repo agar dropdown kebun ter-refresh bila
    // pengguna baru saja membuat kebun dari CreateFarmScreen.
    _repo.addListener(_onRepoChanged);
  }

  Future<void> _loadBatchRecipients() async {
    setState(() {
      _isLoadingRecipients = true;
      _recipientLoadError = null;
    });
    try {
      final recipients = await _repo.loadBatchRecipients();
      if (!mounted) return;
      setState(() {
        _recipients = recipients;
        _isLoadingRecipients = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoadingRecipients = false;
        _recipientLoadError = error.toString();
      });
    }
  }

  Future<void> _openRecipientPicker() async {
    final recipient = await showModalBottomSheet<BatchRecipient>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _RecipientPickerSheet(recipients: _recipients),
    );
    if (!mounted || recipient == null) return;
    setState(() => _selectedRecipient = recipient);
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
    _harvestMethod = (batch.harvestMethod?.isEmpty ?? true)
        ? null
        : batch.harvestMethod;
    _grade = batch.grade;
    _maturityLevel = (batch.maturityLevel?.isEmpty ?? true)
        ? null
        : batch.maturityLevel;
    _shelfLifeEstimate = (batch.shelfLifeEstimate?.isEmpty ?? true)
        ? null
        : batch.shelfLifeEstimate;
    _harvestDate = batch.harvestDate;
    _quantityController.text = batch.quantity.toStringAsFixed(0);
    _fruitCountController.text = batch.fruitCount?.toString() ?? '';
    _storageSuggestionController.text = batch.storageSuggestion ?? '';
    _notesController.text = batch.notes ?? '';
    _photoPath = batch.photoPath;
  }

  @override
  void dispose() {
    _repo.removeListener(_onRepoChanged);
    _notification.dispose();
    _quantityController.dispose();
    _fruitCountController.dispose();
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
                leading: const Icon(
                  Icons.photo_camera_outlined,
                  color: AppColors.primary,
                ),
                title: const Text('Ambil dari Kamera'),
                onTap: () => Navigator.pop(sheetCtx, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(
                  Icons.photo_library_outlined,
                  color: AppColors.primary,
                ),
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

  // ── Submit ─────────────────────────────────────────────────────────────────

  // [FE - Event Handler] _submit menangani aksi simpan. Pada mode tambah:
  // validasi → addBatch → buka QR. Pada mode ubah: validasi → updateBatch
  // (guard DRAFT di repository) → pop kembali ke Detail.
  Future<void> _submit() async {
    if (!widget.isEditMode && _selectedRecipient == null) {
      _notification.show(
        context,
        'Pilih akun tujuan batch terlebih dahulu.',
        isError: true,
      );
      return;
    }

    // Validasi semua field
    final error = FarmerValidator.validateAddBatch(
      farm: _selectedFarm,
      variety: _variety,
      grade: _grade,
      maturityLevel: _maturityLevel,
      shelfLifeEstimate: _shelfLifeEstimate,
      harvestMethod: _harvestMethod,
      harvestDate: _harvestDate,
      quantityText: _quantityController.text,
      fruitCountText: _fruitCountController.text,
      photoPath: _photoPath,
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
    try {
      final batch = await _repo.addBatch(
        farm: _selectedFarm!,
        variety: _variety!,
        fertilizer: _fertilizer ?? '',
        harvestMethod: _harvestMethod ?? '',
        grade: _grade!,
        quantity: double.parse(_quantityController.text.trim()),
        unit: 'kg',
        fruitCount: int.parse(_fruitCountController.text.trim()),
        harvestDate: _harvestDate!,
        maturityLevel: _maturityLevel!,
        shelfLifeEstimate: _shelfLifeEstimate!,
        storageSuggestion: _storageSuggestionController.text.trim(),
        notes: _notesController.text.trim(),
        photoPath: _photoPath,
        recipient: _selectedRecipient!,
      );

      if (!mounted) return;
      setState(() => _isSubmitting = false);

      // Banner sukses (Req 2.8)
      _notification.show(
        context,
        'Batch panen berhasil dicatat dengan kode ${batch.code}.',
        isError: false,
      );

      // Buka QR screen — back dari sini kembali ke Beranda (Req 4.6)
      await FarmerRoutes.push(
        context,
        BatchQrScreen(batchCode: batch.code, openedAfterCreate: true),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      _notification.show(
        context,
        'Batch gagal disimpan: $error',
        isError: true,
      );
    }
  }

  // [FE - Event Handler] Menyimpan perubahan batch DRAFT. Repository menolak
  // (no-op) bila status bukan DRAFT — kasus itu ditangani sebagai error.
  Future<void> _saveEdit() async {
    final ok = await _repo.updateBatch(
      widget.editBatchCode!,
      farm: _selectedFarm,
      variety: _variety,
      fertilizer: _fertilizer ?? '',
      harvestMethod: _harvestMethod ?? '',
      grade: _grade,
      quantity: double.parse(_quantityController.text.trim()),
      unit: 'kg',
      fruitCount: int.parse(_fruitCountController.text.trim()),
      harvestDate: _harvestDate,
      maturityLevel: _maturityLevel,
      shelfLifeEstimate: _shelfLifeEstimate,
      storageSuggestion: _storageSuggestionController.text.trim(),
      notes: _notesController.text.trim(),
      photoPath: _photoPath,
    );

    if (!mounted) return;
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
    if (!mounted) return;
    Navigator.maybePop(context);
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
              title: widget.isEditMode
                  ? 'Ubah Batch Panen'
                  : 'Tambah Batch Panen',
            ),

            // Form scrollable
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── 0. Foto Durian ─────────────────────────────────────
                    // [FE - Component Rendering] Foto durian menjadi bukti
                    // visual awal batch sebelum data dikirim ke penerima.
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

                    if (!widget.isEditMode) ...[
                      if (_isLoadingRecipients)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: LinearProgressIndicator(),
                        )
                      else if (_recipientLoadError != null)
                        _RecipientLoadError(
                          message: _recipientLoadError!,
                          onRetry: _loadBatchRecipients,
                        )
                      else if (_recipients.isEmpty)
                        const _NoRecipientsAvailable()
                      else
                        _RecipientDropdownField(
                          value: _selectedRecipient,
                          onTap: _openRecipientPicker,
                        ),
                      const SizedBox(height: 16),
                    ],

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
                    // [FE - Component Rendering] Berat panen dikunci ke kg
                    // agar tidak rancu dengan jumlah buah dalam butir.
                    _QuantityField(controller: _quantityController),
                    const SizedBox(height: 16),

                    _FruitCountField(controller: _fruitCountController),
                    const SizedBox(height: 16),

                    LabeledDropdownField<String>(
                      label: 'Pilih Grade Awal (Estimasi Petani)',
                      hint: 'Pilih grade awal',
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

class _RecipientLoadError extends StatelessWidget {
  const _RecipientLoadError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Akun tujuan gagal dimuat: $message',
          style: const TextStyle(color: Colors.red, fontSize: 12),
        ),
        TextButton(onPressed: onRetry, child: const Text('Coba lagi')),
      ],
    );
  }
}

class _NoRecipientsAvailable extends StatelessWidget {
  const _NoRecipientsAvailable();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: const Text(
        'Belum ada akun pengepul, UMKM, atau distributor yang aktif.',
        style: TextStyle(fontSize: 13, color: AppColors.subtitle),
      ),
    );
  }
}

class _RecipientDropdownField extends StatelessWidget {
  const _RecipientDropdownField({required this.value, required this.onTap});

  final BatchRecipient? value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Pilih Akun Tujuan (wajib)',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.subtitle,
          ),
        ),
        const SizedBox(height: 6),
        Material(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: double.infinity,
              constraints: const BoxConstraints(minHeight: 52),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      value == null
                          ? 'Pilih nama akun tujuan'
                          : '${value!.fullName} • ID ${value!.accountId}',
                      style: TextStyle(
                        fontSize: 14,
                        color: value == null
                            ? AppColors.placeholder
                            : AppColors.black,
                        fontWeight: value == null
                            ? FontWeight.normal
                            : FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: AppColors.placeholder,
                    size: 22,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _RecipientPickerSheet extends StatefulWidget {
  const _RecipientPickerSheet({required this.recipients});

  final List<BatchRecipient> recipients;

  @override
  State<_RecipientPickerSheet> createState() => _RecipientPickerSheetState();
}

class _RecipientPickerSheetState extends State<_RecipientPickerSheet> {
  final _searchController = TextEditingController();
  String _query = '';

  List<BatchRecipient> get _results {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return widget.recipients;
    return widget.recipients.where((recipient) {
      return recipient.fullName.toLowerCase().contains(query) ||
          recipient.accountId.toLowerCase().contains(query);
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      heightFactor: 0.82,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            12,
            20,
            16 + MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD1D5DB),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Pilih Akun Tujuan',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _searchController,
                autofocus: true,
                onChanged: (value) => setState(() => _query = value),
                decoration: InputDecoration(
                  hintText: 'Cari nama atau ID akun',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Hapus pencarian',
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _query = '');
                          },
                          icon: const Icon(Icons.close_rounded),
                        ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: _results.isEmpty
                    ? const Center(
                        child: Text(
                          'Akun tidak ditemukan. Cari dengan nama atau ID.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.placeholder),
                        ),
                      )
                    : ListView.separated(
                        itemCount: _results.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final recipient = _results[index];
                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 4,
                            ),
                            title: Text(
                              recipient.fullName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(
                              'ID ${recipient.accountId} • ${recipient.role.label}',
                            ),
                            trailing: const Icon(
                              Icons.chevron_right_rounded,
                              color: AppColors.placeholder,
                            ),
                            onTap: () => Navigator.of(context).pop(recipient),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
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
          'Foto Durian',
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
                    _CircleAction(icon: Icons.edit_outlined, onTap: onPick),
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
  const _CircleAction({required this.icon, required this.onTap, this.color});

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
                      fontWeight: value != null
                          ? FontWeight.w500
                          : FontWeight.normal,
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
          style: const TextStyle(fontSize: 14, color: AppColors.black),
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

// [FE - Component Rendering] _FruitCountField menangkap jumlah buah dalam
// satu batch sebagai integer agar data sortasi bisa dihitung per butir.
class _FruitCountField extends StatelessWidget {
  const _FruitCountField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Masukan Jumlah Buah (butir)',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.subtitle,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: const TextStyle(fontSize: 14, color: AppColors.black),
          decoration: InputDecoration(
            hintText: 'Contoh: 18',
            hintStyle: const TextStyle(
              fontSize: 14,
              color: AppColors.placeholder,
            ),
            suffixText: 'butir',
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

/// Input numerik untuk total berat panen dalam kilogram.
class _QuantityField extends StatelessWidget {
  const _QuantityField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Masukan Jumlah Panen (kg)',
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
          style: const TextStyle(fontSize: 14, color: AppColors.black),
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
