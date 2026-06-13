import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/logout_confirmation_dialog.dart';
import '../../auth/screens/home_screen.dart';
import '../data/umkm_repository.dart';
import '../screens/umkm_add_product_screen.dart';
import '../screens/umkm_add_purchase_screen.dart';
import '../screens/umkm_data_screen.dart';
import '../screens/umkm_order_list_screen.dart';
import '../screens/umkm_profile_screen.dart';
import '../umkm_routes.dart';

/// Drawer navigasi utama untuk UMKM.
class UmkmDrawer extends StatelessWidget {
  const UmkmDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final profile = UmkmRepository.instance.profile;

    return Drawer(
      backgroundColor: AppColors.white,
      child: SafeArea(
        child: Column(
          children: [
            _DrawerHeader(
              profileName: profile.ownerName,
              roleLabel: 'UMKM',
              onTap: () {
                Navigator.pop(context);
                UmkmRoutes.push(context, const UmkmProfileScreen());
              },
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _DrawerItem(
                    icon: Icons.home_rounded,
                    label: 'Beranda',
                    onTap: () {
                      Navigator.pop(context);
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.person_rounded,
                    label: 'Profil',
                    onTap: () {
                      Navigator.pop(context);
                      UmkmRoutes.push(context, const UmkmProfileScreen());
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.badge_rounded,
                    label: 'Data UMKM',
                    onTap: () {
                      Navigator.pop(context);
                      UmkmRoutes.push(context, const UmkmDataScreen());
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.inventory_2_rounded,
                    label: 'Tambah Produk',
                    onTap: () {
                      Navigator.pop(context);
                      UmkmRoutes.push(context, const UmkmAddProductScreen());
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.shopping_bag_rounded,
                    label: 'Beli Stok',
                    onTap: () {
                      Navigator.pop(context);
                      UmkmRoutes.push(context, const UmkmAddPurchaseScreen());
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.receipt_long_rounded,
                    label: 'Daftar Pesanan',
                    onTap: () {
                      Navigator.pop(context);
                      UmkmRoutes.push(context, const UmkmOrderListScreen());
                    },
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            _DrawerItem(
              icon: Icons.logout_rounded,
              label: 'Keluar',
              isDestructive: true,
              onTap: () => _confirmLogout(context),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final navigator = Navigator.of(context);
    final confirmed = await showLogoutConfirmationDialog(context);

    if (confirmed != true) return;
    if (!context.mounted) return;
    navigator.pop();
    UmkmRoutes.replaceAll(context, const HomeScreen());
  }
}

class _DrawerHeader extends StatelessWidget {
  const _DrawerHeader({
    required this.profileName,
    required this.roleLabel,
    required this.onTap,
  });

  final String profileName;
  final String roleLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final initial = profileName.isNotEmpty
        ? profileName.trim().substring(0, 1).toUpperCase()
        : 'U';

    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
        decoration: const BoxDecoration(color: AppColors.primaryContainer),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.white.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                initial,
                style: const TextStyle(
                  fontSize: 22,
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
                    profileName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.white,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    roleLabel,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFFEAF7E5),
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
    return ListTile(
      leading: Icon(
        icon,
        color: isDestructive ? const Color(0xFFB91C1C) : AppColors.primary,
      ),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: isDestructive ? const Color(0xFFB91C1C) : AppColors.black,
        ),
      ),
      onTap: onTap,
    );
  }
}
