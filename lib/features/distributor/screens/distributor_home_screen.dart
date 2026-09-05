import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../collector/models/collector_shipment_batch.dart';
import '../../farmer/models/harvest_batch.dart';
import '../data/distributor_repository.dart';
import '../distributor_routes.dart';
import '../models/distributor_acquisition_transaction.dart';
import '../models/distributor_profile.dart';
import '../widgets/distributor_drawer.dart';
import 'distributor_acquisition_verify_screen.dart';
import 'distributor_profile_screen.dart';
import 'distributor_receipt_screen.dart';
import 'distributor_stock_receipt_screen.dart';

class DistributorHomeScreen extends StatefulWidget {
  const DistributorHomeScreen({super.key});

  @override
  State<DistributorHomeScreen> createState() => _DistributorHomeScreenState();
}

class _DistributorHomeScreenState extends State<DistributorHomeScreen>
    with SingleTickerProviderStateMixin {
  final _repo = DistributorRepository.instance;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0, 0.8, curve: Curves.easeInOutCubic),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: const Interval(0, 0.9, curve: Curves.easeOutCubic),
          ),
        );
    _animationController.forward();
    _repo.addListener(_onRepositoryChanged);
  }

  @override
  void dispose() {
    _repo.removeListener(_onRepositoryChanged);
    _animationController.dispose();
    super.dispose();
  }

  void _onRepositoryChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _openProfile() async {
    await DistributorRoutes.push(context, const DistributorProfileScreen());
  }

  Future<void> _openScanner() async {
    await DistributorRoutes.push(
      context,
      const DistributorStockReceiptScreen(),
    );
  }

  Future<void> _openPendingValidation(
    DistributorAcquisitionTransaction transaction,
  ) async {
    await DistributorRoutes.push<bool>(
      context,
      DistributorAcquisitionVerifyScreen(transactionId: transaction.id),
    );
  }

  Future<void> _openCollectorValidation(CollectorShipmentBatch shipment) async {
    final transaction = _repo.initiateCollectorAcquisition(shipment.code);
    if (transaction == null) return;
    await _openPendingValidation(transaction);
  }

  Future<void> _openFarmerValidation(HarvestBatch batch) async {
    final transaction = _repo.initiateFarmerAcquisition(batch.code);
    if (transaction == null) return;
    await _openPendingValidation(transaction);
  }

  Future<void> _openReceipt(CollectorShipmentBatch shipment) async {
    await DistributorRoutes.push<bool>(
      context,
      DistributorReceiptScreen(shipmentCode: shipment.code),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = _repo.profile;
    final pendingTransactions = _repo.pendingAcquisitionTransactions;
    final pendingCodes = pendingTransactions
        .map((transaction) => transaction.itemCode)
        .toSet();
    final collectorReadyShipments = _repo.readyToPickShipments
        .where((shipment) => !pendingCodes.contains(shipment.code))
        .toList();
    final farmerReadyBatches = _repo.availableFarmerAcquisitionBatches
        .where((batch) => !pendingCodes.contains(batch.code))
        .toList();
    final inspectionShipments = _repo.activeShipments;
    final incomingItems = <_IncomingStockItem>[
      ...pendingTransactions.map(
        (transaction) => _IncomingStockItem(
          code: transaction.itemCode,
          source: '${transaction.source.label} - ${transaction.supplierLabel}',
          quantity:
              '${_formatWeight(transaction.expectedWeightKg)} / ${transaction.expectedFruitCount} butir',
          statusLabel: 'Lanjutkan validasi',
          icon: transaction.source == DistributorAcquisitionSource.farmer
              ? Icons.agriculture_outlined
              : Icons.inventory_2_outlined,
          onTap: () => _openPendingValidation(transaction),
        ),
      ),
      ...collectorReadyShipments.map(
        (shipment) => _IncomingStockItem(
          code: shipment.code,
          source: 'Pengepul - ${shipment.collectorId}',
          quantity:
              '${_formatWeight(shipment.totalWeightKg)} / ${shipment.totalFruitCount} butir',
          statusLabel: 'Belum divalidasi',
          icon: Icons.inventory_2_outlined,
          onTap: () => _openCollectorValidation(shipment),
        ),
      ),
      ...farmerReadyBatches.map(
        (batch) => _IncomingStockItem(
          code: batch.code,
          source: 'Petani - ${batch.farmName}',
          quantity:
              '${_formatWeight(batch.quantity)} / ${batch.fruitCount ?? 0} butir',
          statusLabel: 'Belum divalidasi',
          icon: Icons.agriculture_outlined,
          onTap: () => _openFarmerValidation(batch),
        ),
      ),
      ...inspectionShipments.map(
        (shipment) => _IncomingStockItem(
          code: shipment.code,
          source: 'Pengepul - ${shipment.collectorId}',
          quantity:
              '${_formatWeight(shipment.totalWeightKg)} / ${shipment.totalFruitCount} butir',
          statusLabel: 'Perlu pemeriksaan',
          icon: Icons.fact_check_outlined,
          onTap: () => _openReceipt(shipment),
        ),
      ),
    ];
    final totalIncomingCount = incomingItems.length;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.white,
      endDrawer: const DistributorDrawer(),
      body: ColoredBox(
        color: AppColors.homeHeaderSurface,
        child: SafeArea(
          bottom: false,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Column(
                children: [
                  _TopBar(
                    onProfile: _openProfile,
                    onMenu: () => _scaffoldKey.currentState?.openEndDrawer(),
                  ),
                  Expanded(
                    child: ColoredBox(
                      color: AppColors.white,
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
                        children: [
                          _GreetingBlock(profile: profile),
                          const SizedBox(height: 16),
                          _StatRow(repository: _repo),
                          const SizedBox(height: 16),
                          _ScanStockCard(onTap: _openScanner),
                          const SizedBox(height: 18),
                          Row(
                            children: [
                              const Expanded(
                                child: Text(
                                  'Penerimaan Stok',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.black,
                                  ),
                                ),
                              ),
                              Text(
                                '$totalIncomingCount batch',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.placeholder,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          if (totalIncomingCount == 0)
                            const _EmptyIncomingStock()
                          else
                            ...incomingItems.map(
                              (item) => _IncomingBatchCard(
                                code: item.code,
                                source: item.source,
                                quantity: item.quantity,
                                status: item.statusLabel,
                                icon: item.icon,
                                onTap: item.onTap,
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
          IconButton(
            onPressed: onProfile,
            tooltip: 'Profil',
            icon: const Icon(
              Icons.person_outline_rounded,
              color: AppColors.black,
              size: 24,
            ),
          ),
          IconButton(
            onPressed: onMenu,
            tooltip: 'Menu',
            icon: const Icon(
              Icons.menu_rounded,
              color: AppColors.black,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }
}

class _GreetingBlock extends StatelessWidget {
  const _GreetingBlock({required this.profile});

  final DistributorProfile profile;

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
              Icons.local_shipping_rounded,
              size: 15,
              color: AppColors.primary,
            ),
            const SizedBox(width: 4),
            Text(
              profile.roleLabel,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.primary,
              ),
            ),
            if (profile.location.isNotEmpty) ...[
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 7),
                child: Text(
                  '|',
                  style: TextStyle(color: AppColors.placeholder),
                ),
              ),
              Flexible(
                child: Text(
                  profile.location,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.placeholder,
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({required this.repository});

  final DistributorRepository repository;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            value: '${repository.totalKirim}',
            label: 'Total Kirim',
            icon: Icons.inventory_2_outlined,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            value: '${repository.transit}',
            label: 'Transit',
            icon: Icons.pending_actions_outlined,
            color: const Color(0xFFB45309),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            value: '${repository.tiba}',
            label: 'Tiba',
            icon: Icons.verified_outlined,
            color: const Color(0xFF3F8F27),
          ),
        ),
      ],
    );
  }
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: color,
              height: 1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.placeholder,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _ScanStockCard extends StatelessWidget {
  const _ScanStockCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primaryContainer,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Scan Stok Masuk',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.white,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Pindai QR PGL atau DRN untuk mulai validasi',
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
                width: 42,
                height: 42,
                decoration: const BoxDecoration(
                  color: Color(0xFFF3B23C),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.qr_code_scanner_rounded,
                  color: AppColors.white,
                  size: 24,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IncomingStockItem {
  const _IncomingStockItem({
    required this.code,
    required this.source,
    required this.quantity,
    required this.statusLabel,
    required this.icon,
    required this.onTap,
  });

  final String code;
  final String source;
  final String quantity;
  final String statusLabel;
  final IconData icon;
  final VoidCallback onTap;
}

class _IncomingBatchCard extends StatelessWidget {
  const _IncomingBatchCard({
    required this.code,
    required this.source,
    required this.quantity,
    required this.status,
    required this.icon,
    required this.onTap,
  });

  final String code;
  final String source;
  final String quantity;
  final String status;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isInspection = status == 'Perlu pemeriksaan';
    final isPending = status == 'Lanjutkan validasi';
    final statusColor = isInspection
        ? const Color(0xFF2563EB)
        : isPending
        ? const Color(0xFFB45309)
        : AppColors.primary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Ink(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE1E6DF)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: statusColor, size: 23),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              code,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              status,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: statusColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 7),
                      Row(
                        children: [
                          const Icon(
                            Icons.account_tree_outlined,
                            size: 14,
                            color: AppColors.placeholder,
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              source,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.subtitle,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          const Icon(
                            Icons.scale_outlined,
                            size: 14,
                            color: AppColors.placeholder,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            quantity,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.placeholder,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                Align(
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color: statusColor,
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

class _EmptyIncomingStock extends StatelessWidget {
  const _EmptyIncomingStock();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE1E6DF)),
      ),
      child: const Column(
        children: [
          Icon(Icons.inventory_2_outlined, size: 34, color: Color(0xFFCBD5E1)),
          SizedBox(height: 8),
          Text(
            'Tidak ada stok masuk aktif.',
            style: TextStyle(fontSize: 12, color: AppColors.placeholder),
          ),
        ],
      ),
    );
  }
}

String _formatWeight(double value) {
  final formatted = value % 1 == 0
      ? value.toStringAsFixed(0)
      : value.toStringAsFixed(2);
  return '$formatted kg';
}
