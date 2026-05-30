import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_top_bar.dart';
import '../../../shared/widgets/primary_pill_button.dart';
import '../../../shared/widgets/top_notification_banner.dart';
import '../data/farmer_repository.dart';

// [FE - Component Rendering] Screen ini adalah form untuk melengkapi/mengubah
// profil petani (nama, kontak, alamat) — menutup kesenjangan dari registrasi
// yang belum mengumpulkan data alamat. Menyimpan via FarmerRepository.updateProfile.
/// Layar form untuk mengubah / melengkapi profil petani.
///
/// Field di-prefill dari [FarmerRepository.profile] saat ini. Field yang masih
/// kosong (petani baru) tampil dengan placeholder agar mudah dilengkapi.
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _repo = FarmerRepository.instance;
  final _notification = TopNotification();

  late final TextEditingController _nameCtrl;
  late final TextEditingController _contactCtrl;
  late final TextEditingController _villageCtrl;
  late final TextEditingController _districtCtrl;
  late final TextEditingController _cityCtrl;

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // Prefill dari profil saat ini.
    final p = _repo.profile;
    _nameCtrl = TextEditingController(text: p.fullName);
    _contactCtrl = TextEditingController(text: p.contact);
    _villageCtrl = TextEditingController(text: p.village);
    _districtCtrl = TextEditingController(text: p.district);
    _cityCtrl = TextEditingController(text: p.city);
  }

  @override
  void dispose() {
    _notification.dispose();
    _nameCtrl.dispose();
    _contactCtrl.dispose();
    _villageCtrl.dispose();
    _districtCtrl.dispose();
    _cityCtrl.dispose();
    super.dispose();
  }

  // [FE - Event Handler] _submit memvalidasi field wajib lalu menyimpan
  // perubahan profil ke repository, menampilkan banner, dan pop kembali.
  Future<void> _submit() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      _notification.show(context, 'Nama wajib diisi.', isError: true);
      return;
    }

    setState(() => _isSubmitting = true);
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;

    _repo.updateProfile(
      fullName: name,
      contact: _contactCtrl.text,
      village: _villageCtrl.text,
      district: _districtCtrl.text,
      city: _cityCtrl.text,
    );

    setState(() => _isSubmitting = false);
    _notification.show(context, 'Profil berhasil diperbarui.', isError: false);

    // Tunggu banner auto-dismiss sebelum pop agar tidak terpotong.
    await Future.delayed(const Duration(milliseconds: 3200));
    if (mounted) Navigator.maybePop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            const AppTopBar(title: 'Ubah Profil'),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Data diri ──────────────────────────────────────────
                    const _SectionDivider(label: 'Data Diri'),
                    const SizedBox(height: 16),
                    _FormField(
                      label: 'Nama Lengkap',
                      hint: 'Nama lengkap Anda',
                      controller: _nameCtrl,
                      textCapitalization: TextCapitalization.words,
                    ),
                    const SizedBox(height: 16),
                    _FormField(
                      label: 'Kontak (No. HP / Email)',
                      hint: 'Contoh: 081234567890',
                      controller: _contactCtrl,
                      keyboardType: TextInputType.text,
                    ),
                    const SizedBox(height: 24),

                    // ── Alamat ─────────────────────────────────────────────
                    const _SectionDivider(label: 'Alamat'),
                    const SizedBox(height: 16),
                    _FormField(
                      label: 'Desa',
                      hint: 'Contoh: Pakis',
                      controller: _villageCtrl,
                      textCapitalization: TextCapitalization.words,
                    ),
                    const SizedBox(height: 16),
                    _FormField(
                      label: 'Kecamatan',
                      hint: 'Contoh: Pakis',
                      controller: _districtCtrl,
                      textCapitalization: TextCapitalization.words,
                    ),
                    const SizedBox(height: 16),
                    _FormField(
                      label: 'Kota/Kabupaten',
                      hint: 'Contoh: Kabupaten Jember',
                      controller: _cityCtrl,
                      textCapitalization: TextCapitalization.words,
                    ),
                    const SizedBox(height: 32),

                    PrimaryPillButton(
                      label: 'SIMPAN PROFIL',
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
// Sub-widgets
// ─────────────────────────────────────────────────────────────────────────────

/// Field teks bergaya konsisten dengan layar form lain (border tipis, label atas).
class _FormField extends StatelessWidget {
  const _FormField({
    required this.label,
    required this.hint,
    required this.controller,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
  });

  final String label;
  final String hint;
  final TextEditingController controller;
  final TextInputType? keyboardType;
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
          textCapitalization: textCapitalization,
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

/// Pemisah visual dengan label untuk mengelompokkan bagian form.
class _SectionDivider extends StatelessWidget {
  const _SectionDivider({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: AppColors.black,
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(child: Divider(color: Color(0xFFE5E7EB))),
      ],
    );
  }
}
