import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_top_bar.dart';
import '../../../shared/widgets/primary_pill_button.dart';
import '../../../shared/widgets/top_notification_banner.dart';
import '../data/farmer_repository.dart';

/// Layar form untuk membuat kebun durian baru (Req 5.3–5.6).
///
/// Field wajib: nama kebun, provinsi, kota/kabupaten, kecamatan, desa, alamat.
/// Field opsional: latitude, longitude.
///
/// Setelah simpan berhasil, kebun baru langsung tersedia di dropdown
/// Tambah Batch karena [FarmerRepository] memanggil [notifyListeners].
///
/// Implementasi penuh akan diselesaikan pada Task 10.
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

  Future<void> _submit() async {
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

    setState(() => _isSubmitting = true);
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;

    _repo.addFarm(
      name: _nameCtrl.text.trim(),
      province: _provinceCtrl.text.trim(),
      city: _cityCtrl.text.trim(),
      district: _districtCtrl.text.trim(),
      village: _villageCtrl.text.trim(),
      address: _addressCtrl.text.trim(),
      latitude: _latCtrl.text.trim().isEmpty
          ? null
          : double.tryParse(_latCtrl.text.trim()),
      longitude: _lngCtrl.text.trim().isEmpty
          ? null
          : double.tryParse(_lngCtrl.text.trim()),
    );

    setState(() => _isSubmitting = false);

    _notification.show(
      context,
      'Kebun berhasil dibuat.',
      isError: false,
    );

    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) Navigator.maybePop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            const AppTopBar(title: 'Buat Kebun'),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _TextField(
                      label: 'Nama Kebun',
                      hint: 'Contoh: Kebun Pak Risqi',
                      controller: _nameCtrl,
                    ),
                    const SizedBox(height: 16),
                    _TextField(
                      label: 'Provinsi',
                      hint: 'Contoh: Jawa Timur',
                      controller: _provinceCtrl,
                    ),
                    const SizedBox(height: 16),
                    _TextField(
                      label: 'Kota/Kabupaten',
                      hint: 'Contoh: Kabupaten Jember',
                      controller: _cityCtrl,
                    ),
                    const SizedBox(height: 16),
                    _TextField(
                      label: 'Kecamatan',
                      hint: 'Contoh: Pakis',
                      controller: _districtCtrl,
                    ),
                    const SizedBox(height: 16),
                    _TextField(
                      label: 'Desa',
                      hint: 'Contoh: Pakis',
                      controller: _villageCtrl,
                    ),
                    const SizedBox(height: 16),
                    _TextField(
                      label: 'Alamat',
                      hint: 'Contoh: Jl. Raya Pakis No. 1',
                      controller: _addressCtrl,
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),
                    _TextField(
                      label: 'Latitude (opsional)',
                      hint: 'Contoh: -8.1234',
                      controller: _latCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                        signed: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'^-?\d*\.?\d*'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _TextField(
                      label: 'Longitude (opsional)',
                      hint: 'Contoh: 113.7234',
                      controller: _lngCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                        signed: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'^-?\d*\.?\d*'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
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
// Reusable text field
// ─────────────────────────────────────────────────────────────────────────────

class _TextField extends StatelessWidget {
  const _TextField({
    required this.label,
    required this.hint,
    required this.controller,
    this.maxLines = 1,
    this.keyboardType,
    this.inputFormatters,
  });

  final String label;
  final String hint;
  final TextEditingController controller;
  final int maxLines;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;

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
          maxLines: maxLines,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
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
