import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_top_bar.dart';
import '../../../shared/widgets/batch_photo.dart';
import '../../../shared/widgets/osm_map_preview.dart';
import '../../collector/data/collector_repository.dart';
import '../../collector/models/collector_shipment_batch.dart';
import '../../distributor/data/distributor_repository.dart';
import '../../distributor/models/distributor_horizontal_sale.dart';
import '../../farmer/data/cahyadsn_region_service.dart';
import '../../farmer/data/farmer_repository.dart';
import '../../farmer/models/batch_event.dart';
import '../../farmer/models/farm.dart';
import '../../farmer/models/harvest_batch.dart';
import '../../traceability/data/traceability_repository.dart';
import '../../traceability/models/traceability_models.dart';
import '../../umkm/data/umkm_repository.dart';

// [FE - Component Rendering] Screen ini menjadi halaman trace publik yang
// dibuka dari QR batch; konsumen hanya membaca data tanpa aksi edit/verifikasi.
class PublicTraceScreen extends StatefulWidget {
  const PublicTraceScreen({super.key, required this.batchCode});

  final String batchCode;

  @override
  State<PublicTraceScreen> createState() => _PublicTraceScreenState();
}

class _PublicTraceScreenState extends State<PublicTraceScreen> {
  final _repo = FarmerRepository.instance;
  final _collectorRepo = CollectorRepository.instance;
  final _distributorRepo = DistributorRepository.instance;
  final _umkmRepo = UmkmRepository.instance;
  final _traceRepo = TraceabilityRepository.instance;
  final _regionService = CahyadsnRegionService.instance;
  var _routeLoadSerial = 0;
  var _routeLoading = true;
  List<_TraceStop> _routeStops = const [];

  @override
  void initState() {
    super.initState();
    _repo.addListener(_onRepoChanged);
    _collectorRepo.addListener(_onRepoChanged);
    _distributorRepo.addListener(_onRepoChanged);
    _umkmRepo.addListener(_onRepoChanged);
    _traceRepo.addListener(_onRepoChanged);
    _loadRouteStops();
  }

  @override
  void dispose() {
    _repo.removeListener(_onRepoChanged);
    _collectorRepo.removeListener(_onRepoChanged);
    _distributorRepo.removeListener(_onRepoChanged);
    _umkmRepo.removeListener(_onRepoChanged);
    _traceRepo.removeListener(_onRepoChanged);
    super.dispose();
  }

  void _onRepoChanged() {
    if (mounted) setState(() {});
    _loadRouteStops();
  }

  Future<void> _loadRouteStops() async {
    final serial = ++_routeLoadSerial;
    if (mounted) setState(() => _routeLoading = true);

    final cleanCode = _extractTraceCode(widget.batchCode);
    final batch = _repo.findPublicBatch(cleanCode);
    if (batch == null) {
      final traceBatch = _traceRepo.findBatch(cleanCode);
      if (traceBatch != null) {
        await _loadTraceBatchRouteStops(traceBatch, serial);
        return;
      }
      if (!mounted || serial != _routeLoadSerial) return;
      setState(() {
        _routeStops = const [];
        _routeLoading = false;
      });
      return;
    }

    await _regionService.load();
    final events = _repo.publicEventsFor(batch.code);
    final stops = <_TraceStop>[];
    const timelineOnlyTypes = {
      BatchEventType.batchGraded,
      BatchEventType.batchRejected,
      BatchEventType.batchSent,
      BatchEventType.batchProcessed,
      BatchEventType.batchSold,
    };

    Future<void> addEventStop(BatchEvent event) async {
      final duplicate = stops.any(
        (stop) =>
            stop.timestamp.isAtSameMomentAs(event.timestamp) &&
            stop.title == event.title &&
            stop.actorLabel == event.actorLabel,
      );
      if (duplicate) return;

      final location = event.locationLabel?.trim() ?? '';
      stops.add(
        _TraceStop(
          title: event.title,
          actorLabel: event.actorLabel,
          locationName: location.isEmpty ? event.actorLabel : location,
          address: location.isEmpty
              ? 'Lokasi belum dicatat'
              : _publicAddressLabel(location),
          timestamp: event.timestamp,
          description: event.description ?? event.title,
          point: await _publicPointForAddress(location),
        ),
      );
    }

    final createdEvent = _eventForStatus(events, BatchStatus.created);
    final farm = _repo.findPublicFarm(batch.farmId);

    stops.add(
      _TraceStop(
        title: 'Petani',
        actorLabel: createdEvent?.actorLabel ?? 'Petani',
        locationName: batch.farmName,
        address: _publicFarmAddress(farm),
        timestamp:
            createdEvent?.timestamp ?? batch.createdAt ?? batch.harvestDate,
        description: 'Batch dibuat dan QR trace diterbitkan.',
        point: await _publicPointForFarm(farm),
      ),
    );

    for (final event in events.where(
      (event) => event.type == BatchEventType.qrScanned,
    )) {
      final location = event.locationLabel?.trim() ?? '';
      stops.add(
        _TraceStop(
          title: event.title.replaceFirst('QR discan ', ''),
          actorLabel: event.actorLabel,
          locationName: location.isEmpty ? event.actorLabel : location,
          address: location.isEmpty
              ? 'Lokasi scan belum dicatat'
              : _publicAddressLabel(location),
          timestamp: event.timestamp,
          description:
              event.description ?? 'QR batch discan untuk validasi penerimaan.',
          point: await _publicPointForAddress(location),
        ),
      );
    }

    final verifiedEvent =
        _eventForStatus(events, BatchStatus.verifiedByCollector) ??
        _eventForStatus(events, BatchStatus.receivedByUmkm) ??
        _eventByTitle(events, 'Terverifikasi Pengepul') ??
        _eventByTitle(events, 'Terverifikasi Distributor') ??
        _eventByTitle(events, 'Diterima UMKM');
    final shouldShowReceiver =
        verifiedEvent != null ||
        batch.verifiedAt != null ||
        batch.warehouseId?.trim().isNotEmpty == true;
    if (shouldShowReceiver) {
      final receiver = _directReceiverInfo(batch);
      stops.add(
        _TraceStop(
          title: receiver.roleLabel,
          actorLabel: '${receiver.roleLabel} - ${receiver.name}',
          locationName: receiver.name,
          address: _publicAddressLabel(receiver.address),
          timestamp:
              verifiedEvent?.timestamp ??
              batch.verifiedAt ??
              (batch.createdAt ?? batch.harvestDate).add(
                const Duration(days: 1),
              ),
          description:
              'Stok diterima, ditimbang, dan kondisi durian diperiksa.',
          point: await _publicPointForAddress(receiver.address),
        ),
      );
    }
    final shipment = _shipmentForBatch(batch.code);
    if (shipment != null) {
      final destinationAddress = shipment.destinationLocation?.trim() ?? '';
      final destinationName =
          shipment.destinationName?.trim().isNotEmpty == true
          ? shipment.destinationName!.trim()
          : shipment.destinationType.label;
      stops.add(
        _TraceStop(
          title: shipment.destinationType.label,
          actorLabel: '${shipment.destinationType.label} - $destinationName',
          locationName: destinationName,
          address: destinationAddress.isEmpty
              ? 'Alamat tujuan belum dicatat'
              : _publicAddressLabel(destinationAddress),
          timestamp:
              shipment.completedAt ?? shipment.sentAt ?? shipment.packagedAt,
          description: _shipmentDescription(shipment),
          point: await _publicPointForAddress(destinationAddress),
        ),
      );
    }
    final horizontalSales = _horizontalSalesForTrace(
      batchCode: batch.code,
      shipment: shipment,
    );
    for (final sale in horizontalSales) {
      final destinationAddress = sale.destinationLocation.trim();
      stops.add(
        _TraceStop(
          title: 'Distributor',
          actorLabel: '${sale.sellerName} - ${sale.buyerName}',
          locationName: sale.buyerName,
          address: destinationAddress.isEmpty
              ? 'Alamat distributor tujuan belum dicatat'
              : _publicAddressLabel(destinationAddress),
          timestamp: sale.verifiedAt ?? sale.initiatedAt,
          description: _horizontalSaleDescription(sale),
          point: await _publicPointForAddress(destinationAddress),
        ),
      );
    }

    for (final event in events.where(
      (event) => timelineOnlyTypes.contains(event.type),
    )) {
      await addEventStop(event);
    }
    stops.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    if (!mounted || serial != _routeLoadSerial) return;
    setState(() {
      _routeStops = List.unmodifiable(stops);
      _routeLoading = false;
    });
  }

