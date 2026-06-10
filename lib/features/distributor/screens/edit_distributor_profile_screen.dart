import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_top_bar.dart';
import '../../../shared/widgets/primary_pill_button.dart';
import '../../../shared/widgets/top_notification_banner.dart';
import '../data/distributor_repository.dart';

// [FE - Component Rendering] Screen ini mengelola form edit identitas distributor
// agar data pada pelacakan logistik dapat diperbarui secara dinamis.
class EditDistributorProfileScreen extends StatefulWidget {
  const EditDistributorProfileScreen({super.key});

  @override
  State<EditDistributorProfileScreen> createState() =>
      _EditDistributorProfileScreenState();
}

class _EditDistributorProfileScreenState
    extends State<EditDistributorProfileScreen> {
  final _repo = DistributorRepository.instance;
  final _notification = TopNotification();

  late final TextEditingController _nameCtrl;
  late final TextEditingController _businessCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _villageCtrl;
  late final TextEditingController _districtCtrl;
  late final TextEditingController _cityCtrl;
  late final TextEditingController _addressCtrl;

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

  String _phoneFieldValue(String contact) {
    final digits = contact.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('62')) return digits.substring(2);
    if (digits.startsWith('0')) return digits.substring(1);
    return digits;
  }

  String _normalizeIndonesianPhone(String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('0')) return digits.substring(1);
    return digits;
  }

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
    _notification.show(context, 'Profil distributor berhasil diperbarui.');

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
            const AppTopBar(title: 'Ubah Profil Distributor'),
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
                      hint: 'Nama lengkap distributor',
                      controller: _nameCtrl,
                      textCapitalization: TextCapitalization.words,
                    ),
                    const SizedBox(height: 16),
                    _FormField(
                      label: 'Nama Usaha/Hub',
                      hint: 'Contoh: PT. Trans Logistik Durian',
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
                    const _SectionDivider(label: 'Lokasi Operasional Hub'),
                    const SizedBox(height: 16),
                    _FormField(
                      label: 'Desa/Kelurahan',
                      hint: 'Contoh: Genteng',
                      controller: _villageCtrl,
                      textCapitalization: TextCapitalization.words,
                    ),
                    const SizedBox(height: 16),
                    _FormField(
                      label: 'Kecamatan',
                      hint: 'Contoh: Genteng',
                      controller: _districtCtrl,
                      textCapitalization: TextCapitalization.words,
                    ),
                    const SizedBox(height: 16),
                    _FormField(
                      label: 'Kota/Kabupaten',
                      hint: 'Contoh: Surabaya',
                      controller: _cityCtrl,
                      textCapitalization: TextCapitalization.words,
                    ),
                    const SizedBox(height: 16),
                    _FormField(
                      label: 'Alamat Detail Gudang',
                      hint: 'Contoh: Jl. Pemuda No. 15',
                      controller: _addressCtrl,
                      textCapitalization: TextCapitalization.sentences,
                      maxLines: 3,
                    ),
                    const SizedBox(height: 32),
                    // Wrap the Save button to look premium or match other roles
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

  static const Color distributorBlue = Color(0xFF1D6FA4);

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
                color: distributorBlue,
                width: 2,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

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
