import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/primary_pill_button.dart';
import '../consumer_routes.dart';
import '../data/consumer_repository.dart';
import '../models/consumer_product.dart';
import '../models/consumer_transaction.dart';
import '../widgets/consumer_drawer.dart';
import 'consumer_profile_screen.dart';
import 'consumer_product_detail_screen.dart';
import 'consumer_scan_qr_screen.dart';
import 'consumer_transaction_detail_screen.dart';

/// Beranda untuk role Konsumen.
class ConsumerHomeScreen extends StatefulWidget {
  const ConsumerHomeScreen({super.key});

  @override
  State<ConsumerHomeScreen> createState() => _ConsumerHomeScreenState();
}

class _ConsumerHomeScreenState extends State<ConsumerHomeScreen>
    with SingleTickerProviderStateMixin {
  final _repo = ConsumerRepository.instance;
  final _searchController = TextEditingController();
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  ConsumerProductFilter _activeFilter = ConsumerProductFilter.semua;
  _DashboardTab _activeTab = _DashboardTab.products;
  _TransactionPaymentTab _activeTransactionTab =
      _TransactionPaymentTab.unpaid;
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
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(
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

  List<ConsumerProduct> get _filteredProducts {
    return _repo.filteredProducts(_activeFilter, _query);
  }

  List<ConsumerTransaction> get _filteredTransactions {
    final all = _repo.transactions;
    return all
        .where(
          (t) => t.effectivePaymentStatus == _activeTransactionTab.status,
        )
        .toList();
  }

  void _openDrawer() => _scaffoldKey.currentState?.openEndDrawer();

  Future<void> _openProfile() async {
    await ConsumerRoutes.push(context, const ConsumerProfileScreen());
  }

  Future<void> _openScanQr() async {
    await ConsumerRoutes.push(context, const ConsumerScanQrScreen());
  }

  void _openProductDetail(ConsumerProduct product) {
    ConsumerRoutes.push(
      context,
      ConsumerProductDetailScreen(product: product),
    );
  }

  void _openTransactionDetail(ConsumerTransaction transaction) {
    ConsumerRoutes.push(
      context,
      ConsumerTransactionDetailScreen(transaction: transaction),
    );
  }

  @override
  Widget build(BuildContext context) {
    final products = _filteredProducts;
    final transactions = _filteredTransactions;
    final profile = _repo.profile;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.white,
      endDrawer: const ConsumerDrawer(),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SlideTransition(
            position: _slideAnim,
            child: Column(
              children: [
                _TopBar(
                  onProfile: _openProfile,
                  onMenu: _openDrawer,
                ),
                Expanded(
                  child: CustomScrollView(
                    slivers: [
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                        sliver: SliverList(
                          delegate: SliverChildListDelegate([
                            _GreetingBlock(profile: profile),
                            const SizedBox(height: 16),
                            if (_activeTab == _DashboardTab.products) ...[
                              _SearchField(controller: _searchController),
                              const SizedBox(height: 14),
                            ],
                            _ScanQrCard(onTap: _openScanQr),
                            const SizedBox(height: 16),
                            _DashboardTabs(
                              active: _activeTab,
                              onChanged: (tab) =>
                                  setState(() => _activeTab = tab),
                            ),
                            const SizedBox(height: 16),
                            if (_activeTab == _DashboardTab.products) ...[
                              _FilterChips(
                                active: _activeFilter,
                                onChanged: (filter) =>
                                    setState(() => _activeFilter = filter),
                              ),
                              const SizedBox(height: 16),
                              _SectionHeader(
                                title: 'Produk UMKM',
                                trailing: '${products.length} produk',
                              ),
                            ] else ...[
                              _TransactionStatusTabs(
                                activeTab: _activeTransactionTab,
                                onChanged: (tab) =>
                                    setState(() => _activeTransactionTab = tab),
                              ),
                              const SizedBox(height: 12),
                              _SectionHeader(
                                title: 'Transaksi Saya',
                                trailing: '${transactions.length} transaksi',
                              ),
                            ],
                            const SizedBox(height: 12),
                          ]),
                        ),
                      ),
                      if (_activeTab == _DashboardTab.products &&
                          products.isEmpty)
                        const SliverFillRemaining(
                          hasScrollBody: false,
                          child: _EmptyState(),
                        )
                      else if (_activeTab == _DashboardTab.products)
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final product = products[index];
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: _ProductCard(
                                    product: product,
                                    onTap: () => _openProductDetail(product),
                                  ),
                                );
                              },
                              childCount: products.length,
                            ),
                          ),
                        )
                      else if (transactions.isEmpty)
                        const SliverFillRemaining(
                          hasScrollBody: false,
                          child: _TransactionEmptyState(),
                        )
                      else
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final transaction = transactions[index];
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: _TransactionCard(
                                    transaction: transaction,
                                    onTap: () =>
                                        _openTransactionDetail(transaction),
                                  ),
                                );
                              },
                              childCount: transactions.length,
                            ),
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

