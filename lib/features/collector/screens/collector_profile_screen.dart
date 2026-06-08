import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_top_bar.dart';
import '../../auth/screens/home_screen.dart';
import '../collector_routes.dart';
import '../data/collector_repository.dart';
import '../widgets/collector_avatar.dart';
import 'edit_collector_profile_screen.dart';

// [FE - Component Rendering] Layar profil pengepul — menampilkan identitas
// akun dan aksi keluar (logout). Pola mengikuti Profil Petani.
/// Layar Profil untuk role Pengepul.
class CollectorProfileScreen extends StatefulWidget {
  const CollectorProfileScreen({super.key});

  @override
  State<CollectorProfileScreen> createState() => _CollectorProfileScreenState();
}

class _CollectorProfileScreenState extends State<CollectorProfileScreen> {
  final _repo = CollectorRepository.instance;

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

  // [FE - Event Handler] Membuka form edit profil pengepul melalui route
  // khusus agar halaman Profil tetap menjadi layar read-only ringkas.
  Future<void> _openEditProfile() async {
    await CollectorRoutes.push(context, const EditCollectorProfileScreen());
  }

  // [FE - Event Handler] _confirmLogout menampilkan dialog konfirmasi sebelum
  // mengakhiri sesi, lalu membersihkan stack ke layar masuk.
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
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (!mounted) return;

    _repo.logout();
    CollectorRoutes.replaceAll(navigator.context, const HomeScreen());
  }

  @override
  Widget build(BuildContext context) {
    final profile = _repo.profile;

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            const AppTopBar(title: 'Profil'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                children: [
                  // ── Header profil ──────────────────────────────────────
                  Center(
                    child: Column(
                      children: [
                        CollectorAvatar(
                          profile: profile,
                          size: 96,
                          showEditButton: true,
                        ),
                        const SizedBox(height: 14),
                        Text(
                          profile.fullName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.black,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryContainer
                                .withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            profile.roleLabel,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // ── Informasi akun ─────────────────────────────────────
                  const _SectionTitle(title: 'Informasi Akun'),
                  const SizedBox(height: 8),
                  _InfoTile(
                    icon: Icons.storefront_outlined,
                    label: 'Usaha/Lapak',
                    value: profile.businessName.isEmpty
                        ? 'Belum dilengkapi'
                        : profile.businessName,
                  ),
                  _InfoTile(
                    icon: Icons.badge_outlined,
                    label: 'Peran',
                    value: profile.roleLabel,
                  ),
                  _InfoTile(
                    icon: Icons.phone_outlined,
                    label: 'Nomor HP',
                    value: profile.contact.isEmpty
                        ? 'Belum dilengkapi'
                        : profile.contact,
                  ),
                  _InfoTile(
                    icon: Icons.email_outlined,
                    label: 'Email',
                    value: profile.email.isEmpty
                        ? 'Belum dilengkapi'
                        : profile.email,
                  ),
                  _InfoTile(
                    icon: Icons.place_outlined,
                    label: 'Lokasi',
                    value: profile.location.isEmpty
                        ? 'Belum dilengkapi'
                        : profile.location,
                  ),
                  _InfoTile(
                    icon: Icons.map_outlined,
                    label: 'Alamat Detail',
                    value: profile.address.isEmpty
                        ? 'Belum dilengkapi'
                        : profile.address,
                  ),
                  const SizedBox(height: 12),
                  // [FE - Component Rendering] Tombol ini menjadi pintu
                  // masuk form edit tanpa mencampur mode baca dan mode ubah.
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
                ],
              ),
            ),

            // ── Tombol keluar ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _confirmLogout,
                  icon: const Icon(Icons.logout_rounded,
                      color: Color(0xFFDC2626)),
                  label: const Text(
                    'Keluar',
                    style: TextStyle(
                      color: Color(0xFFDC2626),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFDC2626)),
                    shape: const StadiumBorder(),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ),
          ],
        ),
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
        fontWeight: FontWeight.w700,
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
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
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
                    color: AppColors.placeholder,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.black,
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
