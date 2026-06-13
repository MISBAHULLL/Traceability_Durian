import 'package:flutter/foundation.dart';
import '../../../core/storage/local_storage_service.dart';
import '../../collector/data/collector_repository.dart';
import '../../collector/models/collector_shipment_batch.dart';
import '../../farmer/data/farmer_repository.dart';
import '../../farmer/models/harvest_batch.dart';
import '../models/distributor_profile.dart';
import '../models/distributor_receipt.dart';

// [FE - State Management] DistributorRepository mengelola profil distributor,
// memantau batch dari CollectorRepository, dan menyajikan metrik logistik.
class DistributorRepository extends ChangeNotifier {
  DistributorRepository._() {
    _loadFromLocal();
    // Dengarkan perubahan dari CollectorRepository agar metrik dan daftar
    // pengiriman ter-refresh secara real-time.
    CollectorRepository.instance.addListener(_onCollectorRepoChanged);
  }

  static final DistributorRepository instance = DistributorRepository._();

  static const String _kSeedDistributorId = 'distributor-001';
  static final DistributorProfile _kSeedProfile = const DistributorProfile(
    distributorId: _kSeedDistributorId,
    fullName: 'Andi Wijaya',
    roleLabel: 'Distributor Durian',
    businessName: 'PT. Trans Logistik Durian',
    contact: '081234567890',
    email: 'andi.wijaya@translogistik.com',
    location: 'Surabaya Hub, Jawa Timur',
    village: 'Genteng',
    district: 'Genteng',
    city: 'Surabaya',
    address: 'Jl. Pemuda No. 15, Surabaya',
  );

  late DistributorProfile _profile;
  late List<DistributorReceipt> _receipts;
  String _currentDistributorId = _kSeedDistributorId;

  DistributorProfile get profile => _profile;

  void _onCollectorRepoChanged() {
    notifyListeners();
  }

  @override
  void dispose() {
    CollectorRepository.instance.removeListener(_onCollectorRepoChanged);
    super.dispose();
  }

  // ── Local Storage & Session ────────────────────────────────────────────────

  void _loadFromLocal() {
    _currentDistributorId =
        LocalStorageService.loadString('distributor_current_id') ??
        _kSeedDistributorId;

    final profileJson = LocalStorageService.loadJson('distributor_profile');
    if (profileJson != null) {
      _profile = DistributorProfile.fromJson(profileJson);
    } else {
      _profile = _kSeedProfile;
    }

    final receiptJsonList = LocalStorageService.loadJsonList(
      'distributor_receipts',
    );
    _receipts =
        receiptJsonList?.map(DistributorReceipt.fromJson).toList() ?? [];
  }

  void _saveToLocal() {
    LocalStorageService.saveString(
      'distributor_current_id',
      _currentDistributorId,
    );
    LocalStorageService.saveJson('distributor_profile', _profile.toJson());
    LocalStorageService.saveJsonList(
      'distributor_receipts',
      _receipts.map((receipt) => receipt.toJson()).toList(),
    );
  }

  /// Registrasi data distributor baru setelah mendaftar via form registrasi.
  void registerDistributor({
    required String firstName,
    required String lastName,
    required String phone,
    required String email,
  }) {
    _profile = DistributorProfile(
      distributorId: 'dist-reg-${DateTime.now().millisecondsSinceEpoch}',
      fullName: '$firstName $lastName'.trim(),
      roleLabel: 'Distributor Durian',
      contact: phone,
      email: email,
      location: 'Hub Baru, Indonesia',
    );
    _saveToLocal();
    notifyListeners();
  }

  /// Memperbarui informasi profil distributor.
  DistributorProfile updateProfile({
    required String fullName,
    required String businessName,
    required String contact,
    required String email,
    required String village,
    required String district,
    required String city,
    required String address,
  }) {
    final location = city.isNotEmpty ? '$city, Indonesia' : '';
    _profile = _profile.copyWith(
      fullName: fullName.trim(),
      businessName: businessName.trim(),
      contact: contact.trim(),
      email: email.trim(),
      village: village.trim(),
      district: district.trim(),
      city: city.trim(),
      address: address.trim(),
      location: location,
    );
    _saveToLocal();
    notifyListeners();
    return _profile;
  }

  /// Memperbarui foto avatar distributor.
  void updateAvatar(String? path) {
    _profile = _profile.copyWith(avatarPath: path);
    _saveToLocal();
    notifyListeners();
  }

  void logout() {
    _saveToLocal();
    notifyListeners();
  }

  // ── Shipments & Metrics ────────────────────────────────────────────────────

  // [FE - State Management] Distributor hanya membaca manifest yang tujuan
  // penerimanya distributor; pengiriman langsung UMKM tetap terisolasi.
  List<CollectorShipmentBatch> get allShipments => CollectorRepository
      .instance
      .allShipmentBatches
      .where(
        (shipment) =>
            shipment.destinationType == ShipmentDestinationType.distributor,
      )
      .toList();

  // [FE - State Management] Lookup ini menjadi jembatan detail distributor
  // dari kode shipment PGL ke data agregat pengepul yang sedang dipilih.
  CollectorShipmentBatch? findShipment(String code) {
    try {
      return allShipments.firstWhere((shipment) => shipment.code == code);
    } catch (_) {
      return null;
    }
  }

