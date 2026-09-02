import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../auth/screens/home_screen.dart';
import '../data/farmer_repository.dart';
import '../farmer_routes.dart';
import '../models/harvest_batch.dart';
import '../screens/about_screen.dart';
import '../screens/farm_management_screen.dart';
import '../screens/farmer_notifications_screen.dart';
import '../screens/farmer_profile_screen.dart';
import '../screens/help_screen.dart';
import '../screens/ownership_history_screen.dart';
import 'farmer_avatar.dart';

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
      backgroundColor: AppColors.surface,
      elevation: 0,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // ── Header profil (Menggunakan Gradient & Glassmorphism) ──────────
          _DrawerHeader(
            profile: profile,
            onTap: () => _go(context, const FarmerProfileScreen()),
          ),

          const SizedBox(height: 12),

          // ── Grup navigasi utama ──────────────────────────────────────
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              physics: const BouncingScrollPhysics(),
              children: [
                _DrawerItem(
                  icon: Icons.home_rounded,
                  label: 'Beranda',
                  // Beranda adalah layar di belakang drawer; cukup tutup.
                  onTap: () => Navigator.pop(context),
                ),
                _DrawerItem(
                  icon: Icons.forest_rounded, // Ikon kebun yang lebih megah
                  label: 'Kelola Kebun',
                  onTap: () => _go(context, const FarmManagementScreen()),
                ),
                _DrawerItem(
                  icon: Icons.timeline_rounded,
                  label: 'Riwayat Perpindahan',
                  onTap: () => _go(context, const OwnershipHistoryScreen()),
                ),
                _DrawerItem(
                  icon: Icons.notifications_none_rounded,
                  label: 'Notifikasi',
                  onTap: () => _go(context, const FarmerNotificationsScreen()),
                ),
                _DrawerItem(
                  icon: Icons.person_outline_rounded,
                  label: 'Profil',
                  onTap: () => _go(context, const FarmerProfileScreen()),
                ),

                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                  child: Divider(color: Color(0xFFE5E7EB), height: 1),
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

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 28),
            child: Divider(color: Color(0xFFE5E7EB), height: 1),
          ),
          const SizedBox(height: 12),

          // ── Footer: keluar ───────────────────────────────────────────
          SafeArea(
            top: false,
            child: _DrawerItem(
              icon: Icons.power_settings_new_rounded,
              label: 'Keluar',
              isDestructive: true,
              onTap: () => _confirmLogout(context),
            ),
          ),
          const SizedBox(height: 16),
        ],
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
                  onPressed: () => Navigator.pop(dialogCtx, false),
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
                  onPressed: () => Navigator.pop(dialogCtx, true),
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

/// Header drawer berisi avatar foto/inisial, nama, dan label peran petani.
/// Sekarang menggunakan gradient premium dan efek glassmorphism.
class _DrawerHeader extends StatelessWidget {
  const _DrawerHeader({required this.profile, required this.onTap});

  final FarmerProfile profile;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Ink(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, AppColors.primaryContainer],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(24, topPadding + 32, 24, 32),
            child: Row(
              children: [
                // Avatar foto/inisial dengan border putih tebal & bayangan
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: FarmerAvatar(profile: profile, size: 58),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile.fullName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.4,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      // Glassmorphism effect untuk label role
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.35),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          profile.roleLabel,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.white70,
                  size: 26,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Satu baris item menu di dalam drawer dengan ikon dalam kotak membulat.
class _DrawerItem extends StatelessWidget {
  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
  }) : color = null;

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  /// Warna kustom. Jika null, akan memakai warna default atau merah jika destructive.
  final Color? color;

  /// Jika true, akan menggunakan styling merah/berbahaya (untuk Keluar).
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final defaultColor = isDestructive
        ? const Color(0xFFDC2626)
        : AppColors.primary;
    final itemColor = color ?? defaultColor;

    // Warna background ikon yang sangat soft
    final iconBgColor = itemColor.withValues(alpha: 0.12);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Material(
        color: isDestructive ? const Color(0xFFFEF2F2) : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          splashColor: itemColor.withValues(alpha: 0.1),
          highlightColor: itemColor.withValues(alpha: 0.05),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                // Ikon di dalam kotak squircle berwarna
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: iconBgColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 22, color: itemColor),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: isDestructive ? itemColor : AppColors.subtitle,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
                if (!isDestructive)
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: AppColors.placeholder.withValues(alpha: 0.5),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
