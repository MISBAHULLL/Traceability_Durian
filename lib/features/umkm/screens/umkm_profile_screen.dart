import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_top_bar.dart';
import '../../../shared/widgets/primary_pill_button.dart';
import '../../../shared/widgets/profile_header.dart';
import '../../../shared/widgets/profile_info_tile.dart';
import '../../auth/screens/home_screen.dart';
import '../data/umkm_repository.dart';
import '../models/umkm_profile.dart';
import '../umkm_routes.dart';
import 'umkm_data_screen.dart';

/// Profil UMKM.
class UmkmProfileScreen extends StatelessWidget {
  const UmkmProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final profile = UmkmRepository.instance.profile;

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
                    icon: Icons.storefront_rounded,
                    label: 'Nama UMKM',
                    value: profile.name,
                    isEmpty: profile.name.isEmpty,
                  ),
                  const SizedBox(height: 12),
                  ProfileInfoTile(
                    icon: Icons.person_outline_rounded,
                    label: 'Nama Pemilik',
                    value: profile.ownerName,
                    isEmpty: profile.ownerName.isEmpty,
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
                    label: 'Lokasi',
                    value: profile.location.isEmpty ? 'Belum dilengkapi' : profile.location,
                    isEmpty: profile.location.isEmpty,
                  ),
                  const SizedBox(height: 12),
                  ProfileInfoTile(
                    icon: Icons.info_outline_rounded,
                    label: 'Tentang UMKM',
                    value: profile.about.isEmpty ? 'Belum dilengkapi' : profile.about,
                    isEmpty: profile.about.isEmpty,
                  ),
                  const SizedBox(height: 24),
                  PrimaryPillButton(
                    label: 'Data UMKM',
                    onPressed: () {
                      UmkmRoutes.push(context, const UmkmDataScreen());
                    },
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                    onPressed: () {
                        UmkmRoutes.replaceAll(context, const HomeScreen());
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

  final UmkmProfile profile;

  @override
  Widget build(BuildContext context) {
    return ProfileHeader(
      fullName: profile.ownerName,
      roleLabel: 'Pemilik UMKM',
      avatarSize: 96,
    );
  }
}
