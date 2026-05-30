import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_top_bar.dart';
import '../../../shared/widgets/primary_pill_button.dart';
import '../../../shared/widgets/top_notification_banner.dart';
import '../data/farmer_repository.dart';
import '../farmer_routes.dart';
import '../models/harvest_batch.dart';
import '../../auth/screens/home_screen.dart';

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
  }

  @override
  void dispose() {
    _notification.dispose();
    _animController.dispose();
    super.dispose();
  }

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
                // Top bar dengan tombol back (Req 6.2)
                AppTopBar(title: 'Profil'),

                // Konten utama
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),

                        // ── Header profil (Req 6.1) ──────────────────────
                        _ProfileHeader(profile: profile),

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
// Header profil — avatar, nama, label peran
// ─────────────────────────────────────────────────────────────────────────────

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.profile});

  final FarmerProfile profile;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Avatar inisial
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: AppColors.primaryContainer,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            _initials(profile.fullName),
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.white,
              letterSpacing: 1,
            ),
          ),
        ),

        const SizedBox(width: 16),

        // Nama + label peran
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                profile.fullName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.black,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(
                    Icons.agriculture_rounded,
                    size: 14,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    profile.roleLabel,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Mengambil dua huruf pertama dari nama untuk avatar inisial.
  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
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

        // Lokasi lengkap (Req 6.1)
        _InfoRow(
          icon: Icons.place_outlined,
          label: 'Lokasi',
          value: profile.location,
        ),

        const SizedBox(height: 14),

        // Desa / kecamatan / kabupaten
        _InfoRow(
          icon: Icons.map_outlined,
          label: 'Alamat',
          value:
              'Desa ${profile.village}, Kec. ${profile.district}, ${profile.city}',
        ),

        const SizedBox(height: 14),

        // Kontak (Req 6.1)
        _InfoRow(
          icon: Icons.phone_outlined,
          label: 'Kontak',
          value: profile.contact,
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Ikon
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Icon(icon, size: 18, color: AppColors.primary),
        ),

        const SizedBox(width: 12),

        // Label + nilai
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.placeholder,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.black,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tombol Keluar
// ─────────────────────────────────────────────────────────────────────────────

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
