import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../collector/data/collector_repository.dart';
import '../../collector/screens/collector_home_screen.dart';
import '../../consumer/data/consumer_repository.dart';
import '../../consumer/screens/consumer_home_screen.dart';
import '../../farmer/data/farmer_repository.dart';
import '../../farmer/screens/farmer_home_screen.dart';
import '../../distributor/data/distributor_repository.dart';
import '../../distributor/screens/distributor_home_screen.dart';
import '../../umkm/screens/umkm_home_screen.dart';

/// Label tampilan per nilai role.
const Map<String, String> _roleLabels = {
  'petani': 'Petani Durian',
  'pengepul': 'Pengepul Durian',
  'distributor': 'Distributor Durian',
  'umkm': 'UMKM Durian',
  'konsumen': 'Konsumen Durian',
};

const Set<String> _disposableEmailDomains = {
  '10minutemail.com',
  'guerrillamail.com',
  'mailinator.com',
  'temp-mail.org',
  'tempmail.com',
  'throwawaymail.com',
  'yopmail.com',
};

/// Halaman form pendaftaran akun baru.
///
/// Layout:
/// - Header: tombol back + judul "Pendaftaran Akun Baru" + role terpilih
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
  String? _firstNameError;
  String? _lastNameError;
  String? _phoneError;
  String? _emailError;
  String? _passwordError;
  String? _confirmPasswordError;
  bool _showPasswordRequirements = false;

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
    _phoneCtrl.addListener(_handlePhoneChanged);
    _phoneFocus.addListener(_handlePhoneFocusChanged);
    _emailCtrl.addListener(_handleEmailChanged);
    _emailFocus.addListener(_handleEmailFocusChanged);
    _passwordCtrl.addListener(_handlePasswordChanged);
    _passwordFocus.addListener(_handlePasswordFocusChanged);
    _confirmPasswordCtrl.addListener(_handleConfirmPasswordChanged);
    _animController.forward();
  }

  @override
  void dispose() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    _animController.dispose();
    _phoneCtrl.removeListener(_handlePhoneChanged);
    _phoneFocus.removeListener(_handlePhoneFocusChanged);
    _emailCtrl.removeListener(_handleEmailChanged);
    _emailFocus.removeListener(_handleEmailFocusChanged);
    _passwordCtrl.removeListener(_handlePasswordChanged);
    _passwordFocus.removeListener(_handlePasswordFocusChanged);
    _confirmPasswordCtrl.removeListener(_handleConfirmPasswordChanged);
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
    var digits = value.replaceAll(RegExp(r'\D'), '');
    while (digits.startsWith('0')) {
      digits = digits.substring(1);
    }
    while (digits.startsWith('62')) {
      digits = digits.substring(2);
    }
    if (digits.length > 13) return digits.substring(0, 13);
    return digits;
  }

  String _normalizeEmail(String value) => value.trim().toLowerCase();

  void _setControllerText(TextEditingController controller, String text) {
    if (controller.text == text) return;
    controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  void _handlePhoneChanged() {
    final phone = _normalizeIndonesianPhone(_phoneCtrl.text);
    final error = _phoneValidationError(phone);
    setState(() {
      if (_phoneError != null) _phoneError = error;
    });
  }

  void _handlePhoneFocusChanged() {
    setState(() {});
  }

  void _handleEmailChanged() {
    if (_emailError == null) return;
    final email = _normalizeEmail(_emailCtrl.text);
    final error = _emailValidationError(email);
    if (_emailError == error) return;
    setState(() => _emailError = error);
  }

  void _handleEmailFocusChanged() {
    if (_emailFocus.hasFocus) return;
    final email = _normalizeEmail(_emailCtrl.text);
    _setControllerText(_emailCtrl, email);
    if (_emailError != null) {
      setState(() => _emailError = _emailValidationError(email));
    }
  }

  void _handlePasswordChanged() {
    final password = _passwordCtrl.text;
    final shouldShow = _passwordFocus.hasFocus || password.isNotEmpty;
    final error = _passwordError == null
        ? null
        : _passwordValidationError(password);
    setState(() {
      _showPasswordRequirements = shouldShow || _passwordError != null;
      _passwordError = error;
      if (_confirmPasswordError != null) {
        _confirmPasswordError = _confirmPasswordValidationError(
          _confirmPasswordCtrl.text,
          password,
        );
      }
    });
  }

  void _handlePasswordFocusChanged() {
    setState(() {
      _showPasswordRequirements =
          _passwordFocus.hasFocus ||
          _passwordCtrl.text.isNotEmpty ||
          _passwordError != null;
    });
  }

  void _handleConfirmPasswordChanged() {
    if (_confirmPasswordError == null) return;
    final error = _confirmPasswordValidationError(
      _confirmPasswordCtrl.text,
      _passwordCtrl.text,
    );
    if (_confirmPasswordError == error) return;
    setState(() => _confirmPasswordError = error);
  }

  String? _phoneValidationError(String phone) {
    if (phone.isEmpty) return 'Nomor HP wajib diisi.';
    if (!phone.startsWith('8')) {
      return 'Nomor HP wajib diawali angka 8 setelah +62.';
    }
    if (phone.length < 7 || phone.length > 13) {
      return 'Nomor HP harus 7-13 digit setelah +62.';
    }
    return null;
  }

  String? _emailValidationError(String email) {
    if (email.isEmpty) return 'Email wajib diisi.';
    final emailRegex = RegExp(
      r'^[A-Z0-9._%+\-]+@[A-Z0-9.\-]+\.[A-Z]{2,}$',
      caseSensitive: false,
    );
    if (!emailRegex.hasMatch(email)) return 'Format email tidak valid';
    final domain = email.split('@').last;
    final isDisposable = _disposableEmailDomains.any(
      (blocked) => domain == blocked || domain.endsWith('.$blocked'),
    );
    if (isDisposable) return 'Gunakan email aktif, bukan email sementara.';
    return null;
  }

  bool _hasPasswordLength(String password) => password.length >= 8;
  bool _hasPasswordUppercase(String password) =>
      RegExp(r'[A-Z]').hasMatch(password);
  bool _hasPasswordNumber(String password) => RegExp(r'\d').hasMatch(password);
  bool _hasPasswordSymbol(String password) =>
      RegExp(r'[^A-Za-z0-9]').hasMatch(password);

  List<String> _missingPasswordRequirements(String password) {
    return [
      if (!_hasPasswordLength(password)) 'minimal 8 karakter',
      if (!_hasPasswordUppercase(password)) 'huruf kapital',
      if (!_hasPasswordNumber(password)) 'angka',
      if (!_hasPasswordSymbol(password)) 'simbol',
    ];
  }

  String? _passwordValidationError(String password) {
    if (password.isEmpty) return 'Password wajib diisi.';
    final missing = _missingPasswordRequirements(password);
    if (missing.isEmpty) return null;
    return 'Lengkapi password: ${missing.join(', ')}.';
  }

  String? _confirmPasswordValidationError(
    String confirmPassword,
    String password,
  ) {
    if (confirmPassword.isEmpty) return 'Konfirmasi password wajib diisi.';
    if (confirmPassword != password) {
      return 'Password dan konfirmasi tidak cocok.';
    }
    return null;
  }

  bool _validateRegisterFields() {
    final phone = _normalizeIndonesianPhone(_phoneCtrl.text);
    final email = _normalizeEmail(_emailCtrl.text);
    _setControllerText(_phoneCtrl, phone);
    _setControllerText(_emailCtrl, email);

    final password = _passwordCtrl.text;
    final firstNameError = _firstNameCtrl.text.trim().isEmpty
        ? 'Nama depan wajib diisi.'
        : null;
    final lastNameError = _lastNameCtrl.text.trim().isEmpty
        ? 'Nama belakang wajib diisi.'
        : null;
    final phoneError = _phoneValidationError(phone);
    final emailError = _emailValidationError(email);
    final passwordError = _passwordValidationError(password);
    final confirmPasswordError = _confirmPasswordValidationError(
      _confirmPasswordCtrl.text,
      password,
    );

    setState(() {
      _firstNameError = firstNameError;
      _lastNameError = lastNameError;
      _phoneError = phoneError;
      _emailError = emailError;
      _passwordError = passwordError;
      _confirmPasswordError = confirmPasswordError;
      _showPasswordRequirements =
          _showPasswordRequirements ||
          passwordError != null ||
          password.isNotEmpty;
    });

    return [
      firstNameError,
      lastNameError,
      phoneError,
      emailError,
      passwordError,
      confirmPasswordError,
    ].every((error) => error == null);
  }

  void _handleRegister() async {
    FocusScope.of(context).unfocus();

    if (!_validateRegisterFields()) return;

    final firstName = _firstNameCtrl.text.trim();
    final lastName = _lastNameCtrl.text.trim();
    final phone = _normalizeIndonesianPhone(_phoneCtrl.text);
    final email = _normalizeEmail(_emailCtrl.text);
    setState(() => _isLoading = true);

    // Simulasi delay — ganti dengan API call saat BE siap
    await Future.delayed(const Duration(milliseconds: 800));

    if (!mounted) return;
    setState(() => _isLoading = false);

    // Integrasikan dengan API pendaftaran saat backend tersedia.
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
    } else if (widget.role == 'distributor') {
      // [FE - Event Handler] Aktifkan akun distributor baru di repository dengan
      // data registrasi sebelum membuka Beranda Distributor.
      DistributorRepository.instance.registerDistributor(
        firstName: firstName,
        lastName: lastName,
        phone: phone,
        email: email,
      );
      destination = const DistributorHomeScreen();
    } else if (widget.role == 'umkm') {
      // [FE - Event Handler] Aktifkan akun UMKM baru di repository sebelum
      // membuka halaman UMKM.
      // TODO: Tambahkan UMKM repository jika data UMKM harus disimpan.
      destination = const UmkmHomeScreen();
    } else if (widget.role == 'konsumen') {
      // [FE - Event Handler] Aktifkan akun konsumen baru di repository
      // sebelum membuka beranda konsumen.
      ConsumerRepository.instance.registerConsumer(
        firstName: firstName,
        lastName: lastName,
        phone: phone,
        email: email,
      );
      destination = const ConsumerHomeScreen();
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
    final password = _passwordCtrl.text;
    final showPasswordRequirements =
        _showPasswordRequirements ||
        _passwordFocus.hasFocus ||
        password.isNotEmpty;
    final showPhoneHelper = _phoneFocus.hasFocus || _phoneError != null;

    return Scaffold(
      backgroundColor: AppColors.primaryContainer,
      body: SafeArea(
        bottom: false,
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SlideTransition(
            position: _slideAnim,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Header Custom ────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 44),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.maybePop(context),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.arrow_back_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'Daftar Akun Baru',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: -0.5,
                                height: 1.05,
                              ),
                            ),
                            const SizedBox(height: 8),
                            RichText(
                              text: TextSpan(
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.white.withValues(alpha: 0.76),
                                  fontWeight: FontWeight.w500,
                                  height: 1.25,
                                ),
                                children: [
                                  const TextSpan(text: 'Mendaftar sebagai '),
                                  TextSpan(
                                    text: roleLabel,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // ── Form scrollable ──────────────────────────────────────
                Expanded(
                  child: Container(
                    decoration: const BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(32),
                        topRight: Radius.circular(32),
                      ),
                    ),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── Nama ──────────────────────────────────────────
                          _SectionLabel(label: 'Nama Lengkap'),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _FormField(
                                      hasError: _firstNameError != null,
                                      controller: _firstNameCtrl,
                                      focusNode: _firstNameFocus,
                                      hintText: 'Nama depan',
                                      prefixIcon: Icons.person_outline_rounded,
                                      textInputAction: TextInputAction.next,
                                      keyboardType: TextInputType.name,
                                      textCapitalization:
                                          TextCapitalization.words,
                                      onChanged: (_) {
                                        if (_firstNameError == null) return;
                                        setState(() {
                                          _firstNameError =
                                              _firstNameCtrl.text.trim().isEmpty
                                              ? 'Nama depan wajib diisi.'
                                              : null;
                                        });
                                      },
                                      onSubmitted: (_) => FocusScope.of(
                                        context,
                                      ).requestFocus(_lastNameFocus),
                                    ),
                                    _InlineFieldMessage(
                                      message: _firstNameError,
                                      isError: true,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _FormField(
                                      hasError: _lastNameError != null,
                                      controller: _lastNameCtrl,
                                      focusNode: _lastNameFocus,
                                      hintText: 'Nama belakang',
                                      prefixIcon: Icons.person_outline_rounded,
                                      textInputAction: TextInputAction.next,
                                      keyboardType: TextInputType.name,
                                      textCapitalization:
                                          TextCapitalization.words,
                                      onChanged: (_) {
                                        if (_lastNameError == null) return;
                                        setState(() {
                                          _lastNameError =
                                              _lastNameCtrl.text.trim().isEmpty
                                              ? 'Nama belakang wajib diisi.'
                                              : null;
                                        });
                                      },
                                      onSubmitted: (_) => FocusScope.of(
                                        context,
                                      ).requestFocus(_phoneFocus),
                                    ),
                                    _InlineFieldMessage(
                                      message: _lastNameError,
                                      isError: true,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),

                          // ── No. HP ────────────────────────────────────────
                          _SectionLabel(label: 'Nomor HP'),
                          const SizedBox(height: 8),
                          _FormField(
                            hasError: _phoneError != null,
                            controller: _phoneCtrl,
                            focusNode: _phoneFocus,
                            hintText: 'Contoh: 8123456789',
                            prefixIcon: Icons.phone_outlined,
                            prefixText:
                                _phoneFocus.hasFocus ||
                                    _phoneCtrl.text.isNotEmpty
                                ? '+62  '
                                : null,
                            textInputAction: TextInputAction.next,
                            keyboardType: TextInputType.phone,
                            inputFormatters: [
                              _IndonesianPhoneTextInputFormatter(),
                            ],
                            onSubmitted: (_) => FocusScope.of(
                              context,
                            ).requestFocus(_emailFocus),
                          ),
                          if (showPhoneHelper)
                            const _InlineFieldMessage(
                              message: 'Masukkan nomor tanpa angka 0 di depan',
                              icon: Icons.error_outline_rounded,
                            ),
                          _InlineFieldMessage(
                            message: _phoneError,
                            isError: true,
                          ),
                          const SizedBox(height: 18),

                          // ── Email ─────────────────────────────────────────
                          _SectionLabel(label: 'Email'),
                          const SizedBox(height: 8),
                          _FormField(
                            hasError: _emailError != null,
                            controller: _emailCtrl,
                            focusNode: _emailFocus,
                            hintText: 'contoh@email.com',
                            prefixIcon: Icons.email_outlined,
                            textInputAction: TextInputAction.next,
                            keyboardType: TextInputType.emailAddress,
                            onSubmitted: (_) => FocusScope.of(
                              context,
                            ).requestFocus(_passwordFocus),
                          ),
                          _InlineFieldMessage(
                            message: _emailError,
                            isError: true,
                          ),
                          const SizedBox(height: 18),

                          // ── Password ──────────────────────────────────────
                          _SectionLabel(label: 'Password'),
                          const SizedBox(height: 8),
                          _FormField(
                            hasError: _passwordError != null,
                            controller: _passwordCtrl,
                            focusNode: _passwordFocus,
                            hintText: 'Minimal 8 karakter',
                            prefixIcon: Icons.lock_outline_rounded,
                            obscureText: true,
                            textInputAction: TextInputAction.next,
                            onSubmitted: (_) => FocusScope.of(
                              context,
                            ).requestFocus(_confirmPasswordFocus),
                          ),
                          if (showPasswordRequirements)
                            _PasswordRequirementPanel(
                              errorMessage: _passwordError,
                              hasLength: _hasPasswordLength(password),
                              hasUppercase: _hasPasswordUppercase(password),
                              hasNumber: _hasPasswordNumber(password),
                              hasSymbol: _hasPasswordSymbol(password),
                            ),
                          const SizedBox(height: 18),

                          // ── Konfirmasi Password ───────────────────────────
                          _SectionLabel(label: 'Konfirmasi Password'),
                          const SizedBox(height: 8),
                          _FormField(
                            hasError: _confirmPasswordError != null,
                            controller: _confirmPasswordCtrl,
                            focusNode: _confirmPasswordFocus,
                            hintText: 'Ulangi password',
                            prefixIcon: Icons.lock_outline_rounded,
                            obscureText: true,
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) => _handleRegister(),
                          ),
                          _InlineFieldMessage(
                            message: _confirmPasswordError,
                            isError: true,
                          ),
                          const SizedBox(height: 24),

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
                                        color: Color.fromARGB(255, 86, 149, 63),
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
class RegisterTopAppBar extends StatelessWidget {
  const RegisterTopAppBar({super.key, required this.onBack});
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
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.black,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }
}

/// Label section di atas setiap field dengan dot indicator hijau.
class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: Color(0xFF334155),
        ),
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
    this.hasError = false,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.prefixText,
    this.prefixIcon,
    this.inputFormatters,
    this.onChanged,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String hintText;
  final bool hasError;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final String? prefixText;
  final IconData? prefixIcon;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;
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
      borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1.3),
    );
    final focusedBorder = OutlineInputBorder(
      borderRadius: radius,
      borderSide: const BorderSide(color: AppColors.primaryContainer, width: 2),
    );
    final errorBorder = OutlineInputBorder(
      borderRadius: radius,
      borderSide: const BorderSide(color: Color(0xFFDC2626), width: 1.5),
    );

    final effectiveBorder = widget.hasError ? errorBorder : border;
    final iconColor = widget.hasError
        ? const Color(0xFFDC2626)
        : const Color(0xFF94A3B8);

    return TextField(
      controller: widget.controller,
      focusNode: widget.focusNode,
      obscureText: _obscure,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      textCapitalization: widget.textCapitalization,
      inputFormatters: widget.inputFormatters,
      onChanged: widget.onChanged,
      onSubmitted: widget.onSubmitted,
      style: const TextStyle(
        fontSize: 14,
        color: AppColors.black,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        hintText: widget.hintText,
        hintStyle: const TextStyle(
          fontSize: 14,
          color: Color(0xFF94A3B8),
          fontWeight: FontWeight.w400,
        ),
        prefixText: widget.prefixText,
        prefixIcon: widget.prefixIcon != null
            ? Icon(widget.prefixIcon, color: iconColor, size: 20)
            : null,
        prefixIconConstraints: const BoxConstraints(
          minWidth: 44,
          minHeight: 40,
        ),
        prefixStyle: const TextStyle(
          fontSize: 14,
          color: AppColors.black,
          fontWeight: FontWeight.w600,
        ),
        filled: true,
        fillColor: widget.hasError
            ? const Color(0xFFFEF2F2)
            : const Color(0xFFF8FAFC),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 13,
        ),
        border: effectiveBorder,
        enabledBorder: effectiveBorder,
        focusedBorder: widget.hasError ? errorBorder : focusedBorder,
        suffixIcon: widget.obscureText
            ? SizedBox(
                width: 44,
                height: 40,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 44,
                    minHeight: 40,
                  ),
                  onPressed: () => setState(() => _obscure = !_obscure),
                  icon: Icon(
                    _obscure
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: const Color(0xFF94A3B8),
                    size: 20,
                  ),
                ),
              )
            : null,
        suffixIconConstraints: const BoxConstraints(
          minWidth: 44,
          minHeight: 40,
        ),
      ),
    );
  }
}

