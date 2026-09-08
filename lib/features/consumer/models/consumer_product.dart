import '../../../core/network/backend_api_client.dart';
import 'package:flutter/material.dart';

/// Filter kategori produk untuk beranda konsumen.
enum ConsumerProductFilter { semua, segar, olahan, minuman, paket }

/// Kategori produk UMKM yang ditampilkan di beranda konsumen.
enum ConsumerProductCategory { segar, olahan, minuman, paket }

/// Status produk yang terlihat oleh konsumen.
enum ConsumerProductStatus { readyToSell, limitedStock, soldOut, promo }

ConsumerProductCategory consumerProductCategoryFromJson(Object? value) {
  final normalized = value?.toString().trim().toLowerCase();
  return ConsumerProductCategory.values.firstWhere(
    (category) => category.name == normalized,
    orElse: () {
      switch (normalized) {
        case 'segar':
        case 'fresh':
          return ConsumerProductCategory.segar;
        case 'paket':
        case 'package':
          return ConsumerProductCategory.paket;
        case 'minuman':
        case 'drink':
          return ConsumerProductCategory.minuman;
        case 'olahan':
        default:
          return ConsumerProductCategory.olahan;
      }
    },
  );
}

ConsumerProductStatus consumerProductStatusFromJson(Object? value) {
  final normalized = value?.toString().trim().toLowerCase();
  return ConsumerProductStatus.values.firstWhere(
    (status) => status.name.toLowerCase() == normalized,
    orElse: () {
      switch (normalized) {
        case 'aktif':
        case 'readytosell':
          return ConsumerProductStatus.readyToSell;
        case 'habis':
        case 'soldout':
          return ConsumerProductStatus.soldOut;
        case 'terbatas':
        case 'limitedstock':
          return ConsumerProductStatus.limitedStock;
        case 'promo':
        default:
          return ConsumerProductStatus.promo;
      }
    },
  );
}

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

  Map<String, dynamic> toJson() => {
    'code': code,
    'name': name,
    'category': category.name,
    'status': status.name,
    'priceLabel': priceLabel,
    'shortDescription': shortDescription,
    'umkmName': umkmName,
    'location': location,
    'rating': rating,
    'stockLabel': stockLabel,
    'sourceBatchCode': sourceBatchCode,
    'sourceVariety': sourceVariety,
    'sourceGrade': sourceGrade,
    'sourceOriginFarm': sourceOriginFarm,
    'sourceHarvestDate': sourceHarvestDate?.toIso8601String(),
    'sourceHarvestMethod': sourceHarvestMethod,
    'sourceMaturityLevel': sourceMaturityLevel,
    'sourceShelfLifeEstimate': sourceShelfLifeEstimate,
    'sourceVerifiedBy': sourceVerifiedBy,
    'sourceVerifiedAt': sourceVerifiedAt?.toIso8601String(),
    'sourceReceivedQuantity': sourceReceivedQuantity,
    'sourceReceivedFruitCount': sourceReceivedFruitCount,
    'sourceQualityNotes': sourceQualityNotes,
    'sourceNotes': sourceNotes,
    'imagePath': imagePath,
  };

  factory ConsumerProduct.fromJson(Map<String, dynamic> json) {
    return ConsumerProduct(
      code: backendString(json, const ['code']),
      name: backendString(json, const ['name'], 'Produk UMKM'),
      category: consumerProductCategoryFromJson(json['category']),
      status: consumerProductStatusFromJson(json['status']),
      priceLabel: backendString(json, const ['priceLabel', 'price_label'], '-'),
      shortDescription: backendString(
        json,
        const ['shortDescription', 'short_description'],
      ),
      umkmName: backendString(json, const ['umkmName', 'umkm_name'], '-'),
      location: backendString(json, const ['location']),
      rating: backendDouble(json, const ['rating'], 0),
      stockLabel: backendString(json, const ['stockLabel', 'stock_label'], 'Stok belum ditentukan'),
      sourceBatchCode: backendNullableString(json, const ['sourceBatchCode', 'source_batch_code']),
      sourceVariety: backendNullableString(json, const ['sourceVariety', 'source_variety']),
      sourceGrade: backendNullableString(json, const ['sourceGrade', 'source_grade']),
      sourceOriginFarm: backendNullableString(json, const ['sourceOriginFarm', 'source_origin_farm']),
      sourceHarvestDate: backendDateTime(json, const ['sourceHarvestDate', 'source_harvest_date']),
      sourceHarvestMethod: backendNullableString(json, const ['sourceHarvestMethod', 'source_harvest_method']),
      sourceMaturityLevel: backendNullableString(json, const ['sourceMaturityLevel', 'source_maturity_level']),
      sourceShelfLifeEstimate: backendNullableString(json, const ['sourceShelfLifeEstimate', 'source_shelf_life_estimate']),
      sourceVerifiedBy: backendNullableString(json, const ['sourceVerifiedBy', 'source_verified_by']),
      sourceVerifiedAt: backendDateTime(json, const ['sourceVerifiedAt', 'source_verified_at']),
      sourceReceivedQuantity: backendDouble(json, const ['sourceReceivedQuantity', 'source_received_quantity']),
      sourceReceivedFruitCount: backendInt(json, const ['sourceReceivedFruitCount', 'source_received_fruit_count']),
      sourceQualityNotes: backendNullableString(json, const ['sourceQualityNotes', 'source_quality_notes']),
      sourceNotes: backendNullableString(json, const ['sourceNotes', 'source_notes']),
      imagePath: backendNullableString(json, const ['imagePath', 'photo_path', 'image_path']),
    );
  }
}

/// Profil konsumen yang login.
@immutable
class ConsumerProfile {
  static const Object _unset = Object();

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
    Object? avatarPath = _unset,
  }) {
    return ConsumerProfile(
      consumerId: consumerId ?? this.consumerId,
      fullName: fullName ?? this.fullName,
      roleLabel: roleLabel ?? this.roleLabel,
      contact: contact ?? this.contact,
      email: email ?? this.email,
      location: location ?? this.location,
      avatarPath: avatarPath == _unset
          ? this.avatarPath
          : avatarPath as String?,
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
      consumerId: backendString(json, const ['consumerId', 'id'], 'consumer-unknown'),
      fullName: backendString(json, const ['fullName', 'display_name', 'full_name']),
      roleLabel: backendString(json, const ['roleLabel'], 'Konsumen'),
      contact: backendString(json, const ['contact', 'phone']),
      email: backendString(json, const ['email'], ''),
      location: backendString(json, const ['location', 'address']),
      avatarPath: backendNullableString(json, const ['avatarPath', 'avatar_path']),
    );
  }
}
