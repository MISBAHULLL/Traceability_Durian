import 'package:flutter/material.dart';

import '../../../core/network/backend_api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_top_bar.dart';
import '../../../shared/widgets/qr_preview.dart';
import '../data/umkm_repository.dart';
import '../models/umkm_production_record.dart';
import '../models/umkm_product.dart';

class UmkmProductDetailScreen extends StatefulWidget {
  const UmkmProductDetailScreen({super.key, required this.product});

  final UmkmProduct product;

  @override
  State<UmkmProductDetailScreen> createState() =>
      _UmkmProductDetailScreenState();
}

class _UmkmProductDetailScreenState extends State<UmkmProductDetailScreen> {
  bool _isDeleting = false;
  final Map<String, Future<Map<String, dynamic>>> _sourceTraceRequests = {};

  Future<Map<String, dynamic>> _loadSourceTrace(String traceCode) async {
    final response = await BackendApiClient.instance.get(
      '/trace/${Uri.encodeComponent(traceCode)}',
      authenticated: false,
    );
    final payload = backendJson(response.data);
    if (payload is! Map<String, dynamic>) {
      throw const FormatException('Respons trace batch tidak valid.');
    }
    return payload;
  }

  Future<void> _deleteProduct() async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus produk?'),
        content: Text(
          '“${widget.product.name}” akan dihapus permanen dari katalog. '
          'Pesanan yang terhubung ke produk ini juga akan dihapus.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (shouldDelete != true) return;
    setState(() => _isDeleting = true);
    try {
      await UmkmRepository.instance.deleteProduct(widget.product.code);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Produk berhasil dihapus.')));
      Navigator.pop(context);
    } on BackendApiException catch (error) {
      if (!mounted) return;
      setState(() => _isDeleting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menghapus produk: ${error.message}')),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _isDeleting = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal menghapus produk: $error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final production = UmkmRepository.instance.productionRecordForProduct(
      product.code,
    );
    final imagePath = product.imagePath ?? 'assets/images/durian.png';

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            AppTopBar(
              title: 'Detail Produk',
              actions: [
                IconButton(
                  tooltip: 'Hapus produk',
                  onPressed: _isDeleting ? null : _deleteProduct,
                  icon: _isDeleting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.delete_outline_rounded),
                ),
              ],
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _HeaderCard(product: product),
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(
                        imagePath,
                        width: double.infinity,
                        height: 210,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => _FallbackImage(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _SectionCard(
                      title: 'Informasi Produk',
                      children: [
                        _InfoRow(label: 'Nama Produk', value: product.name),
                        _InfoRow(label: 'Kode Produk', value: product.code),
                        _InfoRow(label: 'Kategori', value: product.category),
                        _InfoRow(label: 'Status', value: product.status.label),
                        _InfoRow(label: 'Harga', value: product.priceLabel),
                        _InfoRow(label: 'Stok', value: product.stockLabel),
                        _InfoRow(
                          label: 'Bahan Baku',
                          value: product.sourceMaterialLabel,
                        ),
                        _InfoRow(
                          label: 'Deskripsi',
                          value: product.description,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _SectionCard(
                      title: 'QR Produk',
                      children: [
                        Center(
                          child: QrPreview(
                            data: product.qrCodeData.isEmpty
                                ? product.code
                                : product.qrCodeData,
                            size: 210,
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Pindai QR untuk mengenali produk ini.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.subtitle,
                          ),
                        ),
                      ],
                    ),
                    if (production != null) ...[
                      const SizedBox(height: 16),
                      _ProductionRecordSection(production: production),
                    ],
                    if (product.sourceMaterials.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _SectionCard(
                        title: 'Asal Bahan Baku',
                        children: product.sourceMaterials
                            .map(
                              (material) => _SourceTraceCard(
                                material: material,
                                traceRequest: _sourceTraceRequests.putIfAbsent(
                                  material.traceCode,
                                  () => _loadSourceTrace(material.traceCode),
                                ),
                                onOpenTrace: (trace) {
                                  Navigator.of(context).push(
                                    MaterialPageRoute<void>(
                                      builder: (_) => _DatabaseBatchTraceScreen(
                                        traceCode: material.traceCode,
                                        trace: trace,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            )
                            .toList(),
                      ),
                    ],
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

class _ProductionRecordSection extends StatelessWidget {
  const _ProductionRecordSection({required this.production});

  final UmkmProductionRecord production;

  String _formatDate(DateTime date) {
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
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Catatan Produksi',
      children: [
        _InfoRow(label: 'Nomor Lot', value: production.lotNumber),
        _InfoRow(label: 'Metode', value: production.processMethod),
        _InfoRow(label: 'Produksi', value: _formatDate(production.producedAt)),
        if (production.expiryDate != null)
          _InfoRow(
            label: 'Kedaluwarsa',
            value: _formatDate(production.expiryDate!),
          ),
        _InfoRow(label: 'Hasil', value: production.outputLabel),
        _InfoRow(label: 'Input', value: production.inputWeightLabel),
        _InfoRow(label: 'Loss/Waste', value: production.lossWeightLabel),
        _InfoRow(label: 'Yield', value: production.yieldWeightLabel),
        if (production.note != null && production.note!.trim().isNotEmpty)
          _InfoRow(label: 'Catatan', value: production.note!.trim()),
      ],
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.product});

  final UmkmProduct product;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  product.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.black,
                  ),
                ),
              ),
              _StatusBadge(status: product.status.label),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            product.code,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.placeholder,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 10),
          _CategoryBadge(label: product.category),
        ],
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
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
  const _InfoRow({required this.label, required this.value});

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
                fontWeight: FontWeight.w600,
                color: AppColors.placeholder,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.black,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SourceTraceCard extends StatelessWidget {
  const _SourceTraceCard({
    required this.material,
    required this.traceRequest,
    required this.onOpenTrace,
  });

  final UmkmProductMaterial material;
  final Future<Map<String, dynamic>> traceRequest;
  final ValueChanged<Map<String, dynamic>> onOpenTrace;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            material.traceCode,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            material.quantityLabel,
            style: const TextStyle(fontSize: 11, color: AppColors.placeholder),
          ),
          const SizedBox(height: 8),
          FutureBuilder<Map<String, dynamic>>(
            future: traceRequest,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Text(
                  'Asal batch gagal dimuat: ${snapshot.error}',
                  style: const TextStyle(fontSize: 12, color: Colors.red),
                );
              }
              if (snapshot.connectionState != ConnectionState.done) {
                return const LinearProgressIndicator(minHeight: 2);
              }

              final rawBatch = backendJson(snapshot.data!['batch']);
              final batch = rawBatch is Map<String, dynamic>
                  ? rawBatch
                  : <String, dynamic>{};
              final farmName =
                  (batch['farm_name_snapshot'] ??
                          batch['farmName'] ??
                          material.supplierName)
                      .toString()
                      .trim();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Asal durian: ${farmName.isEmpty ? 'Tidak diketahui' : farmName}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.black,
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () => onOpenTrace(snapshot.data!),
                      icon: const Icon(Icons.account_tree_outlined, size: 16),
                      label: const Text('Lihat trace kode ini'),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _DatabaseBatchTraceScreen extends StatelessWidget {
  const _DatabaseBatchTraceScreen({
    required this.traceCode,
    required this.trace,
  });

  final String traceCode;
  final Map<String, dynamic> trace;

  @override
  Widget build(BuildContext context) {
    final rawBatch = backendJson(trace['batch']);
    final batch = rawBatch is Map<String, dynamic>
        ? rawBatch
        : <String, dynamic>{};
    final rawEvents = trace['events'];
    final events = rawEvents is List
        ? rawEvents
              .whereType<Map>()
              .map((event) => Map<String, dynamic>.from(event))
              .toList()
        : const <Map<String, dynamic>>[];
    final farmName =
        (batch['farm_name_snapshot'] ?? batch['farmName'] ?? 'Tidak diketahui')
            .toString();
    final variety = (batch['variety'] ?? '').toString().trim();

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            AppTopBar(title: 'Trace $traceCode'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _SectionCard(
                    title: 'Asal Durian',
                    children: [
                      _InfoRow(label: 'Kode batch', value: traceCode),
                      _InfoRow(label: 'Asal panen', value: farmName),
                      if (variety.isNotEmpty)
                        _InfoRow(label: 'Varietas', value: variety),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _SectionCard(
                    title: 'Riwayat Trace',
                    children: events.isEmpty
                        ? const [
                            Text(
                              'Belum ada riwayat untuk kode batch ini.',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.subtitle,
                              ),
                            ),
                          ]
                        : events
                              .map((event) => _DatabaseTraceEvent(event: event))
                              .toList(),
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

class _DatabaseTraceEvent extends StatelessWidget {
  const _DatabaseTraceEvent({required this.event});

  final Map<String, dynamic> event;

  @override
  Widget build(BuildContext context) {
    final title = (event['title'] ?? event['status'] ?? 'Perubahan batch')
        .toString();
    final actor = (event['actor_label'] ?? '').toString().trim();
    final rawDate = (event['event_at'] ?? '').toString();
    final parsedDate = DateTime.tryParse(rawDate)?.toLocal();
    final dateLabel = parsedDate == null
        ? rawDate
        : '${parsedDate.year.toString().padLeft(4, '0')}-'
              '${parsedDate.month.toString().padLeft(2, '0')}-'
              '${parsedDate.day.toString().padLeft(2, '0')} '
              '${parsedDate.hour.toString().padLeft(2, '0')}:'
              '${parsedDate.minute.toString().padLeft(2, '0')}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 3),
            child: Icon(Icons.circle, size: 8, color: AppColors.primary),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.black,
                  ),
                ),
                if (dateLabel.isNotEmpty || actor.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Text(
                      [
                        dateLabel,
                        actor,
                      ].where((value) => value.isNotEmpty).join(' · '),
                      style: const TextStyle(
                        fontSize: 11,
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

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
        ),
      ),
    );
  }
}

class _CategoryBadge extends StatelessWidget {
  const _CategoryBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: AppColors.subtitle,
        ),
      ),
    );
  }
}

class _FallbackImage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 210,
      color: AppColors.surface,
      alignment: Alignment.center,
      child: const Icon(
        Icons.image_outlined,
        color: AppColors.placeholder,
        size: 32,
      ),
    );
  }
}
