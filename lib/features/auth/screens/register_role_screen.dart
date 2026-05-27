import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Model data untuk setiap pilihan peran.
class _RoleOption {
  const _RoleOption({
    required this.label,
    required this.assetPath,
    required this.value,
  });

  final String label;
  final String assetPath;
  final String value;
}

/// Daftar peran yang tersedia di DurianTrace.
const List<_RoleOption> _roles = [
  _RoleOption(
    label: 'Petani Durian',
    assetPath: 'assets/images/role_petani.png',
    value: 'petani',
  ),
  _RoleOption(
    label: 'Pengepul Durian',
    assetPath: 'assets/images/role_pengepul.png',
    value: 'pengepul',
  ),
  _RoleOption(
    label: 'Distributor Durian',
    assetPath: 'assets/images/role_distributor.png',
    value: 'distributor',
  ),
  _RoleOption(
    label: 'UMKM Durian',
    assetPath: 'assets/images/role_umkm.png',
    value: 'umkm',
  ),
  _RoleOption(
    label: 'Konsumen Durian',
    assetPath: 'assets/images/role_konsumen.png',
    value: 'konsumen',
  ),
];

/// Halaman pemilihan peran saat pendaftaran akun baru.
///
/// Layout:
/// - TopAppBar: tombol back + judul "Pendaftaran Akun Baru"
/// - Konten: judul "Pilih Peran Anda" + grid 2 kolom (baris terakhir center)
/// - Footer: tombol "SELANJUTNYA"
class RegisterRoleScreen extends StatefulWidget {
  const RegisterRoleScreen({super.key});

  @override
  State<RegisterRoleScreen> createState() => _RegisterRoleScreenState();
}

