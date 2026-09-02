import 'package:flutter/material.dart';

enum DistributorAuditEventType {
  scan,
  acquisition,
  receipt,
  rejection,
  warehouse,
  transfer,
  sale,
  profile,
  session,
}

extension DistributorAuditEventTypeX on DistributorAuditEventType {
  String get label {
    switch (this) {
      case DistributorAuditEventType.scan:
        return 'Scan / T1';
      case DistributorAuditEventType.acquisition:
        return 'Akuisisi';
      case DistributorAuditEventType.receipt:
        return 'Penerimaan';
      case DistributorAuditEventType.rejection:
        return 'Penolakan';
      case DistributorAuditEventType.warehouse:
        return 'Gudang';
      case DistributorAuditEventType.transfer:
        return 'Transfer';
      case DistributorAuditEventType.sale:
        return 'Penjualan';
      case DistributorAuditEventType.profile:
        return 'Profil';
      case DistributorAuditEventType.session:
        return 'Sesi';
    }
  }

  IconData get icon {
    switch (this) {
      case DistributorAuditEventType.scan:
        return Icons.qr_code_scanner_rounded;
      case DistributorAuditEventType.acquisition:
        return Icons.assignment_turned_in_outlined;
      case DistributorAuditEventType.receipt:
        return Icons.fact_check_outlined;
      case DistributorAuditEventType.rejection:
        return Icons.cancel_outlined;
      case DistributorAuditEventType.warehouse:
        return Icons.warehouse_outlined;
      case DistributorAuditEventType.transfer:
        return Icons.compare_arrows_rounded;
      case DistributorAuditEventType.sale:
        return Icons.local_shipping_outlined;
      case DistributorAuditEventType.profile:
        return Icons.person_outline_rounded;
      case DistributorAuditEventType.session:
        return Icons.logout_rounded;
    }
  }
}

class DistributorAuditEvent {
  const DistributorAuditEvent({
    required this.id,
    required this.distributorId,
    required this.actorId,
    required this.actorName,
    required this.actorRole,
    required this.type,
    required this.action,
    required this.objectCode,
    required this.description,
    required this.occurredAt,
    this.metadata = const {},
  });

  final String id;
  final String distributorId;
  final String actorId;
  final String actorName;
  final String actorRole;
  final DistributorAuditEventType type;
  final String action;
  final String objectCode;
  final String description;
  final DateTime occurredAt;
  final Map<String, String> metadata;

  Map<String, dynamic> toJson() => {
    'id': id,
    'distributorId': distributorId,
    'actorId': actorId,
    'actorName': actorName,
    'actorRole': actorRole,
    'type': type.name,
    'action': action,
    'objectCode': objectCode,
    'description': description,
    'occurredAt': occurredAt.toIso8601String(),
    'metadata': metadata,
  };

  factory DistributorAuditEvent.fromJson(Map<String, dynamic> json) {
    final rawMetadata = json['metadata'];
    final metadata = rawMetadata is Map
        ? rawMetadata.map((key, value) => MapEntry('$key', '$value'))
        : <String, String>{};

    return DistributorAuditEvent(
      id: json['id'] as String,
      distributorId: json['distributorId'] as String,
      actorId: json['actorId'] as String? ?? '',
      actorName: json['actorName'] as String? ?? 'Sistem',
      actorRole: json['actorRole'] as String? ?? 'Sistem',
      type: DistributorAuditEventType.values.firstWhere(
        (type) => type.name == json['type'],
        orElse: () => DistributorAuditEventType.acquisition,
      ),
      action: json['action'] as String? ?? '-',
      objectCode: json['objectCode'] as String? ?? '-',
      description: json['description'] as String? ?? '-',
      occurredAt: DateTime.parse(json['occurredAt'] as String),
      metadata: metadata,
    );
  }
}
