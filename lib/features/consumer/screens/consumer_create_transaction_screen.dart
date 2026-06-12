import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_top_bar.dart';
import '../../../shared/widgets/primary_pill_button.dart';
import '../consumer_routes.dart';
import '../data/consumer_repository.dart';
import '../models/consumer_product.dart';
import 'consumer_transaction_qr_screen.dart';

class ConsumerCreateTransactionScreen extends StatefulWidget {
  const ConsumerCreateTransactionScreen({
    super.key,
    required this.product,
  });

  final ConsumerProduct product;

  @override
  State<ConsumerCreateTransactionScreen> createState() => _ConsumerCreateTransactionScreenState();
}

class _ConsumerCreateTransactionScreenState extends State<ConsumerCreateTransactionScreen> {
  final _addressController = TextEditingController(text: 'Desa Pakis, Kec. Panti, Kab. Jember');
  final _coordinateController = TextEditingController(text: '-8.2285, 113.6204');
  final _paymentMethods = ['Transfer Bank', 'Cash on Delivery', 'Virtual Account'];
  String _paymentMethod = 'Transfer Bank';
  int _quantity = 1;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _addressController.dispose();
    _coordinateController.dispose();
    super.dispose();
  }

  void _incrementQuantity() {
    setState(() => _quantity += 1);
  }

  void _decrementQuantity() {
    if (_quantity > 1) {
      setState(() => _quantity -= 1);
    }
  }

  Future<void> _submit() async {
    setState(() => _isSubmitting = true);
    final repo = ConsumerRepository.instance;
    final transaction = repo.addTransaction(
      widget.product,
      quantity: _quantity,
      buyerAddress: _addressController.text.trim(),
      buyerCoordinates: _coordinateController.text.trim(),
      paymentMethod: _paymentMethod,
      note: 'Transaksi dibuat dari detail produk.',
    );
    await ConsumerRoutes.push(
      context,
      ConsumerTransactionQrScreen(transaction: transaction),
    );
    setState(() => _isSubmitting = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            const AppTopBar(title: 'Buat Transaksi'),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionCard(
                      title: 'Detail Pembelian',
                      children: [
                        _InfoRow(label: 'Produk', value: widget.product.name),
                        _InfoRow(label: 'Harga', value: widget.product.priceLabel),
                        _InfoRow(label: 'UMKM', value: widget.product.umkmName),
                        _InfoRow(label: 'Stok', value: widget.product.stockLabel),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _SectionCard(
                      title: 'Jumlah Produk',
                      children: [
                        Row(
                          children: [
                            _QuantityButton(icon: Icons.remove_rounded, onTap: _decrementQuantity),
                            Expanded(
                              child: Center(
                                child: Text(
                                  '$_quantity',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.black,
                                  ),
                                ),
                              ),
                            ),
                            _QuantityButton(icon: Icons.add_rounded, onTap: _incrementQuantity),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _SectionCard(
                      title: 'Alamat Pengiriman',
                      children: [
                        _TextFieldRow(
                          controller: _addressController,
                          hintText: 'Masukkan alamat lengkap',
                        ),
                        const SizedBox(height: 10),
                        _TextFieldRow(
                          controller: _coordinateController,
                          hintText: 'Koordinat (lat, long)',
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _SectionCard(
                      title: 'Pembayaran',
                      children: [
                        DropdownButtonFormField<String>(
                          value: _paymentMethod,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: AppColors.surface,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                            ),
                          ),
                          items: _paymentMethods
                              .map((payment) => DropdownMenuItem(
                                    value: payment,
                                    child: Text(payment),
                                  ))
                              .toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _paymentMethod = value);
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    PrimaryPillButton(
                      label: 'BUAT TRANSAKSI',
                      onPressed: _isSubmitting ? null : _submit,
                      isLoading: _isSubmitting,
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

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppColors.black,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.placeholder,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
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

class _QuantityButton extends StatelessWidget {
  const _QuantityButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Icon(icon, color: AppColors.black),
      ),
    );
  }
}

class _TextFieldRow extends StatelessWidget {
  const _TextFieldRow({
    required this.controller,
    required this.hintText,
  });

  final TextEditingController controller;
  final String hintText;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      style: const TextStyle(fontSize: 13, color: AppColors.black),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(fontSize: 13, color: AppColors.placeholder),
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
      ),
    );
  }
}