  BatchEvent? _eventForStatus(List<BatchEvent> events, BatchStatus status) {
    for (final event in events) {
      if (event.status == status) return event;
    }
    return null;
  }

  BatchEvent? _eventByTitle(List<BatchEvent> events, String title) {
    for (final event in events) {
      if (event.title == title) return event;
    }
    return null;
  }

  String _extractTraceCode(String raw) {
    final text = raw.trim();
    final match = RegExp(
      r'(UMKM-P-\d+|DRN-\d{4}-\d{6}|PGL-\d{3,4}-\d{3,6}|JDL-DST-\d{4}-\d{6})',
      caseSensitive: false,
    ).firstMatch(text);
    return (match?.group(0) ?? text).trim().toUpperCase();
  }

  List<TraceBatch> _traceLineageBatches(String batchCode) {
    final result = <TraceBatch>[];
    final visited = <String>{};

    void visit(String code) {
      final cleanCode = code.trim().toUpperCase();
      if (cleanCode.isEmpty || visited.contains(cleanCode)) return;
      visited.add(cleanCode);

      for (final relation in _traceRepo.parentsOf(cleanCode)) {
        visit(relation.sourceBatchCode);
      }

      final batch = _traceRepo.findBatch(cleanCode);
      if (batch != null) result.add(batch);
    }

    visit(batchCode);
    result.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return result;
  }

  List<_TraceMaterialLineage> _traceMaterialLineages(String batchCode) {
    final directRelations = _traceRepo.parentsOf(batchCode);
    final result = <_TraceMaterialLineage>[];

    for (final relation in directRelations) {
      final sourceCode = relation.sourceBatchCode.trim().toUpperCase();
      result.add(
        _TraceMaterialLineage(
          relation: relation,
          sourceBatch: _traceRepo.findBatch(sourceCode),
          originBatches: _originBatchesFor(sourceCode),
        ),
      );
    }
    return List.unmodifiable(result);
  }

  List<TraceBatch> _originBatchesFor(String batchCode) {
    final result = <TraceBatch>[];
    final visited = <String>{};
    final added = <String>{};

    void addOrigin(TraceBatch batch) {
      if (added.contains(batch.code)) return;
      added.add(batch.code);
      result.add(batch);
    }

    void visit(String code) {
      final cleanCode = code.trim().toUpperCase();
      if (cleanCode.isEmpty || visited.contains(cleanCode)) return;
      visited.add(cleanCode);

      final parents = _traceRepo.parentsOf(cleanCode);
      final batch = _traceRepo.findBatch(cleanCode);
      if (parents.isEmpty) {
        if (batch != null) addOrigin(batch);
        return;
      }

      for (final relation in parents) {
        visit(relation.sourceBatchCode);
      }

      if (batch != null && batch.code.startsWith('DRN-')) {
        addOrigin(batch);
      }
    }

    visit(batchCode);
    result.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return List.unmodifiable(result);
  }

