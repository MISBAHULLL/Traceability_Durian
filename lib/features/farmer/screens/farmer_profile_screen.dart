import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_top_bar.dart';
import '../../auth/screens/home_screen.dart';
import '../data/farmer_repository.dart';
import '../farmer_routes.dart';
import '../models/harvest_batch.dart';
import '../widgets/farmer_avatar.dart';
import 'edit_profile_screen.dart';

const String _kNotSet = 'Belum dilengkapi';
const Color _profileGreen = Color.fromARGB(255, 88, 168, 53);

class FarmerProfileScreen extends StatefulWidget {
  const FarmerProfileScreen({super.key});

  @override
  State<FarmerProfileScreen> createState() => _FarmerProfileScreenState();
}

class _FarmerProfileScreenState extends State<FarmerProfileScreen>
    with SingleTickerProviderStateMixin {
  final _repo = FarmerRepository.instance;

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
      curve: const Interval(0, 0.8, curve: Curves.easeInOutCubic),
    );
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _animController,
            curve: const Interval(0, 0.9, curve: Curves.easeOutCubic),
          ),
        );
    _animController.forward();
    _repo.addListener(_onRepoChanged);
  }

  @override
  void dispose() {
    _repo.removeListener(_onRepoChanged);
    _animController.dispose();
    super.dispose();
  }

  void _onRepoChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _openEditProfile() async {
    await FarmerRoutes.push(context, const EditProfileScreen());
  }

  Future<void> _handleLogout() async {
    setState(() => _isLoggingOut = true);
    await Future.delayed(const Duration(milliseconds: 300));

    if (!mounted) return;
    _repo.logout();
    FarmerRoutes.replaceAll(context, const HomeScreen());
  }

  @override
  Widget build(BuildContext context) {
    final profile = _repo.profile;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Stack(
        children: [
          const Positioned.fill(child: _ProfileBackground()),
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: Column(
                  children: [
                    AppTopBar(
                      title: 'Profil',
                      actions: [
                        _ProfileIconButton(
                          icon: Icons.edit_rounded,
                          tooltip: 'Ubah Profil',
                          onPressed: _openEditProfile,
                        ),
                      ],
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(14, 24, 14, 40),
                        physics: const BouncingScrollPhysics(),
                        child: Column(
                          children: [
                            _BentoCard(
                              borderRadius: 30,
                              color: const Color(0xFFFAFCF8),
                              padding: const EdgeInsets.fromLTRB(
                                24,
                                26,
                                24,
                                24,
                              ),
                              child: _ProfileHeader(profile: profile),
                            ),
                            const SizedBox(height: 26),
                            _ProfileInfoSection(profile: profile),
                            const SizedBox(height: 32),
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
        ],
      ),
    );
  }
}

class _ProfileBackground extends StatelessWidget {
  const _ProfileBackground();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(color: Color(0xFFF0F7EC));
  }
}

class _BentoCard extends StatelessWidget {
  const _BentoCard({
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.borderRadius = 24,
    this.color = Colors.white,
    this.borderColor = const Color(0xFFD5E3CF),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final Color color;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: borderColor, width: 1.2),
      ),
      child: child,
    );
  }
}

class _ProfileIconButton extends StatelessWidget {
  const _ProfileIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: Material(
        color: const Color(0xFFF8FBF5),
        shape: const CircleBorder(
          side: BorderSide(color: Colors.white, width: 1.2),
        ),
        child: IconButton(
          onPressed: onPressed,
          tooltip: tooltip,
          icon: Icon(icon, color: _profileGreen, size: 20),
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.profile});

  final FarmerProfile profile;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 4),
          ),
          child: FarmerAvatar(profile: profile, size: 96, showEditButton: true),
        ),
        const SizedBox(height: 18),
        Text(
          profile.fullName,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 23,
            fontWeight: FontWeight.w800,
            color: AppColors.subtitle,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
          decoration: BoxDecoration(
            color: const Color(0xFFFDFEFB),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: _profileGreen.withValues(alpha: 0.28)),
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
    );
  }
}

class _ProfileInfoSection extends StatelessWidget {
  const _ProfileInfoSection({required this.profile});

