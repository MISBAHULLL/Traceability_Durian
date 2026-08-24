import 'dart:io';
import 'package:flutter/foundation.dart';

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/product_media_tile.dart';
import '../data/umkm_repository.dart';
import '../models/umkm_order.dart';
import '../models/umkm_product.dart';
import '../models/umkm_profile.dart';
import '../models/umkm_stock_order.dart';
import '../widgets/umkm_drawer.dart';
import '../../trace/screens/public_trace_screen.dart';
import 'umkm_add_product_screen.dart';
import 'umkm_add_purchase_screen.dart';
import 'umkm_data_screen.dart';
import 'umkm_material_movement_screen.dart';
import 'umkm_order_detail_screen.dart';
import 'umkm_order_list_screen.dart';
import 'umkm_product_detail_screen.dart';
import 'umkm_profile_screen.dart';

class UmkmHomeScreen extends StatefulWidget {
  const UmkmHomeScreen({super.key});

  @override
  State<UmkmHomeScreen> createState() => _UmkmHomeScreenState();
}

class _UmkmHomeScreenState extends State<UmkmHomeScreen>
    with SingleTickerProviderStateMixin {
  final _repo = UmkmRepository.instance;
  final _searchController = TextEditingController();
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  String _query = '';
  String _activeCategory = 'Semua';
  late final AnimationController _animController;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _repo.addListener(_onRepoChanged);
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
    _searchController.addListener(() {
      setState(() => _query = _searchController.text.trim().toLowerCase());
    });
    _animController.forward();
  }

  @override
  void dispose() {
    _repo.removeListener(_onRepoChanged);
    _searchController.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _onRepoChanged() {
    if (mounted) setState(() {});
  }

  void _openDrawer() {
    _scaffoldKey.currentState?.openEndDrawer();
  }

  Future<void> _openAddProduct() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const UmkmAddProductScreen()),
    );
  }

  Future<void> _openAddPurchase() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const UmkmAddPurchaseScreen()),
    );
  }

  Future<void> _openMaterialMovements() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const UmkmMaterialMovementScreen()),
    );
  }

  Future<void> _openProfile() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const UmkmProfileScreen()),
    );
  }

  Future<void> _openEditUmkm() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => UmkmDataScreen()),
    );
  }

  Future<void> _openProductDetail(UmkmProduct product) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UmkmProductDetailScreen(product: product),
      ),
    );
  }

  Future<void> _openOrderDetail(UmkmOrder order) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => UmkmOrderDetailScreen(order: order)),
    );
  }

  Future<void> _openPurchaseDetail(UmkmStockOrder order) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UmkmStockOrderDetailScreen(order: order),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = _repo.profile;
    final products = _repo.products
        .where((product) {
          final category = product.category;
          return _activeCategory == 'Semua' || category == _activeCategory;
        })
        .where((product) {
          final name = product.name;
          return name.toLowerCase().contains(_query);
        })
        .toList();
    final orders = _repo.orders;
    final materialStocks = _repo.materialStockLedger;
    final purchases = _repo.stockOrders
        .where((order) => order.status == UmkmStockOrderStatus.selesai)
        .toList();
    final categories = [
      'Semua',
      ...{for (final item in _repo.products) item.category},
    ];

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.white,
      endDrawer: const UmkmDrawer(),
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
                                _ProfileCard(
                                  profile: profile,
                                  productCount: products.length,
                                  orderCount: orders.length,
                                  onEdit: _openEditUmkm,
                                ),
                                const SizedBox(height: 20),
                                _DashboardActions(
                                  onAddProduct: _openAddProduct,
                                  onAddPurchase: _openAddPurchase,
                                  onViewMaterialMovements:
                                      _openMaterialMovements,
                                  onViewOrders: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const UmkmOrderListScreen(),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 22),
                                _SectionHeader(
                                  title: 'Stok Bahan Baku Trace',
                                  count: materialStocks.length,
                                ),
                                const SizedBox(height: 12),
                                _MaterialStockPanel(stocks: materialStocks),
                                const SizedBox(height: 22),
                                _SearchField(
                                  controller: _searchController,
                                  hintText: 'Cari produk atau kategori',
                                ),
                                const SizedBox(height: 16),
                                _CategoryChips(
                                  categories: categories,
                                  activeCategory: _activeCategory,
                                  onChanged: (value) =>
                                      setState(() => _activeCategory = value),
                                ),
                                const SizedBox(height: 22),
                                _SectionHeader(
                                  title: 'Produk UMKM',
                                  count: products.length,
                                ),
                              ]),
                            ),
                          ),
                          SliverPadding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
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
                                    onTap: () => _openProductDetail(product),
                                  ),
                                );
                              }, childCount: products.length),
                            ),
                          ),
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                            sliver: SliverList(
                              delegate: SliverChildListDelegate([
                                _SectionHeader(
                                  title: 'Pesanan Masuk',
                                  count: orders.length,
                                ),
                              ]),
                            ),
                          ),
                          SliverPadding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            sliver: SliverList(
                              delegate: SliverChildBuilderDelegate((
                                context,
                                index,
                              ) {
                                final order = orders[index];
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: _OrderCard(
                                    order: order,
                                    onTap: () => _openOrderDetail(order),
                                  ),
                                );
                              }, childCount: orders.length),
                            ),
                          ),
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                            sliver: SliverList(
                              delegate: SliverChildListDelegate([
                                _SectionHeader(
                                  title: 'Pembelian durian',
                                  count: purchases.length,
                                ),
                              ]),
                            ),
                          ),
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                            sliver: SliverList(
                              delegate: SliverChildBuilderDelegate((
                                context,
                                index,
                              ) {
                                final purchase = purchases[index];
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: _PurchaseCard(
                                    purchase: purchase,
                                    onTap: () => _openPurchaseDetail(purchase),
                                  ),
                                );
                              }, childCount: purchases.length),
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