enum _DashboardTab { products, transactions }

enum _TransactionPaymentTab { unpaid, processing, completed }

extension _TransactionPaymentTabX on _TransactionPaymentTab {
  String get label {
    switch (this) {
      case _TransactionPaymentTab.unpaid:
        return 'Belum Dibayar';
      case _TransactionPaymentTab.processing:
        return 'Diproses';
      case _TransactionPaymentTab.completed:
        return 'Selesai';
    }
  }

  ConsumerPaymentStatus get status {
    switch (this) {
      case _TransactionPaymentTab.unpaid:
        return ConsumerPaymentStatus.unpaid;
      case _TransactionPaymentTab.processing:
        return ConsumerPaymentStatus.processing;
      case _TransactionPaymentTab.completed:
        return ConsumerPaymentStatus.paid;
    }
  }
}

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

class _GreetingBlock extends StatelessWidget {
  const _GreetingBlock({required this.profile});

  final ConsumerProfile profile;

  @override
  Widget build(BuildContext context) {
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
        Row(
          children: [
            const Icon(
              Icons.person_outline_rounded,
              size: 15,
              color: AppColors.primary,
            ),
            const SizedBox(width: 4),
            Text(
              profile.roleLabel,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        if (profile.location.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            profile.location,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.placeholder,
            ),
          ),
        ],
      ],
    );
  }
}

class _ScanQrCard extends StatelessWidget {
  const _ScanQrCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        decoration: BoxDecoration(
          color: AppColors.primaryContainer,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.qr_code_scanner_rounded,
                color: AppColors.primaryContainer,
                size: 26,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Scan QR Produk',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.white,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Arahkan kamera ke QR produk untuk melihat detail dan melanjutkan pembelian.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFFEAF7E5),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.white,
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardTabs extends StatelessWidget {
  const _DashboardTabs({required this.active, required this.onChanged});

  final _DashboardTab active;
  final ValueChanged<_DashboardTab> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          _TabButton(
            label: 'Produk',
            isActive: active == _DashboardTab.products,
            onTap: () => onChanged(_DashboardTab.products),
          ),
          _TabButton(
            label: 'Transaksi',
            isActive: active == _DashboardTab.transactions,
            onTap: () => onChanged(_DashboardTab.transactions),
          ),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isActive ? AppColors.primaryContainer : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: isActive ? AppColors.white : AppColors.subtitle,
            ),
          ),
        ),
      ),
    );
  }
}

class _TransactionStatusTabs extends StatelessWidget {
  const _TransactionStatusTabs({
    required this.activeTab,
    required this.onChanged,
  });

  final _TransactionPaymentTab activeTab;
  final ValueChanged<_TransactionPaymentTab> onChanged;

  @override
  Widget build(BuildContext context) {
    final repo = ConsumerRepository.instance;
    final unpaidCount = repo.transactions
        .where((t) => t.effectivePaymentStatus == ConsumerPaymentStatus.unpaid)
        .length;
    final processingCount = repo.transactions
        .where(
          (t) => t.effectivePaymentStatus == ConsumerPaymentStatus.processing,
        )
        .length;
    final completedCount = repo.transactions
        .where((t) => t.effectivePaymentStatus == ConsumerPaymentStatus.paid)
        .length;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _TransactionStatusButton(
              label: 'Belum Dibayar',
              count: unpaidCount,
              isActive: activeTab == _TransactionPaymentTab.unpaid,
              onTap: () => onChanged(_TransactionPaymentTab.unpaid),
            ),
          ),
          Expanded(
            child: _TransactionStatusButton(
              label: 'Diproses',
              count: processingCount,
              isActive: activeTab == _TransactionPaymentTab.processing,
              onTap: () => onChanged(_TransactionPaymentTab.processing),
            ),
          ),
          Expanded(
            child: _TransactionStatusButton(
              label: 'Selesai',
              count: completedCount,
              isActive: activeTab == _TransactionPaymentTab.completed,
              onTap: () => onChanged(_TransactionPaymentTab.completed),
            ),
          ),
        ],
      ),
    );
  }
}

