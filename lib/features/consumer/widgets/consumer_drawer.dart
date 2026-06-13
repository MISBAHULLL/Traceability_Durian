import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/logout_confirmation_dialog.dart';
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
                ConsumerRoutes.push(context, const ConsumerProfileScreen());
              },
            ),
            const Divider(height: 1, color: Color(0xFFE5E7EB)),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
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
                      ConsumerRoutes.push(context, const ConsumerHelpScreen());
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.info_outline_rounded,
                    label: 'Tentang',
                    onTap: () {
                      Navigator.pop(context);
                      ConsumerRoutes.push(context, const ConsumerAboutScreen());
                    },
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFE5E7EB)),
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
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.primary,
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
                      color: AppColors.black,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(
                        Icons.person_outline_rounded,
                        size: 14,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          profile.roleLabel,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppColors.primary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
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
    final itemColor = isDestructive ? const Color(0xFFB91C1C) : AppColors.black;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Icon(
              icon,
              size: 22,
              color: isDestructive
                  ? const Color(0xFFB91C1C)
                  : AppColors.primary,
            ),
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
