import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_top_bar.dart';
import '../../auth/screens/home_screen.dart';
import '../data/umkm_repository.dart';
import '../models/umkm_profile.dart';
import '../umkm_routes.dart';
import '../widgets/umkm_avatar.dart';
import 'umkm_data_screen.dart';

const String _kNotSet = 'Belum dilengkapi';
const Color _profileGreen = Color.fromARGB(255, 88, 168, 53);

class UmkmProfileScreen extends StatefulWidget {
  const UmkmProfileScreen({super.key});

  @override
  State<UmkmProfileScreen> createState() => _UmkmProfileScreenState();
}

class _UmkmProfileScreenState extends State<UmkmProfileScreen> {
  final _repo = UmkmRepository.instance;

  @override
  void initState() {
    super.initState();
    _repo.addListener(_onRepoChanged);
  }

  @override
  void dispose() {
    _repo.removeListener(_onRepoChanged);
    super.dispose();
  }

  void _onRepoChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _openEditProfile() async {
    await UmkmRoutes.push(context, const UmkmDataScreen());
  }

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_rounded, color: Color(0xFFDC2626), size: 28),
            SizedBox(width: 12),
            Text(
              'Keluar Akun?',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
            ),
          ],
        ),
        content: const Text(
          'Anda akan keluar dari sesi ini dan kembali ke halaman masuk. Pastikan semua data telah tersimpan.',
          style: TextStyle(
            color: AppColors.subtitle,
            height: 1.5,
            fontSize: 15,
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        actions: [
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Batal',
                    style: TextStyle(
                      color: AppColors.placeholder,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(dialogContext, true),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: const Color(0xFFDC2626),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Keluar',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    UmkmRoutes.replaceAll(context, const HomeScreen());
  }

  @override
  Widget build(BuildContext context) {
    final profile = _repo.profile;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F7EC),
      body: SafeArea(
        child: Column(
          children: [
            AppTopBar(
              title: 'Profil',
              actions: [
                _ProfileIconButton(
                  icon: Icons.edit_rounded,
                  tooltip: 'Ubah Profil',
                  onPressed: _openEditProfile,
                ),
              ],
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(14, 24, 14, 40),
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    _BentoCard(
                      borderRadius: 30,
                      color: const Color(0xFFFAFCF8),
                      padding: const EdgeInsets.fromLTRB(24, 26, 24, 24),
                      child: _ProfileHeader(
                        profile: profile,
                        onEdit: _openEditProfile,
                      ),
                    ),
                    const SizedBox(height: 26),
                    _ProfileInfoSection(profile: profile),
                    const SizedBox(height: 32),
                    _LogoutButton(onPressed: _confirmLogout),
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

class _BentoCard extends StatelessWidget {
  const _BentoCard({
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.borderRadius = 24,
    this.color = Colors.white,
    this.borderColor = const Color(0xFFD5E3CF),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final Color color;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: borderColor, width: 1.2),
      ),
      child: child,
    );
  }
}

class _ProfileIconButton extends StatelessWidget {
  const _ProfileIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: Material(
        color: const Color(0xFFF8FBF5),
        shape: const CircleBorder(
          side: BorderSide(color: Colors.white, width: 1.2),
        ),
        child: IconButton(
          onPressed: onPressed,
          tooltip: tooltip,
          icon: Icon(icon, color: _profileGreen, size: 20),
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.profile, required this.onEdit});

  final UmkmProfile profile;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 4),
          ),
          child: UmkmAvatar(
            profile: profile,
            size: 96,
            showEditButton: true,
            onEdit: onEdit,
          ),
        ),
        const SizedBox(height: 18),
        Text(
          _valueOrPlaceholder(profile.ownerName),
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 23,
            fontWeight: FontWeight.w800,
            color: AppColors.subtitle,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
          decoration: BoxDecoration(
            color: const Color(0xFFFDFEFB),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: _profileGreen.withValues(alpha: 0.28)),
          ),
          child: const Text(
            'Pemilik UMKM',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: _profileGreen,
            ),
          ),
        ),
      ],
    );
  }
}

