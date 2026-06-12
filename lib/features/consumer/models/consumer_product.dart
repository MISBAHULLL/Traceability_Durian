import 'package:flutter/material.dart';

/// Filter kategori produk untuk beranda konsumen.
enum ConsumerProductFilter { semua, segar, olahan, minuman, paket }

/// Kategori produk UMKM yang ditampilkan di beranda konsumen.
enum ConsumerProductCategory { segar, olahan, minuman, paket }

/// Status produk yang terlihat oleh konsumen.
enum ConsumerProductStatus { readyToSell, limitedStock, soldOut, promo }

extension ConsumerProductFilterX on ConsumerProductFilter {
  String get label {
    switch (this) {
      case ConsumerProductFilter.semua:
        return 'Semua';
      case ConsumerProductFilter.segar:
        return 'Segar';
      case ConsumerProductFilter.olahan:
        return 'Olahan';
      case ConsumerProductFilter.minuman:
        return 'Minuman';
      case ConsumerProductFilter.paket:
        return 'Paket';
    }
  }
}

extension ConsumerProductCategoryX on ConsumerProductCategory {
  String get label {
    switch (this) {
      case ConsumerProductCategory.segar:
        return 'Segar';
      case ConsumerProductCategory.olahan:
        return 'Olahan';
      case ConsumerProductCategory.minuman:
        return 'Minuman';
      case ConsumerProductCategory.paket:
        return 'Paket';
    }
  }
}

extension ConsumerProductStatusX on ConsumerProductStatus {
  String get label {
    switch (this) {
      case ConsumerProductStatus.readyToSell:
        return 'Siap Jual';
      case ConsumerProductStatus.limitedStock:
        return 'Stok Terbatas';
      case ConsumerProductStatus.soldOut:
        return 'Habis';
      case ConsumerProductStatus.promo:
        return 'Promo';
    }
  }

  Color get color {
    switch (this) {
      case ConsumerProductStatus.readyToSell:
        return const Color(0xFF296C11);
      case ConsumerProductStatus.limitedStock:
        return const Color(0xFFB45309);
      case ConsumerProductStatus.soldOut:
        return const Color(0xFFD64545);
      case ConsumerProductStatus.promo:
        return const Color(0xFF6B21A8);
    }
  }

  Color get background => color.withValues(alpha: 0.12);
}

/// Produk UMKM yang ditampilkan ke konsumen.
@immutable
class ConsumerProduct {
  const ConsumerProduct({
    required this.code,
    required this.name,
    required this.category,
    required this.status,
    required this.priceLabel,
    required this.shortDescription,
    required this.umkmName,
    required this.location,
    required this.rating,
    required this.stockLabel,
    this.sourceBatchCode,
    this.sourceVariety,
    this.sourceGrade,
    this.sourceOriginFarm,
    this.sourceHarvestDate,
    this.sourceHarvestMethod,
    this.sourceMaturityLevel,
    this.sourceShelfLifeEstimate,
    this.sourceVerifiedBy,
    this.sourceVerifiedAt,
    this.sourceReceivedQuantity,
    this.sourceReceivedFruitCount,
    this.sourceQualityNotes,
    this.sourceNotes,
    this.imagePath,
  });

  final String code;
  final String name;
  final ConsumerProductCategory category;
  final ConsumerProductStatus status;
  final String priceLabel;
  final String shortDescription;
  final String umkmName;
  final String location;
  final double rating;
  final String stockLabel;
  final String? sourceBatchCode;
  final String? sourceVariety;
  final String? sourceGrade;
  final String? sourceOriginFarm;
  final DateTime? sourceHarvestDate;
  final String? sourceHarvestMethod;
  final String? sourceMaturityLevel;
  final String? sourceShelfLifeEstimate;
  final String? sourceVerifiedBy;
  final DateTime? sourceVerifiedAt;
  final double? sourceReceivedQuantity;
  final int? sourceReceivedFruitCount;
  final String? sourceQualityNotes;
  final String? sourceNotes;
  final String? imagePath;
}

/// Profil konsumen yang login.
@immutable
class ConsumerProfile {
  const ConsumerProfile({
    required this.consumerId,
    required this.fullName,
    required this.roleLabel,
    this.contact = '',
    this.email = '',
    this.location = '',
    this.avatarPath,
  });

  final String consumerId;
  final String fullName;
  final String roleLabel;
  final String contact;
  final String email;
  final String location;
  final String? avatarPath;

  ConsumerProfile copyWith({
    String? consumerId,
    String? fullName,
    String? roleLabel,
    String? contact,
    String? email,
    String? location,
    String? avatarPath,
  }) {
    return ConsumerProfile(
      consumerId: consumerId ?? this.consumerId,
      fullName: fullName ?? this.fullName,
      roleLabel: roleLabel ?? this.roleLabel,
      contact: contact ?? this.contact,
      email: email ?? this.email,
      location: location ?? this.location,
      avatarPath: avatarPath ?? this.avatarPath,
    );
  }

  Map<String, dynamic> toJson() => {
        'consumerId': consumerId,
        'fullName': fullName,
        'roleLabel': roleLabel,
        'contact': contact,
        'email': email,
        'location': location,
        'avatarPath': avatarPath,
      };

  factory ConsumerProfile.fromJson(Map<String, dynamic> json) {
    return ConsumerProfile(
      consumerId: json['consumerId'] as String,
      fullName: json['fullName'] as String,
      roleLabel: json['roleLabel'] as String,
      contact: (json['contact'] as String?) ?? '',
      email: (json['email'] as String?) ?? '',
      location: (json['location'] as String?) ?? '',
      avatarPath: json['avatarPath'] as String?,
    );
  }
}
