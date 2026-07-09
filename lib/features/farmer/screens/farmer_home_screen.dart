import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/batch_photo.dart';
import '../data/farmer_repository.dart';
import '../farmer_routes.dart';
import '../models/harvest_batch.dart';
import 'add_batch_screen.dart';
import 'batch_detail_screen.dart';
import 'batch_qr_screen.dart';
import 'farmer_profile_screen.dart';
import '../widgets/farmer_drawer.dart';

// [FE - Component Rendering] Screen ini adalah layar root petani setelah
// login — menampilkan ringkasan statistik, daftar batch, dan navigasi
// ke semua fitur utama petani.
/// Beranda untuk role Petani (Farmer).
///
/// Mengikuti gaya visual prototype "Beranda" (header, greeting, CTA hijau,
/// search pill, filter chips, card list) namun struktur informasinya
/// disesuaikan dengan peran petani sesuai blueprint:
/// - Petani hanya membuat & melihat batch panen miliknya + QR (role matrix).
/// - Status batch mengikuti state machine (badge per status).
///
/// Data dibaca dari [FarmerRepository.instance] dan di-rebuild secara reaktif
/// saat repo berubah (mis. setelah tambah batch atau tambah kebun).
class FarmerHomeScreen extends StatefulWidget {
  const FarmerHomeScreen({super.key});

  @override
  State<FarmerHomeScreen> createState() => _FarmerHomeScreenState();
}

