import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_top_bar.dart';
import '../../../shared/widgets/top_notification_banner.dart';
import '../data/farmer_repository.dart';
import '../farmer_routes.dart';
import '../models/harvest_batch.dart';
import '../widgets/farmer_avatar.dart';
import '../../auth/screens/home_screen.dart';
import 'edit_profile_screen.dart';

/// Penanda nilai profil yang belum dilengkapi petani.
const String _kNotSet = 'Belum dilengkapi';

// [FE - Component Rendering] Screen ini menampilkan profil petani dan
// menyediakan aksi logout yang membersihkan seluruh stack navigasi
// sehingga tidak ada layar petani yang tersisa setelah keluar.
/// Layar Profil Petani — menampilkan data profil dan aksi keluar (logout).
///
/// Menampilkan nama, label peran, lokasi, dan kontak petani dari
/// [FarmerRepository.profile] (Req 6.1). Tombol "Keluar" memanggil
/// [FarmerRepository.logout] lalu mengganti seluruh stack navigasi ke
/// [HomeScreen] sehingga tidak ada layar petani yang tersisa (Req 6.4).
class FarmerProfileScreen extends StatefulWidget {
  const FarmerProfileScreen({super.key});

  @override
  State<FarmerProfileScreen> createState() => _FarmerProfileScreenState();
}

