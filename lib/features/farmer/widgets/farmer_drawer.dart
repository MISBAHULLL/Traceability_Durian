import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../auth/screens/home_screen.dart';
import '../data/farmer_repository.dart';
import '../farmer_routes.dart';
import '../screens/about_screen.dart';
import '../screens/farm_management_screen.dart';
import '../screens/farmer_profile_screen.dart';
import '../screens/help_screen.dart';

// [FE - Component Rendering] FarmerDrawer adalah navigation drawer utama
// role Petani — dibuka dari ikon hamburger Beranda. Menggantikan pemakaian
// hamburger satu-tujuan dengan menu navigasi penuh (pola standar mobile).
//
// Setiap aksi navigasi menutup drawer dulu (Navigator.pop) sebelum
// mendorong layar tujuan, agar drawer tidak tertinggal di belakang.
/// Drawer navigasi utama untuk Beranda Petani.
class FarmerDrawer extends StatelessWidget {
  const FarmerDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final profile = FarmerRepository.instance.profile;

    return Drawer(
      backgroundColor: AppColors.white,
      child: SafeArea(
        child: Column(
          children: [
            // ── Header profil ────────────────────────────────────────────
            _DrawerHeader(
              fullName: profile.fullName,
              roleLabel: profile.roleLabel,
              onTap: () => _go(context, const FarmerProfileScreen()),
            ),

            const Divider(height: 1, color: Color(0xFFE5E7EB)),

            // ── Grup navigasi utama ──────────────────────────────────────
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  _DrawerItem(
                    icon: Icons.home_rounded,
                    label: 'Beranda',
                    // Beranda adalah layar di belakang drawer; cukup tutup.
                    onTap: () => Navigator.pop(context),
                  ),
                  _DrawerItem(
                    icon: Icons.grass_rounded,
                    label: 'Kelola Kebun',
                    onTap: () => _go(context, const FarmManagementScreen()),
                  ),
                  _DrawerItem(
                    icon: Icons.person_outline_rounded,
                    label: 'Profil',
                    onTap: () => _go(context, const FarmerProfileScreen()),
                  ),

                  const Padding(
                    padding: EdgeInsets.fromLTRB(20, 12, 20, 4),
                    child: Divider(color: Color(0xFFE5E7EB)),
                  ),

                  // ── Grup sekunder ──────────────────────────────────────
                  _DrawerItem(
                    icon: Icons.help_outline_rounded,
                    label: 'Bantuan & Panduan',
                    onTap: () => _go(context, const HelpScreen()),
                  ),
                  _DrawerItem(
                    icon: Icons.info_outline_rounded,
                    label: 'Tentang',
                    onTap: () => _go(context, const AboutScreen()),
                  ),
                ],
              ),
            ),

            const Divider(height: 1, color: Color(0xFFE5E7EB)),

            // ── Footer: keluar ───────────────────────────────────────────
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

  // [FE - Event Handler] _go menutup drawer lalu mendorong [page] — pola
  // navigasi standar agar drawer tidak menumpuk di stack.
  void _go(BuildContext context, Widget page) {
    Navigator.pop(context); // tutup drawer
    FarmerRoutes.push(context, page);
  }

  // [FE - Event Handler] _confirmLogout menampilkan dialog konfirmasi
  // sebelum mengakhiri sesi — mencegah logout tak sengaja.
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
    // Pastikan widget masih terpasang sebelum memakai context lagi (lint-safe).
    if (!context.mounted) return;

    // Reset sesi mock lalu bersihkan stack ke layar masuk.
    FarmerRepository.instance.logout();
    navigator.pop(); // tutup drawer
    FarmerRoutes.replaceAll(context, const HomeScreen());
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sub-widgets
// ─────────────────────────────────────────────────────────────────────────────

/// Header drawer berisi avatar inisial, nama, dan label peran petani.
class _DrawerHeader extends StatelessWidget {
  const _DrawerHeader({
    required this.fullName,
    required this.roleLabel,
    required this.onTap,
  });

  final String fullName;
  final String roleLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
        child: Row(
          children: [
            // Avatar inisial
            Container(
              width: 52,
              height: 52,
              decoration: const BoxDecoration(
                color: AppColors.primaryContainer,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                _initials(fullName),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.white,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fullName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.black,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    roleLabel,
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

  /// Mengambil dua huruf pertama dari nama untuk avatar inisial.
  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
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

  /// Warna kustom (mis. merah untuk Keluar). Default hitam/hijau standar.
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