class _TopBar extends StatelessWidget {
  const _TopBar({required this.onProfile, required this.onMenu});

  final VoidCallback onProfile;
  final VoidCallback onMenu;

  @override
  Widget build(BuildContext context) {
    return Container(
      // [FE - Component Rendering] Band header ini memisahkan navigasi
      // beranda UMKM dari dashboard produk dan pesanan.
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
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
    );
  }
}

class _GreetingBlock extends StatelessWidget {
  const _GreetingBlock({required this.profile});

  final UmkmProfile profile;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Halo, ${profile.ownerName}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.black,
            ),
          ),
        ),
        const SizedBox(height: 2),
        Align(
          alignment: Alignment.centerLeft,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(
                Icons.storefront_rounded,
                size: 16,
                color: AppColors.primaryContainer,
              ),
              SizedBox(width: 6),
              Text(
                'UMKM',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryContainer,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DashboardActions extends StatelessWidget {
  const _DashboardActions({
    required this.onAddProduct,
    required this.onAddPurchase,
    required this.onViewMaterialMovements,
    required this.onViewOrders,
  });

  final VoidCallback onAddProduct;
  final VoidCallback onAddPurchase;
  final VoidCallback onViewMaterialMovements;
  final VoidCallback onViewOrders;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ActionTile(
          icon: Icons.add_box_rounded,
          title: 'Tambah Produk',
          subtitle: 'Buat produk baru, kode & QR otomatis',
          onTap: onAddProduct,
        ),
        const SizedBox(height: 12),
        _ActionTile(
          icon: Icons.shopping_bag_rounded,
          title: 'Beli Stok',
          subtitle: 'Rekam pemasukan durian dengan cepat',
          onTap: onAddPurchase,
        ),
        const SizedBox(height: 12),
        _ActionTile(
          icon: Icons.manage_history_rounded,
          title: 'Riwayat Mutasi',
          subtitle: 'Lihat stok masuk dan bahan baku terpakai',
          onTap: onViewMaterialMovements,
        ),
        const SizedBox(height: 12),
        _ActionTile(
          icon: Icons.receipt_long_rounded,
          title: 'Lihat Pesanan',
          subtitle: 'Buka daftar pesanan masuk UMKM',
          onTap: onViewOrders,
        ),
      ],
    );
  }
}

class _MaterialStockPanel extends StatelessWidget {
  const _MaterialStockPanel({required this.stocks});

  final List<UmkmTraceMaterialStock> stocks;

