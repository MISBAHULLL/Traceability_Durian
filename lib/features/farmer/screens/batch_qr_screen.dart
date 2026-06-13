import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_top_bar.dart';
import '../../../shared/widgets/primary_pill_button.dart';
import '../../trace/screens/public_trace_screen.dart';
import '../data/farmer_repository.dart';
import '../farmer_routes.dart';
import 'farmer_home_screen.dart';

// [FE - Component Rendering] Screen ini menampilkan QR Code yang dapat
// dipindai untuk menelusuri batch secara publik, dengan perilaku back
// khusus bila dibuka setelah create (kembali ke Beranda, bukan ke form).
/// Layar QR Code untuk satu batch panen.
///
/// Menampilkan QR code yang dapat dipindai untuk menelusuri batch secara
/// publik, kode batch, dan URL telusur publik yang dapat disalin.
///
/// Bila [openedAfterCreate] bernilai `true`, tombol back (gesture maupun
/// tombol sistem) akan mengarahkan ke [FarmerHomeScreen] alih-alih pop
/// biasa — mencegah pengguna kembali ke form Tambah Batch (Req 4.6).
class BatchQrScreen extends StatefulWidget {
  const BatchQrScreen({
    super.key,
    required this.batchCode,
    this.openedAfterCreate = false,
  });

  /// Kode batch yang QR-nya akan ditampilkan.
  final String batchCode;

  /// Bila `true`, back gesture/button mengarahkan ke Beranda, bukan pop.
  final bool openedAfterCreate;

  @override
  State<BatchQrScreen> createState() => _BatchQrScreenState();
}

class _BatchQrScreenState extends State<BatchQrScreen>
    with SingleTickerProviderStateMixin {
  final _repo = FarmerRepository.instance;

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
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  // [FE - Event Handler] _handleBack menangani logika back yang berbeda
  // tergantung konteks: bila dibuka setelah create, ganti stack ke Beranda;
  // bila dibuka dari detail/beranda, pop biasa.
  void _handleBack() {
    if (widget.openedAfterCreate) {
      FarmerRoutes.replaceAll(context, const FarmerHomeScreen());
    } else {
      Navigator.maybePop(context);
    }
  }

  // [FE - Event Handler] Tombol ini mensimulasikan hasil scan QR oleh
  // konsumen: membuka halaman trace publik read-only berdasarkan kode batch.
  void _handleViewDetail() {
    FarmerRoutes.push(context, PublicTraceScreen(batchCode: widget.batchCode));
  }

  @override
  Widget build(BuildContext context) {
    final url = _repo.publicTraceUrl(widget.batchCode);

    return PopScope(
      canPop: !widget.openedAfterCreate,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && widget.openedAfterCreate) {
          FarmerRoutes.replaceAll(context, const FarmerHomeScreen());
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.white,
        body: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: SlideTransition(
              position: _slideAnim,
              child: Column(
                children: [
                  // Top bar dengan back kustom (Req 4.6)
                  AppTopBar(title: 'QR Batch', onBack: _handleBack),

                  // Konten utama
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const SizedBox(height: 8),

                          // ── QR Code Card (Req 4.1, 8.2) ─────────────────
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFFE5E7EB),
                              ),
                            ),
                            child: QrImageView(
                              data: url,
                              version: QrVersions.auto,
                              size: 220,
                              backgroundColor: AppColors.white,
                            ),
                          ),

                          const SizedBox(height: 28),

                          // ── Kode Batch (Req 4.2) ─────────────────────────
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                'Kode Batch:',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.subtitle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                widget.batchCode,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primary,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),

                          // ── URL Telusur Publik (Req 4.3) ─────────────────
                          Column(
                            children: [
                              const Text(
                                'URL Telusur Publik',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.placeholder,
                                ),
                              ),
                              const SizedBox(height: 6),
                              SelectableText(
                                url,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.placeholder,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 36),

                          // ── Tombol Lihat Detail ──────────────────────────
                          PrimaryPillButton(
                            label: 'LIHAT DETAIL',
                            onPressed: _handleViewDetail,
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
