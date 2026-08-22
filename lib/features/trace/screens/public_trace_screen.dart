import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_top_bar.dart';
import '../../../shared/widgets/batch_photo.dart';
import '../../../shared/widgets/osm_map_preview.dart';
import '../../collector/data/collector_repository.dart';
import '../../collector/models/collector_shipment_batch.dart';
import '../../distributor/data/distributor_repository.dart';
import '../../farmer/data/cahyadsn_region_service.dart';
import '../../farmer/data/farmer_repository.dart';
import '../../farmer/models/batch_event.dart';
import '../../farmer/models/farm.dart';
import '../../farmer/models/harvest_batch.dart';
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
    _loadRouteStops();
  }

  @override
  void dispose() {
    _repo.removeListener(_onRepoChanged);
    _collectorRepo.removeListener(_onRepoChanged);
    _distributorRepo.removeListener(_onRepoChanged);
    _umkmRepo.removeListener(_onRepoChanged);
    super.dispose();
  }

  void _onRepoChanged() {
    if (mounted) setState(() {});
    _loadRouteStops();
  }

  Future<void> _loadRouteStops() async {
    final serial = ++_routeLoadSerial;
    if (mounted) setState(() => _routeLoading = true);

    final batch = _repo.findPublicBatch(widget.batchCode);
    if (batch == null) {
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
          address: location.isEmpty ? 'Lokasi belum dicatat' : location,
          timestamp: event.timestamp,
          description: event.description ?? event.title,
          point: await _pointForAddress(location),
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
        address: _farmAddress(farm),
        timestamp:
            createdEvent?.timestamp ?? batch.createdAt ?? batch.harvestDate,
        description: 'Batch dibuat dan QR trace diterbitkan.',
        point: await _pointForFarm(farm),
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
          address: location.isEmpty ? 'Lokasi scan belum dicatat' : location,
          timestamp: event.timestamp,
          description:
              event.description ?? 'QR batch discan untuk validasi penerimaan.',
          point: await _pointForAddress(location),
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
          address: receiver.address,
          timestamp:
              verifiedEvent?.timestamp ??
              batch.verifiedAt ??
              (batch.createdAt ?? batch.harvestDate).add(
                const Duration(days: 1),
              ),
          description:
              'Stok diterima, ditimbang, dan kondisi durian diperiksa.',
          point: await _pointForAddress(receiver.address),
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
              : destinationAddress,
          timestamp:
              shipment.completedAt ?? shipment.sentAt ?? shipment.packagedAt,
          description: _shipmentDescription(shipment),
          point: await _pointForAddress(destinationAddress),
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

  CollectorShipmentBatch? _shipmentForBatch(String batchCode) {
    try {
      return _collectorRepo.allShipmentBatches.firstWhere(
        (shipment) => shipment.sourceBatchCodes.contains(batchCode),
      );
    } catch (_) {
      return null;
    }
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

  String _farmAddress(Farm? farm) {
    if (farm == null) return 'Alamat kebun belum ditemukan';
    final parts = [
      farm.address,
      farm.village,
      farm.district,
      farm.city,
      farm.province,
    ].where((value) => value.trim().isNotEmpty).toList();
    return parts.isEmpty ? 'Alamat kebun belum dilengkapi' : parts.join(', ');
  }

  String _shipmentDescription(CollectorShipmentBatch shipment) {
    return switch (shipment.status) {
      CollectorShipmentStatus.readyToShip =>
        'Batch sudah dikemas dan menunggu pengiriman.',
      CollectorShipmentStatus.sent =>
        'Batch sedang dikirim ke tujuan berikutnya.',
      CollectorShipmentStatus.completed =>
        'Batch sudah diterima di tujuan berikutnya.',
    };
  }

  Future<OsmMapPoint?> _pointForFarm(Farm? farm) async {
    if (farm == null) return null;
    if (farm.latitude != null && farm.longitude != null) {
      return OsmMapPoint(farm.latitude!, farm.longitude!);
    }

    final query = _farmAddress(farm);
    final exact = await _regionService.findAddress(query);
    if (exact != null) return OsmMapPoint(exact.latitude, exact.longitude);

    final regionCode = _resolveRegionCode(farm);
    final boundary = await _regionService.loadBoundaryFor(regionCode);
    if (boundary != null) {
      return OsmMapPoint(boundary.latitude, boundary.longitude);
    }
    final region = _regionService.mapForClosest(regionCode);
    if (region != null) return OsmMapPoint(region.latitude, region.longitude);
    return null;
  }

  Future<OsmMapPoint?> _pointForAddress(String address) async {
    if (address.trim().isEmpty) return null;
    final result = await _regionService.findAddress(address);
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
    final batch = _repo.findPublicBatch(widget.batchCode);

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            const AppTopBar(title: 'Trace Durian'),
            Expanded(
              child: batch == null
                  ? _TraceNotFound(batchCode: widget.batchCode)
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
    final hasPhoto = batch.photoPath != null && batch.photoPath!.isNotEmpty;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _TraceStatusHeader(batch: batch),
          const SizedBox(height: 16),
          _TraceRouteMap(stops: routeStops, loading: routeLoading),
          const SizedBox(height: 16),
          if (hasPhoto) ...[
            BatchPhoto(
              path: batch.photoPath,
              width: double.infinity,
              height: 190,
              borderRadius: BorderRadius.circular(10),
            ),
            const SizedBox(height: 16),
          ],
          _TraceSection(
            title: 'Informasi Durian',
            children: [
              _TraceInfoRow(label: 'Kode Batch', value: batch.code),
              _TraceInfoRow(label: 'Varietas', value: batch.variety),
              _TraceInfoRow(
                label: 'Total Berat',
                value: '${batch.quantity.toStringAsFixed(0)} ${batch.unit}',
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
              // [FE - Component Rendering] Data sortir pengepul ditampilkan
              // sebagai hasil verifikasi, bukan pengganti data awal petani.
              if (batch.verifiedGrade != null &&
                  batch.verifiedGrade!.isNotEmpty)
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
              // [FE - Component Rendering] Komposisi grade memperlihatkan
              // hasil sortir pengepul sebagai event tambahan traceability.
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
              if (batch.verifiedBy != null && batch.verifiedBy!.isNotEmpty)
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
                label: 'Tanggal Panen',
                value: _formatDate(batch.harvestDate),
              ),
              _TraceInfoRow(label: 'Asal Kebun', value: batch.farmName),
              if (batch.maturityLevel != null &&
                  batch.maturityLevel!.isNotEmpty)
                _TraceInfoRow(label: 'Kematangan', value: batch.maturityLevel!),
              if (batch.shelfLifeEstimate != null &&
                  batch.shelfLifeEstimate!.isNotEmpty)
                _TraceInfoRow(
                  label: 'Masa Simpan',
                  value: batch.shelfLifeEstimate!,
                ),
              if (batch.harvestMethod != null &&
                  batch.harvestMethod!.isNotEmpty)
                _TraceInfoRow(
                  label: 'Metode Panen',
                  value: batch.harvestMethod!,
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (_hasHandlingInfo(batch)) ...[
            _TraceSection(
              title: 'Catatan Kualitas',
              children: [
                if (batch.storageSuggestion != null &&
                    batch.storageSuggestion!.isNotEmpty)
                  _TraceInfoRow(
                    label: 'Saran Simpan',
                    value: batch.storageSuggestion!,
                  ),
                if (batch.notes != null && batch.notes!.isNotEmpty)
                  _TraceInfoRow(label: 'Catatan', value: batch.notes!),
                if (batch.qualityNotes != null &&
                    batch.qualityNotes!.isNotEmpty)
                  _TraceInfoRow(
                    label: 'Catatan Sortir',
                    value: batch.qualityNotes!,
                  ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }

  bool _hasHandlingInfo(HarvestBatch batch) {
    return (batch.storageSuggestion != null &&
            batch.storageSuggestion!.isNotEmpty) ||
        (batch.notes != null && batch.notes!.isNotEmpty) ||
        (batch.qualityNotes != null && batch.qualityNotes!.isNotEmpty);
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