  bool _isPublicCoreEvent(TraceBatchEvent event) {
    return switch (event.type) {
      TraceEventType.harvestCreated ||
      TraceEventType.handoverReceived ||
      TraceEventType.receiptDisputed ||
      TraceEventType.splitCreated ||
      TraceEventType.consolidated ||
      TraceEventType.processed ||
      TraceEventType.consumerReleased => true,
      _ => false,
    };
  }

  Future<_TraceStop> _traceStopForBatch(
    TraceBatch batch,
    TraceBatchEvent? event,
  ) async {
    final location = event?.locationLabel?.trim().isNotEmpty == true
        ? event!.locationLabel!.trim()
        : batch.publicLocationLabel?.trim().isNotEmpty == true
        ? batch.publicLocationLabel!.trim()
        : batch.locationLabel?.trim() ?? '';
    final actorRole = event?.actorRole ?? batch.currentHolderRole;
    final actorName = event?.actorName.trim().isNotEmpty == true
        ? event!.actorName.trim()
        : batch.currentHolderName;

    return _TraceStop(
      title: _traceStopTitle(batch, event),
      actorLabel: '${actorRole.label} - $actorName',
      locationName: actorName,
      address: location.isEmpty
          ? 'Wilayah belum dicatat'
          : _publicAddressLabel(location),
      timestamp: event?.occurredAt ?? batch.createdAt,
      description: _traceStopDescription(batch, event),
      point: await _publicPointForAddress(location),
    );
  }

  String _traceStopTitle(TraceBatch batch, TraceBatchEvent? event) {
    if (batch.productForm == 'processed_product') return 'Produk UMKM';
    return event?.actorRole.label ?? batch.currentHolderRole.label;
  }

  String _traceStopDescription(TraceBatch batch, TraceBatchEvent? event) {
    if (batch.productForm == 'processed_product') {
      final sources = _traceRepo
          .parentsOf(batch.code)
          .map((relation) => relation.sourceBatchCode)
          .join(', ');
      return sources.isEmpty
          ? 'Produk UMKM dibuat dan QR trace diterbitkan.'
          : 'Produk UMKM dibuat dari bahan baku $sources.';
    }
    if (event != null) return event.description;
    return '${batch.productName} tercatat di rantai traceability.';
  }

