import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/top_notification_banner.dart';
import '../../collector/models/collector_shipment_batch.dart';
import '../data/distributor_repository.dart';
import '../distributor_routes.dart';
import '../models/distributor_profile.dart';
import '../widgets/distributor_drawer.dart';
import 'distributor_profile_screen.dart';
import 'distributor_receipt_screen.dart';
import 'distributor_scan_qr_screen.dart';
import 'distributor_shipment_detail_screen.dart';

// [FE - Component Rendering] DistributorHomeScreen mengikuti pola layout
// yang identik dengan FarmerHomeScreen dan CollectorHomeScreen:
// TopBar (Beranda + ikon profil + hamburger) → endDrawer → CustomScrollView.
class DistributorHomeScreen extends StatefulWidget {
  const DistributorHomeScreen({super.key});

  @override
  State<DistributorHomeScreen> createState() => _DistributorHomeScreenState();
}

class _DistributorHomeScreenState extends State<DistributorHomeScreen>
    with SingleTickerProviderStateMixin {
  final _repo = DistributorRepository.instance;
  final TopNotification _notif = TopNotification();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

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
    _repo.addListener(_onRepoChanged);
  }

  @override
  void dispose() {
    _repo.removeListener(_onRepoChanged);
    _notif.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _onRepoChanged() {
    if (mounted) setState(() {});
  }

  void _openDrawer() => _scaffoldKey.currentState?.openEndDrawer();

  Future<void> _openProfile() async {
    await DistributorRoutes.push(context, const DistributorProfileScreen());
  }

  void _openQrSimulation() {
    // [FE - Event Handler] CTA beranda membuka scanner kamera penuh; daftar
    // lama di bawah dinonaktifkan sementara untuk menjaga diff tetap terarah.
    DistributorRoutes.push(context, const DistributorScanQrScreen());
    /*
    final readyShipments = _repo.readyToPickShipments;
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => DraggableScrollableSheet(
        initialChildSize: 0.65,
        minChildSize: 0.4,
        maxChildSize: 0.85,
        expand: false,
        builder: (context, scrollCtrl) => Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE5E7EB),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Icon(
              Icons.qr_code_scanner_rounded,
              size: 64,
              color: AppColors.primary,
            ),
            const SizedBox(height: 12),
            const Text(
              'Simulasi Scan QR Pengiriman',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.black,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Pilih batch pengepul yang siap diambil',
              style: TextStyle(fontSize: 12, color: AppColors.placeholder),
            ),
            const SizedBox(height: 16),
            const Divider(height: 1, color: Color(0xFFE5E7EB)),
            Expanded(
              child: readyShipments.isEmpty
                  ? const Center(
                      child: Text(
                        'Tidak ada pengiriman baru dari pengepul.',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.placeholder,
                        ),
                      ),
                    )
                  : ListView.builder(
                      controller: scrollCtrl,
                      padding: const EdgeInsets.all(20),
                      itemCount: readyShipments.length,
                      itemBuilder: (context, i) {
                        final s = readyShipments[i];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE5E7EB)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryContainer.withValues(
                                    alpha: 0.15,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.local_shipping_rounded,
                                  color: AppColors.primary,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      s.code,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.black,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${s.totalWeightKg} kg • ${s.totalFruitCount} butir',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors.placeholder,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primaryContainer,
                                  foregroundColor: AppColors.white,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                onPressed: () async {
                                  final ok = _repo.takeShipment(s.code);
                                  Navigator.pop(sheetCtx);
                                  _notif.show(
                                    context,
                                    ok
                                        ? 'Berhasil mengambil ${s.code}!'
                                        : 'Gagal memproses QR Code.',
                                  );
                                  if (ok && mounted) {
                                    await DistributorRoutes.push<bool>(
                                      context,
                                      DistributorReceiptScreen(
                                        shipmentCode: s.code,
                                      ),
                                    );
                                  }
                                },
                                child: const Text(
                                  'Ambil',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
    */
  }

  // [FE - Event Handler] Navigasi ini membuka detail pengiriman agar
  // distributor bisa melihat agregat, timeline, dan provenance tree.
  Future<void> _openShipmentDetail(CollectorShipmentBatch shipment) async {
    await DistributorRoutes.push(
      context,
      DistributorShipmentDetailScreen(shipmentCode: shipment.code),
    );
  }

  // [FE - Event Handler] Kartu transit membuka form verifikasi penerimaan
  // sehingga status tidak dapat diselesaikan tanpa timbang dan inspeksi.
  Future<void> _markAsArrived(CollectorShipmentBatch shipment) async {
    await DistributorRoutes.push<bool>(
      context,
      DistributorReceiptScreen(shipmentCode: shipment.code),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = _repo.profile;
    final activeShipments = _repo.activeShipments;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.white,
      endDrawer: const DistributorDrawer(),
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
                            _StatRow(repo: _repo),
                            const SizedBox(height: 16),
                            _CtaCard(onTap: _openQrSimulation),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Pengiriman Aktif',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.black,
                                  ),
                                ),
                                Text(
                                  '${activeShipments.length} transit',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.placeholder,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                          ]),
                        ),
                      ),
                      if (activeShipments.isEmpty)
                        const SliverFillRemaining(
                          hasScrollBody: false,
                          child: _EmptyState(),
                        )
                      else
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate((context, i) {
                              final s = activeShipments[i];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _ShipmentCard(
                                  shipment: s,
                                  onDetail: () => _openShipmentDetail(s),
                                  onArrive: () => _markAsArrived(s),
                                ),
                              );
                            }, childCount: activeShipments.length),
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