  // [FE - State Management] Resolver provenance ini menghubungkan batch
  // pengiriman pengepul dengan batch panen petani asal untuk detail trace.
  List<HarvestBatch> sourceBatchesForShipment(CollectorShipmentBatch shipment) {
    final farmerRepo = FarmerRepository.instance;
    return shipment.sourceBatchCodes
        .map(farmerRepo.findPublicBatch)
        .whereType<HarvestBatch>()
        .toList();
  }

  // [FE - State Management] Lookup receipt menghubungkan manifest dengan
  // hasil timbang dan inspeksi aktual yang disimpan oleh distributor.
  DistributorReceipt? receiptForShipment(String shipmentCode) {
    try {
      return _receipts.firstWhere(
        (receipt) =>
            receipt.shipmentCode == shipmentCode &&
            receipt.distributorId == _currentDistributorId,
      );
    } catch (_) {
      return null;
    }
  }

  // [FE - State Management] Riwayat receipt menyajikan bukti penerimaan
  // distributor terbaru lebih dulu untuk tab audit aktivitas barang masuk.
  List<DistributorReceipt> get receiptHistory {
    final items = _receipts
        .where((receipt) => receipt.distributorId == _currentDistributorId)
        .toList();
    items.sort((a, b) => b.receivedAt.compareTo(a.receivedAt));
    return List.unmodifiable(items);
  }

  /// Metrik 1: Total Kirim (Transit + Tiba)
  int get totalKirim => allShipments
      .where(
        (e) =>
            e.status == CollectorShipmentStatus.sent ||
            e.status == CollectorShipmentStatus.completed,
      )
      .length;

  /// Metrik 2: Transit (Sedang Dikirim)
  int get transit => allShipments
      .where((e) => e.status == CollectorShipmentStatus.sent)
      .length;

  /// Metrik 3: Tiba (Selesai Dikirim)
  int get tiba => allShipments
      .where((e) => e.status == CollectorShipmentStatus.completed)
      .length;

  /// Daftar pengiriman aktif (Status = Transit / Sent)
  List<CollectorShipmentBatch> get activeShipments =>
      allShipments
          .where((e) => e.status == CollectorShipmentStatus.sent)
          .toList()
        ..sort((a, b) => b.sentAt?.compareTo(a.sentAt ?? DateTime.now()) ?? 0);

  /// Daftar pengiriman yang sudah selesai (Status = Completed)
  List<CollectorShipmentBatch> get historyShipments =>
      allShipments
          .where((e) => e.status == CollectorShipmentStatus.completed)
          .toList()
        ..sort(
          (a, b) =>
              b.completedAt?.compareTo(a.completedAt ?? DateTime.now()) ?? 0,
        );

  /// Daftar pengiriman dari pengepul yang siap diambil (Status = ReadyToShip)
  List<CollectorShipmentBatch> get readyToPickShipments =>
      allShipments
          .where((e) => e.status == CollectorShipmentStatus.readyToShip)
          .toList()
        ..sort((a, b) => b.packagedAt.compareTo(a.packagedAt));

  /// Menandai shipment batch sebagai "Sent" (Handover pengiriman diambil).
  bool takeShipment(String code) {
    try {
      final success = CollectorRepository.instance.markShipmentSent(code);
      if (success) {
        notifyListeners();
        return true;
      }
    } catch (_) {}
    return false;
  }

  // [FE - Event Handler] Mutasi penerimaan menyimpan hasil inspeksi aktual
  // lalu menyelesaikan handover manifest dari pengepul secara konsisten.
  DistributorReceipt? receiveShipment({
    required String code,
    required double receivedWeightKg,
    required int receivedFruitCount,
    required DistributorReceiptCondition condition,
    String? discrepancyNote,
    String? qualityNote,
  }) {
    final shipment = findShipment(code);
    if (shipment == null ||
        shipment.status != CollectorShipmentStatus.sent ||
        receivedWeightKg <= 0 ||
        receivedFruitCount <= 0 ||
        receiptForShipment(code) != null) {
      return null;
    }

    final weightDifference = receivedWeightKg - shipment.totalWeightKg;
    final fruitDifference = receivedFruitCount - shipment.totalFruitCount;
    final hasDiscrepancy =
        weightDifference.abs() > 0.01 || fruitDifference != 0;
    final cleanDiscrepancyNote = discrepancyNote?.trim();
    if (hasDiscrepancy &&
        (cleanDiscrepancyNote == null || cleanDiscrepancyNote.isEmpty)) {
      return null;
    }

    final cleanQualityNote = qualityNote?.trim();
    final completed = CollectorRepository.instance.completeShipment(
      code,
      warehouseNote: cleanQualityNote?.isNotEmpty == true
          ? cleanQualityNote
          : 'Diterima dan diverifikasi oleh distributor.',
    );
    if (!completed) return null;

    final receipt = DistributorReceipt(
      shipmentCode: code,
      distributorId: _currentDistributorId,
      expectedWeightKg: shipment.totalWeightKg,
      expectedFruitCount: shipment.totalFruitCount,
      receivedWeightKg: receivedWeightKg,
      receivedFruitCount: receivedFruitCount,
      condition: condition,
      receivedAt: DateTime.now(),
      discrepancyNote: cleanDiscrepancyNote?.isEmpty == true
          ? null
          : cleanDiscrepancyNote,
      qualityNote: cleanQualityNote?.isEmpty == true ? null : cleanQualityNote,
    );
    _receipts.add(receipt);
    _saveToLocal();
    notifyListeners();
    return receipt;
  }
}
