import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../auth/screens/home_screen.dart';
import '../data/distributor_repository.dart';
import '../distributor_routes.dart';
import '../models/distributor_profile.dart';
import '../screens/distributor_history_screen.dart';
import '../screens/distributor_profile_screen.dart';
import '../screens/distributor_scan_qr_screen.dart';
import 'distributor_avatar.dart';

// [FE - Component Rendering] DistributorDrawer adalah navigation drawer utama
// role Distributor — dibuka dari ikon hamburger Beranda. Pola identik dengan
// FarmerDrawer dan CollectorDrawer agar konsisten di seluruh aplikasi.
/// Drawer navigasi utama untuk Beranda Distributor.
class DistributorDrawer extends StatelessWidget {
  const DistributorDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final profile = DistributorRepository.instance.profile;

    return Drawer(
      backgroundColor: AppColors.white,
      child: SafeArea(
        child: Column(
          children: [
            _DrawerHeader(
              profile: profile,
              onTap: () => _go(context, const DistributorProfileScreen()),
            ),
            const Divider(height: 1, color: Color(0xFFE5E7EB)),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  _DrawerItem(
                    icon: Icons.home_rounded,
                    label: 'Beranda',
                    onTap: () => Navigator.pop(context),
                  ),
                  _DrawerItem(
                    icon: Icons.qr_code_scanner_rounded,
                    label: 'Scan QR Pengiriman',
                    onTap: () => _go(context, const DistributorScanQrScreen()),
                  ),
                  _DrawerItem(
                    icon: Icons.local_shipping_outlined,
                    label: 'Pengiriman Aktif',
                    onTap: () {
                      Navigator.pop(context);
                      // Screen pengiriman aktif akan dihubungkan di sini.
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.history_rounded,
                    label: 'Riwayat Pengiriman',
                    onTap: () => _go(context, const DistributorHistoryScreen()),
                  ),
                  _DrawerItem(
                    icon: Icons.person_outline_rounded,
                    label: 'Profil',
                    onTap: () => _go(context, const DistributorProfileScreen()),
                  ),
                  const Divider(
                    height: 18,
                    color: Color(0xFFE5E7EB),
                    indent: 20,
                    endIndent: 20,
                  ),
                  _DrawerItem(
                    icon: Icons.help_outline_rounded,
                    label: 'Bantuan & Panduan',
                    onTap: () {
                      Navigator.pop(context);
                      // Screen bantuan akan dihubungkan di sini.
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.info_outline_rounded,
                    label: 'Tentang',
                    onTap: () {
                      Navigator.pop(context);
                      // Screen tentang aplikasi akan dihubungkan di sini.
                    },
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFE5E7EB)),
            _DrawerItem(
              icon: Icons.logout_rounded,
              label: 'Keluar',
              color: const Color(0xFFDC2626),
              onTap: () => _confirmLogout(context),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // [FE - Event Handler] _go menutup drawer lalu mendorong [page].
  void _go(BuildContext context, Widget page) {
    Navigator.pop(context); // tutup drawer
    DistributorRoutes.push(context, page);
  }

  // [FE - Event Handler] _confirmLogout menampilkan dialog konfirmasi sebelum
  // mengakhiri sesi — mencegah logout tak sengaja.
  Future<void> _confirmLogout(BuildContext context) async {
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
    if (!context.mounted) return;

    DistributorRepository.instance.logout();
    navigator.pop(); // tutup drawer
    DistributorRoutes.replaceAll(context, const HomeScreen());
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sub-widgets
// ─────────────────────────────────────────────────────────────────────────────

/// Header drawer berisi avatar foto/inisial, nama, dan label peran distributor.
class _DrawerHeader extends StatelessWidget {
  const _DrawerHeader({required this.profile, required this.onTap});

  final DistributorProfile profile;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final subtitle = profile.businessName.isEmpty
        ? profile.roleLabel
        : profile.businessName;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
        child: Row(
          children: [
            DistributorAvatar(profile: profile, size: 52),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    profile.fullName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.black,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.placeholder,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}

/// Satu baris item menu di dalam drawer.
class _DrawerItem extends StatelessWidget {
  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final itemColor = color ?? AppColors.black;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 22, color: color ?? AppColors.primary),
            const SizedBox(width: 16),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: itemColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
