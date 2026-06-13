import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_top_bar.dart';
import '../data/umkm_repository.dart';
import '../models/umkm_order.dart';
import 'umkm_order_detail_screen.dart';

class UmkmOrderListScreen extends StatefulWidget {
  const UmkmOrderListScreen({super.key});

  @override
  State<UmkmOrderListScreen> createState() => _UmkmOrderListScreenState();
}

class _UmkmOrderListScreenState extends State<UmkmOrderListScreen> {
  UmkmOrderStatus _activeStatus = UmkmOrderStatus.diproses;

  UmkmRepository get _repo => UmkmRepository.instance;

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

  @override
  Widget build(BuildContext context) {
    final orders = _repo.orders
        .where((order) => order.status == _activeStatus)
        .toList();

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            const AppTopBar(title: 'Daftar Pesanan'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
                children: [
                  const Text(
                    'Pesanan Masuk',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.black,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Pilih tab untuk melihat pesanan yang sedang diproses atau yang sudah selesai.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.placeholder,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _StatusTabs(
                    active: _activeStatus,
                    onChanged: (value) => setState(() => _activeStatus = value),
                  ),
                  const SizedBox(height: 16),
                  if (orders.isEmpty)
                    const _EmptyState()
                  else
                    ...orders.map(
                      (order) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => UmkmOrderDetailScreen(order: order),
                              ),
                            );
                          },
                          child: _OrderCard(order: order),
                        ),
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

class _StatusTabs extends StatelessWidget {
  const _StatusTabs({
    required this.active,
    required this.onChanged,
  });

  final UmkmOrderStatus active;
  final ValueChanged<UmkmOrderStatus> onChanged;

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
          Expanded(
            child: _TabButton(
              label: 'Diproses',
              isActive: active == UmkmOrderStatus.diproses,
              onTap: () => onChanged(UmkmOrderStatus.diproses),
            ),
          ),
          Expanded(
            child: _TabButton(
              label: 'Selesai',
              isActive: active == UmkmOrderStatus.selesai,
              onTap: () => onChanged(UmkmOrderStatus.selesai),
            ),
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
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: isActive ? AppColors.white : AppColors.subtitle,
          ),
        ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order});

  final UmkmOrder order;

  @override
  Widget build(BuildContext context) {
    return Container(
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
              _StatusBadge(status: order.status),
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
                style: const TextStyle(fontSize: 12, color: AppColors.placeholder),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final UmkmOrderStatus status;

  @override
  Widget build(BuildContext context) {
    final isProcessing = status == UmkmOrderStatus.diproses;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isProcessing
            ? AppColors.primary.withValues(alpha: 0.12)
            : AppColors.primaryContainer.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: isProcessing ? AppColors.primary : AppColors.primaryContainer,
        ),
      ),
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
        children: const [
          Icon(Icons.receipt_long_outlined, size: 56, color: Color(0xFFCBD5E1)),
          SizedBox(height: 12),
          Text(
            'Belum ada pesanan',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.subtitle,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Pesanan untuk tab ini belum tersedia.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: AppColors.placeholder),
          ),
        ],
      ),
    );
  }
}
