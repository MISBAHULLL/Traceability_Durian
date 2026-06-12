import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../auth/screens/home_screen.dart';
import '../consumer_routes.dart';
import '../data/consumer_repository.dart';
import '../models/consumer_product.dart';
import '../screens/consumer_about_screen.dart';
import '../screens/consumer_help_screen.dart';
import '../screens/consumer_profile_screen.dart';

/// Drawer navigasi utama untuk konsumen.
class ConsumerDrawer extends StatelessWidget {
  const ConsumerDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final profile = ConsumerRepository.instance.profile;

    return Drawer(
      backgroundColor: AppColors.white,
      child: SafeArea(
        child: Column(
          children: [
            _DrawerHeader(
              profile: profile,
              onTap: () {
                Navigator.pop(context);
                ConsumerRoutes.push(
                  context,
                  const ConsumerProfileScreen(),
                );
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
                      Navigator.popUntil(context, (route) => route.isFirst);
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.person_rounded,
                    label: 'Profil',
                    onTap: () {
                      Navigator.pop(context);
                      ConsumerRoutes.push(
                        context,
                        const ConsumerProfileScreen(),
                      );
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.help_outline_rounded,
                    label: 'Bantuan',
                    onTap: () {
                      Navigator.pop(context);
                      ConsumerRoutes.push(
                        context,
                        const ConsumerHelpScreen(),
                      );
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.info_outline_rounded,
                    label: 'Tentang',
                    onTap: () {
                      Navigator.pop(context);
                      ConsumerRoutes.push(
                        context,
                        const ConsumerAboutScreen(),
                      );
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
    Navigator.pop(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Keluar'),
        content: const Text('Yakin ingin keluar dari akun konsumen?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, true),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    ConsumerRepository.instance.logout();
    ConsumerRoutes.replaceAll(context, const HomeScreen());
  }
}

class _DrawerHeader extends StatelessWidget {
  const _DrawerHeader({required this.profile, required this.onTap});

  final ConsumerProfile profile;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
        decoration: const BoxDecoration(
          color: AppColors.primaryContainer,
        ),
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
                profile.fullName.isNotEmpty
                    ? profile.fullName.trim().substring(0, 1).toUpperCase()
                    : 'K',
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
                    profile.fullName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.white,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    profile.roleLabel,
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