  @override
  Widget build(BuildContext context) {
    if (stocks.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFBEB),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFFDE68A)),
        ),
        child: const Text(
          'Belum ada stok bahan baku traceable. Setelah UMKM menerima DRN, PGL, atau stok distributor, saldonya akan tampil di sini.',
          style: TextStyle(
            fontSize: 12,
            height: 1.45,
            fontWeight: FontWeight.w700,
            color: Color(0xFF92400E),
          ),
        ),
      );
    }

    return Column(
      children: stocks
          .map(
            (stock) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _MaterialStockCard(stock: stock),
            ),
          )
          .toList(),
    );
  }
}

class _MaterialStockCard extends StatelessWidget {
  const _MaterialStockCard({required this.stock});

  final UmkmTraceMaterialStock stock;

  @override
  Widget build(BuildContext context) {
    final statusColor = stock.isAvailable
        ? AppColors.primary
        : const Color(0xFFB45309);
    final progress = stock.initialQuantity <= 0
        ? 0.0
        : (stock.remainingQuantity / stock.initialQuantity).clamp(0.0, 1.0);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  stock.isAvailable
                      ? Icons.inventory_2_outlined
                      : Icons.inventory_outlined,
                  color: statusColor,
                  size: 21,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stock.traceCode,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      stock.productName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppColors.black,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      stock.supplierName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.placeholder,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _MaterialStatusPill(
                label: stock.isAvailable ? 'Tersedia' : 'Habis',
                color: statusColor,
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 7,
              value: progress,
              backgroundColor: const Color(0xFFE5E7EB),
              valueColor: AlwaysStoppedAnimation<Color>(statusColor),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _MaterialMiniChip(label: stock.initialLabel),
              _MaterialMiniChip(label: stock.remainingLabel),
              _MaterialMiniChip(label: stock.usedLabel),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Sumber trace: ${stock.sourceLabel}',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              height: 1.35,
              color: AppColors.placeholder,
            ),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        PublicTraceScreen(batchCode: stock.publicTraceCode),
                  ),
                );
              },
              icon: const Icon(Icons.account_tree_outlined, size: 16),
              label: const Text('Lihat Trace'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
                textStyle: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MaterialStatusPill extends StatelessWidget {
  const _MaterialStatusPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w900,
          color: color,
        ),
      ),
    );
  }
}

class _MaterialMiniChip extends StatelessWidget {
  const _MaterialMiniChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: AppColors.subtitle,
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller, required this.hintText});

  final TextEditingController controller;
  final String hintText;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      style: const TextStyle(fontSize: 14, color: AppColors.black),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(fontSize: 14, color: AppColors.placeholder),
        prefixIcon: const Icon(
          Icons.search_rounded,
          color: AppColors.placeholder,
          size: 22,
        ),
        filled: true,
        fillColor: AppColors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(
            color: AppColors.primaryContainer,
            width: 2,
          ),
        ),
      ),
    );
  }
}

class _CategoryChips extends StatelessWidget {
  const _CategoryChips({
    required this.categories,
    required this.activeCategory,
    required this.onChanged,
  });

  final List<String> categories;
  final String activeCategory;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final category = categories[index];
          final isActive = category == activeCategory;
          return GestureDetector(
            onTap: () => onChanged(category),
            child: Container(
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
                category,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isActive ? AppColors.white : AppColors.black,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({
    required this.profile,
    required this.productCount,
    required this.orderCount,
    required this.onEdit,
  });

  final UmkmProfile profile;
  final int productCount;
  final int orderCount;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            height: 128,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            clipBehavior: Clip.antiAlias,
            child: profile.imageBytes != null
                ? Image.memory(
                    profile.imageBytes!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const _UmkmImagePlaceholder(),
                  )
                : (!kIsWeb &&
                      profile.imagePath != null &&
                      profile.imagePath!.isNotEmpty)
                ? Image.file(
                    File(profile.imagePath!),
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const _UmkmImagePlaceholder(),
                  )
                : const _UmkmImagePlaceholder(),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Icon(
                Icons.storefront_rounded,
                color: AppColors.primaryContainer,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.black,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      profile.ownerName,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.placeholder,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: onEdit,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                child: const Text('Ubah'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            profile.about,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.subtitle,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _InfoLabel(
                icon: Icons.inventory_2_rounded,
                label: '$productCount Produk',
              ),
              _InfoLabel(
                icon: Icons.receipt_long_rounded,
                label: '$orderCount Pesanan',
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              _InfoLabel(
                icon: Icons.location_on_rounded,
                label: profile.location,
              ),
              _InfoLabel(icon: Icons.email_rounded, label: profile.email),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.primaryContainer,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.primaryContainer),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryContainer.withValues(alpha: 0.14),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.white, size: 30),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFFF7FAF7),
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.white),
          ],
        ),
      ),
    );
  }
}