class _IndonesianPhoneTextInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    while (digits.startsWith('0')) {
      digits = digits.substring(1);
    }
    while (digits.startsWith('62')) {
      digits = digits.substring(2);
    }
    if (digits.length > 13) {
      digits = digits.substring(0, 13);
    }
    return TextEditingValue(
      text: digits,
      selection: TextSelection.collapsed(offset: digits.length),
    );
  }
}

class _InlineFieldMessage extends StatelessWidget {
  const _InlineFieldMessage({
    required this.message,
    this.isError = false,
    this.icon,
  });

  final String? message;
  final bool isError;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    if (message == null || message!.isEmpty) {
      return const SizedBox.shrink();
    }

    final color = isError ? const Color(0xFFDC2626) : AppColors.placeholder;
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon ?? Icons.error_outline_rounded, size: 14, color: color),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              message!,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w500,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PasswordRequirementPanel extends StatelessWidget {
  const _PasswordRequirementPanel({
    required this.hasLength,
    required this.hasUppercase,
    required this.hasNumber,
    required this.hasSymbol,
    this.errorMessage,
  });

  final bool hasLength;
  final bool hasUppercase;
  final bool hasNumber;
  final bool hasSymbol;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InlineFieldMessage(message: errorMessage, isError: true),
          const SizedBox(height: 8),
          _PasswordRequirementItem(
            text: 'Minimal 8 karakter',
            isMet: hasLength,
          ),
          _PasswordRequirementItem(
            text: 'Gunakan huruf kapital',
            isMet: hasUppercase,
          ),
          _PasswordRequirementItem(text: 'Masukkan angka', isMet: hasNumber),
          _PasswordRequirementItem(text: 'Masukkan simbol', isMet: hasSymbol),
        ],
      ),
    );
  }
}

class _PasswordRequirementItem extends StatelessWidget {
  const _PasswordRequirementItem({required this.text, required this.isMet});

  final String text;
  final bool isMet;

  @override
  Widget build(BuildContext context) {
    final color = isMet ? const Color(0xFF58A835) : AppColors.placeholder;
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Icon(Icons.check_circle_outline_rounded, size: 14, color: color),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: isMet ? FontWeight.w600 : FontWeight.w500,
                height: 1.3,
              ),
            ),
          ),
        ],
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
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryContainer.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryContainer,
          foregroundColor: AppColors.white,
          disabledBackgroundColor: AppColors.primaryContainer.withValues(
            alpha: 0.6,
          ),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
                ),
              )
            : const Text(
                'DAFTAR',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
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
