import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../auth/screens/home_screen.dart';
import '../consumer_routes.dart';
import '../data/consumer_repository.dart';
import '../models/consumer_product.dart';
import '../screens/consumer_about_screen.dart';
import '../screens/consumer_audit_trail_screen.dart';
import '../screens/consumer_help_screen.dart';
import '../screens/consumer_profile_screen.dart';
import 'consumer_avatar.dart';

class ConsumerDrawer extends StatelessWidget {
  const ConsumerDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final profile = ConsumerRepository.instance.profile;
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
            onTap: () => _go(context, const ConsumerProfileScreen()),
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
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.popUntil(context, (route) => route.isFirst);
                  },
                ),
                _DrawerItem(
                  icon: Icons.person_outline_rounded,
                  label: 'Profil',
                  onTap: () => _go(context, const ConsumerProfileScreen()),
                ),
                _DrawerItem(
                  icon: Icons.fact_check_outlined,
                  label: 'Audit Trail',
                  onTap: () => _go(context, const ConsumerAuditTrailScreen()),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                  child: Divider(color: Color(0xFFE5E7EB), height: 1),
                ),
                _DrawerItem(
                  icon: Icons.help_outline_rounded,
                  label: 'Bantuan & Panduan',
                  onTap: () => _go(context, const ConsumerHelpScreen()),
                ),
                _DrawerItem(
                  icon: Icons.info_outline_rounded,
                  label: 'Tentang',
                  onTap: () => _go(context, const ConsumerAboutScreen()),
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
    ConsumerRoutes.push(context, page);
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final navigator = Navigator.of(context);
    final confirmed = await _showLogoutDialog(context);
    if (!confirmed || !context.mounted) return;
    ConsumerRepository.instance.logout();
    navigator.pop();
    ConsumerRoutes.replaceAll(context, const HomeScreen());
  }
}

class _DrawerHeader extends StatelessWidget {
  const _DrawerHeader({required this.profile, required this.onTap});
  final ConsumerProfile profile;
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
                  child: ConsumerAvatar(profile: profile, size: 58),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile.fullName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
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
                          profile.roleLabel,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
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
    final color = isDestructive ? const Color(0xFFDC2626) : AppColors.primary;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Material(
        color: isDestructive ? const Color(0xFFFEF2F2) : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 22, color: color),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: isDestructive ? color : AppColors.subtitle,
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

Future<bool> _showLogoutDialog(BuildContext context) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: AppColors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Row(
        children: [
          Icon(Icons.warning_rounded, color: Color(0xFFDC2626)),
          SizedBox(width: 12),
          Text('Keluar Akun?', style: TextStyle(fontWeight: FontWeight.w800)),
        ],
      ),
      content: const Text(
        'Anda akan keluar dari sesi ini dan kembali ke halaman masuk.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Batal'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, true),
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
  return result == true;
}
