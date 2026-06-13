import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_top_bar.dart';
import '../../auth/screens/home_screen.dart';
import '../data/distributor_repository.dart';
import '../distributor_routes.dart';
import '../models/distributor_profile.dart';
import '../widgets/distributor_avatar.dart';
import 'edit_distributor_profile_screen.dart';

const String _kNotSet = 'Belum dilengkapi';

// [FE - Component Rendering] Screen ini menjadi tampilan profil read-only
// distributor agar mode melihat data tidak bercampur dengan mode edit form.
class DistributorProfileScreen extends StatefulWidget {
  const DistributorProfileScreen({super.key});

  @override
  State<DistributorProfileScreen> createState() =>
      _DistributorProfileScreenState();
}

class _DistributorProfileScreenState extends State<DistributorProfileScreen> {
  final _repo = DistributorRepository.instance;

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
    if (mounted) {
      setState(() {});
    }
  }

  // [FE - Event Handler] Membuka form edit sebagai aksi eksplisit dari profil
  // read-only, lalu listener repository memperbarui tampilan saat kembali.
  Future<void> _openEditProfile() async {
    await DistributorRoutes.push(context, const EditDistributorProfileScreen());
  }

  // [FE - Event Handler] Logout distributor memastikan sesi mock tersimpan
  // dan stack navigasi dibersihkan ke layar masuk.
  Future<void> _confirmLogout() async {
    final navigator = Navigator.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.white,
        title: const Text('Keluar dari akun?'),
        content: const Text(
          'Anda akan keluar dari sesi ini dan kembali ke halaman masuk.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: const Text(
              'Batal',
              style: TextStyle(color: AppColors.placeholder),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, true),
            child: const Text(
              'Keluar',
              style: TextStyle(
                color: Color(0xFFDC2626),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (!mounted) return;

    _repo.logout();
    DistributorRoutes.replaceAll(navigator.context, const HomeScreen());
  }

  @override
  Widget build(BuildContext context) {
    final profile = _repo.profile;

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            AppTopBar(
              title: 'Profil',
              actions: [
                IconButton(
                  onPressed: _openEditProfile,
                  icon: const Icon(
                    Icons.edit_outlined,
                    color: AppColors.black,
                    size: 22,
                  ),
                  tooltip: 'Ubah Profil',
                ),
              ],
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                children: [
                  _ProfileHeader(profile: profile),
                  const SizedBox(height: 22),
                  _MetricsRow(repo: _repo),
                  const SizedBox(height: 24),
                  const _SectionTitle(title: 'Informasi Akun'),
                  const SizedBox(height: 10),
                  _InfoTile(
                    icon: Icons.business_outlined,
                    label: 'Nama Usaha/Hub',
                    value: _valueOrPlaceholder(profile.businessName),
                    isEmpty: profile.businessName.isEmpty,
                  ),
                  _InfoTile(
                    icon: Icons.badge_outlined,
                    label: 'Peran',
                    value: profile.roleLabel,
                  ),
                  _InfoTile(
                    icon: Icons.phone_outlined,
                    label: 'Nomor HP',
                    value: _valueOrPlaceholder(profile.contact),
                    isEmpty: profile.contact.isEmpty,
                  ),
                  _InfoTile(
                    icon: Icons.email_outlined,
                    label: 'Email',
                    value: _valueOrPlaceholder(profile.email),
                    isEmpty: profile.email.isEmpty,
                  ),
                  const SizedBox(height: 14),
                  const _SectionTitle(title: 'Lokasi Operasional'),
                  const SizedBox(height: 10),
                  _InfoTile(
                    icon: Icons.place_outlined,
                    label: 'Lokasi Ringkas',
                    value: _composeLocation(profile),
                    isEmpty: _composeLocation(profile) == _kNotSet,
                  ),
                  _InfoTile(
                    icon: Icons.map_outlined,
                    label: 'Alamat Detail Gudang',
                    value: _valueOrPlaceholder(profile.address),
                    isEmpty: profile.address.isEmpty,
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _openEditProfile,
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('Ubah Profil & Lokasi'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                        shape: const StadiumBorder(),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        textStyle: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _confirmLogout,
                      icon: const Icon(
                        Icons.logout_rounded,
                        color: Color(0xFFDC2626),
                      ),
                      label: const Text(
                        'Keluar',
                        style: TextStyle(
                          color: Color(0xFFDC2626),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFDC2626)),
                        shape: const StadiumBorder(),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.profile});

  final DistributorProfile profile;

  @override
  Widget build(BuildContext context) {
    final subtitle = profile.businessName.isEmpty
        ? profile.roleLabel
        : profile.businessName;

    return Column(
      children: [
        DistributorAvatar(profile: profile, size: 96, showEditButton: true),
        const SizedBox(height: 14),
        Text(
          profile.fullName,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: AppColors.black,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }
}

// [FE - Component Rendering] Metrics ringkas memberi konteks operasional
// distributor tanpa harus membuka beranda.
class _MetricsRow extends StatelessWidget {
  const _MetricsRow({required this.repo});

  final DistributorRepository repo;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _MetricCard(
            value: '${repo.totalKirim}',
            label: 'Total Kirim',
            icon: Icons.inventory_2_outlined,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _MetricCard(
            value: '${repo.transit}',
            label: 'Transit',
            icon: Icons.local_shipping_outlined,
            color: const Color(0xFFB45309),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _MetricCard(
            value: '${repo.tiba}',
            label: 'Tiba',
            icon: Icons.task_alt_rounded,
            color: const Color(0xFF1D6FA4),
          ),
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });

  final String value;
  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: color,
              height: 1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.placeholder,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w900,
        color: AppColors.black,
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    this.isEmpty = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool isEmpty;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.placeholder,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    height: 1.35,
                    color: isEmpty ? AppColors.placeholder : AppColors.black,
                    fontStyle: isEmpty ? FontStyle.italic : FontStyle.normal,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _valueOrPlaceholder(String value) {
  return value.trim().isEmpty ? _kNotSet : value.trim();
}

// [UTIL - Helper Function] Lokasi distributor dirakit dari komponen alamat
// agar ringkasan profil tetap konsisten dengan edit profile.
String _composeLocation(DistributorProfile profile) {
  final parts = <String>[
    if (profile.village.trim().isNotEmpty) profile.village.trim(),
    if (profile.district.trim().isNotEmpty) 'Kec. ${profile.district.trim()}',
    if (profile.city.trim().isNotEmpty) profile.city.trim(),
  ];
  if (parts.isNotEmpty) return parts.join(', ');
  return profile.location.trim().isEmpty ? _kNotSet : profile.location.trim();
}
