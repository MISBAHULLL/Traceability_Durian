import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_top_bar.dart';
import '../data/farmer_repository.dart';
import '../farmer_routes.dart';
import '../models/farmer_notification.dart';
import '../models/harvest_batch.dart';
import 'batch_detail_screen.dart';
import 'batch_trace_screen.dart';

const _pageBackground = Color(0xFFF4F6F3);
const _borderColor = Color(0xFFE1E6DF);

enum _NotificationFilter { semua, perluDicek, update }

extension _NotificationFilterX on _NotificationFilter {
  String get label {
    switch (this) {
      case _NotificationFilter.semua:
        return 'Semua';
      case _NotificationFilter.perluDicek:
        return 'Perlu Dicek';
      case _NotificationFilter.update:
        return 'Update';
    }
  }
}

// [FE - Component Rendering] Screen ini menjadi inbox ringan untuk update
// batch petani, termasuk serah terima yang butuh dicek.
class FarmerNotificationsScreen extends StatefulWidget {
  const FarmerNotificationsScreen({super.key});

  @override
  State<FarmerNotificationsScreen> createState() =>
      _FarmerNotificationsScreenState();
}

class _FarmerNotificationsScreenState extends State<FarmerNotificationsScreen> {
  final _repo = FarmerRepository.instance;
  _NotificationFilter _activeFilter = _NotificationFilter.semua;

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

  // [FE - State Management] Listener ini menjaga pusat notifikasi sinkron
  // dengan perubahan batch dari verifikasi, penolakan, atau distribusi.
  void _onRepoChanged() {
    if (mounted) setState(() {});
  }

  List<FarmerNotification> get _filteredNotifications {
    final items = _repo.notifications;

    switch (_activeFilter) {
      case _NotificationFilter.semua:
        return items;
      case _NotificationFilter.perluDicek:
        return items.where((item) => item.requiresAttention).toList();
      case _NotificationFilter.update:
        return items
            .where((item) => item.type == FarmerNotificationType.statusUpdate)
            .toList();
    }
  }

  // [FE - Event Handler] Aksi detail membawa user ke konteks batch penuh
  // ketika notifikasi membutuhkan pemeriksaan data panen.
  Future<void> _openDetail(String batchCode) async {
    await FarmerRoutes.push(context, BatchDetailScreen(batchCode: batchCode));
  }

  // [FE - Event Handler] Aksi trace membuka visual perjalanan batch dari
  // notifikasi agar keterlacakan bisa dicek langsung.
  Future<void> _openTrace(String batchCode) async {
    await FarmerRoutes.push(context, BatchTraceScreen(batchCode: batchCode));
  }

  @override
  Widget build(BuildContext context) {
    final notifications = _filteredNotifications;

    return Scaffold(
      // Warna scaffold mengisi area status bar di luar SafeArea sehingga
      // header terlihat sebagai satu bidang sampai tepi atas layar.
      backgroundColor: AppColors.homeHeaderSurface,
      body: SafeArea(
        child: Column(
          children: [
            const ColoredBox(
              color: AppColors.homeHeaderSurface,
              child: AppTopBar(title: 'Notifikasi'),
            ),
            Expanded(
              child: ColoredBox(
                color: _pageBackground,
                child: Column(
                  children: [
                    _FilterBar(
                      activeFilter: _activeFilter,
                      onChanged: (filter) =>
                          setState(() => _activeFilter = filter),
                    ),
                    Expanded(
                      child: notifications.isEmpty
                          ? const _EmptyNotifications()
                          : ListView.separated(
                              physics: const BouncingScrollPhysics(),
                              padding: const EdgeInsets.fromLTRB(
                                16,
                                16,
                                16,
                                28,
                              ),
                              itemCount: notifications.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(height: 10),
                              itemBuilder: (context, index) {
                                final notification = notifications[index];
                                return _NotificationCard(
                                  notification: notification,
                                  onOpenDetail: () =>
                                      _openDetail(notification.batchCode),
                                  onOpenTrace: () =>
                                      _openTrace(notification.batchCode),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({required this.activeFilter, required this.onChanged});

  final _NotificationFilter activeFilter;
  final ValueChanged<_NotificationFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.white,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
      child: Container(
        height: 42,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: _pageBackground,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _borderColor),
        ),
        child: Row(
          children: _NotificationFilter.values.map((filter) {
            final selected = filter == activeFilter;
            return Expanded(
              child: InkWell(
                onTap: () => onChanged(filter),
                borderRadius: BorderRadius.circular(8),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.primaryContainer
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    filter.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: selected ? AppColors.white : AppColors.placeholder,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({
    required this.notification,
    required this.onOpenDetail,
    required this.onOpenTrace,
  });

  final FarmerNotification notification;
  final VoidCallback onOpenDetail;
  final VoidCallback onOpenTrace;

  @override
  Widget build(BuildContext context) {
    final color = _notificationColor(notification);

    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onOpenDetail,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: notification.requiresAttention
                  ? color.withValues(alpha: 0.36)
                  : _borderColor,
            ),
          ),
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  _notificationIcon(notification),
                  color: color,
                  size: 20,
                ),
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
                            notification.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: AppColors.black,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _NotificationBadge(notification: notification),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      notification.message,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        height: 1.38,
                        color: AppColors.subtitle,
                      ),
                    ),
                    const SizedBox(height: 9),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${notification.batchCode} - ${_formatDateTime(notification.createdAt)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.placeholder,
                            ),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: onOpenTrace,
                          icon: const Icon(Icons.route_rounded, size: 15),
                          label: const Text('Trace'),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            minimumSize: const Size(0, 30),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            textStyle: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: AppColors.placeholder,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotificationBadge extends StatelessWidget {
  const _NotificationBadge({required this.notification});

  final FarmerNotification notification;

  @override
  Widget build(BuildContext context) {
    final color = _notificationColor(notification);
    final label = _notificationBadgeLabel(notification);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w900,
          color: color,
        ),
      ),
    );
  }
}

String _notificationBadgeLabel(FarmerNotification notification) {
  switch (notification.type) {
    case FarmerNotificationType.transactionRequest:
      return 'Scan QR';
    case FarmerNotificationType.statusUpdate:
      return 'Update';
    case FarmerNotificationType.dispute:
      return 'Masalah';
  }
}

class _EmptyNotifications extends StatelessWidget {
  const _EmptyNotifications();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.notifications_none_rounded,
              size: 52,
              color: AppColors.placeholder,
            ),
            SizedBox(height: 14),
            Text(
              'Belum ada notifikasi',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: AppColors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Color _notificationColor(FarmerNotification notification) {
  switch (notification.type) {
    case FarmerNotificationType.transactionRequest:
      return const Color(0xFFB45309);
    case FarmerNotificationType.statusUpdate:
      return notification.batchStatus.color;
    case FarmerNotificationType.dispute:
      return const Color(0xFFD64545);
  }
}

IconData _notificationIcon(FarmerNotification notification) {
  switch (notification.type) {
    case FarmerNotificationType.transactionRequest:
      return Icons.qr_code_scanner_rounded;
    case FarmerNotificationType.statusUpdate:
      return Icons.route_rounded;
    case FarmerNotificationType.dispute:
      return Icons.report_problem_outlined;
  }
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
