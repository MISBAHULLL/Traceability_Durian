import 'package:flutter/foundation.dart';
import '../../../core/storage/local_storage_service.dart';
import '../../collector/data/collector_repository.dart';
import '../../collector/models/collector_shipment_batch.dart';
import '../../farmer/data/farmer_repository.dart';
import '../../farmer/models/harvest_batch.dart';
import '../models/distributor_profile.dart';

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
  }

  void _saveToLocal() {
    LocalStorageService.saveString(
      'distributor_current_id',
      _currentDistributorId,
    );
    LocalStorageService.saveJson('distributor_profile', _profile.toJson());
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

  /// Mengambil semua shipment batch dari CollectorRepository.
  List<CollectorShipmentBatch> get allShipments =>
      CollectorRepository.instance.shipmentBatches;

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

  /// Menandai shipment batch sebagai "Completed" (Tiba di lokasi tujuan).
  bool completeShipment(String code, {String? warehouseNote}) {
    try {
      final success = CollectorRepository.instance.completeShipment(
        code,
        warehouseNote:
            warehouseNote ?? 'Diterima dengan baik oleh distributor.',
      );
      if (success) {
        notifyListeners();
        return true;
      }
    } catch (_) {}
    return false;
  }
}
