import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../auth/screens/home_screen.dart';
import '../collector_routes.dart';
import '../data/collector_repository.dart';
import '../models/collector_product.dart';
import '../screens/add_transaction_screen.dart';
import '../screens/collector_about_screen.dart';
import '../screens/collector_help_screen.dart';
import '../screens/collector_history_screen.dart';
import '../screens/collector_profile_screen.dart';
import '../screens/collector_scan_qr_screen.dart';
import '../screens/collector_shipments_screen.dart';
import '../screens/collector_stock_screen.dart';
import '../screens/collector_warehouses_screen.dart';
import 'collector_avatar.dart';

class CollectorDrawer extends StatelessWidget {
  const CollectorDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final profile = CollectorRepository.instance.profile;

    return Drawer(
      backgroundColor: AppColors.surface,
      elevation: 0,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(28)),
      ),
      child: Column(
        children: [
          _DrawerHeader(
            profile: profile,
            onTap: () => _go(context, const CollectorProfileScreen()),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              physics: const BouncingScrollPhysics(),
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
                  icon: Icons.inventory_2_outlined,
                  label: 'Stok Saya',
                  onTap: () => _go(context, const CollectorStockScreen()),
                ),
                _DrawerItem(
                  icon: Icons.warehouse_outlined,
                  label: 'Kelola Gudang',
                  onTap: () => _go(context, const CollectorWarehousesScreen()),
                ),
                _DrawerItem(
                  icon: Icons.local_shipping_outlined,
                  label: 'Batch Pengiriman',
                  onTap: () => _go(context, const CollectorShipmentsScreen()),
                ),
                _DrawerItem(
                  icon: Icons.history_rounded,
                  label: 'Riwayat Aktivitas',
                  onTap: () => _go(context, const CollectorHistoryScreen()),
                ),
                _DrawerItem(
                  icon: Icons.person_outline_rounded,
                  label: 'Profil',
                  onTap: () => _go(context, const CollectorProfileScreen()),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                  child: Divider(color: Color(0xFFE5E7EB), height: 1),
                ),
                _DrawerItem(
                  icon: Icons.help_outline_rounded,
                  label: 'Bantuan & Panduan',
                  onTap: () => _go(context, const CollectorHelpScreen()),
                ),
                _DrawerItem(
                  icon: Icons.info_outline_rounded,
                  label: 'Tentang',
                  onTap: () => _go(context, const CollectorAboutScreen()),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
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

  void _go(BuildContext context, Widget page) {
    Navigator.pop(context);
    CollectorRoutes.push(context, page);
  }

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

    if (confirmed != true || !context.mounted) return;

    CollectorRepository.instance.logout();
    navigator.pop();
    CollectorRoutes.replaceAll(context, const HomeScreen());
  }
}

class _DrawerHeader extends StatelessWidget {
  const _DrawerHeader({required this.profile, required this.onTap});

  final CollectorProfile profile;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final subtitle = profile.businessName.isEmpty
        ? profile.roleLabel
        : profile.businessName;

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
                  child: CollectorAvatar(profile: profile, size: 58),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile.fullName,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: 8),
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
                          ),
                        ),
                        child: Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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

class _DrawerItem extends StatelessWidget {
  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final itemColor = isDestructive
        ? const Color(0xFFDC2626)
        : AppColors.primary;

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
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: itemColor.withValues(alpha: 0.12),
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
