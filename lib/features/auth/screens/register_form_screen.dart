import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../collector/data/collector_repository.dart';
import '../../collector/screens/collector_home_screen.dart';
import '../../farmer/data/farmer_repository.dart';
import '../../farmer/screens/farmer_home_screen.dart';

/// Label tampilan per nilai role.
const Map<String, String> _roleLabels = {
  'petani': 'Petani Durian',
  'pengepul': 'Pengepul Durian',
  'distributor': 'Distributor Durian',
  'umkm': 'UMKM Durian',
  'konsumen': 'Konsumen Durian',
};

/// Warna aksen badge per role.
const Map<String, Color> _roleColors = {
  'petani': Color(0xFF296C11),
  'pengepul': Color(0xFF58A835),
  'distributor': Color(0xFF1D6FA4),
  'umkm': Color(0xFFB45309),
  'konsumen': Color(0xFF6B21A8),
};

/// Ikon badge per role.
const Map<String, IconData> _roleIcons = {
  'petani': Icons.agriculture_rounded,
  'pengepul': Icons.inventory_2_rounded,
  'distributor': Icons.local_shipping_rounded,
  'umkm': Icons.storefront_rounded,
  'konsumen': Icons.people_rounded,
};

/// Halaman form pendaftaran akun baru.
///
/// Layout:
/// - TopAppBar: tombol back + judul "Pendaftaran Akun Baru"
/// - Badge role (read-only, dari screen sebelumnya)
/// - Form: Nama Depan, Nama Belakang, No. HP, Email, Password, Konfirmasi Password
/// - Tombol DAFTAR
/// - Link "Sudah punya akun? Masuk"
class RegisterFormScreen extends StatefulWidget {
  const RegisterFormScreen({super.key, required this.role});

  /// Nilai role yang dipilih di [RegisterRoleScreen], contoh: 'petani'.
  final String role;

  @override
  State<RegisterFormScreen> createState() => _RegisterFormScreenState();
}

