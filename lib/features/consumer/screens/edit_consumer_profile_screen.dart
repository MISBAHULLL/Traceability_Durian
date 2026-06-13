import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_top_bar.dart';
import '../../../shared/widgets/primary_pill_button.dart';
import '../../../shared/widgets/top_notification_banner.dart';
import '../data/consumer_repository.dart';

class EditConsumerProfileScreen extends StatefulWidget {
  const EditConsumerProfileScreen({super.key});

  @override
  State<EditConsumerProfileScreen> createState() =>
      _EditConsumerProfileScreenState();
}

class _EditConsumerProfileScreenState extends State<EditConsumerProfileScreen> {
  final _repo = ConsumerRepository.instance;
  final _notification = TopNotification();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _locationCtrl;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final profile = _repo.profile;
    _nameCtrl = TextEditingController(text: profile.fullName);
    _phoneCtrl = TextEditingController(text: _phoneFieldValue(profile.contact));
    _emailCtrl = TextEditingController(text: profile.email);
    _locationCtrl = TextEditingController(text: profile.location);
  }

  @override
  void dispose() {
    _notification.dispose();
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _locationCtrl.dispose();
    super.dispose();
  }

  String _phoneFieldValue(String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('62')) return digits.substring(2);
    if (digits.startsWith('0')) return digits.substring(1);
    return digits;
  }

  Future<void> _submit() async {
    final name = _nameCtrl.text.trim();
    final phone = _phoneCtrl.text.replaceAll(RegExp(r'\D'), '');
    final email = _emailCtrl.text.trim();
    if (name.isEmpty || phone.length < 9 || phone.length > 13) {
      _notification.show(
        context,
        'Nama dan nomor HP wajib diisi dengan benar.',
        isError: true,
      );
      return;
    }
    if (!RegExp(r'^[\w\.\+\-]+@[\w\-]+\.[a-zA-Z]{2,}$').hasMatch(email)) {
      _notification.show(context, 'Format email tidak valid.', isError: true);
      return;
    }

    setState(() => _isSubmitting = true);
    await Future.delayed(const Duration(milliseconds: 350));
    if (!mounted) return;
    _repo.updateProfile(
      fullName: name,
      contact: '+62 $phone',
      email: email,
      location: _locationCtrl.text,
    );
    setState(() => _isSubmitting = false);
    _notification.show(context, 'Profil konsumen berhasil diperbarui.');
    await Future.delayed(const Duration(milliseconds: 900));
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
                  children: [
                    _Field(label: 'Nama Lengkap', controller: _nameCtrl),
                    const SizedBox(height: 16),
                    _Field(
                      label: 'Nomor HP',
                      controller: _phoneCtrl,
                      prefixText: '+62  ',
                      keyboardType: TextInputType.phone,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(13),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _Field(
                      label: 'Email',
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),
                    _Field(
                      label: 'Domisili',
                      controller: _locationCtrl,
                      maxLines: 2,
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

class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.controller,
    this.prefixText,
    this.keyboardType,
    this.inputFormatters,
    this.maxLines = 1,
  });
  final String label;
  final TextEditingController controller;
  final String? prefixText;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
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
            fontWeight: FontWeight.w700,
            color: AppColors.subtitle,
          ),
        ),
        const SizedBox(height: 7),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          maxLines: maxLines,
          decoration: InputDecoration(
            prefixText: prefixText,
            filled: true,
            fillColor: AppColors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFD5E3CF)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFD5E3CF)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
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
