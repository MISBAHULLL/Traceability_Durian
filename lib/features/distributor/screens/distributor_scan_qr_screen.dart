import 'package:flutter/material.dart';

import 'distributor_stock_receipt_screen.dart';

// [FE - Component Rendering] Backward-compatible route untuk entry lama
// "Scan QR"; flow aktual distributor sekarang adalah scan stok masuk PGL/DRN.
class DistributorScanQrScreen extends StatelessWidget {
  const DistributorScanQrScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const DistributorStockReceiptScreen();
  }
}
