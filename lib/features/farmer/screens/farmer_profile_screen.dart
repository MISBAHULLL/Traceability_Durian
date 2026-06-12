import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_top_bar.dart';
import '../../../shared/widgets/profile_header.dart';
import '../../../shared/widgets/profile_info_tile.dart';
import '../../../shared/widgets/primary_pill_button.dart';
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
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.0, 0.9, curve: Curves.easeOutCubic),
    ));
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
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SlideTransition(
            position: _slideAnim,
            child: Column(
              children: [
                // Top bar dengan tombol back + aksi ubah profil (Req 6.2)
                AppTopBar(
                  title: 'Profil',
                  actions: [
                    IconButton(
                      onPressed: _openEditProfile,
                      icon: const Icon(
                        Icons.edit_outlined,
                        color: AppColors.black,
                        size: 22,
                      ),
                      tooltip: 'Ubah Profil',
                    ),
                  ],
                ),

                // Konten utama
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),

                        // ── Header profil (Req 6.1) ──────────────────────
                        ProfileHeader(
                          fullName: profile.fullName,
                          roleLabel: profile.roleLabel,
                          avatar: FarmerAvatar(
                            profile: profile,
                            size: 72,
                            showEditButton: true,
                          ),
                          avatarSize: 72,
                        ),

                        const SizedBox(height: 28),

                        // ── Divider ──────────────────────────────────────
                        const Divider(color: Color(0xFFE5E7EB)),

                        const SizedBox(height: 24),

                        // ── Detail info ──────────────────────────────────
                        _ProfileInfoSection(profile: profile),

                        const SizedBox(height: 40),

                        // ── Tombol Keluar (Req 6.3) ──────────────────────
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
// Seksi detail info — lokasi dan kontak
// ─────────────────────────────────────────────────────────────────────────────

class _ProfileInfoSection extends StatelessWidget {
  const _ProfileInfoSection({required this.profile});

  final FarmerProfile profile;
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
          icon: Icons.place_outlined,
          label: 'Lokasi',
          value: _composeAddress(profile),
          isEmpty: _composeAddress(profile) == _kNotSet,
        ),
        const SizedBox(height: 12),
        ProfileInfoTile(
          icon: Icons.phone_outlined,
          label: 'Nomor HP',
          value: profile.contact.isEmpty ? _kNotSet : profile.contact,
          isEmpty: profile.contact.isEmpty,
        ),
        const SizedBox(height: 12),
        ProfileInfoTile(
          icon: Icons.email_outlined,
          label: 'Email',
          value: profile.emailValue.isEmpty ? _kNotSet : profile.emailValue,
          isEmpty: profile.emailValue.isEmpty,
        ),
      ],
    );
  }

  /// Merakit alamat dari komponen non-kosong (desa, kecamatan, kabupaten).
  ///
  /// Mengembalikan [_kNotSet] bila seluruh komponen kosong — terjadi pada
  /// petani yang baru mendaftar dan belum melengkapi profil.
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


// ─────────────────────────────────────────────────────────────────────────────
// Tombol Keluar
// ─────────────────────────────────────────────────────────────────────────────

// [FE - Component Rendering] _LogoutButton menggunakan warna merah untuk
// memberi sinyal visual bahwa ini adalah aksi destruktif (logout),
// berbeda dari tombol aksi utama hijau di layar lain.
/// Tombol logout dengan gaya pill merah agar berbeda dari aksi utama hijau.
///
/// Menggunakan [PrimaryPillButton] sebagai referensi pola, namun dengan
/// warna merah untuk memberi sinyal destruktif (Req 6.3, 8.2).
class _LogoutButton extends StatelessWidget {
  const _LogoutButton({
    required this.isLoading,
    required this.onPressed,
  });

  final bool isLoading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFDC2626),
          disabledBackgroundColor:
              const Color(0xFFDC2626).withValues(alpha: 0.55),
          foregroundColor: AppColors.white,
          disabledForegroundColor: AppColors.white.withValues(alpha: 0.7),
          elevation: 0,
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
                ),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.logout_rounded, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'KELUAR',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                      color: AppColors.white,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
