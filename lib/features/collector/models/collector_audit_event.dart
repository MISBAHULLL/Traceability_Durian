enum CollectorAuditEventType {
  purchase,
  receipt,
  rejection,
  grading,
  shipment,
  incoming,
  warehouse,
  transfer,
}

extension CollectorAuditEventTypeX on CollectorAuditEventType {
  String get label {
    switch (this) {
      case CollectorAuditEventType.purchase:
        return 'T1 / Scan';
      case CollectorAuditEventType.receipt:
        return 'Penerimaan';
      case CollectorAuditEventType.rejection:
        return 'Penolakan';
      case CollectorAuditEventType.grading:
        return 'Grading';
      case CollectorAuditEventType.shipment:
        return 'Pengiriman';
      case CollectorAuditEventType.incoming:
        return 'PGL Masuk';
      case CollectorAuditEventType.warehouse:
        return 'Gudang';
      case CollectorAuditEventType.transfer:
        return 'Transfer Gudang';
    }
  }
}

CollectorAuditEventType collectorAuditEventTypeFromJson(Object? value) {
  return CollectorAuditEventType.values.firstWhere(
    (type) => type.name == value,
    orElse: () => CollectorAuditEventType.receipt,
  );
}

// [DB - Model/Entity] Event audit formal pengepul. Model ini sengaja generik
// agar semua aksi operasional bisa difilter dari satu timeline: aktor, periode,
// tipe event, kode batch/PGL, dan kategori aksi.
class CollectorAuditEvent {
  const CollectorAuditEvent({
    required this.id,
    required this.type,
    required this.action,
    required this.actorName,
    required this.actorRole,
    required this.objectCode,
    required this.description,
    required this.occurredAt,
    this.locationLabel,
    this.statusLabel,
    this.metadata = const {},
  });

  final String id;
  final CollectorAuditEventType type;
  final String action;
  final String actorName;
  final String actorRole;
  final String objectCode;
  final String description;
  final DateTime occurredAt;
  final String? locationLabel;
  final String? statusLabel;
  final Map<String, String> metadata;

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'action': action,
    'actorName': actorName,
    'actorRole': actorRole,
    'objectCode': objectCode,
    'description': description,
    'occurredAt': occurredAt.toIso8601String(),
    'locationLabel': locationLabel,
    'statusLabel': statusLabel,
    'metadata': metadata,
  };

  factory CollectorAuditEvent.fromJson(Map<String, dynamic> json) {
    final rawMetadata = json['metadata'];
    final metadata = rawMetadata is Map
        ? rawMetadata.map((key, value) => MapEntry('$key', '$value'))
        : <String, String>{};

    return CollectorAuditEvent(
      id: json['id'] as String,
      type: collectorAuditEventTypeFromJson(json['type']),
      action: json['action'] as String? ?? '-',
      actorName: json['actorName'] as String? ?? 'Pengepul',
      actorRole: json['actorRole'] as String? ?? 'Pengepul',
      objectCode: json['objectCode'] as String? ?? '-',
      description: json['description'] as String? ?? '',
      occurredAt: DateTime.parse(json['occurredAt'] as String),
      locationLabel: json['locationLabel'] as String?,
      statusLabel: json['statusLabel'] as String?,
      metadata: metadata,
    );
  }
}
