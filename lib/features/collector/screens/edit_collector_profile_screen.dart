import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_top_bar.dart';
import '../../../shared/widgets/primary_pill_button.dart';
import '../../../shared/widgets/top_notification_banner.dart';
import '../data/collector_repository.dart';

// [FE - Component Rendering] Screen ini adalah form edit identitas pengepul
// yang menjadi data aktor saat verifikasi batch dan transaksi distribusi.
class EditCollectorProfileScreen extends StatefulWidget {
  const EditCollectorProfileScreen({super.key});

  @override
  State<EditCollectorProfileScreen> createState() =>
      _EditCollectorProfileScreenState();
}

class _EditCollectorProfileScreenState
    extends State<EditCollectorProfileScreen> {
  final _repo = CollectorRepository.instance;
  final _notification = TopNotification();

  late final TextEditingController _nameCtrl;
  late final TextEditingController _businessCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _villageCtrl;
  late final TextEditingController _districtCtrl;
  late final TextEditingController _cityCtrl;
  late final TextEditingController _addressCtrl;

  // [FE - State Management] Flag ini mengunci tombol simpan selama proses
  // submit mock berlangsung agar user tidak mengirim perubahan ganda.
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final profile = _repo.profile;
    _nameCtrl = TextEditingController(text: profile.fullName);
    _businessCtrl = TextEditingController(text: profile.businessName);
    _phoneCtrl = TextEditingController(text: _phoneFieldValue(profile.contact));
    _emailCtrl = TextEditingController(text: profile.email);
    _villageCtrl = TextEditingController(text: profile.village);
    _districtCtrl = TextEditingController(text: profile.district);
    _cityCtrl = TextEditingController(text: profile.city);
    _addressCtrl = TextEditingController(text: profile.address);
  }

  @override
  void dispose() {
    _notification.dispose();
    _nameCtrl.dispose();
    _businessCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _villageCtrl.dispose();
    _districtCtrl.dispose();
    _cityCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  // [UTIL - Helper Function] Helper ini menyiapkan nomor profil agar field
  // edit hanya berisi digit lokal setelah prefix +62.
  String _phoneFieldValue(String contact) {
    final digits = contact.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('62')) return digits.substring(2);
    if (digits.startsWith('0')) return digits.substring(1);
    return digits;
  }

  // [UTIL - Helper Function] Normalisasi ini menjaga format nomor HP pengepul
  // konsisten antara registrasi, edit profil, dan calon payload API.
  String _normalizeIndonesianPhone(String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('0')) return digits.substring(1);
    return digits;
  }

  // [FE - Event Handler] _submit memvalidasi form lalu menyimpan profil
  // pengepul ke repository dan local storage mock.
  Future<void> _submit() async {
    final name = _nameCtrl.text.trim();
    final businessName = _businessCtrl.text.trim();
    final phone = _normalizeIndonesianPhone(_phoneCtrl.text);
    final email = _emailCtrl.text.trim();

    if (name.isEmpty) {
      _notification.show(context, 'Nama wajib diisi.', isError: true);
      return;
    }
    if (phone.isEmpty) {
      _notification.show(context, 'Nomor HP wajib diisi.', isError: true);
      return;
    }
    if (phone.length < 9 || phone.length > 13) {
      _notification.show(
        context,
        'Nomor HP tidak valid (9-13 digit setelah +62).',
        isError: true,
      );
      return;
    }
    if (email.isEmpty) {
      _notification.show(context, 'Email wajib diisi.', isError: true);
      return;
    }
    final emailRegex = RegExp(r'^[\w\.\+\-]+@[\w\-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(email)) {
      _notification.show(context, 'Format email tidak valid.', isError: true);
      return;
    }

    setState(() => _isSubmitting = true);
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;

    _repo.updateProfile(
      fullName: name,
      contact: '+62 $phone',
      email: email,
      businessName: businessName,
      village: _villageCtrl.text,
      district: _districtCtrl.text,
      city: _cityCtrl.text,
      address: _addressCtrl.text,
    );

    setState(() => _isSubmitting = false);
    _notification.show(context, 'Profil pengepul berhasil diperbarui.');

    await Future.delayed(const Duration(milliseconds: 1200));
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
                    const _SectionDivider(label: 'Data Diri'),
                    const SizedBox(height: 16),
                    _FormField(
                      label: 'Nama Lengkap',
                      hint: 'Nama lengkap pengepul',
                      controller: _nameCtrl,
                      textCapitalization: TextCapitalization.words,
                    ),
                    const SizedBox(height: 16),
                    _FormField(
                      label: 'Nama Usaha/Lapak',
                      hint: 'Contoh: Lapak Durian Jember',
                      controller: _businessCtrl,
                      textCapitalization: TextCapitalization.words,
                    ),
                    const SizedBox(height: 16),
                    _FormField(
                      label: 'Nomor HP',
                      hint: 'Contoh: 8123456789',
                      controller: _phoneCtrl,
                      prefixText: '+62  ',
                      keyboardType: TextInputType.phone,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(13),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _FormField(
                      label: 'Email',
                      hint: 'contoh@email.com',
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 24),
                    const _SectionDivider(label: 'Lokasi Operasional'),
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
                    const SizedBox(height: 16),
                    _FormField(
                      label: 'Alamat Detail',
                      hint: 'Contoh: Jl. Raya Pakis No. 2',
                      controller: _addressCtrl,
                      textCapitalization: TextCapitalization.sentences,
                      maxLines: 3,
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

// [FE - Component Rendering] Field reusable ini menjaga tampilan form edit
// profil pengepul konsisten dengan form petani dan transaksi.
class _FormField extends StatelessWidget {
  const _FormField({
    required this.label,
    required this.hint,
    required this.controller,
    this.keyboardType,
    this.prefixText,
    this.inputFormatters,
    this.textCapitalization = TextCapitalization.none,
    this.maxLines = 1,
  });

  final String label;
  final String hint;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final String? prefixText;
  final List<TextInputFormatter>? inputFormatters;
  final TextCapitalization textCapitalization;
  final int maxLines;

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
          textCapitalization: textCapitalization,
          maxLines: maxLines,
          style: const TextStyle(fontSize: 14, color: AppColors.black),
          decoration: InputDecoration(
            hintText: hint,
            prefixText: prefixText,
            prefixStyle: const TextStyle(
              fontSize: 14,
              color: AppColors.subtitle,
              fontWeight: FontWeight.w500,
            ),
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

// [FE - Component Rendering] Divider ini memisahkan kelompok data agar form
// profil tetap mudah dipindai pada layar mobile.
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
