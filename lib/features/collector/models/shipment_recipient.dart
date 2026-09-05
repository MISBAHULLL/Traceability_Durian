import 'collector_shipment_batch.dart';

/// Ringkasan akun penerima yang nanti dapat diisi dari endpoint daftar user.
class ShipmentRecipient {
  const ShipmentRecipient({
    required this.userId,
    required this.name,
    required this.address,
    required this.destinationType,
  });

  final String userId;
  final String name;
  final String address;
  final ShipmentDestinationType destinationType;
}

/// Data sementara FE untuk mensimulasikan akun yang sudah terdaftar.
/// Sumber ini dapat diganti API tanpa mengubah komponen pemilih pada form.
abstract final class ShipmentRecipientDirectory {
  static const List<ShipmentRecipient> recipients = [
    ShipmentRecipient(
      userId: 'umkm-001',
      name: 'UMKM Sari Durian Jember',
      address: 'Jl. Trunojoyo No. 18, Kaliwates, Kabupaten Jember, Jawa Timur',
      destinationType: ShipmentDestinationType.umkm,
    ),
    ShipmentRecipient(
      userId: 'umkm-002',
      name: 'Dapur Durian Wonosalam',
      address: 'Desa Wonosalam, Kecamatan Wonosalam, Kabupaten Jombang',
      destinationType: ShipmentDestinationType.umkm,
    ),
    ShipmentRecipient(
      userId: 'distributor-001',
      name: 'PT Trans Logistik Durian',
      address: 'Jl. Pemuda No. 15, Genteng, Kota Surabaya, Jawa Timur',
      destinationType: ShipmentDestinationType.distributor,
    ),
    ShipmentRecipient(
      userId: 'distributor-002',
      name: 'CV Nusantara Durian',
      address: 'Jl. Soekarno Hatta No. 88, Kota Bandung, Jawa Barat',
      destinationType: ShipmentDestinationType.distributor,
    ),
    ShipmentRecipient(
      userId: 'consumer-001',
      name: 'Ayu Prameswari',
      address: 'Gg. Melati, Jl. A. Yani, Kota Surabaya, Jawa Timur',
      destinationType: ShipmentDestinationType.consumer,
    ),
    ShipmentRecipient(
      userId: 'consumer-002',
      name: 'Budi Santoso',
      address: 'Perumahan Tegal Besar, Kabupaten Jember, Jawa Timur',
      destinationType: ShipmentDestinationType.consumer,
    ),
    ShipmentRecipient(
      userId: 'collector-002',
      name: 'Pengepul Wonosalam Makmur',
      address: 'Desa Panglungan, Kecamatan Wonosalam, Kabupaten Jombang',
      destinationType: ShipmentDestinationType.collector,
    ),
    ShipmentRecipient(
      userId: 'collector-003',
      name: 'Sentra Durian Lumajang',
      address: 'Desa Klakah, Kecamatan Klakah, Kabupaten Lumajang',
      destinationType: ShipmentDestinationType.collector,
    ),
  ];

  static List<ShipmentRecipient> forDestination(
    ShipmentDestinationType? destinationType,
  ) {
    if (destinationType == null) return const [];
    return recipients
        .where((item) => item.destinationType == destinationType)
        .toList(growable: false);
  }
}
