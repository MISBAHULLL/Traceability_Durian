import 'package:flutter/material.dart';

// [DB - Model/Entity] Enum ini merepresentasikan state machine status batch
// pada rantai pasok durian — dipakai di seluruh lapisan UI dan repository.
/// Status batch panen mengikuti state machine DurianTrace.
///
/// Lihat blueprint 07_USER_FLOW_AND_STATE_MACHINE:
/// DRAFT → CREATED → VERIFIED_BY_COLLECTOR → IN_DISTRIBUTION →
/// RECEIVED_BY_UMKM → PROCESSED → SOLD (atau REJECTED).
enum BatchStatus {
  draft,
  created,
  verifiedByCollector,
  inDistribution,
  receivedByUmkm,
  processed,
  sold,
  rejected,
}

// [FE - Component Rendering] Extension ini menyediakan label, warna teks,
// dan warna background badge untuk tiap status — dikonsumsi langsung oleh widget badge.
/// Label, warna teks, dan warna background badge untuk tiap status.
extension BatchStatusX on BatchStatus {
  String get label {
    switch (this) {
      case BatchStatus.draft:
        return 'Draft';
      case BatchStatus.created:
        return 'Menunggu Verifikasi';
      case BatchStatus.verifiedByCollector:
        return 'Terverifikasi';
      case BatchStatus.inDistribution:
        return 'Didistribusikan';
      case BatchStatus.receivedByUmkm:
        return 'Diterima UMKM';
      case BatchStatus.processed:
        return 'Diolah';
      case BatchStatus.sold:
        return 'Terjual';
      case BatchStatus.rejected:
        return 'Ditolak';
    }
  }

  /// Warna utama badge (teks + ikon).
  Color get color {
    switch (this) {
      case BatchStatus.draft:
        return const Color(0xFF6B7280);
      case BatchStatus.created:
        return const Color(0xFFB45309); // amber tua — menunggu aksi
      case BatchStatus.verifiedByCollector:
        return const Color(0xFF296C11); // hijau brand — sukses
      case BatchStatus.inDistribution:
        return const Color(0xFF1D6FA4); // biru — sedang berjalan
      case BatchStatus.receivedByUmkm:
        return const Color(0xFF6B21A8); // ungu
      case BatchStatus.processed:
        return const Color(0xFF0F766E); // teal
      case BatchStatus.sold:
        return const Color(0xFF3F8F27); // hijau gelap — selesai
      case BatchStatus.rejected:
        return const Color(0xFFD64545); // merah — gagal
    }
  }

  /// Warna background badge (soft).
  Color get background => color.withValues(alpha: 0.12);

  /// Apakah status ini termasuk "batch aktif" (masih berjalan di rantai pasok).
  bool get isActive {
    switch (this) {
      case BatchStatus.created:
      case BatchStatus.verifiedByCollector:
      case BatchStatus.inDistribution:
      case BatchStatus.receivedByUmkm:
        return true;
      case BatchStatus.draft:
      case BatchStatus.processed:
      case BatchStatus.sold:
      case BatchStatus.rejected:
        return false;
    }
  }
}

// [FE - State Management] Extension ini menyediakan logika filter chip
// yang menentukan batch mana yang lolos berdasarkan status — dipakai oleh
// helper searchAndFilterBatches di FarmerRepository.
/// Filter cepat yang ditampilkan sebagai chips di Beranda Petani.
enum BatchFilter { semua, menunggu, terverifikasi, ditolak }

extension BatchFilterX on BatchFilter {
  String get label {
    switch (this) {
      case BatchFilter.semua:
        return 'Semua';
      case BatchFilter.menunggu:
        return 'Menunggu';
      case BatchFilter.terverifikasi:
        return 'Terverifikasi';
      case BatchFilter.ditolak:
        return 'Ditolak';
    }
  }

  /// Mengecek apakah sebuah batch lolos filter ini.
  bool matches(BatchStatus status) {
    switch (this) {
      case BatchFilter.semua:
        return true;
      case BatchFilter.menunggu:
        return status == BatchStatus.created;
      case BatchFilter.terverifikasi:
        return status == BatchStatus.verifiedByCollector;
      case BatchFilter.ditolak:
        return status == BatchStatus.rejected;
    }
  }
}

// [DB - Model/Entity] Model ini merepresentasikan satu batch panen durian
// sebagai unit data utama yang mengalir di seluruh rantai pasok.
/// Model satu batch panen durian milik petani.
class HarvestBatch {
  const HarvestBatch({
    required this.code,
    required this.farmerId,
    required this.farmId,
    required this.variety,
    required this.grade,
    required this.quantity,
    required this.unit,
    required this.harvestDate,
    required this.farmName,
    required this.status,
    this.fertilizer,
    this.harvestMethod,
    this.maturityLevel,
    this.shelfLifeEstimate,
    this.storageSuggestion,
    this.notes,
    this.createdAt,
    this.photoPath,
  });

  /// Kode unik batch, contoh: DRN-2026-000128.
  final String code;

  /// ID petani pemilik batch — dipakai untuk isolasi data (Req 7.2).
  final String farmerId;

  /// ID kebun asal batch — relasi ke [Farm].
  final String farmId;

  /// Varietas durian, contoh: Montong, Bawor.
  final String variety;

