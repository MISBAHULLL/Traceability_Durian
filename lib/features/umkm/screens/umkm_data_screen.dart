import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

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
  final _imagePicker = ImagePicker();
  String? _imagePath;
  Uint8List? _imageBytes;
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
    _imagePath = _profile.imagePath;
    _imageBytes = _profile.imageBytes;
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

  Future<void> _pickImage() async {
    final image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (!mounted || image == null) return;
    final bytes = await image.readAsBytes();
    setState(() {
      _imagePath = image.path;
      _imageBytes = bytes;
    });
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
      imagePath: _imagePath,
      imageBytes: _imageBytes,
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
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            const AppTopBar(title: 'Data UMKM'),
            Expanded(
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
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.placeholder,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _SectionCard(
                      title: 'Foto UMKM',
                      children: [
                        _ImagePickerCard(
                          imagePath: _imagePath,
                          imageBytes: _imageBytes,
                          onPick: _pickImage,
                          onClear: _imagePath == null
                              ? null
                              : () => setState(() {
                                  _imagePath = null;
                                  _imageBytes = null;
                                }),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _SectionCard(
                      title: 'Informasi Dasar',
                      children: [
                        _buildField(label: 'Nama UMKM', controller: _nameCtrl),
                        const SizedBox(height: 14),
                        _buildField(
                          label: 'Nama Pemilik',
                          controller: _ownerCtrl,
                        ),
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
                      ],
                    ),
                    const SizedBox(height: 16),
                    _SectionCard(
                      title: 'Lokasi & Profil',
                      children: [
                        _buildField(label: 'Lokasi', controller: _locationCtrl),
                        const SizedBox(height: 14),
                        _buildField(
                          label: 'Tentang UMKM',
                          controller: _aboutCtrl,
                          maxLines: 4,
                        ),
                      ],
                    ),
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
          ],
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

class _ImagePickerCard extends StatelessWidget {
  const _ImagePickerCard({
    required this.imagePath,
    required this.imageBytes,
    required this.onPick,
    required this.onClear,
  });

  final String? imagePath;
  final Uint8List? imageBytes;
  final VoidCallback onPick;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            height: 170,
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            clipBehavior: Clip.antiAlias,
            child: kIsWeb
                ? imageBytes != null
                      ? Image.memory(
                          imageBytes!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => const _ImagePlaceholder(),
                        )
                      : const _ImagePlaceholder()
                : imagePath != null && imagePath!.isNotEmpty
                ? Image.file(
                    File(imagePath!),
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const _ImagePlaceholder(),
                  )
                : const _ImagePlaceholder(),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onPick,
                  icon: const Icon(Icons.photo_library_outlined, size: 18),
                  label: const Text('Pilih Foto UMKM'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primaryContainer,
                    side: const BorderSide(color: Color(0xFFE5E7EB)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              if (onClear != null) ...[
                const SizedBox(width: 10),
                IconButton(
                  onPressed: onClear,
                  icon: const Icon(Icons.delete_outline_rounded),
                  color: const Color(0xFFB91C1C),
                  splashRadius: 22,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.storefront_outlined,
            size: 42,
            color: AppColors.placeholder,
          ),
          SizedBox(height: 8),
          Text(
            'Tambahkan gambar UMKM',
            style: TextStyle(fontSize: 12, color: AppColors.placeholder),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppColors.black,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}