// ── TopBar (identik dengan Petani & Pengepul) ────────────────────────────────

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
          IconButton(
            onPressed: onProfile,
            icon: const Icon(
              Icons.person_outline_rounded,
              color: AppColors.black,
              size: 24,
            ),
            splashRadius: 22,
          ),
          const SizedBox(width: 4),
          IconButton(
            onPressed: onMenu,
            icon: const Icon(
              Icons.menu_rounded,
              color: AppColors.black,
              size: 24,
            ),
            splashRadius: 22,
          ),
        ],
      ),
    );
  }
}

// ── Greeting ─────────────────────────────────────────────────────────────────

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
              const Text(
                '  •  ',
                style: TextStyle(fontSize: 13, color: AppColors.placeholder),
              ),
              Flexible(
                child: Text(
                  profile.location,
                  style: const TextStyle(
                    fontSize: 12,
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

// ── Stat Row (3 kartu: Total Kirim, Transit, Tiba) ──────────────────────────

class _StatRow extends StatelessWidget {
  const _StatRow({required this.repo});
  final DistributorRepository repo;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            value: '${repo.totalKirim}',
            label: 'Total Kirim',
            icon: Icons.inventory_2_outlined,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            value: '${repo.transit}',
            label: 'Transit',
            icon: Icons.pending_actions_outlined,
            color: const Color(0xFFB45309),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            value: '${repo.tiba}',
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
        borderRadius: BorderRadius.circular(12),
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
              height: 1.0,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
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

// ── CTA Ambil Pengiriman (identik pola dengan AddBatchCard petani) ───────────

class _CtaCard extends StatelessWidget {
  const _CtaCard({required this.onTap});
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
                    'Ambil Pengiriman',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.white,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Scan QR batch pengepul untuk mulai kirim',
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
                Icons.qr_code_scanner_rounded,
                color: AppColors.white,
                size: 24,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Shipment Card ────────────────────────────────────────────────────────────

// [FE - Component Rendering] Kartu ini menampilkan ringkasan shipment; aksi
// navigasi dan konfirmasi dipisah agar area klik tidak terasa ambigu.
class _ShipmentCard extends StatelessWidget {
  const _ShipmentCard({
    required this.shipment,
    required this.onDetail,
    required this.onArrive,
  });

  final CollectorShipmentBatch shipment;
  final VoidCallback onDetail;
  final VoidCallback onArrive;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.local_shipping_outlined,
                    color: Color(0xFFB45309),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            shipment.code,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: AppColors.black,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF3C7),
                              borderRadius: BorderRadius.circular(99),
                            ),
                            child: const Text(
                              'Transit',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFFB45309),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Asal: Gudang Pak Risqi',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.subtitle,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.scale_outlined,
                            size: 13,
                            color: AppColors.placeholder,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${shipment.totalWeightKg.toStringAsFixed(0)} Kg',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.placeholder,
                            ),
                          ),
                          const SizedBox(width: 14),
                          const Icon(
                            Icons.eco_outlined,
                            size: 13,
                            color: AppColors.placeholder,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${shipment.totalFruitCount} butir',
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
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF0F0F0)),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 9, 14, 12),
            // [FE - Component Rendering] Footer memisahkan status dan aksi
            // agar label tombol tidak overflow pada viewport mobile sempit.
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.timer_outlined,
                      size: 14,
                      color: AppColors.placeholder,
                    ),
                    SizedBox(width: 5),
                    Text(
                      'Dalam perjalanan',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.placeholder,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 9),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(color: AppColors.primary),
                          minimumSize: const Size.fromHeight(38),
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        onPressed: onDetail,
                        icon: const Icon(Icons.visibility_outlined, size: 15),
                        label: const Text(
                          'Detail',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromARGB(
                            255,
                            88,
                            168,
                            53,
                          ),
                          foregroundColor: AppColors.white,
                          elevation: 0,
                          minimumSize: const Size.fromHeight(38),
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        onPressed: onArrive,
                        icon: const Icon(Icons.fact_check_outlined, size: 15),
                        label: const Text(
                          'Verifikasi Terima',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
// ── Empty State ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.local_shipping_outlined,
              size: 48,
              color: Color(0xFFCBD5E1),
            ),
            SizedBox(height: 12),
            Text(
              'Tidak ada pengiriman aktif saat ini.',
              style: TextStyle(color: AppColors.placeholder),
            ),
          ],
        ),
      ),
    );
  }
}
