import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/top_notification_banner.dart';
import '../collector_routes.dart';
import '../data/collector_repository.dart';
import '../models/collector_product.dart';
import '../widgets/collector_drawer.dart';
import 'collector_profile_screen.dart';
import 'collector_scan_qr_screen.dart';

// [FE - Component Rendering] Screen ini adalah layar root pengepul setelah
// login — turunan langsung dari prototype "Beranda — Pengepul Durian".
/// Beranda untuk role Pengepul (Collector).
///
/// Mengikuti gaya visual prototype "Beranda — Pengepul Durian" (header,
/// greeting, CTA hijau "Tambah Transaksi", search pill, chip kategori,
/// kartu produk, bottom navigation) namun dirender dengan token desain
/// aplikasi (AppColors, transisi fade, TopNotification) agar menyatu dengan
/// layar lain.
///
/// Catatan peran (Role Permission Matrix): pengepul TIDAK membuat data panen.
/// "Tambah Transaksi" diturunkan menjadi alur memilih & memverifikasi produk
/// durian milik petani — data deskriptif produk bersifat read-only.
class CollectorHomeScreen extends StatefulWidget {
  const CollectorHomeScreen({super.key});

  @override
  State<CollectorHomeScreen> createState() => _CollectorHomeScreenState();
}

