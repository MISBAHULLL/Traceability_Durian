import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_top_bar.dart';
import '../../collector/models/collector_shipment_batch.dart';
import '../data/distributor_repository.dart';
import '../distributor_routes.dart';
import '../models/distributor_receipt.dart';
import 'distributor_shipment_detail_screen.dart';

const _pageBackground = Color(0xFFF4F6F3);
const _borderColor = Color(0xFFE1E6DF);

enum _ActivityTab { receipts, shipments }

// [FE - Component Rendering] Screen ini memisahkan audit barang masuk dari
// aktivitas pengiriman keluar agar peran distributor tidak tercampur.
class DistributorHistoryScreen extends StatefulWidget {
  const DistributorHistoryScreen({super.key});

  @override
  State<DistributorHistoryScreen> createState() =>
      _DistributorHistoryScreenState();
}

class _DistributorHistoryScreenState extends State<DistributorHistoryScreen> {
  final _repo = DistributorRepository.instance;
  _ActivityTab _activeTab = _ActivityTab.receipts;

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

  // [FE - State Management] Listener ini menjaga tab audit mengikuti receipt
  // dan perubahan status manifest secara reaktif.
  void _onRepoChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _openDetail(String shipmentCode) async {
    await DistributorRoutes.push(
      context,
      DistributorShipmentDetailScreen(shipmentCode: shipmentCode),
    );
  }

  @override
  Widget build(BuildContext context) {
    final completedInbound = _repo.historyShipments;
    final receiptsByCode = {
      for (final receipt in _repo.receiptHistory) receipt.shipmentCode: receipt,
    };

    return Scaffold(
      backgroundColor: _pageBackground,
      body: SafeArea(
        child: Column(
          children: [
            const ColoredBox(
              color: AppColors.white,
              child: AppTopBar(title: 'Riwayat Aktivitas'),
            ),
            _ActivityTabBar(
              activeTab: _activeTab,
              receiptCount: completedInbound.length,
              shipmentCount: 0,
              onChanged: (tab) => setState(() => _activeTab = tab),
            ),
            Expanded(
              child: _activeTab == _ActivityTab.receipts
                  ? _ReceiptList(
                      shipments: completedInbound,
                      receiptsByCode: receiptsByCode,
                      onDetail: _openDetail,
                    )
                  : const _OutboundEmptyState(),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivityTabBar extends StatelessWidget {
  const _ActivityTabBar({
    required this.activeTab,
    required this.receiptCount,
    required this.shipmentCount,
    required this.onChanged,
  });

  final _ActivityTab activeTab;
  final int receiptCount;
  final int shipmentCount;
  final ValueChanged<_ActivityTab> onChanged;

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
                selected: activeTab == _ActivityTab.receipts,
                onTap: () => onChanged(_ActivityTab.receipts),
              ),
            ),
            Expanded(
              child: _TabButton(
                label: 'Pengiriman',
                count: shipmentCount,
                selected: activeTab == _ActivityTab.shipments,
                onTap: () => onChanged(_ActivityTab.shipments),
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

class _ReceiptList extends StatelessWidget {
  const _ReceiptList({
    required this.shipments,
    required this.receiptsByCode,
    required this.onDetail,
  });

  final List<CollectorShipmentBatch> shipments;
  final Map<String, DistributorReceipt> receiptsByCode;
  final ValueChanged<String> onDetail;

  @override
  Widget build(BuildContext context) {
    if (shipments.isEmpty) {
      return const _EmptyState(
        icon: Icons.inventory_2_outlined,
        title: 'Belum ada riwayat penerimaan',
        message:
            'Pengiriman pengepul yang selesai diverifikasi akan tercatat di sini.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      itemCount: shipments.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final shipment = shipments[index];
        return _ReceiptHistoryCard(
          shipment: shipment,
          receipt: receiptsByCode[shipment.code],
          onTap: () => onDetail(shipment.code),
        );
      },
    );
  }
}

// [FE - Component Rendering] Kartu penerimaan membandingkan manifest dengan
// receipt aktual; shipment seed lama tetap ditandai sebagai data legacy.
class _ReceiptHistoryCard extends StatelessWidget {
  const _ReceiptHistoryCard({
    required this.shipment,
    required this.receipt,
    required this.onTap,
  });

  final CollectorShipmentBatch shipment;
  final DistributorReceipt? receipt;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final actualReceipt = receipt;
    final receivedAt =
        actualReceipt?.receivedAt ??
        shipment.completedAt ??
        shipment.packagedAt;
    final hasDifference = actualReceipt?.hasDiscrepancy == true;
    final statusColor = hasDifference
        ? const Color(0xFF9A6700)
        : AppColors.primary;

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
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      hasDifference
                          ? Icons.warning_amber_rounded
                          : Icons.fact_check_outlined,
                      size: 21,
                      color: statusColor,
                    ),
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
                          _formatDateTime(receivedAt),
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.placeholder,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _StatusBadge(
                    label: actualReceipt == null
                        ? 'Data lama'
                        : hasDifference
                        ? 'Ada selisih'
                        : 'Sesuai',
                    color: actualReceipt == null
                        ? const Color(0xFF1D6FA4)
                        : statusColor,
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: _borderColor),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 13),
              child: Column(
                children: [
                  _InfoRow(
                    label: 'Manifest',
                    value:
                        '${_formatWeight(shipment.totalWeightKg)} · ${shipment.totalFruitCount} butir',
                  ),
                  _InfoRow(
                    label: 'Diterima',
                    value: actualReceipt == null
                        ? 'Detail aktual belum tersedia'
                        : '${_formatWeight(actualReceipt.receivedWeightKg)} · ${actualReceipt.receivedFruitCount} butir',
                  ),
                  _InfoRow(
                    label: 'Kondisi',
                    value: actualReceipt?.condition.label ?? '-',
                  ),
                  _InfoRow(
                    label: 'Lokasi',
                    value: actualReceipt?.destinationLocation ?? '-',
                    isLast: actualReceipt?.temperatureCelsius == null,
                  ),
                  if (actualReceipt?.temperatureCelsius != null)
                    _InfoRow(
                      label: 'Suhu',
                      value:
                          '${_formatTemperature(actualReceipt!.temperatureCelsius!)} C',
                      isLast: true,
                    ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(14, 9, 10, 9),
              decoration: const BoxDecoration(
                color: Color(0xFFF8F9F7),
                border: Border(top: BorderSide(color: _borderColor)),
              ),
              child: const Row(
                children: [
                  Expanded(
                    child: Text(
                      'Lihat detail dan provenance',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppColors.placeholder,
                      ),
                    ),
                  ),
                  Icon(
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

class _OutboundEmptyState extends StatelessWidget {
  const _OutboundEmptyState();

  @override
  Widget build(BuildContext context) {
    return const _EmptyState(
      icon: Icons.local_shipping_outlined,
      title: 'Belum ada pengiriman keluar',
      message:
          'Batch distributor yang dikirim ke UMKM akan tercatat setelah fitur stok dan batch DST dibuat.',
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
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

class _InfoRow extends StatelessWidget {
  const _InfoRow({
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
            width: 78,
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

String _formatWeight(double value) {
  final text = value % 1 == 0
      ? value.toStringAsFixed(0)
      : value.toStringAsFixed(2);
  return '$text kg';
}

String _formatTemperature(double value) {
  return value % 1 == 0 ? value.toStringAsFixed(0) : value.toStringAsFixed(1);
}

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