  final FarmerProfile profile;

  @override
  Widget build(BuildContext context) {
    final address = _composeAddress(profile);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
        LayoutBuilder(
          builder: (context, constraints) {
            final useColumns = constraints.maxWidth >= 310;
            final locationCard = _InfoCard(
              icon: Icons.location_on_outlined,
              label: 'LOKASI KEBUN',
              value: address,
              isEmpty: address == _kNotSet,
              color: Colors.white,
            );
            final phoneCard = _InfoCard(
              icon: Icons.phone_outlined,
              label: 'NOMOR HP',
              value: profile.contact.isEmpty ? _kNotSet : profile.contact,
              isEmpty: profile.contact.isEmpty,
              color: Colors.white,
            );

            return Column(
              children: [
                if (useColumns)
                  Row(
                    children: [
                      Expanded(child: locationCard),
                      const SizedBox(width: 14),
                      Expanded(child: phoneCard),
                    ],
                  )
                else ...[
                  locationCard,
                  const SizedBox(height: 14),
                  phoneCard,
                ],
                const SizedBox(height: 14),
                _InfoCard(
                  icon: Icons.mail_outline_rounded,
                  label: 'ALAMAT EMAIL',
                  value: profile.emailValue.isEmpty
                      ? _kNotSet
                      : profile.emailValue,
                  isEmpty: profile.emailValue.isEmpty,
                  horizontal: true,
                  color: Colors.white,
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  static String _composeAddress(FarmerProfile profile) {
    final parts = <String>[
      if (profile.village.isNotEmpty) 'Desa ${profile.village}',
      if (profile.district.isNotEmpty) 'Kec. ${profile.district}',
      if (profile.city.isNotEmpty) profile.city,
    ];
    if (parts.isNotEmpty) return parts.join(', ');
    return profile.location.isNotEmpty ? profile.location : _kNotSet;
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.label,
    required this.value,
    this.isEmpty = false,
    this.horizontal = false,
    this.color = Colors.white,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool isEmpty;
  final bool horizontal;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final valueText = Text(
      value,
      maxLines: horizontal ? 2 : 3,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: isEmpty ? AppColors.placeholder : AppColors.subtitle,
        fontStyle: isEmpty ? FontStyle.italic : FontStyle.normal,
        height: 1.3,
      ),
    );
    final labelText = Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        fontSize: 10.5,
        fontWeight: FontWeight.w800,
        color: AppColors.placeholder,
        letterSpacing: 0.35,
      ),
    );
    final horizontalContent = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [labelText, const SizedBox(height: 5), valueText],
    );

    return _BentoCard(
      borderRadius: 24,
      color: color,
      padding: EdgeInsets.all(horizontal ? 18 : 20),
      child: horizontal
          ? Row(
              children: [
                _InfoIcon(icon: icon),
                const SizedBox(width: 16),
                Expanded(child: horizontalContent),
              ],
            )
          : SizedBox(
              height: 90,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _InfoIcon(icon: icon),
                      const SizedBox(width: 12),
                      Expanded(child: labelText),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(width: double.infinity, child: valueText),
                ],
              ),
            ),
    );
  }
}

class _InfoIcon extends StatelessWidget {
  const _InfoIcon({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E2),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withValues(alpha: 0.9)),
      ),
      alignment: Alignment.center,
      child: Icon(icon, size: 21, color: _profileGreen),
    );
  }
}

class _LogoutButton extends StatelessWidget {
  const _LogoutButton({required this.isLoading, required this.onPressed});

  final bool isLoading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return _BentoCard(
      borderRadius: 20,
      padding: EdgeInsets.zero,
      color: const Color(0xFFFFFDFC),
      borderColor: const Color(0xFFF1D3D3),
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          side: BorderSide.none,
          foregroundColor: const Color(0xFFDC2626),
          disabledForegroundColor: const Color(
            0xFFDC2626,
          ).withValues(alpha: 0.5),
          padding: const EdgeInsets.symmetric(vertical: 17),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
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
                  Icon(Icons.logout_rounded, size: 21),
                  SizedBox(width: 10),
                  Text(
                    'Keluar Akun',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