class _CollectorHomeScreenState extends State<CollectorHomeScreen>
    with SingleTickerProviderStateMixin {
  final _repo = CollectorRepository.instance;
  final TextEditingController _searchController = TextEditingController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TopNotification _notif = TopNotification();

  ProductCategory _activeCategory = ProductCategory.durianSegar;
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

    _repo.addListener(_onRepoChanged);
  }

  @override
  void dispose() {
    _repo.removeListener(_onRepoChanged);
    _notif.dispose();
    _animController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onRepoChanged() {
    if (mounted) setState(() {});
  }

  // [UTIL - Helper Function] _filteredProducts menggabungkan filter kategori
  // dan query pencarian melalui pure function searchAndFilterProducts.
  List<CollectorProduct> get _filteredProducts {
    return searchAndFilterProducts(_repo.products, _activeCategory, _query);
  }

  // ── Navigasi ───────────────────────────────────────────────────────────────

  void _openDrawer() => _scaffoldKey.currentState?.openEndDrawer();

  Future<void> _openProfile() async {
    await Navigator.push(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 400),
        pageBuilder: (_, _, _) => const CollectorProfileScreen(),
        transitionsBuilder: (_, animation, _, child) => FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: Curves.easeInOutCubic,
          ),
          child: child,
        ),
      ),
    );
  }

  // [FE - Event Handler] _openScanQr membuka simulasi scan QR sebagai pintu
  // utama pengepul untuk mencari batch petani sebelum verifikasi.
  Future<void> _openScanQr() async {
    await CollectorRoutes.push(context, const CollectorScanQrScreen());
  }

  void _onProductTap(CollectorProduct product) {
    _notif.show(
      context,
      'Detail & transaksi untuk ${product.name} akan segera hadir.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final products = _filteredProducts;
    final profile = _repo.profile;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.white,
      endDrawer: const CollectorDrawer(),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SlideTransition(
            position: _slideAnim,
            child: Column(
              children: [
                _TopBar(onProfile: _openProfile, onMenu: _openDrawer),
                Expanded(
                  child: CustomScrollView(
                    slivers: [
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                        sliver: SliverList(
                          delegate: SliverChildListDelegate([
                            _GreetingBlock(profile: profile),
                            const SizedBox(height: 16),
                            _AddTransactionCard(onTap: _openScanQr),
                            const SizedBox(height: 16),
                            _SearchField(controller: _searchController),
                            const SizedBox(height: 14),
                            _CategoryChips(
                              active: _activeCategory,
                              onChanged: (c) =>
                                  setState(() => _activeCategory = c),
                            ),
                            const SizedBox(height: 16),
                          ]),
                        ),
                      ),
                      if (products.isEmpty)
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
                              final product = products[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _ProductCard(
                                  product: product,
                                  onTap: () => _onProductTap(product),
                                ),
                              );
                            }, childCount: products.length),
                          ),
                        ),
                    ],
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
// Top bar
// ─────────────────────────────────────────────────────────────────────────────

// [FE - Component Rendering] _TopBar mengikuti pola beranda petani:
// judul "Beranda" di kiri dan ikon aksi di kanan.
class _TopBar extends StatelessWidget {
  const _TopBar({required this.onProfile, required this.onMenu});

  final VoidCallback onProfile;
  final VoidCallback onMenu;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 12, 4),
      child: Row(
        children: [
          const Text(
            'Beranda',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.black,
            ),
          ),
          const Spacer(),
          _IconButton(icon: Icons.person_outline_rounded, onTap: onProfile),
          const SizedBox(width: 4),
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
    return IconButton(
      onPressed: onTap,
      icon: Icon(icon, color: AppColors.black, size: 24),
      splashRadius: 22,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Greeting
// ─────────────────────────────────────────────────────────────────────────────

class _GreetingBlock extends StatelessWidget {
  const _GreetingBlock({required this.profile});

  final CollectorProfile profile;

  @override
  Widget build(BuildContext context) {
    final secondaryLabel = profile.businessName.isEmpty
        ? profile.roleLabel
        : profile.businessName;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Halo, ${profile.fullName}',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.black,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          secondaryLabel,
          style: const TextStyle(fontSize: 13, color: AppColors.placeholder),
        ),
        // [FE - Component Rendering] Lokasi operasional ditampilkan bila ada
        // agar pengepul langsung tahu konteks akun yang sedang aktif.
        if (profile.location.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            profile.location,
            style: const TextStyle(fontSize: 12, color: AppColors.placeholder),
          ),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CTA Tambah Transaksi
// ─────────────────────────────────────────────────────────────────────────────

// [FE - Component Rendering] _AddTransactionCard adalah CTA utama pengepul —
// turunan dari kartu "Tambah Transaksi" pada prototype.
class _AddTransactionCard extends StatelessWidget {
  const _AddTransactionCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
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
                    'Scan QR Batch',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.white,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'scan kode batch petani untuk verifikasi',
                    style: TextStyle(
                      fontSize: 11,
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
                color: AppColors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.qr_code_scanner_rounded,
                color: AppColors.primaryContainer,
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
      textAlign: TextAlign.center,
      style: const TextStyle(fontSize: 14, color: AppColors.black),
      decoration: InputDecoration(
        hintText: 'Masukan Kode Produk',
        hintStyle: const TextStyle(fontSize: 14, color: AppColors.placeholder),
        suffixIcon: const Icon(
          Icons.search_rounded,
          color: AppColors.placeholder,
          size: 22,
        ),
        filled: true,
        fillColor: AppColors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(999),
          borderSide: const BorderSide(color: AppColors.black),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(999),
          borderSide: const BorderSide(color: AppColors.black),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(999),
          borderSide: const BorderSide(color: AppColors.black, width: 1.5),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Category chips
// ─────────────────────────────────────────────────────────────────────────────

// [FE - Component Rendering] _CategoryChips menampilkan chip kategori produk
// (Durian Segar / Olahan / Bibit) dan memanggil onChanged saat dipilih.
class _CategoryChips extends StatelessWidget {
  const _CategoryChips({required this.active, required this.onChanged});

  final ProductCategory active;
  final ValueChanged<ProductCategory> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 34,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: ProductCategory.values.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final category = ProductCategory.values[index];
          final isActive = category == active;
          return GestureDetector(
            onTap: () => onChanged(category),
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
                category.label,
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
// Product card
// ─────────────────────────────────────────────────────────────────────────────

// [FE - Component Rendering] _ProductCard mereplikasi kartu produk prototype:
// thumbnail di kiri + daftar atribut (berat, rasa, daging buah, lokasi,
// waktu panen, pemilik pohon) di kanan.
class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.product, required this.onTap});

  final CollectorProduct product;
  final VoidCallback onTap;

  String _formatDate(DateTime d) {
    const months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
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
          border: Border.all(color: AppColors.black),
        ),
        clipBehavior: Clip.antiAlias,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Thumbnail produk (1/3 lebar)
              SizedBox(
                width: 104,
                child: Container(
                  color: AppColors.surface,
                  child:
                      (product.imagePath != null &&
                          product.imagePath!.isNotEmpty)
                      ? Image.asset(
                          product.imagePath!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => const _ImageFallback(),
                        )
                      : Image.asset(
                          'assets/images/durian.png',
                          fit: BoxFit.contain,
                          errorBuilder: (_, _, _) => const _ImageFallback(),
                        ),
                ),
              ),
              // Detail produk (2/3 lebar)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.black,
                        ),
                      ),
                      const SizedBox(height: 6),
                      _Bullet(text: 'Berat : ${product.weightRange}'),
                      if (product.taste.trim() != '-')
                        _Bullet(text: 'Rasa : ${product.taste}'),
                      // [FE - Component Rendering] Jumlah buah dari petani
                      // membantu pengepul membaca batch dalam satuan butir.
                      if (product.fruitCount != null)
                        _Bullet(
                          text: 'Jumlah Buah : ${product.fruitCount} butir',
                        ),
                      _Bullet(
                        text: 'Daging Buah : ${product.fleshDescription}',
                      ),
                      // [FE - Component Rendering] Info traceability dari
                      // petani ditampilkan ringkas di kartu antrean pengepul.
                      if (product.shelfLifeEstimate != null &&
                          product.shelfLifeEstimate!.isNotEmpty)
                        _Bullet(
                          text: 'Masa Simpan : ${product.shelfLifeEstimate}',
                        ),
                      _Bullet(text: 'Lokasi : ${product.location}'),
                      _Bullet(
                        text:
                            'Waktu Panen : ${_formatDate(product.harvestDate)}',
                      ),
                      _Bullet(text: 'Pemilik Pohon : ${product.treeOwner}'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ImageFallback extends StatelessWidget {
  const _ImageFallback();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Icon(Icons.eco_outlined, color: AppColors.primary, size: 28),
    );
  }
}

// [FE - Component Rendering] _Bullet menampilkan satu baris atribut produk
// dengan penanda titik, meniru daftar berpoin pada prototype.
class _Bullet extends StatelessWidget {
  const _Bullet({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 1, right: 5),
            child: Text(
              '•',
              style: TextStyle(fontSize: 11, color: AppColors.placeholder),
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 10,
                height: 1.35,
                color: AppColors.placeholder,
              ),
            ),
          ),
        ],
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
        children: const [
          Icon(Icons.search_off_rounded, size: 56, color: Color(0xFFCBD5E1)),
          SizedBox(height: 12),
          Text(
            'Tidak ada produk yang cocok',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.subtitle,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Coba ubah kata kunci pencarian atau kategori.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: AppColors.placeholder),
          ),
        ],
      ),
    );
  }
}
