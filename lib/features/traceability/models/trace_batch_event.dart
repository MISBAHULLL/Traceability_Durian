import 'trace_actor.dart';

enum TraceEventType {
  harvestCreated,
  handoverProposed,
  handoverConfirmed,
  handoverDispatched,
  handoverReceived,
  handoverCompleted,
  handoverCancelled,
  receiptDisputed,
  gradingRecorded,
  splitCreated,
  consolidated,
  processed,
  consumerReleased,
  correctionRecorded,
  lossRecorded,
  disposalRecorded,
}

extension TraceEventTypeX on TraceEventType {
  String get label {
    switch (this) {
      case TraceEventType.harvestCreated:
        return 'Panen Dicatat';
      case TraceEventType.handoverProposed:
        return 'T1 Dibuat';
      case TraceEventType.handoverConfirmed:
        return 'T1 Dikonfirmasi';
      case TraceEventType.handoverDispatched:
        return 'Dikirim';
      case TraceEventType.handoverReceived:
        return 'T2 Diterima';
      case TraceEventType.handoverCompleted:
        return 'Handover Selesai';
      case TraceEventType.handoverCancelled:
        return 'Handover Dibatalkan';
      case TraceEventType.receiptDisputed:
        return 'Receipt Dispute';
      case TraceEventType.gradingRecorded:
        return 'Grading Dicatat';
      case TraceEventType.splitCreated:
        return 'Split Batch';
      case TraceEventType.consolidated:
        return 'Konsolidasi';
      case TraceEventType.processed:
        return 'Diproses';
      case TraceEventType.consumerReleased:
        return 'Rilis ke Konsumen';
      case TraceEventType.correctionRecorded:
        return 'Koreksi Dicatat';
      case TraceEventType.lossRecorded:
        return 'Loss Dicatat';
      case TraceEventType.disposalRecorded:
        return 'Disposal Dicatat';
    }
  }
}

TraceEventType traceEventTypeFromJson(Object? value) {
  return TraceEventType.values.firstWhere(
    (type) => type.name == value,
    orElse: () => TraceEventType.correctionRecorded,
  );
}

class TraceBatchEvent {
  const TraceBatchEvent({
    required this.id,
    required this.batchCode,
    required this.type,
    required this.actorId,
    required this.actorRole,
    required this.actorName,
    required this.title,
    required this.description,
    required this.occurredAt,
    this.locationLabel,
    this.relatedObjectId,
    this.metadata = const {},
  });

  final String id;
  final String batchCode;
  final TraceEventType type;
  final String actorId;
  final TraceActorRole actorRole;
  final String actorName;
  final String title;
  final String description;
  final DateTime occurredAt;
  final String? locationLabel;
  final String? relatedObjectId;
  final Map<String, String> metadata;

  Map<String, dynamic> toJson() => {
    'id': id,
    'batchCode': batchCode,
    'type': type.name,
    'actorId': actorId,
    'actorRole': actorRole.name,
    'actorName': actorName,
    'title': title,
    'description': description,
    'occurredAt': occurredAt.toIso8601String(),
    'locationLabel': locationLabel,
    'relatedObjectId': relatedObjectId,
    'metadata': metadata,
  };

  factory TraceBatchEvent.fromJson(Map<String, dynamic> json) {
    final rawMetadata = json['metadata'];
    final metadata = rawMetadata is Map
        ? rawMetadata.map((key, value) => MapEntry('$key', '$value'))
        : <String, String>{};

    return TraceBatchEvent(
      id: json['id'] as String,
      batchCode: json['batchCode'] as String,
      type: traceEventTypeFromJson(json['type']),
      actorId: json['actorId'] as String? ?? '',
      actorRole: traceActorRoleFromJson(json['actorRole']),
      actorName: json['actorName'] as String? ?? '-',
      title: json['title'] as String? ?? '-',
      description: json['description'] as String? ?? '-',
      occurredAt: DateTime.parse(json['occurredAt'] as String),
      locationLabel: json['locationLabel'] as String?,
      relatedObjectId: json['relatedObjectId'] as String?,
      metadata: metadata,
    );
  }
}
