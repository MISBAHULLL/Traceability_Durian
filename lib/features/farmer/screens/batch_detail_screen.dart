import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_top_bar.dart';
import '../../../shared/widgets/batch_photo.dart';
import '../../../shared/widgets/osm_map_preview.dart';
import '../../../shared/widgets/primary_pill_button.dart';
import '../../trace/screens/public_trace_screen.dart';
import '../data/cahyadsn_region_service.dart';
import '../data/farmer_repository.dart';
import '../farmer_routes.dart';
import '../models/batch_event.dart';
import '../models/farm.dart';
import '../models/harvest_batch.dart';
import 'add_batch_screen.dart';
import 'batch_qr_screen.dart';

/// Memformat sisa durasi jendela koreksi menjadi teks ringkas berbahasa
/// Indonesia, mis. "14 menit" atau "45 detik".
String _formatRemaining(Duration d) {
  if (d.inMinutes >= 1) return '${d.inMinutes} menit';
  return '${d.inSeconds} detik';
}

// [FE - Component Rendering] Screen ini menampilkan detail lengkap satu
// batch — mengambil data dari FarmerRepository dan menegakkan aturan
// role (aksi ubah hanya DRAFT, aksi role lain disembunyikan).
/// Layar detail satu batch panen milik petani.
///
/// Menampilkan profil petani, peta lokasi kebun, kode batch, informasi produk,
/// badge status, timeline kejadian, dan aksi utama (QR). Aksi "Ubah Data"
/// hanya muncul bila status batch adalah DRAFT (Req 3.8, 3.9, 7.3).
///
/// Aksi verifikasi, distribusi, penerimaan, dan pembuatan produk
/// disembunyikan sesuai role matrix petani (Req 3.10, 7.1).
///
/// Bila [batchCode] tidak ditemukan di repository, layar menampilkan
/// state "Batch tidak ditemukan" dengan tombol kembali.
class BatchDetailScreen extends StatefulWidget {
  const BatchDetailScreen({super.key, required this.batchCode});

  /// Kode batch yang akan ditampilkan detailnya.
  final String batchCode;

  @override
  State<BatchDetailScreen> createState() => _BatchDetailScreenState();
}

class _BatchDetailScreenState extends State<BatchDetailScreen> {
  final _repo = FarmerRepository.instance;

  @override
  void initState() {
    super.initState();
    _repo.addListener(_onRepoChanged);
  }

  @override
  void dispose() {
    _repo.removeListener(_onRepoChanged);
    super.dispose();
  }

  void _onRepoChanged() {
    if (mounted) setState(() {});
  }

  // ── Navigasi ───────────────────────────────────────────────────────────────

  void _openQr() {
    FarmerRoutes.push(context, BatchQrScreen(batchCode: widget.batchCode));
  }

  // [FE - Event Handler] Membuka halaman trace publik yang sama dengan QR.
  void _openTrace() {
    FarmerRoutes.push(context, PublicTraceScreen(batchCode: widget.batchCode));
  }

