import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_top_bar.dart';
import '../../../shared/widgets/batch_photo.dart';
import '../../farmer/models/harvest_batch.dart';
import '../collector_routes.dart';
import '../data/collector_repository.dart';
import '../models/collector_shipment_batch.dart';
import 'shipment_qr_screen.dart';

const _pageBackground = Color(0xFFF4F6F3);
const _borderColor = Color(0xFFE1E6DF);

enum _HistoryTab { receipts, shipments }

// [FE - Component Rendering] Screen ini menjadi audit trail operasional
// pengepul dengan pemisahan aktivitas penerimaan dan pengiriman stok.
class CollectorHistoryScreen extends StatefulWidget {
  const CollectorHistoryScreen({super.key});

  @override
  State<CollectorHistoryScreen> createState() => _CollectorHistoryScreenState();
}

class _CollectorHistoryScreenState extends State<CollectorHistoryScreen> {
  final _repo = CollectorRepository.instance;
  _HistoryTab _activeTab = _HistoryTab.receipts;

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

  // [FE - State Management] Listener ini menjaga riwayat mengikuti perubahan
  // status verifikasi, penolakan, dan handover pengiriman secara reaktif.
  void _onRepoChanged() {
    if (mounted) setState(() {});
  }

  // [FE - Event Handler] Kartu pengiriman membuka QR dan detail handover dari
  // manifest yang dipilih tanpa membuat salinan data riwayat baru.
  Future<void> _openShipment(CollectorShipmentBatch shipment) async {
    await CollectorRoutes.push(
      context,
      ShipmentQrScreen(shipmentCode: shipment.code),
    );
  }

  @override
  Widget build(BuildContext context) {
    final receipts = _repo.historyBatches;
    final shipments = _repo.shipmentBatches;

    return Scaffold(
      backgroundColor: _pageBackground,
      body: SafeArea(
        child: Column(
          children: [
            const ColoredBox(
              color: AppColors.white,
              child: AppTopBar(title: 'Riwayat Aktivitas'),
            ),
            _HistoryTabBar(
              activeTab: _activeTab,
              receiptCount: receipts.length,
              shipmentCount: shipments.length,
              onChanged: (tab) => setState(() => _activeTab = tab),
            ),
            Expanded(
              child: _activeTab == _HistoryTab.receipts
                  ? _ReceiptHistoryList(receipts: receipts)
                  : _ShipmentHistoryList(
                      shipments: shipments,
                      onOpen: _openShipment,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// [FE - Component Rendering] Segmented tab menjaga dua jenis audit tetap
// berada pada satu menu tanpa mencampurkan penerimaan dan pengiriman.
class _HistoryTabBar extends StatelessWidget {
  const _HistoryTabBar({
    required this.activeTab,
    required this.receiptCount,
    required this.shipmentCount,
    required this.onChanged,
  });

  final _HistoryTab activeTab;
  final int receiptCount;
  final int shipmentCount;
  final ValueChanged<_HistoryTab> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      child: Container(
        height: 44,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: _pageBackground,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Expanded(
              child: _TabButton(
                label: 'Penerimaan',
                count: receiptCount,
                selected: activeTab == _HistoryTab.receipts,
                onTap: () => onChanged(_HistoryTab.receipts),
              ),
            ),
            Expanded(
              child: _TabButton(
                label: 'Pengiriman',
                count: shipmentCount,
                selected: activeTab == _HistoryTab.shipments,
                onTap: () => onChanged(_HistoryTab.shipments),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: selected ? Border.all(color: _borderColor) : null,
        ),
        child: Text(
          '$label ($count)',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: selected ? AppColors.primary : AppColors.placeholder,
          ),
        ),
      ),
    );
  }
}

class _ReceiptHistoryList extends StatelessWidget {
  const _ReceiptHistoryList({required this.receipts});

  final List<HarvestBatch> receipts;

  @override
  Widget build(BuildContext context) {
    if (receipts.isEmpty) {
      return const _EmptyHistory(
        icon: Icons.fact_check_outlined,
        title: 'Belum ada aktivitas penerimaan',
        message: 'Verifikasi dan penolakan batch petani akan tercatat di sini.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      itemCount: receipts.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) => _ReceiptCard(batch: receipts[index]),
    );
  }
}

class _ShipmentHistoryList extends StatelessWidget {
  const _ShipmentHistoryList({required this.shipments, required this.onOpen});

  final List<CollectorShipmentBatch> shipments;
  final ValueChanged<CollectorShipmentBatch> onOpen;

  @override
  Widget build(BuildContext context) {
    if (shipments.isEmpty) {
      return const _EmptyHistory(
        icon: Icons.local_shipping_outlined,
        title: 'Belum ada aktivitas pengiriman',
        message:
            'Manifest yang dibuat untuk UMKM atau distributor akan muncul di sini.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      itemCount: shipments.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final shipment = shipments[index];
        return _ShipmentHistoryCard(
          shipment: shipment,
          onTap: () => onOpen(shipment),
        );
      },
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: AppColors.placeholder),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: AppColors.black,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                height: 1.4,
                color: AppColors.placeholder,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// [FE - Component Rendering] Kartu penerimaan mempertahankan data awal dan
// hasil aksi pengepul sebagai bukti audit yang tidak hilang saat status lanjut.
class _ReceiptCard extends StatelessWidget {
  const _ReceiptCard({required this.batch});

  final HarvestBatch batch;

  bool get _isRejected => batch.rejectedAt != null;

  @override
  Widget build(BuildContext context) {
    final eventAt = _isRejected
        ? batch.rejectedAt!
        : batch.verifiedAt ?? batch.createdAt ?? batch.harvestDate;
    final statusColor = _isRejected
        ? const Color(0xFFC83B3B)
        : AppColors.primary;
    final receivedWeight = batch.receivedQuantity ?? batch.quantity;
    final receivedFruit = batch.receivedFruitCount ?? batch.fruitCount;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ActivityIcon(
                  icon: _isRejected
                      ? Icons.close_rounded
                      : Icons.fact_check_outlined,
                  color: statusColor,
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        batch.code,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Durian ${batch.variety} · ${batch.farmName}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppColors.black,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _StatusBadge(
                  label: _isRejected ? 'Ditolak' : 'Diterima',
                  color: statusColor,
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: _borderColor),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 13),
            child: Column(
              children: [
                _DetailRow(label: 'Waktu', value: _formatDateTime(eventAt)),
                _DetailRow(
                  label: _isRejected ? 'Jumlah awal' : 'Jumlah diterima',
                  value:
                      '${_formatWeight(receivedWeight)} kg · ${receivedFruit ?? '-'} butir',
                ),
                _DetailRow(
                  label: 'Grade',
                  value: _isRejected
                      ? 'Estimasi petani Grade ${batch.grade}'
                      : 'Dominan Grade ${batch.verifiedGrade ?? batch.grade}',
                  isLast: true,
                ),
              ],
            ),
          ),
          if ((_isRejected ? batch.rejectionReason : batch.qualityNotes)
                  ?.trim()
                  .isNotEmpty ==
              true)
            _NoteBox(
              text: (_isRejected ? batch.rejectionReason : batch.qualityNotes)!
                  .trim(),
              isError: _isRejected,
            ),
          if (!_isRejected &&
              batch.verificationPhotoPath?.trim().isNotEmpty == true)
            _VerificationPhotoPreview(path: batch.verificationPhotoPath!),
        ],
      ),
    );
  }
}

class _VerificationPhotoPreview extends StatelessWidget {
  const _VerificationPhotoPreview({required this.path});

  final String path;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: _borderColor)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Foto Verifikasi Fisik',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: AppColors.placeholder,
            ),
          ),
          const SizedBox(height: 8),
          BatchPhoto(
            path: path,
            width: double.infinity,
            height: 150,
            borderRadius: BorderRadius.circular(8),
          ),
        ],
      ),
    );
  }
}