class _FarmerProfileScreenState extends State<FarmerProfileScreen>
    with SingleTickerProviderStateMixin {
  final _repo = FarmerRepository.instance;
  final _notification = TopNotification();

  late final AnimationController _animController;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  bool _isLoggingOut = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.0, 0.8, curve: Curves.easeInOutCubic),
    );
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _animController,
            curve: const Interval(0.0, 0.9, curve: Curves.easeOutCubic),
          ),
        );
    _animController.forward();
    // Dengarkan perubahan repo agar profil ter-refresh setelah diedit.
    _repo.addListener(_onRepoChanged);
  }

  @override
  void dispose() {
    _repo.removeListener(_onRepoChanged);
    _notification.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _onRepoChanged() {
    if (mounted) setState(() {});
  }

  // [FE - Event Handler] _openEditProfile membuka form ubah profil; saat
  // kembali, listener repo otomatis me-refresh tampilan.
  Future<void> _openEditProfile() async {
    await FarmerRoutes.push(context, const EditProfileScreen());
  }

  // [FE - Event Handler] _handleLogout menangani aksi keluar: reset mock
  // repository lalu ganti seluruh stack navigasi ke HomeScreen (login).
  /// Menangani aksi keluar: reset sesi mock lalu bersihkan stack ke login.
  Future<void> _handleLogout() async {
    setState(() => _isLoggingOut = true);

    // Simulasi delay singkat agar transisi terasa natural
    await Future.delayed(const Duration(milliseconds: 300));

    if (!mounted) return;

    // Reset state mock repository (Req 6.4)
    _repo.logout();

    // Ganti seluruh stack navigasi ke layar login (Req 6.4)
    FarmerRoutes.replaceAll(context, const HomeScreen());
  }

  @override
  Widget build(BuildContext context) {
    final profile = _repo.profile;

    return Scaffold(
      backgroundColor:
          AppColors.surface, // Background surface agar card putih menonjol
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SlideTransition(
            position: _slideAnim,
            child: Column(
              children: [
                // Top bar dengan tombol back + aksi ubah profil (Req 6.2)
                AppTopBar(
                  title: 'Profil Saya',
                  actions: [
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        onPressed: _openEditProfile,
                        icon: const Icon(
                          Icons.edit_rounded,
                          color: AppColors.primary,
                          size: 20,
                        ),
                        tooltip: 'Ubah Profil',
                      ),
                    ),
                  ],
                ),

                // Konten utama
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      children: [
                        // ── Header profil (Center-aligned Premium) ────────
                        _ProfileHeader(profile: profile),

                        const SizedBox(height: 32),

                        // ── Detail info (Card Based) ──────────────────────
                        _ProfileInfoSection(profile: profile),

                        const SizedBox(height: 48),

                        // ── Tombol Keluar (Outlined Premium) ──────────────
                        _LogoutButton(
                          isLoading: _isLoggingOut,
                          onPressed: _handleLogout,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Header profil — avatar, nama, label peran (Center Aligned)
// ─────────────────────────────────────────────────────────────────────────────

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.profile});

  final FarmerProfile profile;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Avatar foto/inisial dengan shadow memancar
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 4),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.15),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: FarmerAvatar(
            profile: profile,
            size: 100,
            showEditButton: true,
          ),
        ),

        const SizedBox(height: 20),

        // Nama
        Text(
          profile.fullName,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: AppColors.black,
            letterSpacing: -0.5,
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 8),

        // Label peran bergaya lencana (badge)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
          ),
          child: Text(
            profile.roleLabel,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Seksi detail info — lokasi dan kontak (Card Layout)
// ─────────────────────────────────────────────────────────────────────────────

class _ProfileInfoSection extends StatelessWidget {
  const _ProfileInfoSection({required this.profile});

  final FarmerProfile profile;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 8, bottom: 12),
          child: Text(
            'Informasi Akun',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.subtitle,
              letterSpacing: 0.2,
            ),
          ),
        ),

        // Card melengkung dengan bayangan halus
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFF3F4F6), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              // Lokasi
              _InfoRow(
                icon: Icons.place_rounded,
                label: 'Lokasi Kebun',
                value: _composeAddress(profile),
                isEmpty: _composeAddress(profile) == _kNotSet,
              ),

              const Divider(height: 1, color: Color(0xFFF3F4F6), indent: 68),

              // Nomor HP
              _InfoRow(
                icon: Icons.phone_rounded,
                label: 'Nomor HP',
                value: profile.contact.isEmpty ? _kNotSet : profile.contact,
                isEmpty: profile.contact.isEmpty,
              ),

              const Divider(height: 1, color: Color(0xFFF3F4F6), indent: 68),

              // Email
              _InfoRow(
                icon: Icons.email_rounded,
                label: 'Alamat Email',
                value: profile.emailValue.isEmpty
                    ? _kNotSet
                    : profile.emailValue,
                isEmpty: profile.emailValue.isEmpty,
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Merakit alamat dari komponen non-kosong (desa, kecamatan, kabupaten).
  static String _composeAddress(FarmerProfile p) {
    final parts = <String>[
      if (p.village.isNotEmpty) 'Desa ${p.village}',
      if (p.district.isNotEmpty) 'Kec. ${p.district}',
      if (p.city.isNotEmpty) p.city,
    ];
    if (parts.isNotEmpty) return parts.join(', ');
    // Fallback ke ringkasan lokasi bila ada, selain itu penanda kosong.
    return p.location.isNotEmpty ? p.location : _kNotSet;
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.isEmpty = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool isEmpty;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Ikon di dalam lingkaran transparan
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 22, color: AppColors.primary),
          ),

          const SizedBox(width: 16),

          // Label + nilai
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.placeholder,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: isEmpty ? AppColors.placeholder : AppColors.black,
                    fontStyle: isEmpty ? FontStyle.italic : FontStyle.normal,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tombol Keluar (Outlined Premium)
// ─────────────────────────────────────────────────────────────────────────────

/// Tombol logout dengan gaya outlined merah elegan.
class _LogoutButton extends StatelessWidget {
  const _LogoutButton({required this.isLoading, required this.onPressed});

  final bool isLoading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFFDC2626), width: 1.5),
          foregroundColor: const Color(0xFFDC2626),
          disabledForegroundColor: const Color(
            0xFFDC2626,
          ).withValues(alpha: 0.5),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFDC2626)),
                ),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.power_settings_new_rounded, size: 22),
                  SizedBox(width: 10),
                  Text(
                    'Keluar Akun',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