  CollectorShipmentBatch? _shipmentForBatch(String batchCode) {
    try {
      return _collectorRepo.allShipmentBatches.firstWhere(
        (shipment) => shipment.sourceBatchCodes.contains(batchCode),
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> _loadTraceBatchRouteStops(
    TraceBatch targetBatch,
    int serial,
  ) async {
    await _regionService.load();
    final stops = <_TraceStop>[];
    final seenStops = <String>{};

    Future<void> addStop(_TraceStop stop) async {
      final key =
          '${stop.title}|${stop.actorLabel}|${stop.timestamp.toIso8601String()}';
      if (seenStops.contains(key)) return;
      seenStops.add(key);
      stops.add(stop);
    }

    for (final batch in _traceLineageBatches(targetBatch.code)) {
      final farmerBatch = _repo.findPublicBatch(batch.code);
      if (farmerBatch != null) {
        final createdEvent = _eventForStatus(
          _repo.publicEventsFor(farmerBatch.code),
          BatchStatus.created,
        );
        final farm = _repo.findPublicFarm(farmerBatch.farmId);
        await addStop(
          _TraceStop(
            title: 'Petani',
            actorLabel: createdEvent?.actorLabel ?? 'Petani',
            locationName: farmerBatch.farmName,
            address: _publicFarmAddress(farm),
            timestamp:
                createdEvent?.timestamp ??
                farmerBatch.createdAt ??
                farmerBatch.harvestDate,
            description: 'Batch dibuat dan QR trace diterbitkan.',
            point: await _publicPointForFarm(farm),
          ),
        );
      }

      final events = _traceRepo.eventsForBatch(batch.code);
      final notableEvents = events.where(_isPublicCoreEvent).toList();
      if (notableEvents.isEmpty) {
        await addStop(await _traceStopForBatch(batch, null));
      } else {
        for (final event in notableEvents) {
          await addStop(await _traceStopForBatch(batch, event));
        }
      }
    }

    stops.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    if (!mounted || serial != _routeLoadSerial) return;
    setState(() {
      _routeStops = List.unmodifiable(stops);
      _routeLoading = false;
    });
  }

  List<DistributorHorizontalSale> _horizontalSalesForTrace({
    required String batchCode,
    CollectorShipmentBatch? shipment,
  }) {
    final sourceCodes = <String>{batchCode.trim().toUpperCase()};
    if (shipment != null) {
      sourceCodes.add(shipment.code.trim().toUpperCase());
    }

    final sales = _distributorRepo.allHorizontalSales
        .where(
          (sale) => sourceCodes.contains(sale.itemCode.trim().toUpperCase()),
        )
        .toList();
    sales.sort((a, b) => a.initiatedAt.compareTo(b.initiatedAt));
    return sales;
  }

  _ReceiverInfo _directReceiverInfo(HarvestBatch batch) {
    final role = batch.verifiedByRole ?? BatchReceiverRole.collector;
    final receiverName = batch.verifiedBy?.trim();
    switch (role) {
      case BatchReceiverRole.collector:
        final warehouse = _collectorRepo.findWarehouse(batch.warehouseId);
        final name = receiverName?.isNotEmpty == true
            ? receiverName!
            : _collectorRepo.profile.businessName;
        final address = warehouse?.location.trim().isNotEmpty == true
            ? warehouse!.location.trim()
            : _collectorAddress;
        return _ReceiverInfo(
          roleLabel: role.label,
          name: name.isEmpty ? role.label : name,
          address: address,
        );
      case BatchReceiverRole.distributor:
        final warehouse = _distributorRepo.defaultWarehouse;
        final profile = _distributorRepo.profile;
        final name = receiverName?.isNotEmpty == true
            ? receiverName!
            : profile.businessName;
        final address = warehouse?.location.trim().isNotEmpty == true
            ? warehouse!.location.trim()
            : _distributorAddress;
        return _ReceiverInfo(
          roleLabel: role.label,
          name: name.isEmpty ? profile.fullName : name,
          address: address,
        );
      case BatchReceiverRole.umkm:
        final profile = _umkmRepo.profile;
        final name = receiverName?.isNotEmpty == true
            ? receiverName!
            : profile.name;
        return _ReceiverInfo(
          roleLabel: role.label,
          name: name.isEmpty ? role.label : name,
          address: profile.location.trim().isEmpty
              ? 'Alamat UMKM belum dicatat'
              : profile.location.trim(),
        );
    }
  }

  String get _collectorAddress {
    final profile = _collectorRepo.profile;
    final parts = [
      profile.address,
      profile.village,
      profile.district,
      profile.city,
      profile.location,
    ].where((value) => value.trim().isNotEmpty).toList();
    return parts.isEmpty ? 'Alamat pengepul belum dicatat' : parts.join(', ');
  }

  String get _distributorAddress {
    final profile = _distributorRepo.profile;
    final parts = [
      profile.address,
      profile.village,
      profile.district,
      profile.city,
      profile.location,
    ].where((value) => value.trim().isNotEmpty).toList();
    return parts.isEmpty
        ? 'Alamat distributor belum dicatat'
        : parts.join(', ');
  }

  String _shipmentDescription(CollectorShipmentBatch shipment) {
    return switch (shipment.status) {
      CollectorShipmentStatus.readyToShip =>
        'Batch sudah dikemas dan menunggu pengiriman.',
      CollectorShipmentStatus.sent =>
        'Batch sedang dikirim ke tujuan berikutnya.',
      CollectorShipmentStatus.completed =>
        'Batch sudah diterima di tujuan berikutnya.',
      CollectorShipmentStatus.rejected =>
        'Batch ditolak saat validasi penerimaan.',
    };
  }

  String _horizontalSaleDescription(DistributorHorizontalSale sale) {
    return switch (sale.status) {
      DistributorHorizontalSaleStatus.initiated =>
        'Stok dialihkan dari ${sale.sellerName} ke ${sale.buyerName} dan menunggu validasi penerima.',
      DistributorHorizontalSaleStatus.verified =>
        'Stok diterima dan divalidasi oleh distributor tujuan.',
      DistributorHorizontalSaleStatus.rejected =>
        'Stok ditolak oleh distributor tujuan saat validasi penerimaan.',
    };
  }

  String _publicFarmAddress(Farm? farm) {
    if (farm == null) return 'Wilayah kebun belum ditemukan';
    final parts = [
      farm.village,
      farm.district,
      farm.city,
      farm.province,
    ].where((value) => value.trim().isNotEmpty).toList();
    return parts.isEmpty ? 'Wilayah kebun belum dilengkapi' : parts.join(', ');
  }

  String _publicAddressLabel(String address) {
    final parts = address
        .split(',')
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .where(
          (part) =>
              !part.toLowerCase().startsWith('jl ') &&
              !part.toLowerCase().startsWith('jalan ') &&
              !RegExp(r'^rt\b|^rw\b', caseSensitive: false).hasMatch(part),
        )
        .toList();
    if (parts.isEmpty) {
      return address.trim().isEmpty ? 'Wilayah belum dicatat' : address.trim();
    }
    final visible = parts.length <= 3 ? parts : parts.sublist(parts.length - 3);
    return visible.join(', ');
  }

  Future<OsmMapPoint?> _publicPointForFarm(Farm? farm) async {
    if (farm == null) return null;
    final regionCode = _resolveRegionCode(farm);
    final boundary = await _regionService.loadBoundaryFor(regionCode);
    if (boundary != null) {
      return OsmMapPoint(boundary.latitude, boundary.longitude);
    }
    final region = _regionService.mapForClosest(regionCode);
    if (region != null) return OsmMapPoint(region.latitude, region.longitude);

    final exact = await _regionService.findAddress(_publicFarmAddress(farm));
    if (exact != null) return OsmMapPoint(exact.latitude, exact.longitude);
    return null;
  }

  Future<OsmMapPoint?> _publicPointForAddress(String address) async {
    final publicAddress = _publicAddressLabel(address);
    if (publicAddress.trim().isEmpty ||
        publicAddress == 'Wilayah belum dicatat') {
      return null;
    }
    final result = await _regionService.findAddress(publicAddress);
    if (result == null) return null;
    return OsmMapPoint(result.latitude, result.longitude);
  }

  String? _resolveRegionCode(Farm farm) {
    final province = _regionService.findExact(
      _regionService.provinces,
      farm.province,
    );
    if (province == null) return null;

    final city = _regionService.findExact(
      _regionService.childrenOf(province.code),
      farm.city,
    );
    if (city == null) return province.code;

    final district = _regionService.findExact(
      _regionService.childrenOf(city.code),
      farm.district,
    );
    if (district == null) return city.code;

    final village = _regionService.findExact(
      _regionService.childrenOf(district.code),
      farm.village,
    );
    return village?.code ?? district.code;
  }

  @override
  Widget build(BuildContext context) {
    final cleanCode = _extractTraceCode(widget.batchCode);
    final batch = _repo.findPublicBatch(cleanCode);
    final traceBatch = batch == null ? _traceRepo.findBatch(cleanCode) : null;

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            const AppTopBar(title: 'Trace Durian'),
            Expanded(
              child: batch == null
                  ? traceBatch == null
                        ? _TraceNotFound(batchCode: cleanCode)
                        : _TraceProductContent(
                            batch: traceBatch,
                            lineageBatches: _traceLineageBatches(
                              traceBatch.code,
                            ),
                            sourceRelations: _traceRepo.parentsOf(
                              traceBatch.code,
                            ),
                            materialLineages: _traceMaterialLineages(
                              traceBatch.code,
                            ),
                            consumerReleaseEvents: _traceRepo
                                .eventsForBatch(traceBatch.code)
                                .where(
                                  (event) =>
                                      event.type ==
                                      TraceEventType.consumerReleased,
                                )
                                .toList(),
                            routeStops: _routeStops,
                            routeLoading: _routeLoading,
                          )
                  : _TraceContent(
                      batch: batch,
                      routeStops: _routeStops,
                      routeLoading: _routeLoading,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TraceContent extends StatelessWidget {
  const _TraceContent({
    required this.batch,
    required this.routeStops,
    required this.routeLoading,
  });

  final HarvestBatch batch;
  final List<_TraceStop> routeStops;
  final bool routeLoading;

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

  String _formatDateTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '${_formatDate(dt)}, $h:$m';
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _TraceBatchSummaryCard(
            batch: batch,
            createdLabel: _formatDateTime(batch.createdAt ?? batch.harvestDate),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => _TraceBatchInformationScreen(batch: batch),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          _TraceRouteMap(stops: routeStops, loading: routeLoading),
        ],
      ),
    );
  }
}

class _TraceBatchSummaryCard extends StatelessWidget {
  const _TraceBatchSummaryCard({
    required this.batch,
    required this.createdLabel,
    required this.onTap,
  });

  final HarvestBatch batch;
  final String createdLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: Color(0xFFE1E6DF)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 118,
          child: Row(
            children: [
              BatchPhoto(
                path: batch.photoPath,
                width: 116,
                height: 118,
                borderRadius: BorderRadius.zero,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Durian ${batch.variety}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: AppColors.black,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: batch.status.background,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              batch.status.label,
                              maxLines: 1,
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: batch.status.color,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Dibuat $createdLabel',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.placeholder,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${batch.quantity.toStringAsFixed(0)} ${batch.unit} dari ${batch.farmName}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          height: 1.3,
                          fontWeight: FontWeight.w600,
                          color: AppColors.subtitle,
                        ),
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              batch.code,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right_rounded,
                            size: 20,
                            color: AppColors.primary,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _TraceBatchInformationScreen extends StatelessWidget {
  const _TraceBatchInformationScreen({required this.batch});

  final HarvestBatch batch;

  String _formatDate(DateTime date) {
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
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _formatDateTime(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '${_formatDate(date)}, $hour:$minute';
  }

  bool get _hasHandlingInfo {
    return (batch.storageSuggestion?.isNotEmpty ?? false) ||
        (batch.notes?.isNotEmpty ?? false) ||
        (batch.qualityNotes?.isNotEmpty ?? false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            const AppTopBar(title: 'Informasi Durian'),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    BatchPhoto(
                      path: batch.photoPath,
                      width: double.infinity,
                      height: 190,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    const SizedBox(height: 16),
                    _TraceStatusHeader(batch: batch),
                    const SizedBox(height: 16),
                    _TraceSection(
                      title: 'Informasi Durian',
                      children: [
                        _TraceInfoRow(label: 'Kode Batch', value: batch.code),
                        _TraceInfoRow(label: 'Varietas', value: batch.variety),
                        _TraceInfoRow(
                          label: 'Total Berat',
                          value:
                              '${batch.quantity.toStringAsFixed(0)} ${batch.unit}',
                        ),
                        if (batch.fruitCount != null)
                          _TraceInfoRow(
                            label: 'Jumlah Buah',
                            value: '${batch.fruitCount} butir',
                          ),
                        _TraceInfoRow(
                          label: 'Grade Awal Petani',
                          value: 'Grade ${batch.grade}',
                        ),
                        if (batch.verifiedGrade?.isNotEmpty ?? false)
                          _TraceInfoRow(
                            label: 'Grade Pengepul',
                            value: 'Grade ${batch.verifiedGrade}',
                          ),
                        if (batch.receivedQuantity != null)
                          _TraceInfoRow(
                            label: 'Berat Diterima',
                            value:
                                '${batch.receivedQuantity!.toStringAsFixed(0)} ${batch.unit}',
                          ),
                        if (batch.receivedFruitCount != null)
                          _TraceInfoRow(
                            label: 'Jumlah Diterima',
                            value: '${batch.receivedFruitCount} butir',
                          ),
                        if (batch.gradeBreakdown.isNotEmpty)
                          _TraceInfoRow(
                            label: 'Komposisi Grade',
                            value: batch.gradeBreakdown
                                .map((item) {
                                  final weight = item.weightKg % 1 == 0
                                      ? item.weightKg.toStringAsFixed(0)
                                      : item.weightKg.toStringAsFixed(2);
                                  return '${item.grade}: $weight kg / ${item.fruitCount} butir';
                                })
                                .join('\n'),
                          ),
                        if (batch.verifiedBy?.isNotEmpty ?? false)
                          _TraceInfoRow(
                            label: 'Diverifikasi Oleh',
                            value: batch.verifiedBy!,
                          ),
                        if (batch.verifiedAt != null)
                          _TraceInfoRow(
                            label: 'Waktu Verifikasi',
                            value: _formatDateTime(batch.verifiedAt!),
                          ),
                        _TraceInfoRow(
                          label: 'Batch Dibuat',
                          value: _formatDateTime(
                            batch.createdAt ?? batch.harvestDate,
                          ),
                        ),
                        _TraceInfoRow(
                          label: 'Tanggal Panen',
                          value: _formatDate(batch.harvestDate),
                        ),
                        _TraceInfoRow(
                          label: 'Asal Kebun',
                          value: batch.farmName,
                        ),
                        if (batch.maturityLevel?.isNotEmpty ?? false)
                          _TraceInfoRow(
                            label: 'Kematangan',
                            value: batch.maturityLevel!,
                          ),
                        if (batch.shelfLifeEstimate?.isNotEmpty ?? false)
                          _TraceInfoRow(
                            label: 'Masa Simpan',
                            value: batch.shelfLifeEstimate!,
                          ),
                        if (batch.harvestMethod?.isNotEmpty ?? false)
                          _TraceInfoRow(
                            label: 'Metode Panen',
                            value: batch.harvestMethod!,
                          ),
                      ],
                    ),
                    if (_hasHandlingInfo) ...[
                      const SizedBox(height: 16),
                      _TraceSection(
                        title: 'Catatan Kualitas',
                        children: [
                          if (batch.storageSuggestion?.isNotEmpty ?? false)
                            _TraceInfoRow(
                              label: 'Saran Simpan',
                              value: batch.storageSuggestion!,
                            ),
                          if (batch.notes?.isNotEmpty ?? false)
                            _TraceInfoRow(
                              label: 'Catatan',
                              value: batch.notes!,
                            ),
                          if (batch.qualityNotes?.isNotEmpty ?? false)
                            _TraceInfoRow(
                              label: 'Catatan Sortir',
                              value: batch.qualityNotes!,
                            ),
                        ],
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

class _TraceProductContent extends StatelessWidget {
  const _TraceProductContent({
    required this.batch,
    required this.lineageBatches,
    required this.sourceRelations,
    required this.materialLineages,
    required this.consumerReleaseEvents,
    required this.routeStops,
    required this.routeLoading,
  });

  final TraceBatch batch;
  final List<TraceBatch> lineageBatches;
  final List<TraceBatchRelation> sourceRelations;
  final List<_TraceMaterialLineage> materialLineages;
  final List<TraceBatchEvent> consumerReleaseEvents;
  final List<_TraceStop> routeStops;
  final bool routeLoading;

  String _formatDateTime(DateTime dt) {
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
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}, $h:$m';
  }

  String _formatQuantity(double value, String unit) {
    final text = value % 1 == 0
        ? value.toStringAsFixed(0)
        : value.toStringAsFixed(1);
    return '$text $unit';
  }

  List<TraceBatch> get _originBatches {
    final byCode = <String, TraceBatch>{};
    for (final item in materialLineages) {
      for (final origin in item.originBatches) {
        byCode[origin.code] = origin;
      }
    }
    if (byCode.isEmpty) {
      for (final origin in lineageBatches.where(
        (item) => item.code.startsWith('DRN-'),
      )) {
        byCode[origin.code] = origin;
      }
    }
    if (byCode.isEmpty) {
      for (final origin in lineageBatches.where(
        (item) => item.code != batch.code,
      )) {
        byCode[origin.code] = origin;
      }
    }
    final origins = byCode.values.toList();
    origins.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return origins;
  }

  List<MapEntry<String, String>> get _productionRows {
    const keys = [
      'Lot Produksi',
      'Metode Proses',
      'Tanggal Produksi',
      'Kedaluwarsa',
      'Hasil Produksi',
      'Input bahan baku',
      'Loss/Waste',
      'Yield',
      'Catatan Produksi',
    ];
    return keys
        .where(
          (key) =>
              batch.metadata.containsKey(key) &&
              batch.metadata[key]!.trim().isNotEmpty,
        )
        .map((key) => MapEntry(key, batch.metadata[key]!))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final originBatches = _originBatches;
    final productionRows = _productionRows;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _TraceProductHeader(batch: batch),
          const SizedBox(height: 16),
          _TraceRouteMap(stops: routeStops, loading: routeLoading),
          const SizedBox(height: 16),
          _TraceSection(
            title: 'Informasi Produk',
            children: [
              _TraceInfoRow(label: 'Kode Produk', value: batch.code),
              _TraceInfoRow(label: 'Nama Produk', value: batch.productName),
              _TraceInfoRow(label: 'Status', value: batch.status.label),
              _TraceInfoRow(
                label: 'Jumlah Awal',
                value: _formatQuantity(batch.quantityInitial, batch.unit),
              ),
              _TraceInfoRow(
                label: 'Sisa Batch',
                value: _formatQuantity(batch.quantityCurrent, batch.unit),
              ),
              _TraceInfoRow(label: 'Pelaku', value: batch.currentHolderName),
              _TraceInfoRow(
                label: 'Dibuat',
                value: _formatDateTime(batch.createdAt),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (productionRows.isNotEmpty) ...[
            _TraceSection(
              title: 'Catatan Produksi',
              children: productionRows
                  .map(
                    (entry) =>
                        _TraceInfoRow(label: entry.key, value: entry.value),
                  )
                  .toList(),
            ),
            const SizedBox(height: 16),
          ],
          if (consumerReleaseEvents.isNotEmpty) ...[
            _TraceSection(
              title: 'Rilis Konsumen',
              children: consumerReleaseEvents
                  .map(
                    (event) => _TraceInfoRow(
                      label: event.metadata['Order'] ?? 'Order',
                      value: [
                        event.metadata['Jumlah'] ?? 'Jumlah belum dicatat',
                        event.metadata['Pembeli'] ?? 'Konsumen',
                        _formatDateTime(event.occurredAt),
                      ].join(' / '),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 16),
          ],
          _TraceSection(
            title: 'Komposisi Bahan Baku',
            children: materialLineages.isEmpty
                ? _fallbackSourceRows()
                : materialLineages
                      .asMap()
                      .entries
                      .map(
                        (entry) => _TraceMaterialLineageBlock(
                          index: entry.key + 1,
                          item: entry.value,
                        ),
                      )
                      .toList(),
          ),
          const SizedBox(height: 16),
          _TraceSection(
            title: 'Ringkasan Asal Durian',
            children: originBatches.isEmpty
                ? const [
                    _TraceInfoRow(
                      label: 'Asal',
                      value: 'Asal durian belum ditemukan di lineage.',
                    ),
                  ]
                : originBatches
                      .map(
                        (origin) => _TraceInfoRow(
                          label: origin.code,
                          value:
                              '${origin.productName} / ${origin.originActorName}',
                        ),
                      )
                      .toList(),
          ),
        ],
      ),
    );
  }

  List<Widget> _fallbackSourceRows() {
    if (sourceRelations.isNotEmpty) {
      return sourceRelations
          .map(
            (relation) => _TraceInfoRow(
              label: relation.sourceBatchCode,
              value:
                  '${relation.type.label} / ${_formatQuantity(relation.quantity, relation.unit)}',
            ),
          )
          .toList();
    }
    return [
      _TraceInfoRow(
        label: 'Sumber',
        value: batch.sourceReference ?? 'Belum tercatat',
      ),
    ];
  }
}

class _TraceMaterialLineage {
  const _TraceMaterialLineage({
    required this.relation,
    required this.sourceBatch,
    required this.originBatches,
  });

  final TraceBatchRelation relation;
  final TraceBatch? sourceBatch;
  final List<TraceBatch> originBatches;
}

class _TraceMaterialLineageBlock extends StatelessWidget {
  const _TraceMaterialLineageBlock({required this.index, required this.item});

  final int index;
  final _TraceMaterialLineage item;

  String _formatQuantity(double value, String unit) {
    final text = value % 1 == 0
        ? value.toStringAsFixed(0)
        : value.toStringAsFixed(1);
    return '$text $unit';
  }

  @override
  Widget build(BuildContext context) {
    final source = item.sourceBatch;
    final sourceName = source?.productName ?? 'Batch sumber';
    final holderName = source?.currentHolderName.trim().isNotEmpty == true
        ? source!.currentHolderName
        : source?.originActorName ?? 'Pelaku belum tercatat';
    final origins = item.originBatches;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: Text(
              '$index',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                color: AppColors.white,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.relation.sourceBatchCode,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$sourceName / $holderName',
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1.35,
                    fontWeight: FontWeight.w700,
                    color: AppColors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${item.relation.type.label} - ${_formatQuantity(item.relation.quantity, item.relation.unit)}',
                  style: const TextStyle(
                    fontSize: 11,
                    height: 1.35,
                    color: AppColors.subtitle,
                  ),
                ),
                if (item.relation.note != null &&
                    item.relation.note!.trim().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    item.relation.note!.trim(),
                    style: const TextStyle(
                      fontSize: 11,
                      height: 1.35,
                      color: AppColors.placeholder,
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                _TraceOriginList(origins: origins),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TraceOriginList extends StatelessWidget {
  const _TraceOriginList({required this.origins});

  final List<TraceBatch> origins;

  @override
  Widget build(BuildContext context) {
    if (origins.isEmpty) {
      return const Text(
        'Asal paling awal belum ditemukan.',
        style: TextStyle(
          fontSize: 11,
          height: 1.35,
          color: AppColors.placeholder,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          origins.length == 1
              ? 'Asal durian'
              : 'Sumber ini gabungan dari ${origins.length} asal durian',
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: AppColors.black,
          ),
        ),
        const SizedBox(height: 6),
        ...origins.map((origin) => _TraceOriginMiniRow(origin: origin)),
      ],
    );
  }
}

class _TraceOriginMiniRow extends StatelessWidget {
  const _TraceOriginMiniRow({required this.origin});

  final TraceBatch origin;

  @override
  Widget build(BuildContext context) {
    final location = origin.publicLocationLabel?.trim().isNotEmpty == true
        ? origin.publicLocationLabel!.trim()
        : origin.locationLabel?.trim();
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 5),
            child: Icon(
              Icons.fiber_manual_record,
              size: 7,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              [
                origin.code,
                origin.originActorName,
                if (location != null && location.isNotEmpty) location,
              ].join(' / '),
              style: const TextStyle(
                fontSize: 11,
                height: 1.35,
                color: AppColors.subtitle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TraceProductHeader extends StatelessWidget {
  const _TraceProductHeader({required this.batch});

  final TraceBatch batch;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.verified_outlined, color: AppColors.primary, size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Produk UMKM Traceable',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            batch.productName,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.black,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            batch.code,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.subtitle,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReceiverInfo {
  const _ReceiverInfo({
    required this.roleLabel,
    required this.name,
    required this.address,
  });

  final String roleLabel;
  final String name;
  final String address;
}

class _TraceStop {
  const _TraceStop({
    required this.title,
    required this.actorLabel,
    required this.locationName,
    required this.address,
    required this.timestamp,
    required this.description,
    this.point,
  });

  final String title;
  final String actorLabel;
  final String locationName;
  final String address;
  final DateTime timestamp;
  final String description;
  final OsmMapPoint? point;
}

class _TraceRouteMap extends StatelessWidget {
  const _TraceRouteMap({required this.stops, required this.loading});

  final List<_TraceStop> stops;
  final bool loading;

  List<_TraceStop> get _mappedStops =>
      stops.where((stop) => stop.point != null).toList();

  OsmMapPoint get _center {
    final mapped = _mappedStops;
    if (mapped.isEmpty) return const OsmMapPoint(-2.5, 118);
    final totalLatitude = mapped.fold<double>(
      0,
      (total, stop) => total + stop.point!.latitude,
    );
    final totalLongitude = mapped.fold<double>(
      0,
      (total, stop) => total + stop.point!.longitude,
    );
    return OsmMapPoint(
      totalLatitude / mapped.length,
      totalLongitude / mapped.length,
    );
  }

  int get _zoom {
    final mapped = _mappedStops;
    if (mapped.length <= 1) return 11;
    final latitudes = mapped.map((stop) => stop.point!.latitude).toList();
    final longitudes = mapped.map((stop) => stop.point!.longitude).toList();
    final latRange =
        latitudes.reduce((a, b) => a > b ? a : b) -
        latitudes.reduce((a, b) => a < b ? a : b);
    final lonRange =
        longitudes.reduce((a, b) => a > b ? a : b) -
        longitudes.reduce((a, b) => a < b ? a : b);
    final range = latRange > lonRange ? latRange : lonRange;
    if (range <= 0.05) return 13;
    if (range <= 0.2) return 11;
    if (range <= 1) return 9;
    if (range <= 3) return 8;
    if (range <= 8) return 6;
    return 5;
  }

  @override
  Widget build(BuildContext context) {
    final mapped = _mappedStops;
    final route = mapped.map((stop) => stop.point!).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Peta Perjalanan',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: AppColors.black,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          height: 220,
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6EE),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFD1E8CC)),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              Positioned.fill(
                child: OsmMapPreview(
                  center: _center,
                  initialZoom: _zoom,
                  markers: [
                    for (var i = 0; i < mapped.length; i++)
                      OsmMapMarker(
                        point: mapped[i].point!,
                        label: '${stops.indexOf(mapped[i]) + 1}',
                        color: i == 0
                            ? AppColors.primaryContainer
                            : const Color(0xFFE85D32),
                      ),
                  ],
                  route: route,
                ),
              ),
              if (loading)
                const Positioned.fill(
                  child: ColoredBox(
                    color: Color(0x55FFFFFF),
                    child: Center(
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primaryContainer,
                        ),
                      ),
                    ),
                  ),
                ),
              Positioned(
                right: 6,
                bottom: 5,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.88),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    child: Text(
                      '(c) OpenStreetMap',
                      style: TextStyle(fontSize: 9, color: AppColors.subtitle),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        if (stops.isEmpty && !loading)
          const Text(
            'Tracking perjalanan belum tersedia.',
            style: TextStyle(fontSize: 12, color: AppColors.placeholder),
          )
        else
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 2),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE5E7EB)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              children: [
                for (var i = 0; i < stops.length; i++)
                  _TrackingTimelineItem(
                    stop: stops[i],
                    isFirst: i == 0,
                    isLast: i == stops.length - 1,
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _TrackingTimelineItem extends StatelessWidget {
  const _TrackingTimelineItem({
    required this.stop,
    required this.isFirst,
    required this.isLast,
  });

  final _TraceStop stop;
  final bool isFirst;
  final bool isLast;

  String _formatDate(DateTime dt) {
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
    return '${dt.day} ${months[dt.month - 1]}';
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = isFirst
        ? AppColors.primaryContainer
        : const Color(0xFF94A3B8);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 48,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _formatDate(stop.timestamp),
                  style: TextStyle(
                    fontSize: 11,
                    height: 1.1,
                    fontWeight: isFirst ? FontWeight.w800 : FontWeight.w600,
                    color: isFirst ? AppColors.black : AppColors.placeholder,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _formatTime(stop.timestamp),
                  style: TextStyle(
                    fontSize: 11,
                    height: 1.1,
                    fontWeight: isFirst ? FontWeight.w800 : FontWeight.w500,
                    color: isFirst ? AppColors.black : AppColors.placeholder,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 18,
            child: Column(
              children: [
                Container(
                  width: isFirst ? 12 : 8,
                  height: isFirst ? 12 : 8,
                  margin: const EdgeInsets.only(top: 2),
                  decoration: BoxDecoration(
                    color: isFirst ? accentColor : AppColors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: accentColor, width: 2),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 1.5,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: const Color(0xFFD9DEE8),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    stop.description,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.35,
                      fontWeight: isFirst ? FontWeight.w800 : FontWeight.w700,
                      color: isFirst ? AppColors.black : AppColors.subtitle,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    stop.actorLabel,
                    style: const TextStyle(
                      fontSize: 12,
                      height: 1.3,
                      fontWeight: FontWeight.w700,
                      color: AppColors.subtitle,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    stop.address,
                    style: const TextStyle(
                      fontSize: 12,
                      height: 1.35,
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

class _TraceStatusHeader extends StatelessWidget {
  const _TraceStatusHeader({required this.batch});

  final HarvestBatch batch;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: batch.status.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: batch.status.color.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.verified_outlined,
                color: batch.status.color,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  batch.status.label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: batch.status.color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Durian ${batch.variety}',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.black,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            batch.code,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.subtitle,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }
}

// [FE - Component Rendering] Section ini mengelompokkan atribut trace agar
// konsumen dapat membaca asal, kualitas, dan handling batch secara terstruktur.
class _TraceSection extends StatelessWidget {
  const _TraceSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
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
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }
}

class _TraceInfoRow extends StatelessWidget {
  const _TraceInfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 118,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.placeholder,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                height: 1.35,
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

class _TraceNotFound extends StatelessWidget {
  const _TraceNotFound({required this.batchCode});

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
              fontWeight: FontWeight.w800,
              color: AppColors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            batchCode,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: AppColors.placeholder),
          ),
        ],
      ),
    );
  }
}
