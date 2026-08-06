import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_top_bar.dart';
import '../../auth/screens/home_screen.dart';
import '../consumer_routes.dart';
import '../data/consumer_repository.dart';
import '../widgets/consumer_avatar.dart';
import 'edit_consumer_profile_screen.dart';

const String _kNotSet = 'Belum dilengkapi';
const Color _profileGreen = Color.fromARGB(255, 88, 168, 53);

class ConsumerProfileScreen extends StatefulWidget {
  const ConsumerProfileScreen({super.key});

  @override
  State<ConsumerProfileScreen> createState() => _ConsumerProfileScreenState();
}

class _ConsumerProfileScreenState extends State<ConsumerProfileScreen> {
  final _repo = ConsumerRepository.instance;

  @override
  void initState() {
    super.initState();
    _repo.addListener(_refresh);
  }

  @override
  void dispose() {
    _repo.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  Future<void> _edit() =>
      ConsumerRoutes.push(context, const EditConsumerProfileScreen());

  Future<void> _logout() async {
    final confirmed = await _showLogoutDialog(context);
    if (!confirmed || !mounted) return;
    _repo.logout();
    ConsumerRoutes.replaceAll(context, const HomeScreen());
  }

  @override
  Widget build(BuildContext context) {
    final profile = _repo.profile;
    return Scaffold(
      backgroundColor: const Color(0xFFF0F7EC),
      body: SafeArea(
        child: Column(
          children: [
            AppTopBar(
              title: 'Profil',
              actions: [_EditButton(onPressed: _edit)],
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(14, 24, 14, 40),
                children: [
                  _Card(
                    color: const Color(0xFFFAFCF8),
                    radius: 30,
                    child: Column(
                      children: [
                        ConsumerAvatar(
                          profile: profile,
                          size: 96,
                          showEditButton: true,
                        ),
                        const SizedBox(height: 18),
                        Text(
                          profile.fullName,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 23,
                            fontWeight: FontWeight.w800,
                            color: AppColors.subtitle,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFDFEFB),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: _profileGreen.withValues(alpha: 0.28),
                            ),
                          ),
                          child: Text(
                            profile.roleLabel,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: _profileGreen,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 26),
                  const Padding(
                    padding: EdgeInsets.only(left: 7, bottom: 12),
                    child: Text(
                      'INFORMASI DETAIL',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppColors.placeholder,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: _Info(
                          icon: Icons.phone_outlined,
                          label: 'NOMOR HP',
                          value: profile.contact,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _Info(
                          icon: Icons.location_on_outlined,
                          label: 'DOMISILI',
                          value: profile.location,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _Info(
                    icon: Icons.mail_outline_rounded,
                    label: 'ALAMAT EMAIL',
                    value: profile.email,
                    horizontal: true,
                  ),
                  const SizedBox(height: 32),
                  _Card(
                    padding: EdgeInsets.zero,
                    radius: 20,
                    borderColor: const Color(0xFFF1D3D3),
                    child: OutlinedButton.icon(
                      onPressed: _logout,
                      icon: const Icon(Icons.logout_rounded),
                      label: const Text('Keluar Akun'),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide.none,
                        foregroundColor: const Color(0xFFDC2626),
                        padding: const EdgeInsets.symmetric(vertical: 17),
                        textStyle: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
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

class _Card extends StatelessWidget {
  const _Card({
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.radius = 24,
    this.color = Colors.white,
    this.borderColor = const Color(0xFFD5E3CF),
  });
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color color;
  final Color borderColor;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: padding,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: borderColor, width: 1.2),
    ),
    child: child,
  );
}

class _EditButton extends StatelessWidget {
  const _EditButton({required this.onPressed});
  final VoidCallback onPressed;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(right: 4),
    child: Material(
      color: const Color(0xFFF8FBF5),
      shape: const CircleBorder(side: BorderSide(color: Colors.white)),
      child: IconButton(
        onPressed: onPressed,
        tooltip: 'Ubah Profil',
        icon: const Icon(Icons.edit_rounded, color: _profileGreen, size: 20),
      ),
    ),
  );
}

class _Info extends StatelessWidget {
  const _Info({
    required this.icon,
    required this.label,
    required this.value,
    this.horizontal = false,
  });
  final IconData icon;
  final String label;
  final String value;
  final bool horizontal;
  @override
  Widget build(BuildContext context) {
    final empty = value.trim().isEmpty;
    final text = empty ? _kNotSet : value.trim();
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w800,
            color: AppColors.placeholder,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          text,
          maxLines: horizontal ? 2 : 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: empty ? AppColors.placeholder : AppColors.subtitle,
            fontStyle: empty ? FontStyle.italic : FontStyle.normal,
          ),
        ),
      ],
    );
    final iconWidget = Container(
      width: 40,
      height: 40,
      decoration: const BoxDecoration(
        color: Color(0xFFE8F5E2),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Icon(icon, size: 21, color: _profileGreen),
    );
    return _Card(
      child: horizontal
          ? Row(
              children: [
                iconWidget,
                const SizedBox(width: 16),
                Expanded(child: content),
              ],
            )
          : SizedBox(
              height: 90,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      iconWidget,
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          label,
                          style: const TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            color: AppColors.placeholder,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    text,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: empty ? AppColors.placeholder : AppColors.subtitle,
                      fontStyle: empty ? FontStyle.italic : FontStyle.normal,
                    ),
                  ),
                ],
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
      title: const Text(
        'Keluar Akun?',
        style: TextStyle(fontWeight: FontWeight.w800),
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