class _UmkmImagePlaceholder extends StatelessWidget {
  const _UmkmImagePlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.storefront_outlined,
            size: 42,
            color: AppColors.placeholder,
          ),
          SizedBox(height: 8),
          Text(
            'Gambar UMKM',
            style: TextStyle(fontSize: 12, color: AppColors.placeholder),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.count});

  final String title;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.black,
          ),
        ),
        Text(
          '$count item',
          style: const TextStyle(fontSize: 12, color: AppColors.black),
        ),
      ],
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.product, required this.onTap});

  final UmkmProduct product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ProductMediaTile(imagePath: product.imagePath),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
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
                        ),
                        const SizedBox(width: 8),
                        _StatusBadge(product.status),
                      ],
                    ),
                    const SizedBox(height: 7),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        _CategoryBadge(label: product.category),
                        Text(
                          product.priceLabel,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 7),
                    Text(
                      product.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        height: 1.35,
                        color: AppColors.placeholder,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _MetaLine(
                      icon: Icons.inventory_2_outlined,
                      text: product.stockLabel,
                    ),
                    _MetaLine(
                      icon: Icons.qr_code_2_rounded,
                      text: product.code,
                    ),
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

class _MetaLine extends StatelessWidget {
  const _MetaLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        children: [
          Icon(icon, size: 12, color: AppColors.placeholder),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 10,
                height: 1.25,
                color: AppColors.placeholder,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ignore: unused_element
class _ImageFallback extends StatelessWidget {
  const _ImageFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      alignment: Alignment.center,
      child: const Icon(
        Icons.image_outlined,
        color: AppColors.placeholder,
        size: 30,
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge(this.status);

  final UmkmProductStatus status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: status == UmkmProductStatus.aktif
            ? AppColors.primary.withValues(alpha: 0.12)
            : AppColors.subtitle.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: status == UmkmProductStatus.aktif
              ? AppColors.primary
              : AppColors.subtitle,
        ),
      ),
    );
  }
}

class _CategoryBadge extends StatelessWidget {
  const _CategoryBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
        ),
      ),
    );
  }
}

// ignore: unused_element
class _Bullet extends StatelessWidget {
  const _Bullet({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          const Icon(Icons.circle, size: 5, color: AppColors.placeholder),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, color: AppColors.subtitle),
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order, required this.onTap});

  final UmkmOrder order;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    order.productName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.black,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: order.status == UmkmOrderStatus.diproses
                        ? AppColors.primary.withValues(alpha: 0.12)
                        : AppColors.primaryContainer.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    order.status.label,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: order.status == UmkmOrderStatus.diproses
                          ? AppColors.primary
                          : AppColors.primaryContainer,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Pembeli: ${order.buyerName}',
              style: const TextStyle(fontSize: 12, color: AppColors.subtitle),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Text(
                  order.totalLabel,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
                const Spacer(),
                Text(
                  'x${order.quantity}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.placeholder,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PurchaseCard extends StatelessWidget {
  const _PurchaseCard({required this.purchase, required this.onTap});

  final UmkmStockOrder purchase;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    purchase.supplierName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.black,
                    ),
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.subtitle,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              purchase.offerName,
              style: const TextStyle(fontSize: 12, color: AppColors.subtitle),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Text(
                  purchase.totalLabel,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
                const Spacer(),
                Text(
                  'x${purchase.quantityKg}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.placeholder,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoLabel extends StatelessWidget {
  const _InfoLabel({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 200),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.primaryContainer),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, color: AppColors.black),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