  Future<void> _openEdit() async {
    // Buka form dalam mode ubah dengan kode batch ini (prefill + updateBatch).
    await FarmerRoutes.push(
      context,
      AddBatchScreen(editBatchCode: widget.batchCode),
    );
    // Repo listener sudah menangani refresh via _onRepoChanged
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final batch = _repo.findBatch(widget.batchCode);

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar dengan tombol back (Req 3.1)
            const AppTopBar(title: 'Detail Batch'),

            // Konten utama
            Expanded(
              child: batch == null
                  ? _BatchNotFound(batchCode: widget.batchCode)
                  : _BatchDetailContent(
                      batch: batch,
                      repo: _repo,
                      onOpenQr: _openQr,
                      onOpenTrace: _openTrace,
                      onOpenEdit: _openEdit,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// State: Batch tidak ditemukan
// ─────────────────────────────────────────────────────────────────────────────

class _BatchNotFound extends StatelessWidget {
  const _BatchNotFound({required this.batchCode});

  final String batchCode;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.search_off_rounded,
            size: 64,
            color: Color(0xFFCBD5E1),
          ),
          const SizedBox(height: 16),
          const Text(
            'Batch tidak ditemukan',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.subtitle,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Kode "$batchCode" tidak ditemukan atau bukan milik akun ini.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.placeholder,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: 160,
            child: PrimaryPillButton(
              label: 'KEMBALI',
              onPressed: () => Navigator.maybePop(context),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Konten detail batch
// ─────────────────────────────────────────────────────────────────────────────

// [FE - Component Rendering] _BatchDetailContent merakit semua sub-widget
// detail batch dan menentukan visibilitas aksi berdasarkan canEditBatch —
// menegakkan aturan state machine di lapisan UI.
class _BatchDetailContent extends StatelessWidget {
  const _BatchDetailContent({
    required this.batch,
    required this.repo,
    required this.onOpenQr,
    required this.onOpenTrace,
    required this.onOpenEdit,
  });

  final HarvestBatch batch;
  final FarmerRepository repo;
  final VoidCallback onOpenQr;
  final VoidCallback onOpenTrace;
  final VoidCallback onOpenEdit;

  @override
  Widget build(BuildContext context) {
    final profile = repo.profile;
    final events = repo.eventsFor(batch.code);
    final canEdit = repo.canEditBatch(batch.code);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Foto Durian (bila ada) ─────────────────────────────────────────
          // ── Profil Petani (Req 3.2) ────────────────────────────────────────
          _FarmerProfileSection(profile: profile),
          const SizedBox(height: 16),

          // ── Peta Lokasi Kebun (Req 3.3) ───────────────────────────────────
          _BatchProductSummaryCard(batch: batch),
          const SizedBox(height: 16),

          // ── Kode Batch (Req 3.4) ───────────────────────────────────────────
          _BatchCodeRow(code: batch.code),
          const SizedBox(height: 12),
          PrimaryPillButton(label: 'LIHAT QR CODE', onPressed: onOpenQr),
          const SizedBox(height: 18),

          // ── Informasi Produk (Req 3.4) ─────────────────────────────────────
          // ── Badge Status (Req 3.5) ─────────────────────────────────────────

          // [FE - Component Rendering] Kartu penolakan hanya muncul saat
          // batch rejected agar petani mendapat konteks bisnisnya.
          if (batch.status == BatchStatus.rejected) ...[
            _RejectionInfoCard(batch: batch),
            const SizedBox(height: 16),
          ],

          // ── Timeline (Req 3.6) ─────────────────────────────────────────────
          _BatchTimeline(events: events),
          const SizedBox(height: 24),

          // ── Aksi Utama → QR (Req 3.7) ─────────────────────────────────────
          OutlinedButton.icon(
            onPressed: onOpenTrace,
            icon: const Icon(Icons.route_rounded, size: 18),
            label: const Text('LIHAT TRACE DURIAN'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primaryContainer),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
              textStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
              ),
            ),
          ),

          // ── Aksi Ubah Data — selama jendela koreksi terbuka (Req 3.8) ────
          // Tampil bila batch masih dapat diubah (DRAFT, atau CREATED dalam
          // jendela waktu). Untuk CREATED, sertakan sisa waktu agar user paham
          // tombol akan hilang setelah jendela habis.
          if (canEdit) ...[
            const SizedBox(height: 12),
            _EditButton(onTap: onOpenEdit),
            Builder(
              builder: (_) {
                final remaining = repo.remainingEditTime(batch.code);
                if (remaining <= Duration.zero) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.schedule_rounded,
                        size: 14,
                        color: AppColors.placeholder,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Masih dapat diubah ${_formatRemaining(remaining)} lagi',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.placeholder,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Seksi Profil Petani (Req 3.2)
// ─────────────────────────────────────────────────────────────────────────────

class _FarmerProfileSection extends StatelessWidget {
  const _FarmerProfileSection({required this.profile});

  final FarmerProfile profile;

  @override
  Widget build(BuildContext context) {
    // Susun alamat dari komponen non-kosong: desa, kecamatan, kabupaten.
    final addressParts = <String>[
      if (profile.village.isNotEmpty) profile.village,
      if (profile.district.isNotEmpty) 'Kec. ${profile.district}',
      if (profile.city.isNotEmpty) profile.city,
    ];
    final address = addressParts.isNotEmpty
        ? addressParts.join(', ')
        : 'Alamat belum dilengkapi';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          // Avatar inisial
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primaryContainer.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                profile.fullName.isNotEmpty
                    ? profile.fullName[0].toUpperCase()
                    : 'P',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryContainer,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.fullName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.black,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    const Icon(
                      Icons.place_outlined,
                      size: 13,
                      color: AppColors.placeholder,
                    ),
                    const SizedBox(width: 3),
                    Expanded(
                      child: Text(
                        address,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.placeholder,
                          height: 1.3,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
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

// ─────────────────────────────────────────────────────────────────────────────
// Peta Lokasi Kebun (Req 3.3)
// ─────────────────────────────────────────────────────────────────────────────

class _BatchProductSummaryCard extends StatefulWidget {
  const _BatchProductSummaryCard({required this.batch});

  final HarvestBatch batch;

  @override
  State<_BatchProductSummaryCard> createState() =>
      _BatchProductSummaryCardState();
}

class _BatchProductSummaryCardState extends State<_BatchProductSummaryCard> {
  bool _isExpanded = false;

  HarvestBatch get batch => widget.batch;

  String _formatDate(DateTime date) {
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
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _formatWeight(double value) {
    return value % 1 == 0 ? value.toStringAsFixed(0) : value.toStringAsFixed(1);
  }

  String _formatDateTime(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '${_formatDate(date)}, $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final createdAt = batch.createdAt ?? batch.harvestDate;
    final maturity = batch.maturityLevel?.trim();

    return AnimatedSize(
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeInOutCubic,
      alignment: Alignment.topCenter,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE1E6DF)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => setState(() => _isExpanded = !_isExpanded),
                child: SizedBox(
                  height: 132,
                  child: Row(
                    children: [
                      BatchPhoto(
                        path: batch.photoPath,
                        width: 120,
                        height: 132,
                        borderRadius: BorderRadius.zero,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(0, 12, 10, 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Durian ${batch.variety}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.black,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 7,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: batch.status.background,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      batch.status.label,
                                      maxLines: 1,
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w700,
                                        color: batch.status.color,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Dibuat ${_formatDate(createdAt)}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.placeholder,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                '${_formatWeight(batch.quantity)} ${batch.unit} | ${batch.fruitCount ?? 0} butir',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.subtitle,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                maturity == null || maturity.isEmpty
                                    ? 'Grade ${batch.grade}'
                                    : 'Grade ${batch.grade} | $maturity',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.subtitle,
                                ),
                              ),
                              const Spacer(),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.landscape_outlined,
                                    size: 13,
                                    color: AppColors.primary,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      batch.farmName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.placeholder,
                                      ),
                                    ),
                                  ),
                                  AnimatedRotation(
                                    turns: _isExpanded ? 0.5 : 0,
                                    duration: const Duration(milliseconds: 220),
                                    child: const Icon(
                                      Icons.keyboard_arrow_down_rounded,
                                      size: 20,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ],
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
            if (_isExpanded) ...[
              const Divider(height: 1, color: Color(0xFFE5E7EB)),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
                child: _ExpandedBatchInformation(
                  batch: batch,
                  formatDate: _formatDate,
                  formatDateTime: _formatDateTime,
                  formatWeight: _formatWeight,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ExpandedBatchInformation extends StatelessWidget {
  const _ExpandedBatchInformation({
    required this.batch,
    required this.formatDate,
    required this.formatDateTime,
    required this.formatWeight,
  });

  final HarvestBatch batch;
  final String Function(DateTime) formatDate;
  final String Function(DateTime) formatDateTime;
  final String Function(double) formatWeight;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[
      _BatchDetailRow(label: 'Kode Batch', value: batch.code),
      _BatchDetailRow(
        label: 'Tanggal Panen',
        value: formatDate(batch.harvestDate),
      ),
      _BatchDetailRow(label: 'Varietas', value: batch.variety),
      _BatchDetailRow(
        label: 'Jumlah Awal',
        value:
            '${formatWeight(batch.quantity)} ${batch.unit} / ${batch.fruitCount ?? 0} butir',
      ),
      _BatchDetailRow(label: 'Grade Awal', value: 'Grade ${batch.grade}'),
      if (batch.maturityLevel?.isNotEmpty ?? false)
        _BatchDetailRow(label: 'Kematangan', value: batch.maturityLevel!),
      if (batch.shelfLifeEstimate?.isNotEmpty ?? false)
        _BatchDetailRow(
          label: 'Estimasi Masa Simpan',
          value: batch.shelfLifeEstimate!,
        ),
      if (batch.harvestMethod?.isNotEmpty ?? false)
        _BatchDetailRow(label: 'Metode Panen', value: batch.harvestMethod!),
      if (batch.storageSuggestion?.isNotEmpty ?? false)
        _BatchDetailRow(
          label: 'Saran Penyimpanan',
          value: batch.storageSuggestion!,
        ),
      if (batch.verifiedGrade?.isNotEmpty ?? false)
        _BatchDetailRow(
          label: 'Grade Penerima',
          value: 'Grade ${batch.verifiedGrade}',
        ),
      if (batch.receivedQuantity != null)
        _BatchDetailRow(
          label: 'Jumlah Diterima',
          value:
              '${formatWeight(batch.receivedQuantity!)} ${batch.unit} / ${batch.receivedFruitCount ?? 0} butir',
        ),
      if (batch.verifiedBy?.isNotEmpty ?? false)
        _BatchDetailRow(label: 'Diverifikasi Oleh', value: batch.verifiedBy!),
      if (batch.verifiedAt != null)
        _BatchDetailRow(
          label: 'Waktu Verifikasi',
          value: formatDateTime(batch.verifiedAt!),
        ),
      if (batch.gradeBreakdown.isNotEmpty)
        _BatchDetailRow(
          label: 'Komposisi Grade',
          value: batch.gradeBreakdown
              .map((item) {
                return '${item.grade}: ${formatWeight(item.weightKg)} kg / ${item.fruitCount} butir';
              })
              .join('\n'),
        ),
      if (batch.notes?.isNotEmpty ?? false)
        _BatchDetailRow(label: 'Catatan', value: batch.notes!),
      if (batch.qualityNotes?.isNotEmpty ?? false)
        _BatchDetailRow(label: 'Catatan Sortir', value: batch.qualityNotes!),
    ];

    return Column(children: rows);
  }
}

class _BatchDetailRow extends StatelessWidget {
  const _BatchDetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 116,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.placeholder,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 11,
                height: 1.35,
                fontWeight: FontWeight.w700,
                color: AppColors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FarmMapCard extends StatefulWidget {
  const _FarmMapCard({required this.farm});

  final Farm? farm;

  @override
  State<_FarmMapCard> createState() => _FarmMapCardState();
}

class _FarmMapCardState extends State<_FarmMapCard> {
  final _regionService = CahyadsnRegionService.instance;
  CahyadsnRegionMap? _region;
  CahyadsnRegionBoundary? _boundary;
  int _regionLevel = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadMapTarget();
  }

  @override
  void didUpdateWidget(covariant _FarmMapCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.farm != widget.farm) {
      _loadMapTarget();
    }
  }

  Future<void> _loadMapTarget() async {
    setState(() => _loading = true);
    await _regionService.load();
    final code = _resolveRegionCode(widget.farm);
    final region = _regionService.mapForClosest(code);
    final boundary = await _regionService.loadBoundaryFor(code);
    if (!mounted) return;
    setState(() {
      _region = region;
      _boundary = boundary;
      _regionLevel = code == null ? 0 : CahyadsnRegionService.levelOf(code);
      _loading = false;
    });
  }

  String? _resolveRegionCode(Farm? farm) {
    if (farm == null) return null;

    final province = _regionService.findExact(
      _regionService.provinces,
      farm.province,
    );
    if (province == null) return null;

    final city = _regionService.findExact(
      _regionService.childrenOf(province.code),
      farm.city,
    );
    if (city == null) return province.code;

    final district = _regionService.findExact(
      _regionService.childrenOf(city.code),
      farm.district,
    );
    if (district == null) return city.code;

    final village = _regionService.findExact(
      _regionService.childrenOf(district.code),
      farm.village,
    );
    return village?.code ?? district.code;
  }

  bool get _hasCoordinate {
    return widget.farm?.latitude != null && widget.farm?.longitude != null;
  }

  OsmMapPoint get _mapCenter {
    final farm = widget.farm;
    if (farm?.latitude != null && farm?.longitude != null) {
      return OsmMapPoint(farm!.latitude!, farm.longitude!);
    }
    final boundary = _boundary;
    if (boundary != null) {
      return OsmMapPoint(boundary.latitude, boundary.longitude);
    }
    final region = _region;
    if (region != null) return OsmMapPoint(region.latitude, region.longitude);
    return const OsmMapPoint(-2.5, 118);
  }

  int get _zoom {
    if (_hasCoordinate) return 14;
    return switch (_regionLevel) {
      0 => 5,
      1 => 7,
      2 => 10,
      3 => 12,
      _ => 14,
    };
  }

  @override
  Widget build(BuildContext context) {
    final center = _mapCenter;
    return Container(
      height: 190,
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6EE),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD1E8CC)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned.fill(
            child: OsmMapPreview(
              center: center,
              initialZoom: _zoom,
              markerPoint: center,
              boundary: _boundary?.rings,
            ),
          ),
          if (_loading)
            const Positioned.fill(
              child: ColoredBox(
                color: Color(0x55FFFFFF),
                child: Center(
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primaryContainer,
                    ),
                  ),
                ),
              ),
            ),
          Positioned(
            right: 6,
            top: 5,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.88),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                child: Text(
                  '(c) OpenStreetMap',
                  style: TextStyle(fontSize: 9, color: AppColors.subtitle),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Baris Kode Batch (Req 3.4)
// ─────────────────────────────────────────────────────────────────────────────

class _BatchCodeRow extends StatelessWidget {
  const _BatchCodeRow({required this.code});

  final String code;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.qr_code_rounded, size: 18, color: AppColors.primary),
        const SizedBox(width: 8),
        const Text(
          'Kode Batch:',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.subtitle,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            code,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
              letterSpacing: 0.8,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Kartu Informasi Produk (Req 3.4)
// ─────────────────────────────────────────────────────────────────────────────

// Dipertahankan sementara untuk kompatibilitas desain detail lama.
// ignore: unused_element
class _ProductInfoCard extends StatelessWidget {
  const _ProductInfoCard({required this.batch});

  final HarvestBatch batch;

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

  String _formatDateTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '${_formatDate(dt)}, $h:$m';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Informasi Produk',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.subtitle,
            ),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFF0F0F0)),
          const SizedBox(height: 12),
          _InfoRow(
            icon: Icons.eco_outlined,
            label: 'Varietas',
            value: batch.variety,
          ),
          const SizedBox(height: 10),
          _InfoRow(
            icon: Icons.scale_outlined,
            label: 'Total Berat',
            value: '${batch.quantity.toStringAsFixed(0)} ${batch.unit}',
          ),
          // [FE - Component Rendering] Jumlah buah ditampilkan terpisah dari
          // total panen agar pengepul bisa membaca komposisi batch per butir.
          if (batch.fruitCount != null) ...[
            const SizedBox(height: 10),
            _InfoRow(
              icon: Icons.inventory_2_outlined,
              label: 'Jumlah Buah',
              value: '${batch.fruitCount} butir',
            ),
          ],
          const SizedBox(height: 10),
          _InfoRow(
            icon: Icons.star_border_rounded,
            label: 'Grade Awal',
            value: 'Grade ${batch.grade}',
          ),
          // [FE - Component Rendering] Hasil verifikasi pengepul ditampilkan
          // terpisah agar grade petani tidak tertimpa oleh grade sortir.
          if (batch.verifiedGrade != null &&
              batch.verifiedGrade!.isNotEmpty) ...[
            const SizedBox(height: 10),
            _InfoRow(
              icon: Icons.verified_outlined,
              label: 'Grade Pengepul',
              value: 'Grade ${batch.verifiedGrade}',
            ),
          ],
          if (batch.receivedQuantity != null) ...[
            const SizedBox(height: 10),
            _InfoRow(
              icon: Icons.inventory_outlined,
              label: 'Berat Diterima',
              value:
                  '${batch.receivedQuantity!.toStringAsFixed(0)} ${batch.unit}',
            ),
          ],
          if (batch.receivedFruitCount != null) ...[
            const SizedBox(height: 10),
            _InfoRow(
              icon: Icons.inventory_2_outlined,
              label: 'Jumlah Diterima',
              value: '${batch.receivedFruitCount} butir',
            ),
          ],
          // [FE - Component Rendering] Rincian grade pengepul membantu petani
          // melihat hasil sortir riil tanpa mengubah grade awal miliknya.
          if (batch.gradeBreakdown.isNotEmpty) ...[
            const SizedBox(height: 10),
            _InfoRow(
              icon: Icons.grading_outlined,
              label: 'Komposisi Grade',
              value: batch.gradeBreakdown
                  .map((item) {
                    final weight = item.weightKg % 1 == 0
                        ? item.weightKg.toStringAsFixed(0)
                        : item.weightKg.toStringAsFixed(2);
                    return '${item.grade}: $weight kg / ${item.fruitCount} butir';
                  })
                  .join('\n'),
            ),
          ],
          if (batch.verifiedBy != null && batch.verifiedBy!.isNotEmpty) ...[
            const SizedBox(height: 10),
            _InfoRow(
              icon: Icons.person_search_outlined,
              label: 'Diverifikasi Oleh',
              value: batch.verifiedBy!,
            ),
          ],
          if (batch.verifiedAt != null) ...[
            const SizedBox(height: 10),
            _InfoRow(
              icon: Icons.event_available_outlined,
              label: 'Waktu Verifikasi',
              value: _formatDateTime(batch.verifiedAt!),
            ),
          ],
          if (batch.qualityNotes != null && batch.qualityNotes!.isNotEmpty) ...[
            const SizedBox(height: 10),
            _InfoRow(
              icon: Icons.rate_review_outlined,
              label: 'Catatan Sortir',
              value: batch.qualityNotes!,
            ),
          ],
          const SizedBox(height: 10),
          _InfoRow(
            icon: Icons.calendar_today_outlined,
            label: 'Tanggal Panen',
            value: _formatDate(batch.harvestDate),
          ),
          // [FE - Component Rendering] Baris opsional ini menampilkan
          // metadata kualitas durian yang dipakai role berikutnya saat sortir.
          if (batch.maturityLevel != null &&
              batch.maturityLevel!.isNotEmpty) ...[
            const SizedBox(height: 10),
            _InfoRow(
              icon: Icons.spa_outlined,
              label: 'Tingkat Kematangan',
              value: batch.maturityLevel!,
            ),
          ],
          if (batch.shelfLifeEstimate != null &&
              batch.shelfLifeEstimate!.isNotEmpty) ...[
            const SizedBox(height: 10),
            _InfoRow(
              icon: Icons.schedule_outlined,
              label: 'Estimasi Masa Simpan',
              value: batch.shelfLifeEstimate!,
            ),
          ],
          if (batch.fertilizer != null && batch.fertilizer!.isNotEmpty) ...[
            const SizedBox(height: 10),
            _InfoRow(
              icon: Icons.grass_outlined,
              label: 'Pupuk',
              value: batch.fertilizer!,
            ),
          ],
          if (batch.harvestMethod != null &&
              batch.harvestMethod!.isNotEmpty) ...[
            const SizedBox(height: 10),
            _InfoRow(
              icon: Icons.agriculture_outlined,
              label: 'Metode Panen',
              value: batch.harvestMethod!,
            ),
          ],
          if (batch.storageSuggestion != null &&
              batch.storageSuggestion!.isNotEmpty) ...[
            const SizedBox(height: 10),
            _InfoRow(
              icon: Icons.inventory_2_outlined,
              label: 'Saran Penyimpanan',
              value: batch.storageSuggestion!,
            ),
          ],
          if (batch.notes != null && batch.notes!.isNotEmpty) ...[
            const SizedBox(height: 10),
            _InfoRow(
              icon: Icons.notes_outlined,
              label: 'Catatan Panen',
              value: batch.notes!,
            ),
          ],
          const SizedBox(height: 10),
          _InfoRow(
            icon: Icons.place_outlined,
            label: 'Kebun',
            value: batch.farmName,
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.placeholder),
        const SizedBox(width: 10),
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: const TextStyle(fontSize: 13, color: AppColors.placeholder),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.black,
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Seksi Badge Status (Req 3.5)
// ─────────────────────────────────────────────────────────────────────────────

// Dipertahankan sementara untuk kompatibilitas desain detail lama.
// ignore: unused_element
class _StatusSection extends StatelessWidget {
  const _StatusSection({required this.status});

  final BatchStatus status;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text(
          'Status:',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.subtitle,
          ),
        ),
        const SizedBox(width: 10),
        _StatusBadge(status: status),
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: status.background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: status.color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            status.label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: status.color,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Timeline Batch (Req 3.6)
// ─────────────────────────────────────────────────────────────────────────────

// [FE - Component Rendering] _BatchTimeline merender daftar BatchEvent
// sebagai timeline vertikal kronologis — warna dot mengikuti status
// batch pada tiap kejadian.
class _BatchTimeline extends StatelessWidget {
  const _BatchTimeline({required this.events});

  final List<BatchEvent> events;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Riwayat Batch',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.subtitle,
          ),
        ),
        const SizedBox(height: 12),
        if (events.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Belum ada riwayat untuk batch ini.',
              style: TextStyle(fontSize: 13, color: AppColors.placeholder),
            ),
          )
        else
          ...List.generate(events.length, (index) {
            final event = events[index];
            final isLast = index == events.length - 1;
            return _TimelineItem(event: event, isLast: isLast);
          }),
      ],
    );
  }
}

class _TimelineItem extends StatelessWidget {
  const _TimelineItem({required this.event, required this.isLast});

  final BatchEvent event;
  final bool isLast;

  String _formatDateTime(DateTime dt) {
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
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}, $h:$m';
  }

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Kolom kiri: dot + garis vertikal
          SizedBox(
            width: 24,
            child: Column(
              children: [
                // Dot berwarna sesuai status
                Container(
                  width: 14,
                  height: 14,
                  margin: const EdgeInsets.only(top: 2),
                  decoration: BoxDecoration(
                    color: event.status.color,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: event.status.color.withValues(alpha: 0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                ),
                // Garis vertikal (kecuali item terakhir)
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: const Color(0xFFE5E7EB),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Konten kanan
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.black,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    event.actorLabel,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.placeholder,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _formatDateTime(event.timestamp),
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.placeholder,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// [FE - Component Rendering] Widget ini menampilkan metadata audit penolakan
// dari repository agar petani tahu alasan batch tidak lanjut ke transaksi.
class _RejectionInfoCard extends StatelessWidget {
  const _RejectionInfoCard({required this.batch});

  final HarvestBatch batch;

  String _formatDateTime(DateTime dt) {
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
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}, $h:$m';
  }

  @override
  Widget build(BuildContext context) {
    final reason = batch.rejectionReason?.trim();
    final rejectedBy = batch.rejectedBy?.trim();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF5F5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF3B4B4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.report_problem_outlined,
                size: 18,
                color: Color(0xFFD64545),
              ),
              SizedBox(width: 8),
              Text(
                'Informasi Penolakan',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFFD64545),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            reason == null || reason.isEmpty
                ? 'Batch ditolak, tetapi alasan belum dicatat.'
                : reason,
            style: const TextStyle(
              fontSize: 13,
              height: 1.45,
              fontWeight: FontWeight.w600,
              color: AppColors.black,
            ),
          ),
          if (rejectedBy != null && rejectedBy.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              'Ditolak oleh: $rejectedBy',
              style: const TextStyle(fontSize: 12, color: AppColors.subtitle),
            ),
          ],
          if (batch.rejectedAt != null) ...[
            const SizedBox(height: 4),
            Text(
              'Waktu: ${_formatDateTime(batch.rejectedAt!)}',
              style: const TextStyle(fontSize: 12, color: AppColors.subtitle),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tombol Ubah Data (Req 3.8 — hanya DRAFT)
// ─────────────────────────────────────────────────────────────────────────────

class _EditButton extends StatelessWidget {
  const _EditButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: const Icon(Icons.edit_outlined, size: 18),
        label: const Text(
          'UBAH DATA',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryContainer,
          side: const BorderSide(color: AppColors.primaryContainer, width: 1.5),
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }
}