class _ProfileInfoSection extends StatelessWidget {
  const _ProfileInfoSection({required this.profile});

  final UmkmProfile profile;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 7, bottom: 12),
          child: Text(
            'INFORMASI DETAIL',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: AppColors.placeholder,
              letterSpacing: 1.2,
            ),
          ),
        ),
        LayoutBuilder(
          builder: (context, constraints) {
            final useColumns = constraints.maxWidth >= 310;
            final businessCard = _InfoCard(
              icon: Icons.storefront_outlined,
              label: 'NAMA UMKM',
              value: _valueOrPlaceholder(profile.name),
              isEmpty: profile.name.trim().isEmpty,
            );
            final contactCard = _InfoCard(
              icon: Icons.phone_outlined,
              label: 'KONTAK',
              value: _valueOrPlaceholder(profile.contact),
              isEmpty: profile.contact.trim().isEmpty,
            );

            return Column(
              children: [
                if (useColumns)
                  Row(
                    children: [
                      Expanded(child: businessCard),
                      const SizedBox(width: 14),
                      Expanded(child: contactCard),
                    ],
                  )
                else ...[
                  businessCard,
                  const SizedBox(height: 14),
                  contactCard,
                ],
                const SizedBox(height: 14),
                _InfoCard(
                  icon: Icons.mail_outline_rounded,
                  label: 'ALAMAT EMAIL',
                  value: _valueOrPlaceholder(profile.email),
                  isEmpty: profile.email.trim().isEmpty,
                  horizontal: true,
                ),
                const SizedBox(height: 14),
                _InfoCard(
                  icon: Icons.location_on_outlined,
                  label: 'LOKASI USAHA',
                  value: _valueOrPlaceholder(profile.location),
                  isEmpty: profile.location.trim().isEmpty,
                  horizontal: true,
                ),
                const SizedBox(height: 14),
                _InfoCard(
                  icon: Icons.info_outline_rounded,
                  label: 'TENTANG UMKM',
                  value: _valueOrPlaceholder(profile.about),
                  isEmpty: profile.about.trim().isEmpty,
                  horizontal: true,
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.label,
    required this.value,
    this.isEmpty = false,
    this.horizontal = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool isEmpty;
  final bool horizontal;

  @override
  Widget build(BuildContext context) {
    final valueText = Text(
      value,
      maxLines: horizontal ? 4 : 2,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: isEmpty ? AppColors.placeholder : AppColors.subtitle,
        fontStyle: isEmpty ? FontStyle.italic : FontStyle.normal,
        height: 1.3,
      ),
    );
    final labelText = Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        fontSize: 10.5,
        fontWeight: FontWeight.w800,
        color: AppColors.placeholder,
        letterSpacing: 0.35,
      ),
    );

    return _BentoCard(
      borderRadius: 24,
      padding: EdgeInsets.all(horizontal ? 18 : 20),
      child: horizontal
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _InfoIcon(icon: icon),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [labelText, const SizedBox(height: 5), valueText],
                  ),
                ),
              ],
            )
          : SizedBox(
              height: 90,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _InfoIcon(icon: icon),
                      const SizedBox(width: 12),
                      Expanded(child: labelText),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(width: double.infinity, child: valueText),
                ],
              ),
            ),
    );
  }
}

class _InfoIcon extends StatelessWidget {
  const _InfoIcon({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: const BoxDecoration(
        color: Color(0xFFE8F5E2),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Icon(icon, size: 21, color: _profileGreen),
    );
  }
}

class _LogoutButton extends StatelessWidget {
  const _LogoutButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return _BentoCard(
      borderRadius: 20,
      padding: EdgeInsets.zero,
      color: const Color(0xFFFFFDFC),
      borderColor: const Color(0xFFF1D3D3),
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          side: BorderSide.none,
          foregroundColor: const Color(0xFFDC2626),
          padding: const EdgeInsets.symmetric(vertical: 17),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout_rounded, size: 21),
            SizedBox(width: 10),
            Text(
              'Keluar Akun',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _valueOrPlaceholder(String value) {
  return value.trim().isEmpty ? _kNotSet : value.trim();
}
