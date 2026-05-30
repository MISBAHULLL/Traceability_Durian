import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_top_bar.dart';
import '../../../shared/widgets/primary_pill_button.dart';
import '../data/farmer_repository.dart';
import '../farmer_routes.dart';
import '../models/batch_event.dart';
import '../models/harvest_batch.dart';
import 'add_batch_screen.dart';
import 'batch_qr_screen.dart';

// [FE - Component Rendering] Screen ini menampilkan detail lengkap satu
// batch — mengambil data dari FarmerRepository dan menegakkan aturan
// role (aksi ubah hanya DRAFT, aksi role lain disembunyikan).
/// Layar detail satu batch panen milik petani.
///
/// Menampilkan profil petani, placeholder peta, kode batch, informasi produk,
/// badge status, timeline kejadian, dan aksi utama (QR). Aksi "Ubah Data"
/// hanya muncul bila status batch adalah DRAFT (Req 3.8, 3.9, 7.3).
///
/// Aksi verifikasi, distribusi, penerimaan, dan pembuatan produk
/// disembunyikan sesuai role matrix petani (Req 3.10, 7.1).
///
/// Bila [batchCode] tidak ditemukan di repository, layar menampilkan
/// state "Batch tidak ditemukan" dengan tombol kembali.
class BatchDetailScreen extends StatefulWidget {
  const BatchDetailScreen({
    super.key,
    required this.batchCode,
  });

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
    FarmerRoutes.push(
      context,
      BatchQrScreen(batchCode: widget.batchCode),
    );
  }

  Future<void> _openEdit() async {
    await FarmerRoutes.push(context, const AddBatchScreen());
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
    required this.onOpenEdit,
  });

  final HarvestBatch batch;
  final FarmerRepository repo;
  final VoidCallback onOpenQr;
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
          // ── Profil Petani (Req 3.2) ────────────────────────────────────────
          _FarmerProfileSection(profile: profile),
          const SizedBox(height: 16),

          // ── Placeholder Peta (Req 3.3) ─────────────────────────────────────
          const _MapPlaceholderCard(),
          const SizedBox(height: 16),

          // ── Kode Batch (Req 3.4) ───────────────────────────────────────────
          _BatchCodeRow(code: batch.code),
          const SizedBox(height: 16),

          // ── Informasi Produk (Req 3.4) ─────────────────────────────────────
          _ProductInfoCard(batch: batch),
          const SizedBox(height: 16),

          // ── Badge Status (Req 3.5) ─────────────────────────────────────────
          _StatusSection(status: batch.status),
          const SizedBox(height: 16),

          // ── Timeline (Req 3.6) ─────────────────────────────────────────────
          _BatchTimeline(events: events),
          const SizedBox(height: 24),

          // ── Aksi Utama → QR (Req 3.7) ─────────────────────────────────────
          PrimaryPillButton(
            label: 'LIHAT QR CODE',
            onPressed: onOpenQr,
          ),

          // ── Aksi Ubah Data — hanya DRAFT (Req 3.8, 3.9) ──────────────────
          if (canEdit) ...[
            const SizedBox(height: 12),
            _EditButton(onTap: onOpenEdit),
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
    final address =
        addressParts.isNotEmpty ? addressParts.join(', ') : 'Alamat belum dilengkapi';

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
// Placeholder Peta (Req 3.3)
// ─────────────────────────────────────────────────────────────────────────────

class _MapPlaceholderCard extends StatelessWidget {
  const _MapPlaceholderCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 140,
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6EE),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD1E8CC)),
      ),
      child: Stack(
        children: [
          // Grid garis peta simulasi
          CustomPaint(
            size: const Size(double.infinity, 140),
            painter: _MapGridPainter(),
          ),
          // Label tengah
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.white.withValues(alpha: 0.9),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.place_rounded,
                    size: 28,
                    color: AppColors.primaryContainer,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.white.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'Peta Lokasi',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.subtitle,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Painter untuk grid garis peta simulasi pada placeholder.
class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFB8D9B2)
      ..strokeWidth = 0.8;

    const step = 28.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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
        const Icon(
          Icons.qr_code_rounded,
          size: 18,
          color: AppColors.primary,
        ),
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
            label: 'Jumlah',
            value: '${batch.quantity.toStringAsFixed(0)} ${batch.unit}',
          ),
          const SizedBox(height: 10),
          _InfoRow(
            icon: Icons.star_border_rounded,
            label: 'Grade/Mutu',
            value: 'Grade ${batch.grade}',
          ),
          const SizedBox(height: 10),
          _InfoRow(
            icon: Icons.calendar_today_outlined,
            label: 'Tanggal Panen',
            value: _formatDate(batch.harvestDate),
          ),
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
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.placeholder,
            ),
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
              style: TextStyle(
                fontSize: 13,
                color: AppColors.placeholder,
              ),
            ),
          )
        else
          ...List.generate(events.length, (index) {
            final event = events[index];
            final isLast = index == events.length - 1;
            return _TimelineItem(
              event: event,
              isLast: isLast,
            );
          }),
      ],
    );
  }
}

class _TimelineItem extends StatelessWidget {
  const _TimelineItem({
    required this.event,
    required this.isLast,
  });

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
                    border: Border.all(
                      color: AppColors.white,
                      width: 2,
                    ),
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
