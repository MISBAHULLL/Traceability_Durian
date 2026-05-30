import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_top_bar.dart';
import '../../../shared/widgets/primary_pill_button.dart';
import '../../../shared/widgets/top_notification_banner.dart';
import '../data/farmer_repository.dart';

// [FE - Component Rendering] Screen ini adalah form pembuatan kebun baru —
// field wajib divalidasi sebelum disimpan ke FarmerRepository, dan kebun
// baru langsung tersedia di dropdown AddBatchScreen via notifyListeners.
/// Layar form untuk membuat kebun durian baru (Req 5.3–5.6).
///
/// Field wajib: nama kebun, provinsi, kota/kabupaten, kecamatan, desa, alamat.
/// Field opsional: latitude, longitude.
///
/// Alur submit (Req 5.4, 5.5):
/// 1. Validasi via [FarmerValidator.validateCreateFarm].
/// 2. Bila gagal → tampilkan [TopNotification] error berbahasa Indonesia.
/// 3. Bila valid → panggil [FarmerRepository.addFarm], tampilkan banner sukses,
///    lalu pop. Kebun baru langsung tersedia di dropdown Tambah Batch (Req 5.6)
///    karena repo memanggil [notifyListeners].
class CreateFarmScreen extends StatefulWidget {
  const CreateFarmScreen({super.key});

  @override
  State<CreateFarmScreen> createState() => _CreateFarmScreenState();
}

class _CreateFarmScreenState extends State<CreateFarmScreen> {
  final _repo = FarmerRepository.instance;
  final _notification = TopNotification();

  final _nameCtrl = TextEditingController();
  final _provinceCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _districtCtrl = TextEditingController();
  final _villageCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _latCtrl = TextEditingController();
  final _lngCtrl = TextEditingController();

  bool _isSubmitting = false;

  @override
  void dispose() {
    _notification.dispose();
    _nameCtrl.dispose();
    _provinceCtrl.dispose();
    _cityCtrl.dispose();
    _districtCtrl.dispose();
    _villageCtrl.dispose();
    _addressCtrl.dispose();
    _latCtrl.dispose();
    _lngCtrl.dispose();
    super.dispose();
  }

  // ── Submit ─────────────────────────────────────────────────────────────────