class _RegisterRoleScreenState extends State<RegisterRoleScreen>
    with SingleTickerProviderStateMixin {
  String? _selectedRole;

  late final AnimationController _animController;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeInOutCubic,
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    ));
    _animController.forward();
  }

  @override
  void dispose() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    _animController.dispose();
    super.dispose();
  }

  void _showTopNotification(String message, {bool isError = false}) {
    _overlayEntry?.remove();
    _overlayEntry = null;

    final overlay = Overlay.of(context);
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (_) => _TopNotificationBanner(
        message: message,
        isError: isError,
        onDismiss: () {
          entry.remove();
          if (_overlayEntry == entry) _overlayEntry = null;
        },
      ),
    );

    _overlayEntry = entry;
    overlay.insert(entry);
  }

  void _handleNext() {
    if (_selectedRole == null) {
      _showTopNotification(
        'Silakan pilih peran Anda terlebih dahulu.',
        isError: true,
      );
      return;
    }

    // TODO: Navigasi ke halaman form pendaftaran berikutnya
    // Navigator.push(context, MaterialPageRoute(
    //   builder: (_) => RegisterFormScreen(role: _selectedRole!),
    // ));
    _showTopNotification(
      'Peran dipilih: $_selectedRole. Halaman berikutnya segera hadir.',
      isError: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SlideTransition(
            position: _slideAnim,
            child: Column(
              children: [
                // ── TopAppBar ──────────────────────────────────────────────
                _TopAppBar(onBack: () => Navigator.maybePop(context)),

                // ── Konten — fit 1 layar tanpa scroll ──────────────────────
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                    child: Column(
                      children: [
                        const Text(
                          'Pilih Peran Anda',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.black,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // 3 baris membagi ruang vertikal secara proporsional
                        Expanded(
                          child: _twoColRow(_roles[0], _roles[1]),
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: _twoColRow(_roles[2], _roles[3]),
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: _oneColCenter(_roles[4]),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Footer tombol ──────────────────────────────────────────
                _FooterButton(onPressed: _handleNext),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Baris dengan 2 kolom card berukuran sama.
  Widget _twoColRow(_RoleOption a, _RoleOption b) {
    const double gap = 16;
    return Row(
      children: [
        Expanded(child: _buildCard(a)),
        const SizedBox(width: gap),
        Expanded(child: _buildCard(b)),
      ],
    );
  }

  /// Baris dengan 1 card di tengah, lebar sama persis dengan kolom di atas.
  Widget _oneColCenter(_RoleOption role) {
    const double gap = 16;
    final screenW = MediaQuery.of(context).size.width;
    final colW = (screenW - 48 - gap) / 2;
    return Center(
      child: SizedBox(
        width: colW,
        child: _buildCard(role),
      ),
    );
  }

  /// Card builder — tanpa SizedBox tinggi, biar Expanded yang atur tinggi.
  Widget _buildCard(_RoleOption role) => _RoleCard(
        role: role,
        isSelected: _selectedRole == role.value,
        onTap: () => setState(() => _selectedRole = role.value),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Sub-widgets
// ─────────────────────────────────────────────────────────────────────────────

/// TopAppBar dengan tombol back dan judul terpusat.
class _TopAppBar extends StatelessWidget {
  const _TopAppBar({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Tombol back di kiri
          Align(
            alignment: Alignment.centerLeft,
            child: GestureDetector(
              onTap: onBack,
              behavior: HitTestBehavior.opaque,
              child: Container(
                padding: const EdgeInsets.all(4),
                child: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 22,
                  color: AppColors.black,
                ),
              ),
            ),
          ),
          // Judul di tengah
          const Text(
            'Pendaftaran Akun Baru',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.black,
            ),
          ),
        ],
      ),
    );
  }
}

/// Kartu pilihan peran — gambar + label, dengan highlight saat dipilih.
class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.role,
    required this.isSelected,
    required this.onTap,
  });

  final _RoleOption role;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF4F7F2) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color:
                isSelected ? AppColors.primaryContainer : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.max,
          children: [
            // Gambar role — flexible agar tetap responsive di layar kecil,
            // dengan target ukuran 120 dan downscale jika ruang tidak cukup.
            Flexible(
              child: AnimatedScale(
                scale: isSelected ? 1.08 : 1.0,
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                child: Image.asset(
                  role.assetPath,
                  width: 120,
                  height: 120,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const SizedBox(
                    width: 120,
                    height: 120,
                    child: Icon(
                      Icons.person_outline_rounded,
                      size: 48,
                      color: AppColors.placeholder,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Label
            Text(
              role.label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.visible,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected ? AppColors.primary : AppColors.black,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tombol "SELANJUTNYA" yang dipasang di bagian bawah layar.
class _FooterButton extends StatelessWidget {
  const _FooterButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.white,
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryContainer,
            foregroundColor: AppColors.white,
            elevation: 0,
            shape: const StadiumBorder(),
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: const Text(
            'SELANJUTNYA',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
              color: AppColors.white,
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Overlay notification (sama persis dengan HomeScreen)
// ─────────────────────────────────────────────────────────────────────────────

class _TopNotificationBanner extends StatefulWidget {
  const _TopNotificationBanner({
    required this.message,
    required this.isError,
    required this.onDismiss,
  });

  final String message;
  final bool isError;
  final VoidCallback onDismiss;

  @override
  State<_TopNotificationBanner> createState() =>
      _TopNotificationBannerState();
}

class _TopNotificationBannerState extends State<_TopNotificationBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<Offset> _slide;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);

    _ctrl.forward();
    Future.delayed(const Duration(seconds: 3), _dismiss);
  }

  void _dismiss() async {
    if (!mounted) return;
    await _ctrl.reverse();
    widget.onDismiss();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final bgColor =
        widget.isError ? const Color(0xFFFFDAD6) : const Color(0xFFDCF5DC);
    final textColor =
        widget.isError ? const Color(0xFF7F1D1D) : const Color(0xFF14532D);
    final iconColor =
        widget.isError ? const Color(0xFFB91C1C) : const Color(0xFF16A34A);

    return Positioned(
      top: topPadding + 12,
      left: 24,
      right: 24,
      child: SlideTransition(
        position: _slide,
        child: FadeTransition(
          opacity: _fade,
          child: GestureDetector(
            onTap: _dismiss,
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.10),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(
                      widget.isError
                          ? Icons.error_outline_rounded
                          : Icons.check_circle_outline_rounded,
                      color: iconColor,
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        widget.message,
                        style: TextStyle(
                          color: textColor,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          height: 1.4,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.close_rounded,
                      color: textColor.withValues(alpha: 0.6),
                      size: 18,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