class _FarmerHomeScreenState extends State<FarmerHomeScreen>
    with SingleTickerProviderStateMixin {
  final _repo = FarmerRepository.instance;
  final TextEditingController _searchController = TextEditingController();

  // Key untuk membuka navigation drawer dari ikon hamburger di top bar.
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  BatchFilter _activeFilter = BatchFilter.semua;
  String _query = '';

  late final AnimationController _animController;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

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

    _searchController.addListener(() {
      setState(() => _query = _searchController.text.trim().toLowerCase());
    });

    // Dengarkan perubahan repo agar stat cards, daftar, dan badge
    // ter-refresh secara reaktif (Req 1.2, 1.3).
    _repo.addListener(_onRepoChanged);
  }

  @override
  void dispose() {
    _repo.removeListener(_onRepoChanged);
    _animController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // [FE - State Management] _onRepoChanged adalah listener reaktif yang
  // memicu rebuild saat FarmerRepository berubah (batch/kebun baru ditambah).
  void _onRepoChanged() {
    if (mounted) setState(() {});
  }

  // [UTIL - Helper Function] _filteredBatches menggabungkan filter chip
  // dan query pencarian menjadi satu daftar — menggunakan pure function
  // searchAndFilterBatches agar logika filter dapat diuji secara independen.
  /// Daftar batch setelah difilter chip + query pencarian (Req 1.4, 1.5, 1.6).
  ///
  /// Menggunakan helper murni [searchAndFilterBatches] dari FarmerRepository.
  List<HarvestBatch> get _filteredBatches {
    return searchAndFilterBatches(_repo.batches, _activeFilter, _query);
  }

  // ── Navigasi ───────────────────────────────────────────────────────────────

  /// Buka Layar Tambah Batch Panen (Req 1.8).
  Future<void> _openAddBatch() async {
    await FarmerRoutes.push(context, const AddBatchScreen());
    // Repo listener (_onRepoChanged) sudah menangani refresh otomatis.
  }

  /// Buka Layar Detail Batch untuk batch tertentu (Req 1.9).
  Future<void> _openBatchDetail(String code) async {
    await FarmerRoutes.push(context, BatchDetailScreen(batchCode: code));
  }

  /// Buka Layar QR Batch untuk batch tertentu (Req 1.10).
  Future<void> _openBatchQr(String code) async {
    await FarmerRoutes.push(context, BatchQrScreen(batchCode: code));
  }

  /// Buka Layar Profil Petani (Req 1.11).
  Future<void> _openProfile() async {
    await FarmerRoutes.push(context, const FarmerProfileScreen());
  }

  /// Buka navigation drawer dari ikon hamburger.
  void _openDrawer() {
    _scaffoldKey.currentState?.openEndDrawer();
  }

  @override
  Widget build(BuildContext context) {
    final batches = _filteredBatches;
    final profile = _repo.profile;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.white,
      endDrawer: const FarmerDrawer(),
      body: ColoredBox(
        color: AppColors.homeHeaderSurface,
        child: SafeArea(
          bottom: false,
          child: FadeTransition(
            opacity: _fadeAnim,
            child: SlideTransition(
              position: _slideAnim,
              child: Column(
                children: [
                  _TopBar(onProfile: _openProfile, onMenu: _openDrawer),
                  Expanded(
                    child: ColoredBox(
                      color: AppColors.white,
                      child: CustomScrollView(
                        physics: const BouncingScrollPhysics(),
                        slivers: [
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                            sliver: SliverList(
                              delegate: SliverChildListDelegate([
                                _GreetingBlock(profile: profile),
                                const SizedBox(height: 16),
                                _StatRow(repo: _repo),
                                const SizedBox(height: 16),
                                _AddBatchCard(onTap: _openAddBatch),
                                const SizedBox(height: 16),
                                _SearchField(controller: _searchController),
                                const SizedBox(height: 14),
                                _FilterChips(
                                  active: _activeFilter,
                                  onChanged: (f) =>
                                      setState(() => _activeFilter = f),
                                ),
                                const SizedBox(height: 16),
                                _SectionHeader(count: batches.length),
                                const SizedBox(height: 12),
                              ]),
                            ),
                          ),
                          if (batches.isEmpty)
                            const SliverFillRemaining(
                              hasScrollBody: false,
                              child: _EmptyState(),
                            )
                          else
                            SliverPadding(
                              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                              sliver: SliverList(
                                delegate: SliverChildBuilderDelegate((
                                  context,
                                  index,
                                ) {
                                  final batch = batches[index];
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: _BatchCard(
                                      batch: batch,
                                      onTap: () => _openBatchDetail(batch.code),
                                      onShowQr: () => _openBatchQr(batch.code),
                                    ),
                                  );
                                }, childCount: batches.length),
                              ),
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
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Top bar
// ─────────────────────────────────────────────────────────────────────────────

// [FE - Component Rendering] _TopBar adalah top bar khusus Beranda —
// tidak memiliki tombol back karena ini adalah layar root setelah login.
/// Top bar: judul "Beranda" di tengah + ikon profil & menu di kanan.
///
/// Tidak ada tombol back karena beranda adalah root setelah login.
/// Ikon menu membuka navigation drawer (Beranda, Kelola Kebun, Profil,
/// Bantuan, Tentang, Keluar).
class _TopBar extends StatelessWidget {
  const _TopBar({required this.onProfile, required this.onMenu});

  final VoidCallback onProfile;
  final VoidCallback onMenu;

  @override
  Widget build(BuildContext context) {
    return Container(
      // [FE - Component Rendering] Band header ini menjadi pembatas visual
      // antara area sistem atas dan konten utama beranda.
      width: double.infinity,
      color: AppColors.homeHeaderSurface,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Row(
        children: [
          const Text(
            'Beranda',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppColors.black,
              letterSpacing: -0.5,
            ),
          ),
          const Spacer(),
          _IconButton(icon: Icons.person_outline_rounded, onTap: onProfile),
          const SizedBox(width: 10),
          _IconButton(icon: Icons.menu_rounded, onTap: onMenu),
        ],
      ),
    );
  }
}

class _IconButton extends StatelessWidget {
  const _IconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFF0F2F5)),
          ),
          child: Icon(icon, color: AppColors.black, size: 22),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Greeting
// ─────────────────────────────────────────────────────────────────────────────

class _GreetingBlock extends StatelessWidget {
  const _GreetingBlock({required this.profile});

  final FarmerProfile profile;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Halo, ${profile.fullName}',
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppColors.black,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            // Label peran bergaya lencana, TANPA icon
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.2),
                ),
              ),
              child: Text(
                profile.roleLabel,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),

            // Tampilkan lokasi hanya bila sudah dilengkapi
            if (profile.location.isNotEmpty) ...[
              const SizedBox(width: 8),
              const Icon(
                Icons.location_on_rounded,
                size: 14,
                color: AppColors.placeholder,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  profile.location,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.placeholder,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Statistik ringkas
// ─────────────────────────────────────────────────────────────────────────────

// [FE - Component Rendering] _StatRow menampilkan tiga kartu ringkasan
// yang nilainya dibaca langsung dari FarmerRepository — ter-refresh
// otomatis saat repo berubah via listener di FarmerHomeScreen.
class _StatRow extends StatelessWidget {
  const _StatRow({required this.repo});

  final FarmerRepository repo;

  @override
  Widget build(BuildContext context) {
    final items = [
      _StatItem(
        value: '${repo.totalBatch}',
        label: 'Total Batch',
        icon: Icons.inventory_2_rounded,
        color: AppColors.primary,
      ),
      _StatItem(
        value: '${repo.pendingVerificationBatch}',
        label: 'Menunggu',
        icon: Icons.pending_actions_rounded,
        color: const Color(0xFFD97706),
      ),
      _StatItem(
        value: '${repo.verifiedBatch}',
        label: 'Diterima',
        icon: Icons.verified_rounded,
        color: const Color(0xFF16A34A),
      ),
      _StatItem(
        value: '${repo.rejectedBatch}',
        label: 'Ditolak',
        icon: Icons.cancel_outlined,
        color: const Color(0xFFDC2626),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 12.0;
        const peekWidth = 10.0;
        final rawCardWidth = (constraints.maxWidth - (gap * 3) - peekWidth) / 3;
        final cardWidth = rawCardWidth.clamp(96.0, 118.0).toDouble();
        const cardHeight = 112.0;

        // [FE - Component Rendering] List horizontal ini menjaga tiga kartu
        // tetap dominan di mobile, sementara kartu Ditolak tersedia via swipe.
        return SizedBox(
          height: cardHeight,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            clipBehavior: Clip.none,
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(width: gap),
            itemBuilder: (context, index) {
              final item = items[index];
              return SizedBox(
                width: cardWidth,
                height: cardHeight,
                child: _StatCard(
                  value: item.value,
                  label: item.label,
                  icon: item.icon,
                  color: item.color,
                ),
              );
            },
          ),
        );
      },
    );
  }
}

// [FE - Component Rendering] Model tampilan ringan ini menyatukan value,
// label, icon, dan warna agar daftar statistik mudah ditambah tanpa duplikasi.
class _StatItem {
  const _StatItem({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });

  final String value;
  final String label;
  final IconData icon;
  final Color color;
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });

  final String value;
  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    // [FE - Component Rendering] Kartu ini mengisi ukuran dari parent strip
    // agar isi statistik tidak overflow pada layar mobile sempit.
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 19, color: color),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w800,
              color: color,
              height: 1.0,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10.5,
              color: AppColors.placeholder,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CTA Tambah Batch (versi petani dari "Tambah Transaksi" prototype)
// ─────────────────────────────────────────────────────────────────────────────

class _AddBatchCard extends StatelessWidget {
  const _AddBatchCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.primaryContainer,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tambah Batch Panen',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.white,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Catat panen dan siapkan QR untuk pengepul',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFFEAF7E5),
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: Color(0xFFF3B23C),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.add_rounded,
                color: AppColors.white,
                size: 26,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Search
// ─────────────────────────────────────────────────────────────────────────────

class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      style: const TextStyle(fontSize: 14, color: AppColors.black),
      decoration: InputDecoration(
        hintText: 'Cari kode batch / varietas',
        hintStyle: const TextStyle(fontSize: 14, color: AppColors.placeholder),
        prefixIcon: const Icon(
          Icons.search_rounded,
          color: AppColors.placeholder,
          size: 22,
        ),
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(999),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(999),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(999),
          borderSide: const BorderSide(
            color: AppColors.primaryContainer,
            width: 2,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Filter chips
// ─────────────────────────────────────────────────────────────────────────────

// [FE - Component Rendering] _FilterChips menampilkan chip filter status
// dan memanggil onChanged saat chip dipilih — state filter disimpan
// di FarmerHomeScreen dan dipakai oleh _filteredBatches.
class _FilterChips extends StatelessWidget {
  const _FilterChips({required this.active, required this.onChanged});

  final BatchFilter active;
  final ValueChanged<BatchFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 34,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: BatchFilter.values.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = BatchFilter.values[index];
          final isActive = filter == active;
          return GestureDetector(
            onTap: () => onChanged(filter),
            behavior: HitTestBehavior.opaque,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isActive
                    ? AppColors.primaryContainer
                    : AppColors.surface,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: isActive
                      ? AppColors.primaryContainer
                      : const Color(0xFFE5E7EB),
                ),
              ),
              child: Text(
                filter.label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isActive ? AppColors.white : AppColors.subtitle,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section header daftar batch
// ─────────────────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Batch Panen Saya',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.black,
          ),
        ),
        Text(
          '$count batch',
          style: const TextStyle(fontSize: 12, color: AppColors.placeholder),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Card batch
// ─────────────────────────────────────────────────────────────────────────────

// [FE - Component Rendering] _BatchCard adalah kartu daftar batch yang
// menampilkan info ringkas dan menyediakan dua aksi: tap kartu → detail,
// tap tombol QR → layar QR.
class _BatchCard extends StatelessWidget {
  const _BatchCard({
    required this.batch,
    required this.onTap,
    required this.onShowQr,
  });

  final HarvestBatch batch;
  final VoidCallback onTap;
  final VoidCallback onShowQr;

  String _formatDate(DateTime d) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Thumbnail durian — foto batch bila ada, selain itu fallback.
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child:
                        (batch.photoPath != null && batch.photoPath!.isNotEmpty)
                        ? BatchPhoto(
                            path: batch.photoPath,
                            width: 56,
                            height: 56,
                            borderRadius: BorderRadius.circular(10),
                          )
                        : Image.asset(
                            'assets/images/durian.png',
                            fit: BoxFit.contain,
                            errorBuilder: (_, _, _) => const Icon(
                              Icons.eco_outlined,
                              color: AppColors.primary,
                            ),
                          ),
                  ),
                  const SizedBox(width: 12),
                  // Info utama
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Durian ${batch.variety}',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.black,
                                ),
                              ),
                            ),
                            _StatusBadge(status: batch.status),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          batch.code,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 12,
                          runSpacing: 2,
                          children: [
                            _MetaItem(
                              icon: Icons.scale_outlined,
                              text:
                                  '${batch.quantity.toStringAsFixed(0)} '
                                  '${batch.unit}',
                            ),
                            _MetaItem(
                              icon: Icons.star_border_rounded,
                              text: 'Grade ${batch.grade}',
                            ),
                            _MetaItem(
                              icon: Icons.calendar_today_outlined,
                              text: _formatDate(batch.harvestDate),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFF0F0F0)),
            // Footer: kebun + tombol QR & detail
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
              child: Row(
                children: [
                  const Icon(
                    Icons.place_outlined,
                    size: 14,
                    color: AppColors.placeholder,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      batch.farmName,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.placeholder,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: onShowQr,
                    icon: const Icon(Icons.qr_code_2_rounded, size: 18),
                    label: const Text('QR'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      minimumSize: const Size(0, 36),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      textStyle: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
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

class _MetaItem extends StatelessWidget {
  const _MetaItem({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: AppColors.placeholder),
        const SizedBox(width: 3),
        Text(
          text,
          style: const TextStyle(fontSize: 12, color: AppColors.subtitle),
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final BatchStatus status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: status.background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: status.color,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty state
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 48),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.inventory_2_outlined,
            size: 56,
            color: Color(0xFFCBD5E1),
          ),
          const SizedBox(height: 12),
          const Text(
            'Belum ada batch yang cocok',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.subtitle,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Coba ubah filter atau kata kunci pencarian,\n'
            'atau tambah batch panen baru.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.placeholder,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
