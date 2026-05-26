import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Landing + login screen for DurianTrace.
///
/// Layout:
/// - Top white section: durian illustration, "Selamat Datang" caption,
///   and the system title.
/// - Bottom green canvas with rounded top corners that hosts the email and
///   password fields, the MASUK button, and the "Daftar Disini" link.
/// - A footer caption pinned to the bottom of the green canvas.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _identifierController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final FocusNode _identifierFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    _identifierFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  void _handleLogin() {
    // Frontend-only stub. Authentication wiring happens in a later task
    // (see TASK MOB-02 in the blueprint).
    FocusScope.of(context).unfocus();
    final identifier = _identifierController.text.trim();
    final password = _passwordController.text;

    if (identifier.isEmpty || password.isEmpty) {
      _showSnack('Email/Username dan password wajib diisi.');
      return;
    }

    _showSnack('Form siap dikirim ke backend.');
  }

  void _handleRegisterTap() {
    _showSnack('Halaman daftar belum tersedia.');
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      // resizeToAvoidBottomInset = true (default) keeps the green panel
      // visible when the keyboard appears.
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const _WelcomeHeader(),
            Expanded(
              child: _LoginPanel(
                identifierController: _identifierController,
                passwordController: _passwordController,
                identifierFocus: _identifierFocus,
                passwordFocus: _passwordFocus,
                onLogin: _handleLogin,
                onRegisterTap: _handleRegisterTap,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Top white section: durian image, welcome caption, and the system title.
class _WelcomeHeader extends StatelessWidget {
  const _WelcomeHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 55),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Durian illustration sourced from local assets.
          Transform.translate(
            offset: const Offset(0, 27), // positif = turun, negatif = naik
            child: Image.asset(
              'assets/images/durian.png',
              width: 170,
              height: 170,
              fit: BoxFit.contain,
              // If the asset is missing for any reason, fall back to a glyph
              // so the layout never breaks during development.
              errorBuilder: (context, error, stackTrace) => const Text(
                'Icon Durian',
                style: TextStyle(fontSize: 64),
              ),
            ),
          ),
          const SizedBox(height: 7),
            Transform.translate(
            offset: const Offset(0, 25), // positif = turun, negatif = naik
            child: const Text(
            'Selamat Datang',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              letterSpacing: 0.4,
              color: Color.fromARGB(255, 2, 2, 3),
            ),
          ),
          ),
          const SizedBox(height: 10),
          Transform.translate(
            offset: const Offset(0, 27), // positif = turun, negatif = naik
            child: const Text(
              'System Traceability Durian\nJawa Timur',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                height: 1.3,
                color: AppColors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Green canvas with the login form and the footer disclaimer.
class _LoginPanel extends StatelessWidget {
  const _LoginPanel({
    required this.identifierController,
    required this.passwordController,
    required this.identifierFocus,
    required this.passwordFocus,
    required this.onLogin,
    required this.onRegisterTap,
  });

  final TextEditingController identifierController;
  final TextEditingController passwordController;
  final FocusNode identifierFocus;
  final FocusNode passwordFocus;
  final VoidCallback onLogin;
  final VoidCallback onRegisterTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.primaryContainer,
        borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
        child: Stack(
          children: [
            // Form content.
            SafeArea(
              top: false,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 55, 24, 24),
                child: Column(
                  children: [
                    _RoundedTextField(
                      controller: identifierController,
                      focusNode: identifierFocus,
                      hintText: 'Masukan Email / Username',
                      textInputAction: TextInputAction.next,
                      keyboardType: TextInputType.emailAddress,
                      onSubmitted: (_) =>
                          FocusScope.of(context).requestFocus(passwordFocus),
                    ),
                    const SizedBox(height: 20),
                    _RoundedTextField(
                      controller: passwordController,
                      focusNode: passwordFocus,
                      hintText: 'Password',
                      obscureText: true,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => onLogin(),
                    ),
                    const SizedBox(height: 55),
                    _PrimaryActionButton(onPressed: onLogin),
                    const SizedBox(height: 35),
                    GestureDetector(
                      onTap: onRegisterTap,
                      behavior: HitTestBehavior.opaque,
                      child: const Text(
                        'Daftar Disini',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.black,
                          decoration: TextDecoration.underline,
                          decorationThickness: 2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 86),
                    const Text(
                      'PEMERINTAH PROVINSI JAWA TIMUR',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.6,
                        color: AppColors.footerCaption,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// White pill-shaped text field used by the login panel.
class _RoundedTextField extends StatelessWidget {
  const _RoundedTextField({
    required this.controller,
    required this.focusNode,
    required this.hintText,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String hintText;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    const border = OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(999)),
      borderSide: BorderSide.none,
    );

    return TextField(
      controller: controller,
      focusNode: focusNode,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      onSubmitted: onSubmitted,
      textAlign: TextAlign.center,
      style: const TextStyle(
        fontSize: 14,
        color: AppColors.black,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(
          fontSize: 14,
          color: AppColors.placeholder,
        ),
        filled: true,
        fillColor: AppColors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        border: border,
        enabledBorder: border,
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(999)),
          borderSide: BorderSide(
            color: Color.fromRGBO(144, 217, 114, 1),
            width: 2,
          ),
        ),
      ),
    );
  }
}

/// White rounded "MASUK" button.
class _PrimaryActionButton extends StatelessWidget {
  const _PrimaryActionButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.black,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 37, vertical: 14),
      ),
      child: Stack(
        children: [
          // Layer bawah: stroke/outline
          Text(
            'MASUK',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              letterSpacing: 2,
              foreground: Paint()
                ..style = PaintingStyle.stroke
                ..strokeWidth = 1
                ..color = AppColors.black,
            ),
          ),
          // Layer atas: fill normal
          const Text(
            'MASUK',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
              color: AppColors.black,
            ),
          ),
        ],
      ),
    );
  }
}