class _RegisterFormScreenState extends State<RegisterFormScreen>
    with SingleTickerProviderStateMixin {
  // Controllers
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();

  // Focus nodes
  final _firstNameFocus = FocusNode();
  final _lastNameFocus = FocusNode();
  final _phoneFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _confirmPasswordFocus = FocusNode();

  bool _isLoading = false;
  OverlayEntry? _overlayEntry;

  late final AnimationController _animController;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

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
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
        );
    _animController.forward();
  }

  @override
  void dispose() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    _animController.dispose();
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    _firstNameFocus.dispose();
    _lastNameFocus.dispose();
    _phoneFocus.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _confirmPasswordFocus.dispose();
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

  // [UTIL - Helper Function] Normalisasi ini menjaga nomor HP register tetap
  // konsisten untuk profil mock dan nanti mudah dipetakan ke payload API.
  String _normalizeIndonesianPhone(String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('0')) return digits.substring(1);
    return digits;
  }

  void _handleRegister() async {
    FocusScope.of(context).unfocus();

    final firstName = _firstNameCtrl.text.trim();
    final lastName = _lastNameCtrl.text.trim();
    final phone = _normalizeIndonesianPhone(_phoneCtrl.text);
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;
    final confirmPassword = _confirmPasswordCtrl.text;

    // ── Validasi ──────────────────────────────────────────────────────────
    if (firstName.isEmpty) {
      _showTopNotification('Nama depan wajib diisi.', isError: true);
      return;
    }
    if (lastName.isEmpty) {
      _showTopNotification('Nama belakang wajib diisi.', isError: true);
      return;
    }
    if (phone.isEmpty) {
      _showTopNotification('Nomor HP wajib diisi.', isError: true);
      return;
    }
    if (phone.length < 9 || phone.length > 13) {
      _showTopNotification(
        'Nomor HP tidak valid (9-13 digit setelah +62).',
        isError: true,
      );
      return;
    }
    if (email.isEmpty) {
      _showTopNotification('Email wajib diisi.', isError: true);
      return;
    }
    final emailRegex = RegExp(r'^[\w\.\+\-]+@[\w\-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(email)) {
      _showTopNotification('Format email tidak valid.', isError: true);
      return;
    }
    if (password.isEmpty) {
      _showTopNotification('Password wajib diisi.', isError: true);
      return;
    }
    if (password.length < 8) {
      _showTopNotification('Password minimal 8 karakter.', isError: true);
      return;
    }
    if (confirmPassword.isEmpty) {
      _showTopNotification('Konfirmasi password wajib diisi.', isError: true);
      return;
    }
    if (password != confirmPassword) {
      _showTopNotification(
        'Password dan konfirmasi tidak cocok.',
        isError: true,
      );
      return;
    }

    setState(() => _isLoading = true);

    // Simulasi delay — ganti dengan API call saat BE siap
    await Future.delayed(const Duration(milliseconds: 800));

    if (!mounted) return;
    setState(() => _isLoading = false);

    // TODO: Ganti dengan API call saat BE siap
    _showTopNotification(
      'Pendaftaran berhasil! Selamat datang.',
      isError: false,
    );

    // Navigasi ke beranda sesuai role setelah sukses.
    // Saat ini role petani dan pengepul yang memiliki beranda. Role lain
    // menyusul.
    Widget? destination;

    if (widget.role == 'petani') {
      // [FE - Event Handler] Aktifkan akun petani baru di repository dengan
      // data registrasi sebelum membuka Beranda, agar profil yang tampil
      // adalah identitas user (bukan data seed contoh).
      FarmerRepository.instance.registerFarmer(
        firstName: firstName,
        lastName: lastName,
        phone: phone,
        email: email,
      );
      destination = const FarmerHomeScreen();
    } else if (widget.role == 'pengepul') {
      // [FE - Event Handler] Aktifkan akun pengepul baru di repository dengan
      // data registrasi sebelum membuka Beranda Pengepul.
      CollectorRepository.instance.registerCollector(
        firstName: firstName,
        lastName: lastName,
        phone: phone,
        email: email,
      );
      destination = const CollectorHomeScreen();
    }

    if (destination == null) return;

    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (_, _, _) => destination!,
        transitionsBuilder: (_, animation, _, child) => FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: Curves.easeInOutCubic,
          ),
          child: child,
        ),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final roleLabel = _roleLabels[widget.role] ?? widget.role;
    final roleColor = _roleColors[widget.role] ?? AppColors.primary;
    final roleIcon = _roleIcons[widget.role] ?? Icons.person_rounded;

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        bottom: false,
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SlideTransition(
            position: _slideAnim,
            child: Column(
              children: [
                // ── TopAppBar ────────────────────────────────────────────
                _TopAppBar(onBack: () => Navigator.maybePop(context)),

                // ── Form scrollable ──────────────────────────────────────
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Badge role — read only
                        _RoleBadge(
                          label: roleLabel,
                          color: roleColor,
                          icon: roleIcon,
                        ),
                        const SizedBox(height: 24),

                        // ── Nama ──────────────────────────────────────────
                        _SectionLabel(label: 'Nama Lengkap'),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: _FormField(
                                controller: _firstNameCtrl,
                                focusNode: _firstNameFocus,
                                hintText: 'Nama depan',
                                textInputAction: TextInputAction.next,
                                keyboardType: TextInputType.name,
                                textCapitalization: TextCapitalization.words,
                                onSubmitted: (_) => FocusScope.of(
                                  context,
                                ).requestFocus(_lastNameFocus),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _FormField(
                                controller: _lastNameCtrl,
                                focusNode: _lastNameFocus,
                                hintText: 'Nama belakang',
                                textInputAction: TextInputAction.next,
                                keyboardType: TextInputType.name,
                                textCapitalization: TextCapitalization.words,
                                onSubmitted: (_) => FocusScope.of(
                                  context,
                                ).requestFocus(_phoneFocus),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // ── No. HP ────────────────────────────────────────
                        _SectionLabel(label: 'Nomor HP'),
                        const SizedBox(height: 8),
                        _FormField(
                          controller: _phoneCtrl,
                          focusNode: _phoneFocus,
                          hintText: 'Contoh: 8123456789',
                          prefixText: '+62  ',
                          textInputAction: TextInputAction.next,
                          keyboardType: TextInputType.phone,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(15),
                          ],
                          onSubmitted: (_) =>
                              FocusScope.of(context).requestFocus(_emailFocus),
                        ),
                        const SizedBox(height: 16),

                        // ── Email ─────────────────────────────────────────
                        _SectionLabel(label: 'Email'),
                        const SizedBox(height: 8),
                        _FormField(
                          controller: _emailCtrl,
                          focusNode: _emailFocus,
                          hintText: 'contoh@email.com',
                          textInputAction: TextInputAction.next,
                          keyboardType: TextInputType.emailAddress,
                          onSubmitted: (_) => FocusScope.of(
                            context,
                          ).requestFocus(_passwordFocus),
                        ),
                        const SizedBox(height: 16),

                        // ── Password ──────────────────────────────────────
                        _SectionLabel(label: 'Password'),
                        const SizedBox(height: 8),
                        _FormField(
                          controller: _passwordCtrl,
                          focusNode: _passwordFocus,
                          hintText: 'Minimal 8 karakter',
                          obscureText: true,
                          textInputAction: TextInputAction.next,
                          onSubmitted: (_) => FocusScope.of(
                            context,
                          ).requestFocus(_confirmPasswordFocus),
                        ),
                        const SizedBox(height: 16),

                        // ── Konfirmasi Password ───────────────────────────
                        _SectionLabel(label: 'Konfirmasi Password'),
                        const SizedBox(height: 8),
                        _FormField(
                          controller: _confirmPasswordCtrl,
                          focusNode: _confirmPasswordFocus,
                          hintText: 'Ulangi password',
                          obscureText: true,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _handleRegister(),
                        ),
                        const SizedBox(height: 32),

                        // ── Tombol DAFTAR ─────────────────────────────────
                        _RegisterButton(
                          onPressed: _handleRegister,
                          isLoading: _isLoading,
                        ),
                        const SizedBox(height: 20),

                        // ── Link masuk ────────────────────────────────────
                        Center(
                          child: GestureDetector(
                            onTap: () {
                              // Kembali ke HomeScreen (pop semua sampai root)
                              Navigator.of(
                                context,
                              ).popUntil((route) => route.isFirst);
                            },
                            behavior: HitTestBehavior.opaque,
                            child: RichText(
                              text: const TextSpan(
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.placeholder,
                                ),
                                children: [
                                  TextSpan(text: 'Sudah punya akun? '),
                                  TextSpan(
                                    text: 'Masuk',
                                    style: TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w700,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
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
          Align(
            alignment: Alignment.centerLeft,
            child: GestureDetector(
              onTap: onBack,
              behavior: HitTestBehavior.opaque,
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 22,
                  color: AppColors.black,
                ),
              ),
            ),
          ),
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

/// Badge role yang dipilih — read only, ditampilkan di atas form.
class _RoleBadge extends StatelessWidget {
  const _RoleBadge({
    required this.label,
    required this.color,
    required this.icon,
  });

  final String label;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25), width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Mendaftar sebagai',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.placeholder,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Label section di atas setiap field.
class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.subtitle,
      ),
    );
  }
}

/// Text field dengan border rounded dan label di atas.
class _FormField extends StatefulWidget {
  const _FormField({
    required this.controller,
    required this.focusNode,
    required this.hintText,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.prefixText,
    this.inputFormatters,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String hintText;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final String? prefixText;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onSubmitted;

  @override
  State<_FormField> createState() => _FormFieldState();
}

class _FormFieldState extends State<_FormField> {
  late bool _obscure;

  @override
  void initState() {
    super.initState();
    _obscure = widget.obscureText;
  }

  @override
  Widget build(BuildContext context) {
    const radius = BorderRadius.all(Radius.circular(12));

    final border = OutlineInputBorder(
      borderRadius: radius,
      borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 1),
    );
    final focusedBorder = OutlineInputBorder(
      borderRadius: radius,
      borderSide: BorderSide(color: AppColors.primaryContainer, width: 2),
    );

    return TextField(
      controller: widget.controller,
      focusNode: widget.focusNode,
      obscureText: _obscure,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      textCapitalization: widget.textCapitalization,
      inputFormatters: widget.inputFormatters,
      onSubmitted: widget.onSubmitted,
      style: const TextStyle(fontSize: 14, color: AppColors.black),
      decoration: InputDecoration(
        hintText: widget.hintText,
        hintStyle: const TextStyle(fontSize: 14, color: AppColors.placeholder),
        prefixText: widget.prefixText,
        prefixStyle: const TextStyle(
          fontSize: 14,
          color: AppColors.subtitle,
          fontWeight: FontWeight.w500,
        ),
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: border,
        enabledBorder: border,
        focusedBorder: focusedBorder,
        suffixIcon: widget.obscureText
            ? IconButton(
                onPressed: () => setState(() => _obscure = !_obscure),
                icon: Icon(
                  _obscure
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: AppColors.placeholder,
                  size: 20,
                ),
              )
            : null,
      ),
    );
  }
}

/// Tombol DAFTAR full-width.
class _RegisterButton extends StatelessWidget {
  const _RegisterButton({required this.onPressed, required this.isLoading});

  final VoidCallback onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryContainer,
          foregroundColor: AppColors.white,
          disabledBackgroundColor: AppColors.primaryContainer.withValues(
            alpha: 0.6,
          ),
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
            : const Text(
                'DAFTAR',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                  color: AppColors.white,
                ),
              ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Overlay notification
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
  State<_TopNotificationBanner> createState() => _TopNotificationBannerState();
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
    final bgColor = widget.isError
        ? const Color(0xFFFFDAD6)
        : const Color(0xFFDCF5DC);
    final textColor = widget.isError
        ? const Color(0xFF7F1D1D)
        : const Color(0xFF14532D);
    final iconColor = widget.isError
        ? const Color(0xFFB91C1C)
        : const Color(0xFF16A34A);

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
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
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
