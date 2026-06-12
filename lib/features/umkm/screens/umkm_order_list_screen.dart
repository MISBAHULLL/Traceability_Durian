import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_top_bar.dart';
import '../data/umkm_repository.dart';
import '../models/umkm_order.dart';
import 'umkm_order_detail_screen.dart';

class UmkmOrderListScreen extends StatelessWidget {
  const UmkmOrderListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final orders = UmkmRepository.instance.orders;

    return Scaffold(
      appBar: const PreferredSize(
        preferredSize: Size.fromHeight(72),
        child: AppTopBar(title: 'Daftar Pesanan'),
      ),
      backgroundColor: AppColors.white,
      body: SafeArea(
        bottom: false,
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          itemCount: orders.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final order = orders[index];
            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => UmkmOrderDetailScreen(order: order)),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
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
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.black),
                          ),
                        ),
                        Text(
                          order.status.label,
                          style: const TextStyle(fontSize: 12, color: AppColors.primary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('Pembeli: ${order.buyerName}', style: const TextStyle(fontSize: 12, color: AppColors.subtitle)),
                    const SizedBox(height: 8),
                    Text(order.totalLabel, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.primary)),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