  // [FE - Event Handler] _submit menangani aksi simpan kebun: validasi →
  // error banner atau addFarm + sukses banner + pop kembali ke pemanggil.
  Future<void> _submit() async {
    // Validasi semua field
    final error = FarmerValidator.validateCreateFarm(
      name: _nameCtrl.text,
      province: _provinceCtrl.text,
      city: _cityCtrl.text,
      district: _districtCtrl.text,
      village: _villageCtrl.text,
      address: _addressCtrl.text,
      latitudeText: _latCtrl.text.isEmpty ? null : _latCtrl.text,
      longitudeText: _lngCtrl.text.isEmpty ? null : _lngCtrl.text,
    );

    if (error != null) {
      _notification.show(context, error, isError: true);
      return;
    }

    // Semua valid — mulai proses simpan
    setState(() => _isSubmitting = true);

    // Simulasi async singkat agar indikator loading terlihat
    await Future.delayed(const Duration(milliseconds: 400));

    if (!mounted) return;

    // Parse koordinat opsional
    final lat = _latCtrl.text.trim().isEmpty
        ? null
        : double.tryParse(_latCtrl.text.trim());
    final lng = _lngCtrl.text.trim().isEmpty
        ? null
        : double.tryParse(_lngCtrl.text.trim());

    _repo.addFarm(
      name: _nameCtrl.text.trim(),
      province: _provinceCtrl.text.trim(),
      city: _cityCtrl.text.trim(),
      district: _districtCtrl.text.trim(),
      village: _villageCtrl.text.trim(),
      address: _addressCtrl.text.trim(),
      latitude: lat,
      longitude: lng,
    );

    setState(() => _isSubmitting = false);

    // Banner sukses (Req 5.5)
    _notification.show(
      context,
      'Kebun "${_nameCtrl.text.trim()}" berhasil ditambahkan.',
      isError: false,
    );

    // Tunggu sebentar agar banner terlihat sebelum pop
    await Future.delayed(const Duration(milliseconds: 800));

    if (mounted) Navigator.maybePop(context);
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar dengan tombol back (Req 8.2)
            const AppTopBar(title: 'Buat Kebun'),

            // Form scrollable
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Nama Kebun (wajib) ─────────────────────────────────
                    _FormField(
                      label: 'Nama Kebun',
                      hint: 'Contoh: Kebun Pak Risqi',
                      controller: _nameCtrl,
                      textCapitalization: TextCapitalization.words,
                    ),
                    const SizedBox(height: 16),

                    // ── Provinsi (wajib) ───────────────────────────────────
                    _FormField(
                      label: 'Provinsi',
                      hint: 'Contoh: Jawa Timur',
                      controller: _provinceCtrl,
                      textCapitalization: TextCapitalization.words,
                    ),
                    const SizedBox(height: 16),

                    // ── Kota/Kabupaten (wajib) ─────────────────────────────
                    _FormField(
                      label: 'Kota/Kabupaten',
                      hint: 'Contoh: Kabupaten Jember',
                      controller: _cityCtrl,
                      textCapitalization: TextCapitalization.words,
                    ),
                    const SizedBox(height: 16),

                    // ── Kecamatan (wajib) ──────────────────────────────────
                    _FormField(
                      label: 'Kecamatan',
                      hint: 'Contoh: Pakis',
                      controller: _districtCtrl,
                      textCapitalization: TextCapitalization.words,
                    ),
                    const SizedBox(height: 16),

                    // ── Desa (wajib) ───────────────────────────────────────
                    _FormField(
                      label: 'Desa',
                      hint: 'Contoh: Pakis',
                      controller: _villageCtrl,
                      textCapitalization: TextCapitalization.words,
                    ),
                    const SizedBox(height: 16),

                    // ── Alamat (wajib) ─────────────────────────────────────
                    _FormField(
                      label: 'Alamat',
                      hint: 'Contoh: Jl. Raya Pakis No. 1',
                      controller: _addressCtrl,
                      maxLines: 3,
                      textCapitalization: TextCapitalization.sentences,
                    ),
                    const SizedBox(height: 16),

                    // ── Divider opsional ───────────────────────────────────
                    const _SectionDivider(label: 'Koordinat (Opsional)'),
                    const SizedBox(height: 16),

                    // ── Latitude (opsional) ────────────────────────────────
                    _FormField(
                      label: 'Latitude',
                      hint: 'Contoh: -8.1234',
                      controller: _latCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                        signed: true,
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'^-?\d*\.?\d*'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // ── Longitude (opsional) ───────────────────────────────
                    _FormField(
                      label: 'Longitude',
                      hint: 'Contoh: 113.7234',
                      controller: _lngCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                        signed: true,
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'^-?\d*\.?\d*'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // ── Tombol Simpan ──────────────────────────────────────
                    PrimaryPillButton(
                      label: 'SIMPAN KEBUN',
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
// Reusable form field
// ─────────────────────────────────────────────────────────────────────────────

/// Field teks bergaya konsisten dengan layar lain (border tipis, label atas).
class _FormField extends StatelessWidget {
  const _FormField({
    required this.label,
    required this.hint,
    required this.controller,
    this.keyboardType,
    this.inputFormatters,
    this.maxLines = 1,
    this.textCapitalization = TextCapitalization.none,
  });

  final String label;
  final String hint;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final int maxLines;
  final TextCapitalization textCapitalization;

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
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          maxLines: maxLines,
          textCapitalization: textCapitalization,
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

// ─────────────────────────────────────────────────────────────────────────────
// Section divider
// ─────────────────────────────────────────────────────────────────────────────

/// Pemisah visual dengan label untuk memisahkan bagian wajib dan opsional.
class _SectionDivider extends StatelessWidget {
  const _SectionDivider({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: Color(0xFFE5E7EB))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.placeholder,
            ),
          ),
        ),
        const Expanded(child: Divider(color: Color(0xFFE5E7EB))),
      ],
    );
  }
}
