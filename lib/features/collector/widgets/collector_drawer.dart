import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../auth/screens/home_screen.dart';
import '../collector_routes.dart';
import '../data/collector_repository.dart';
import '../models/collector_product.dart';
import '../screens/add_transaction_screen.dart';
import '../screens/collector_profile_screen.dart';
import '../screens/collector_scan_qr_screen.dart';
import 'collector_avatar.dart';

// [FE - Component Rendering] CollectorDrawer adalah navigation drawer utama
// role Pengepul — dibuka dari ikon hamburger Beranda. Pola identik dengan
// FarmerDrawer agar konsisten di seluruh aplikasi.
/// Drawer navigasi utama untuk Beranda Pengepul.
class CollectorDrawer extends StatelessWidget {
  const CollectorDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final profile = CollectorRepository.instance.profile;

    return Drawer(
      backgroundColor: AppColors.white,
      child: SafeArea(
        child: Column(
          children: [
            _DrawerHeader(
              profile: profile,
              onTap: () => _go(context, const CollectorProfileScreen()),
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
                    label: 'Scan QR',
                    onTap: () => _go(context, const CollectorScanQrScreen()),
                  ),
                  _DrawerItem(
                    icon: Icons.fact_check_outlined,
                    label: 'Verifikasi Manual',
                    onTap: () => _go(context, const AddTransactionScreen()),
                  ),
                  _DrawerItem(
                    icon: Icons.person_outline_rounded,
                    label: 'Profil',
                    onTap: () => _go(context, const CollectorProfileScreen()),
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
    CollectorRoutes.push(context, page);
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

    CollectorRepository.instance.logout();
    navigator.pop(); // tutup drawer
    CollectorRoutes.replaceAll(context, const HomeScreen());
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sub-widgets
// ─────────────────────────────────────────────────────────────────────────────

/// Header drawer berisi avatar foto/inisial, nama, dan label peran pengepul.
class _DrawerHeader extends StatelessWidget {
  const _DrawerHeader({required this.profile, required this.onTap});

  final CollectorProfile profile;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final subtitle =
        profile.businessName.isEmpty ? profile.roleLabel : profile.businessName;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
        child: Row(
          children: [
            CollectorAvatar(profile: profile, size: 52),
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
