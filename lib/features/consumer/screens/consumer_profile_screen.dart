import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_top_bar.dart';
import '../../../shared/widgets/profile_header.dart';
import '../../../shared/widgets/profile_info_tile.dart';
import '../data/consumer_repository.dart';
import '../consumer_routes.dart';
import '../models/consumer_product.dart';
import '../../auth/screens/home_screen.dart';

/// Profil konsumen.
class ConsumerProfileScreen extends StatelessWidget {
  const ConsumerProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final profile = ConsumerRepository.instance.profile;

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            const AppTopBar(title: 'Profil'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
                children: [
                  const SizedBox(height: 8),
                  _Header(profile: profile),
                  const SizedBox(height: 24),
                  const Text(
                    'Informasi Akun',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.placeholder,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ProfileInfoTile(
                    icon: Icons.person_outline_rounded,
                    label: 'Nama Lengkap',
                    value: profile.fullName,
                    isEmpty: profile.fullName.isEmpty,
                  ),
                  const SizedBox(height: 12),
                  ProfileInfoTile(
                    icon: Icons.verified_user_outlined,
                    label: 'Peran',
                    value: profile.roleLabel,
                  ),
                  const SizedBox(height: 12),
                  ProfileInfoTile(
                    icon: Icons.phone_outlined,
                    label: 'Kontak',
                    value: profile.contact.isEmpty ? 'Belum dilengkapi' : profile.contact,
                    isEmpty: profile.contact.isEmpty,
                  ),
                  const SizedBox(height: 12),
                  ProfileInfoTile(
                    icon: Icons.mail_outline_rounded,
                    label: 'Email',
                    value: profile.email.isEmpty ? 'Belum dilengkapi' : profile.email,
                    isEmpty: profile.email.isEmpty,
                  ),
                  const SizedBox(height: 12),
                  ProfileInfoTile(
                    icon: Icons.location_on_outlined,
                    label: 'Domisili',
                    value: profile.location.isEmpty ? 'Belum dilengkapi' : profile.location,
                    isEmpty: profile.location.isEmpty,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        ConsumerRepository.instance.logout();
                        ConsumerRoutes.replaceAll(context, const HomeScreen());
                      },
                      icon: const Icon(
                        Icons.logout_rounded,
                        color: Color(0xFFDC2626),
                      ),
                      label: const Text(
                        'Keluar',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFDC2626),
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFDC2626)),
                        shape: const StadiumBorder(),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        foregroundColor: const Color(0xFFDC2626),
                      ),
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

class _Header extends StatelessWidget {
  const _Header({required this.profile});

  final ConsumerProfile profile;

  @override
  Widget build(BuildContext context) {
    final avatar = profile.avatarPath != null && profile.avatarPath!.isNotEmpty
        ? ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Image.asset(
              profile.avatarPath!,
              fit: BoxFit.cover,
              width: 96,
              height: 96,
            ),
          )
        : null;

    return ProfileHeader(
      fullName: profile.fullName,
      roleLabel: profile.roleLabel,
      avatar: avatar,
      avatarSize: 96,
    );
  }
}