// [FE - Component Rendering] Kartu pengiriman mencatat manifest, penerima,
// kuantitas, dan status handover untuk audit stok keluar pengepul.
class _ShipmentHistoryCard extends StatelessWidget {
  const _ShipmentHistoryCard({required this.shipment, required this.onTap});

  final CollectorShipmentBatch shipment;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final statusColor = switch (shipment.status) {
      CollectorShipmentStatus.readyToShip => const Color(0xFF9A6700),
      CollectorShipmentStatus.sent => const Color(0xFF1D6FA4),
      CollectorShipmentStatus.completed => AppColors.primary,
    };
    final latestTime =
        shipment.completedAt ?? shipment.sentAt ?? shipment.packagedAt;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _borderColor),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ActivityIcon(
                    icon:
                        shipment.destinationType == ShipmentDestinationType.umkm
                        ? Icons.storefront_outlined
                        : Icons.local_shipping_outlined,
                    color: statusColor,
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          shipment.code,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Tujuan ${shipment.destinationType.label}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _StatusBadge(
                    label: shipment.status.label,
                    color: statusColor,
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: _borderColor),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 13),
              child: Column(
                children: [
                  _DetailRow(
                    label: 'Aktivitas terakhir',
                    value: _formatDateTime(latestTime),
                  ),
                  _DetailRow(
                    label: 'Isi manifest',
                    value: '${shipment.sourceBatchCodes.length} batch sumber',
                  ),
                  _DetailRow(
                    label: 'Total dikirim',
                    value:
                        '${_formatWeight(shipment.totalWeightKg)} kg · ${shipment.totalFruitCount} butir',
                    isLast: true,
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
              decoration: const BoxDecoration(
                color: Color(0xFFF8F9F7),
                border: Border(top: BorderSide(color: _borderColor)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      shipment.sourceBatchCodes.join(', '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.placeholder,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color: AppColors.primary,
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

class _ActivityIcon extends StatelessWidget {
  const _ActivityIcon({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, size: 21, color: color),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    this.isLast = false,
  });

  final String label;
  final String value;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 112,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.placeholder,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 11,
                height: 1.35,
                fontWeight: FontWeight.w700,
                color: AppColors.subtitle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NoteBox extends StatelessWidget {
  const _NoteBox({required this.text, required this.isError});

  final String text;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
      decoration: BoxDecoration(
        color: isError ? const Color(0xFFFFF1F1) : const Color(0xFFF8F9F7),
        border: const Border(top: BorderSide(color: _borderColor)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          height: 1.4,
          color: isError ? const Color(0xFFA52F2F) : AppColors.placeholder,
        ),
      ),
    );
  }
}

String _formatWeight(double value) {
  return value % 1 == 0 ? value.toStringAsFixed(0) : value.toStringAsFixed(2);
}

// [UTIL - Helper Function] Formatter ini menyeragamkan waktu audit pada kartu
// penerimaan dan pengiriman agar kronologi mudah dibandingkan pengguna.
String _formatDateTime(DateTime date) {
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
  final hour = date.hour.toString().padLeft(2, '0');
  final minute = date.minute.toString().padLeft(2, '0');
  return '${date.day} ${months[date.month - 1]} ${date.year}, $hour:$minute';
}
