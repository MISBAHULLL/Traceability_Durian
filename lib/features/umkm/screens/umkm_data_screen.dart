import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_top_bar.dart';
import '../../../shared/widgets/primary_pill_button.dart';
import '../data/umkm_repository.dart';
import '../models/umkm_profile.dart';

class UmkmDataScreen extends StatefulWidget {
  const UmkmDataScreen({super.key});

  @override
  State<UmkmDataScreen> createState() => _UmkmDataScreenState();
}

class _UmkmDataScreenState extends State<UmkmDataScreen> {
  final _repo = UmkmRepository.instance;
  late final UmkmProfile _profile;
  late final TextEditingController _nameCtrl;
  late final TextEditingController _ownerCtrl;
  late final TextEditingController _contactCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _locationCtrl;
  late final TextEditingController _aboutCtrl;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _profile = _repo.profile;
    _nameCtrl = TextEditingController(text: _profile.name);
    _ownerCtrl = TextEditingController(text: _profile.ownerName);
    _contactCtrl = TextEditingController(text: _profile.contact);
    _emailCtrl = TextEditingController(text: _profile.email);
    _locationCtrl = TextEditingController(text: _profile.location);
    _aboutCtrl = TextEditingController(text: _profile.about);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _ownerCtrl.dispose();
    _contactCtrl.dispose();
    _emailCtrl.dispose();
    _locationCtrl.dispose();
    _aboutCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    setState(() => _isSaving = true);
    final updatedProfile = _profile.copyWith(
      name: _nameCtrl.text.trim(),
      ownerName: _ownerCtrl.text.trim(),
      contact: _contactCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      location: _locationCtrl.text.trim(),
      about: _aboutCtrl.text.trim(),
    );
    await Future.delayed(const Duration(milliseconds: 500));
    _repo.updateProfile(updatedProfile);
    if (!mounted) return;
    setState(() => _isSaving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Data UMKM berhasil diperbarui')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const PreferredSize(
        preferredSize: Size.fromHeight(72),
        child: AppTopBar(title: 'Data UMKM'),
      ),
      backgroundColor: AppColors.white,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Perbarui Data Usaha',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.black,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Perbarui informasi usaha, kontak, dan deskripsi UMKM Anda.',
                style: TextStyle(fontSize: 12, color: AppColors.placeholder, height: 1.5),
              ),
              const SizedBox(height: 20),
              _buildField(label: 'Nama UMKM', controller: _nameCtrl),
              const SizedBox(height: 14),
              _buildField(label: 'Nama Pemilik', controller: _ownerCtrl),
              const SizedBox(height: 14),
              _buildField(
                label: 'Kontak',
                controller: _contactCtrl,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 14),
              _buildField(
                label: 'Email',
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 14),
              _buildField(label: 'Lokasi', controller: _locationCtrl),
              const SizedBox(height: 14),
              _buildField(label: 'Tentang UMKM', controller: _aboutCtrl, maxLines: 4),
              const SizedBox(height: 24),
              PrimaryPillButton(
                label: 'Simpan Perubahan',
                isLoading: _isSaving,
                onPressed: _isSaving ? null : _saveProfile,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.black,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          decoration: const InputDecoration(
            filled: true,
            fillColor: AppColors.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(14)),
              borderSide: BorderSide.none,
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }
}
