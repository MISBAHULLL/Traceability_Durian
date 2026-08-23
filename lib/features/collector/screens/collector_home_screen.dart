import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/product_media_tile.dart';
import '../collector_routes.dart';
import '../data/collector_repository.dart';
import '../models/collector_product.dart';
import '../widgets/collector_drawer.dart';
import 'add_transaction_screen.dart';
import 'collector_profile_screen.dart';
import 'collector_scan_qr_screen.dart';
import 'collector_stock_screen.dart';

// [FE - Component Rendering] Screen ini adalah layar root pengepul setelah
// login — turunan langsung dari prototype "Beranda — Pengepul Durian".
/// Beranda untuk role Pengepul (Collector).
///
/// Mengikuti gaya visual prototype "Beranda — Pengepul Durian" (header,
/// greeting, CTA hijau "Tambah Transaksi", search pill, chip kategori,
/// kartu produk, bottom navigation) namun dirender dengan token desain
/// aplikasi (AppColors dan transisi fade) agar menyatu dengan
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

  int get _incomingTodayCount {
    final now = DateTime.now();
    return _repo.stockBatches.where((batch) {
      final receivedAt =
          batch.verifiedAt ?? batch.createdAt ?? batch.harvestDate;
      return _isSameDay(receivedAt, now);
    }).length;
  }

  double get _incomingTodayWeight {
    final now = DateTime.now();
    return _repo.stockBatches
        .where((batch) {
          final receivedAt =
              batch.verifiedAt ?? batch.createdAt ?? batch.harvestDate;
          return _isSameDay(receivedAt, now);
        })
        .fold<double>(
          0,
          (sum, batch) => sum + (batch.receivedQuantity ?? batch.quantity),
        );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
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

  Future<void> _openStock() async {
    await CollectorRoutes.push(context, const CollectorStockScreen());
  }

  Future<void> _onProductTap(CollectorProduct product) async {
    if (product.category != ProductCategory.durianSegar) return;

    final transaction = _repo.initiatePurchaseTransaction(product.code);
    if (transaction == null) return;

    final completed = await CollectorRoutes.push<bool>(
      context,
      AddTransactionScreen(
        initialBatchCode: product.code,
        initialTransactionId: transaction.id,
      ),
    );
    if (completed == true && mounted) {
      await CollectorRoutes.push(context, const CollectorStockScreen());
    }
  }

  @override
  Widget build(BuildContext context) {
    final products = _filteredProducts;
    final profile = _repo.profile;
    final overview = _repo.stockOverview;
    final pendingCount = _repo.pendingPurchaseTransactions.length;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.white,
      endDrawer: const CollectorDrawer(),
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
                        slivers: [
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                            sliver: SliverList(
                              delegate: SliverChildListDelegate([
                                _GreetingBlock(profile: profile),
                                const SizedBox(height: 16),
                                _OperationalSummaryGrid(
                                  incomingTodayCount: _incomingTodayCount,
                                  incomingTodayWeight: _incomingTodayWeight,
                                  pendingCount: pendingCount,
                                  activeBatchCount: overview.activeBatchCount,
                                  totalWeightKg: overview.totalWeightKg,
                                  totalFruitCount: overview.totalFruitCount,
                                  onOpenScan: _openScanQr,
                                  onOpenStock: _openStock,
                                ),
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

// [FE - Component Rendering] _TopBar mengikuti pola beranda petani:
// judul "Beranda" di kiri dan ikon aksi di kanan.
class _TopBar extends StatelessWidget {
  const _TopBar({required this.onProfile, required this.onMenu});

  final VoidCallback onProfile;
  final VoidCallback onMenu;

  @override
  Widget build(BuildContext context) {
    return Container(
      // [FE - Component Rendering] Band header ini memberi warna pembatas
      // untuk area navigasi utama di beranda pengepul.
      width: double.infinity,
      color: AppColors.homeHeaderSurface,
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
class _OperationalSummaryGrid extends StatelessWidget {
  const _OperationalSummaryGrid({
    required this.incomingTodayCount,
    required this.incomingTodayWeight,
    required this.pendingCount,
    required this.activeBatchCount,
    required this.totalWeightKg,
    required this.totalFruitCount,
    required this.onOpenScan,
    required this.onOpenStock,
  });

  final int incomingTodayCount;
  final double incomingTodayWeight;
  final int pendingCount;
  final int activeBatchCount;
  final double totalWeightKg;
  final int totalFruitCount;
  final VoidCallback onOpenScan;
  final VoidCallback onOpenStock;

  static const double _gap = 8;

  String _formatWeight(double value) {
    return value % 1 == 0 ? value.toStringAsFixed(0) : value.toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = (constraints.maxWidth - _gap) / 2;

        return Wrap(
          spacing: _gap,
          runSpacing: _gap,
          children: [
            _SummaryMetricCard(
              width: itemWidth,
              icon: Icons.move_to_inbox_outlined,
              title: 'Durian Masuk Hari Ini',
              value: '$incomingTodayCount batch',
              detail: '${_formatWeight(incomingTodayWeight)} kg diterima',
              color: AppColors.primary,
              onTap: onOpenStock,
            ),
            _SummaryMetricCard(
              width: itemWidth,
              icon: Icons.pending_actions_outlined,
              title: 'Transaksi Menunggu',
              value: '$pendingCount batch',
              detail: 'perlu scan dan verifikasi',
              color: const Color(0xFFB45309),
              onTap: onOpenScan,
            ),
            _SummaryMetricCard(
              width: itemWidth,
              icon: Icons.inventory_2_outlined,
              title: 'Batch Aktif',
              value: '$activeBatchCount batch',
              detail: 'stok siap dikelola',
              color: const Color(0xFF1D6FA4),
              onTap: onOpenStock,
            ),
            _SummaryMetricCard(
              width: itemWidth,
              icon: Icons.scale_outlined,
              title: 'Ringkasan Stok',
              value: '${_formatWeight(totalWeightKg)} kg',
              detail: '$totalFruitCount butir tercatat',
              color: const Color(0xFF6B21A8),
              onTap: onOpenStock,
            ),
          ],
        );
      },
    );
  }
}

class _SummaryMetricCard extends StatelessWidget {
  const _SummaryMetricCard({
    required this.width,
    required this.icon,
    required this.title,
    required this.value,
    required this.detail,
    required this.color,
    required this.onTap,
  });

  final double width;
  final IconData icon;
  final String title;
  final String value;
  final String detail;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: 74,
      child: Material(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 17, color: color),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 10,
                          height: 1.15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.placeholder,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        value,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.1,
                          fontWeight: FontWeight.w900,
                          color: AppColors.black,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        detail,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 9,
                          height: 1.1,
                          color: AppColors.placeholder,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 16,
                  color: AppColors.placeholder.withValues(alpha: 0.55),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

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
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // [FE - Component Rendering] Media tile menjaga gambar batch
              // tidak memanjang mengikuti tinggi detail traceability.
              ProductMediaTile(imagePath: product.imagePath),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.25,
                        fontWeight: FontWeight.w800,
                        color: AppColors.black,
                      ),
                    ),
                    const SizedBox(height: 7),
                    _Bullet(text: 'Berat : ${product.weightRange}'),
                    if (product.taste.trim() != '-')
                      _Bullet(text: 'Rasa : ${product.taste}'),
                    if (product.fruitCount != null)
                      _Bullet(
                        text: 'Jumlah Buah : ${product.fruitCount} butir',
                      ),
                    _Bullet(text: 'Daging Buah : ${product.fleshDescription}'),
                    if (product.shelfLifeEstimate != null &&
                        product.shelfLifeEstimate!.isNotEmpty)
                      _Bullet(
                        text: 'Masa Simpan : ${product.shelfLifeEstimate}',
                      ),
                    _Bullet(text: 'Lokasi : ${product.location}'),
                    _Bullet(
                      text: 'Waktu Panen : ${_formatDate(product.harvestDate)}',
                    ),
                    _Bullet(text: 'Pemilik Pohon : ${product.treeOwner}'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ignore: unused_element
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