class _TransactionStatusButton extends StatelessWidget {
  const _TransactionStatusButton({
    required this.label,
    required this.count,
    required this.isActive,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isActive ? AppColors.primaryContainer : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isActive ? AppColors.white : AppColors.subtitle,
              ),
            ),
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isActive
                    ? AppColors.white.withValues(alpha: 0.3)
                    : AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isActive ? AppColors.white : AppColors.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      style: const TextStyle(fontSize: 14, color: AppColors.black),
      decoration: InputDecoration(
        hintText: 'Cari produk',
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

class _FilterChips extends StatelessWidget {
  const _FilterChips({required this.active, required this.onChanged});

  final ConsumerProductFilter active;
  final ValueChanged<ConsumerProductFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 34,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: ConsumerProductFilter.values.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = ConsumerProductFilter.values[index];
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

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.trailing});

  final String title;
  final String trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.black,
          ),
        ),
        Text(
          trailing,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.placeholder,
          ),
        ),
      ],
    );
  }
}

class _TransactionCard extends StatelessWidget {
  const _TransactionCard({
    required this.transaction,
    required this.onTap,
  });

  final ConsumerTransaction transaction;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final product = transaction.product;
    final paymentStatus = transaction.effectivePaymentStatus;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 62,
              height: 62,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              clipBehavior: Clip.antiAlias,
              child: product.imagePath != null && product.imagePath!.isNotEmpty
                  ? Image.asset(product.imagePath!, fit: BoxFit.cover)
                  : Image.asset('assets/images/durian.png', fit: BoxFit.contain),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          product.name,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: AppColors.black,
                          ),
                        ),
                      ),
                      _TransactionBadge(paymentStatus),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    transaction.id,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${product.umkmName} • ${transaction.totalLabel}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.placeholder,
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

class _TransactionBadge extends StatelessWidget {
  const _TransactionBadge(this.status);

  final ConsumerPaymentStatus status;

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

class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.product, required this.onTap});

  final ConsumerProduct product;
  final VoidCallback onTap;

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
        clipBehavior: Clip.antiAlias,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: 104,
                child: Container(
                  color: AppColors.surface,
                  child: product.imagePath != null && product.imagePath!.isNotEmpty
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
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              product.name,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.black,
                              ),
                            ),
                          ),
                          _StatusBadge(product.status),
                        ],
                      ),
                      const SizedBox(height: 6),
                      _CategoryBadge(label: product.category.label),
                      const SizedBox(height: 6),
                      Text(
                        product.priceLabel,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        product.shortDescription,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          height: 1.35,
                          color: AppColors.placeholder,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _Bullet(text: product.umkmName),
                      _Bullet(text: product.location),
                      _Bullet(text: product.stockLabel),
                      _Bullet(text: 'Rating ${product.rating.toStringAsFixed(1)}'),
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

class _StatusBadge extends StatelessWidget {
  const _StatusBadge(this.status);

  final ConsumerProductStatus status;

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

class _CategoryBadge extends StatelessWidget {
  const _CategoryBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
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

class _ImageFallback extends StatelessWidget {
  const _ImageFallback();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Icon(Icons.storefront_outlined, color: AppColors.primary, size: 28),
    );
  }
}

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

class _TransactionEmptyState extends StatelessWidget {
  const _TransactionEmptyState();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(24, 24, 24, 48),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_outlined, size: 56, color: Color(0xFFCBD5E1)),
          SizedBox(height: 12),
          Text(
            'Belum ada transaksi',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.subtitle,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Tekan Tambah Transaksi untuk membuat transaksi pertama.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: AppColors.placeholder),
          ),
        ],
      ),
    );
  }
}
