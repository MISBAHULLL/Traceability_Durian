import 'package:flutter/material.dart';

import '../../core/network/backend_api_client.dart';
import '../../core/theme/app_colors.dart';
import '../../features/distributor/models/distributor_horizontal_sale.dart';

class SalesInboxScreen extends StatefulWidget {
  const SalesInboxScreen({super.key});

  @override
  State<SalesInboxScreen> createState() => _SalesInboxScreenState();
}

class _SalesInboxScreenState extends State<SalesInboxScreen> {
  List<DistributorHorizontalSale> _sales = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response = await BackendApiClient.instance.get('/sales/incoming');
      final data = response.data;
      if (data is! List) {
        throw const FormatException('Data penjualan masuk tidak valid.');
      }
      if (!mounted) return;
      setState(() {
        _sales = data
            .whereType<Map>()
            .map(
              (item) => DistributorHorizontalSale.fromJson(
                Map<String, dynamic>.from(item),
              ),
            )
            .toList();
        _loading = false;
      });
    } on BackendApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.message;
        _loading = false;
      });
    } on FormatException catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.message;
        _loading = false;
      });
    }
  }

  Future<void> _receive(DistributorHorizontalSale sale) async {
    final result = await showDialog<_ReceiveInput>(
      context: context,
      builder: (context) => _ReceiveDialog(sale: sale),
    );
    if (result == null) return;

    try {
      await BackendApiClient.instance.post(
        '/sales/${Uri.encodeComponent(sale.id)}/receive',
        body: {
          'received_weight_kg': result.weight,
          'received_fruit_count': result.fruitCount,
          'condition': result.condition,
          'discrepancy_note': result.discrepancyNote,
        },
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Penerimaan T2 berhasil disimpan.')),
      );
      await _load();
    } on BackendApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message),
          backgroundColor: const Color(0xFFDC2626),
        ),
      );
    }
  }

  Future<void> _reject(DistributorHorizontalSale sale) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => const _RejectDialog(),
    );
    if (reason == null || reason.trim().isEmpty) return;

    try {
      await BackendApiClient.instance.post(
        '/sales/${Uri.encodeComponent(sale.id)}/reject',
        body: {'reason': reason.trim()},
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Penjualan ditolak. Batch kembali ke stok penjual.'),
        ),
      );
      await _load();
    } on BackendApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message),
          backgroundColor: const Color(0xFFDC2626),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F3),
      appBar: AppBar(
        title: const Text('Penjualan Masuk'),
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.black,
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? ListView(
                children: [
                  SizedBox(height: 240),
                  Center(child: CircularProgressIndicator()),
                ],
              )
            : _error != null
            ? ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  const SizedBox(height: 120),
                  const Icon(Icons.cloud_off_outlined, size: 42),
                  const SizedBox(height: 12),
                  Text(_error!, textAlign: TextAlign.center),
                  TextButton(onPressed: _load, child: const Text('Coba lagi')),
                ],
              )
            : _sales.isEmpty
            ? ListView(
                padding: const EdgeInsets.all(24),
                children: const [
                  SizedBox(height: 140),
                  Icon(
                    Icons.inventory_2_outlined,
                    size: 48,
                    color: AppColors.placeholder,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Belum ada penjualan yang menunggu konfirmasi.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.subtitle),
                  ),
                ],
              )
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: _sales.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) => _IncomingSaleCard(
                  sale: _sales[index],
                  onReceive: () => _receive(_sales[index]),
                  onReject: () => _reject(_sales[index]),
                ),
              ),
      ),
    );
  }
}

class _IncomingSaleCard extends StatelessWidget {
  const _IncomingSaleCard({
    required this.sale,
    required this.onReceive,
    required this.onReject,
  });

  final DistributorHorizontalSale sale;
  final VoidCallback onReceive;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              sale.id,
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              sale.itemCode,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text('Dari: ${sale.sellerName}'),
            Text(
              'Manifest ${sale.expectedWeightKg} kg • ${sale.expectedFruitCount} butir',
            ),
            if (sale.qualityNote?.isNotEmpty == true)
              Text('Catatan: ${sale.qualityNote}'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onReject,
                    child: const Text('Tolak'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: onReceive,
                    child: const Text('Validasi T2'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ReceiveInput {
  const _ReceiveInput({
    required this.weight,
    required this.fruitCount,
    required this.condition,
    this.discrepancyNote,
  });

  final double weight;
  final int fruitCount;
  final String condition;
  final String? discrepancyNote;
}

class _ReceiveDialog extends StatefulWidget {
  const _ReceiveDialog({required this.sale});

  final DistributorHorizontalSale sale;

  @override
  State<_ReceiveDialog> createState() => _ReceiveDialogState();
}

class _ReceiveDialogState extends State<_ReceiveDialog> {
  late final _weightCtrl = TextEditingController(
    text: widget.sale.expectedWeightKg.toString(),
  );
  late final _fruitCtrl = TextEditingController(
    text: widget.sale.expectedFruitCount.toString(),
  );
  final _noteCtrl = TextEditingController();
  String _condition = 'good';
  String? _error;

  @override
  void dispose() {
    _weightCtrl.dispose();
    _fruitCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final weight = double.tryParse(
      _weightCtrl.text.trim().replaceAll(',', '.'),
    );
    final fruit = int.tryParse(_fruitCtrl.text.trim());
    if (weight == null || weight < 0 || fruit == null || fruit < 0) {
      setState(() => _error = 'Masukkan berat dan jumlah buah yang valid.');
      return;
    }
    final discrepancy =
        (weight - widget.sale.expectedWeightKg).abs() > 0.01 ||
        fruit != widget.sale.expectedFruitCount;
    if (discrepancy && _noteCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Catatan selisih wajib diisi.');
      return;
    }
    Navigator.pop(
      context,
      _ReceiveInput(
        weight: weight,
        fruitCount: fruit,
        condition: _condition,
        discrepancyNote: _noteCtrl.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Validasi T2 Penjualan'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _weightCtrl,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Berat diterima (kg)',
              ),
            ),
            TextField(
              controller: _fruitCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Jumlah buah diterima',
              ),
            ),
            DropdownButtonFormField<String>(
              initialValue: _condition,
              decoration: const InputDecoration(labelText: 'Kondisi durian'),
              items: const [
                DropdownMenuItem(value: 'good', child: Text('Baik')),
                DropdownMenuItem(
                  value: 'minorDamage',
                  child: Text('Kerusakan ringan'),
                ),
                DropdownMenuItem(value: 'damaged', child: Text('Rusak')),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _condition = value);
              },
            ),
            TextField(
              controller: _noteCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Catatan selisih (jika berbeda)',
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  _error!,
                  style: const TextStyle(color: Color(0xFFDC2626)),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Simpan T2')),
      ],
    );
  }
}

class _RejectDialog extends StatefulWidget {
  const _RejectDialog();

  @override
  State<_RejectDialog> createState() => _RejectDialogState();
}

class _RejectDialogState extends State<_RejectDialog> {
  final _reasonCtrl = TextEditingController();

  @override
  void dispose() {
    _reasonCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Tolak penjualan?'),
      content: TextField(
        controller: _reasonCtrl,
        autofocus: true,
        maxLines: 3,
        decoration: const InputDecoration(
          labelText: 'Alasan penolakan',
          border: OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFFDC2626),
          ),
          onPressed: () {
            if (_reasonCtrl.text.trim().isEmpty) return;
            Navigator.pop(context, _reasonCtrl.text.trim());
          },
          child: const Text('Tolak'),
        ),
      ],
    );
  }
}