  /// Grade/mutu, contoh: A, B, C.
  final String grade;

  /// Jumlah hasil panen.
  final double quantity;

  /// Satuan, contoh: kg.
  final String unit;

  /// Tanggal panen.
  final DateTime harvestDate;

  /// Nama kebun asal batch.
  final String farmName;

  /// Status batch saat ini pada rantai pasok.
  final BatchStatus status;

  /// Pupuk yang digunakan, contoh: Organik Kompos, NPK (opsional).
  final String? fertilizer;

  /// Metode panen, contoh: Jatuh Alami, Petik Matang.
  final String? harvestMethod;

  // [DB - Model/Entity] Metadata kualitas ini ikut melekat pada batch agar
  // informasi panen dapat dibaca role berikutnya sampai konsumen.
  /// Tingkat kematangan saat panen, contoh: Matang Pohon.
  final String? maturityLevel;

  /// Estimasi masa simpan durian segar, contoh: 2-3 hari.
  final String? shelfLifeEstimate;

  /// Saran penyimpanan untuk menjaga kualitas durian (opsional).
  final String? storageSuggestion;

  /// Catatan tambahan dari petani tentang kondisi panen (opsional).
  final String? notes;

  /// Waktu batch dibuat — dipakai untuk urutan daftar dan timeline.
  final DateTime? createdAt;

  /// Path/URI foto durian untuk batch ini (opsional).
  ///
  /// Pada fase FE-only, ini berisi path file lokal (mobile/desktop) atau
  /// blob URL (web) hasil dari image_picker. Di masa depan diganti URL
  /// gambar dari server.
  final String? photoPath;

  /// Membuat salinan batch dengan field yang diubah.
  HarvestBatch copyWith({
    String? code,
    String? farmerId,
    String? farmId,
    String? variety,
    String? grade,
    double? quantity,
    String? unit,
    DateTime? harvestDate,
    String? farmName,
    BatchStatus? status,
    String? fertilizer,
    String? harvestMethod,
    String? maturityLevel,
    String? shelfLifeEstimate,
    String? storageSuggestion,
    String? notes,
    DateTime? createdAt,
    String? photoPath,
  }) {
    return HarvestBatch(
      code: code ?? this.code,
      farmerId: farmerId ?? this.farmerId,
      farmId: farmId ?? this.farmId,
      variety: variety ?? this.variety,
      grade: grade ?? this.grade,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      harvestDate: harvestDate ?? this.harvestDate,
      farmName: farmName ?? this.farmName,
      status: status ?? this.status,
      fertilizer: fertilizer ?? this.fertilizer,
      harvestMethod: harvestMethod ?? this.harvestMethod,
      maturityLevel: maturityLevel ?? this.maturityLevel,
      shelfLifeEstimate: shelfLifeEstimate ?? this.shelfLifeEstimate,
      storageSuggestion: storageSuggestion ?? this.storageSuggestion,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      photoPath: photoPath ?? this.photoPath,
    );
  }
}

// [DB - Model/Entity] Model ini merepresentasikan profil petani yang login —
// dipakai oleh FarmerRepository sebagai data sesi mock.
/// Data profil petani yang login (mock untuk tahap FE).
class FarmerProfile {
  const FarmerProfile({
    required this.farmerId,
    required this.fullName,
    required this.roleLabel,
    required this.location,
    required this.village,
    required this.district,
    required this.city,
    required this.contact,
    this.email,
    this.avatarPath,
  });

  /// ID unik petani — dipakai untuk isolasi data (Req 7.2).
  final String farmerId;

  final String fullName;
  final String roleLabel;

  /// Lokasi ringkas yang ditampilkan di Beranda (sudah ada).
  final String location;

  /// Desa — ditampilkan di Detail Batch (Req 3.2).
  final String village;

  /// Kecamatan — ditampilkan di Detail Batch (Req 3.2).
  final String district;

  /// Kabupaten/kota — ditampilkan di Detail Batch (Req 3.2).
  final String city;

  /// Nomor HP utama petani — ditampilkan di Profil dan dipakai kontak cepat.
  final String contact;

  /// Email akun petani — nullable agar aman saat hot reload dari model lama.
  final String? email;

  // [UTIL - Helper Function] Getter ini memberi nilai aman untuk UI/API mock
  // ketika instance profil lama belum memiliki field email setelah hot reload.
  String get emailValue => email ?? '';

  /// Path/URI foto profil (opsional). Null berarti pakai avatar inisial.
  final String? avatarPath;

  /// Membuat salinan profil dengan field tertentu diubah.
  FarmerProfile copyWith({
    String? farmerId,
    String? fullName,
    String? roleLabel,
    String? location,
    String? village,
    String? district,
    String? city,
    String? contact,
    String? email,
    String? avatarPath,
  }) {
    return FarmerProfile(
      farmerId: farmerId ?? this.farmerId,
      fullName: fullName ?? this.fullName,
      roleLabel: roleLabel ?? this.roleLabel,
      location: location ?? this.location,
      village: village ?? this.village,
      district: district ?? this.district,
      city: city ?? this.city,
      contact: contact ?? this.contact,
      email: email ?? emailValue,
      avatarPath: avatarPath ?? this.avatarPath,
    );
  }
}
