import 'package:flutter/material.dart';

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

/// Filter cepat yang ditampilkan sebagai chips di Beranda Petani.
enum BatchFilter { semua, menunggu, terverifikasi, distribusi }

extension BatchFilterX on BatchFilter {
  String get label {
    switch (this) {
      case BatchFilter.semua:
        return 'Semua';
      case BatchFilter.menunggu:
        return 'Menunggu';
      case BatchFilter.terverifikasi:
        return 'Terverifikasi';
      case BatchFilter.distribusi:
        return 'Distribusi';
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
      case BatchFilter.distribusi:
        return status == BatchStatus.inDistribution ||
            status == BatchStatus.receivedByUmkm;
    }
  }
}

/// Model satu batch panen durian milik petani.
class HarvestBatch {
  const HarvestBatch({
    required this.code,
    required this.variety,
    required this.grade,
    required this.quantity,
    required this.unit,
    required this.harvestDate,
    required this.farmName,
    required this.status,
  });

  /// Kode unik batch, contoh: DRN-2026-000128.
  final String code;

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
}

/// Data ringkas profil petani yang login (mock untuk tahap FE).
class FarmerProfile {
  const FarmerProfile({
    required this.fullName,
    required this.roleLabel,
    required this.location,
  });

  final String fullName;
  final String roleLabel;
  final String location;
}
