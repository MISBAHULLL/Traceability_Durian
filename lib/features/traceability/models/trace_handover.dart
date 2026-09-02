import 'trace_actor.dart';
import 'trace_batch_event.dart';

enum TraceHandoverStatus {
  proposed,
  confirmed,
  dispatched,
  received,
  completed,
  cancelled,
  expired,
  disputed,
  resolved,
}

extension TraceHandoverStatusX on TraceHandoverStatus {
  String get label {
    switch (this) {
      case TraceHandoverStatus.proposed:
        return 'T1 Dibuat';
      case TraceHandoverStatus.confirmed:
        return 'T1 Dikonfirmasi';
      case TraceHandoverStatus.dispatched:
        return 'Dikirim';
      case TraceHandoverStatus.received:
        return 'T2 Diterima';
      case TraceHandoverStatus.completed:
        return 'Selesai';
      case TraceHandoverStatus.cancelled:
        return 'Dibatalkan';
      case TraceHandoverStatus.expired:
        return 'Kedaluwarsa';
      case TraceHandoverStatus.disputed:
        return 'Dispute';
      case TraceHandoverStatus.resolved:
        return 'Dispute Selesai';
    }
  }
}

TraceHandoverStatus traceHandoverStatusFromJson(Object? value) {
  return TraceHandoverStatus.values.firstWhere(
    (status) => status.name == value,
    orElse: () => TraceHandoverStatus.proposed,
  );
}

enum TraceHandoverType { normal, horizontal, returnFlow }

TraceHandoverType traceHandoverTypeFromJson(Object? value) {
  return TraceHandoverType.values.firstWhere(
    (type) => type.name == value,
    orElse: () => TraceHandoverType.normal,
  );
}

class TraceHandover {
  const TraceHandover({
    required this.id,
    required this.senderId,
    required this.senderRole,
    required this.senderName,
    required this.receiverId,
    required this.receiverRole,
    required this.receiverName,
    required this.status,
    required this.type,
    required this.createdAt,
    this.confirmedAt,
    this.dispatchedAt,
    this.completedAt,
    this.sourceLocationLabel,
    this.destinationLocationLabel,
    this.originalHandoverId,
    this.metadata = const {},
  });

  final String id;
  final String senderId;
  final TraceActorRole senderRole;
  final String senderName;
  final String receiverId;
  final TraceActorRole receiverRole;
  final String receiverName;
  final TraceHandoverStatus status;
  final TraceHandoverType type;
  final DateTime createdAt;
  final DateTime? confirmedAt;
  final DateTime? dispatchedAt;
  final DateTime? completedAt;
  final String? sourceLocationLabel;
  final String? destinationLocationLabel;
  final String? originalHandoverId;
  final Map<String, String> metadata;

  TraceHandover copyWith({
    TraceHandoverStatus? status,
    DateTime? confirmedAt,
    DateTime? dispatchedAt,
    DateTime? completedAt,
    String? sourceLocationLabel,
    String? destinationLocationLabel,
    Map<String, String>? metadata,
  }) {
    return TraceHandover(
      id: id,
      senderId: senderId,
      senderRole: senderRole,
      senderName: senderName,
      receiverId: receiverId,
      receiverRole: receiverRole,
      receiverName: receiverName,
      status: status ?? this.status,
      type: type,
      createdAt: createdAt,
      confirmedAt: confirmedAt ?? this.confirmedAt,
      dispatchedAt: dispatchedAt ?? this.dispatchedAt,
      completedAt: completedAt ?? this.completedAt,
      sourceLocationLabel: sourceLocationLabel ?? this.sourceLocationLabel,
      destinationLocationLabel:
          destinationLocationLabel ?? this.destinationLocationLabel,
      originalHandoverId: originalHandoverId,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'senderId': senderId,
    'senderRole': senderRole.name,
    'senderName': senderName,
    'receiverId': receiverId,
    'receiverRole': receiverRole.name,
    'receiverName': receiverName,
    'status': status.name,
    'type': type.name,
    'createdAt': createdAt.toIso8601String(),
    'confirmedAt': confirmedAt?.toIso8601String(),
    'dispatchedAt': dispatchedAt?.toIso8601String(),
    'completedAt': completedAt?.toIso8601String(),
    'sourceLocationLabel': sourceLocationLabel,
    'destinationLocationLabel': destinationLocationLabel,
    'originalHandoverId': originalHandoverId,
    'metadata': metadata,
  };

  factory TraceHandover.fromJson(Map<String, dynamic> json) {
    final rawMetadata = json['metadata'];
    final metadata = rawMetadata is Map
        ? rawMetadata.map((key, value) => MapEntry('$key', '$value'))
        : <String, String>{};

    return TraceHandover(
      id: json['id'] as String,
      senderId: json['senderId'] as String? ?? '',
      senderRole: traceActorRoleFromJson(json['senderRole']),
      senderName: json['senderName'] as String? ?? '-',
      receiverId: json['receiverId'] as String? ?? '',
      receiverRole: traceActorRoleFromJson(json['receiverRole']),
      receiverName: json['receiverName'] as String? ?? '-',
      status: traceHandoverStatusFromJson(json['status']),
      type: traceHandoverTypeFromJson(json['type']),
      createdAt: DateTime.parse(json['createdAt'] as String),
      confirmedAt: json['confirmedAt'] == null
          ? null
          : DateTime.parse(json['confirmedAt'] as String),
      dispatchedAt: json['dispatchedAt'] == null
          ? null
          : DateTime.parse(json['dispatchedAt'] as String),
      completedAt: json['completedAt'] == null
          ? null
          : DateTime.parse(json['completedAt'] as String),
      sourceLocationLabel: json['sourceLocationLabel'] as String?,
      destinationLocationLabel: json['destinationLocationLabel'] as String?,
      originalHandoverId: json['originalHandoverId'] as String?,
      metadata: metadata,
    );
  }
}

class TraceHandoverItem {
  const TraceHandoverItem({
    required this.id,
    required this.handoverId,
    required this.sourceBatchCode,
    required this.proposedQuantity,
    required this.unit,
    this.proposedFruitCount,
    this.note,
  });

  final String id;
  final String handoverId;
  final String sourceBatchCode;
  final double proposedQuantity;
  final String unit;
  final int? proposedFruitCount;
  final String? note;

  Map<String, dynamic> toJson() => {
    'id': id,
    'handoverId': handoverId,
    'sourceBatchCode': sourceBatchCode,
    'proposedQuantity': proposedQuantity,
    'unit': unit,
    'proposedFruitCount': proposedFruitCount,
    'note': note,
  };

  factory TraceHandoverItem.fromJson(Map<String, dynamic> json) {
    return TraceHandoverItem(
      id: json['id'] as String,
      handoverId: json['handoverId'] as String,
      sourceBatchCode: json['sourceBatchCode'] as String,
      proposedQuantity: (json['proposedQuantity'] as num).toDouble(),
      unit: json['unit'] as String? ?? 'kg',
      proposedFruitCount: (json['proposedFruitCount'] as num?)?.toInt(),
      note: json['note'] as String?,
    );
  }
}

class TraceHandoverReceipt {
  const TraceHandoverReceipt({
    required this.id,
    required this.handoverItemId,
    required this.sourceBatchCode,
    required this.receiverBatchCode,
    required this.acceptedQuantity,
    required this.rejectedQuantity,
    required this.disputedQuantity,
    required this.unit,
    required this.conditionLabel,
    required this.receivedAt,
    this.acceptedFruitCount,
    this.rejectedFruitCount,
    this.disputedFruitCount,
    this.note,
    this.evidencePath,
  });

  final String id;
  final String handoverItemId;
  final String sourceBatchCode;
  final String receiverBatchCode;
  final double acceptedQuantity;
  final double rejectedQuantity;
  final double disputedQuantity;
  final String unit;
  final int? acceptedFruitCount;
  final int? rejectedFruitCount;
  final int? disputedFruitCount;
  final String conditionLabel;
  final String? note;
  final String? evidencePath;
  final DateTime receivedAt;

  double get totalAccountedQuantity =>
      acceptedQuantity + rejectedQuantity + disputedQuantity;

  Map<String, dynamic> toJson() => {
    'id': id,
    'handoverItemId': handoverItemId,
    'sourceBatchCode': sourceBatchCode,
    'receiverBatchCode': receiverBatchCode,
    'acceptedQuantity': acceptedQuantity,
    'rejectedQuantity': rejectedQuantity,
    'disputedQuantity': disputedQuantity,
    'unit': unit,
    'acceptedFruitCount': acceptedFruitCount,
    'rejectedFruitCount': rejectedFruitCount,
    'disputedFruitCount': disputedFruitCount,
    'conditionLabel': conditionLabel,
    'note': note,
    'evidencePath': evidencePath,
    'receivedAt': receivedAt.toIso8601String(),
  };

  factory TraceHandoverReceipt.fromJson(Map<String, dynamic> json) {
    return TraceHandoverReceipt(
      id: json['id'] as String,
      handoverItemId: json['handoverItemId'] as String,
      sourceBatchCode: json['sourceBatchCode'] as String,
      receiverBatchCode: json['receiverBatchCode'] as String,
      acceptedQuantity: (json['acceptedQuantity'] as num).toDouble(),
      rejectedQuantity: (json['rejectedQuantity'] as num).toDouble(),
      disputedQuantity: (json['disputedQuantity'] as num).toDouble(),
      unit: json['unit'] as String? ?? 'kg',
      acceptedFruitCount: (json['acceptedFruitCount'] as num?)?.toInt(),
      rejectedFruitCount: (json['rejectedFruitCount'] as num?)?.toInt(),
      disputedFruitCount: (json['disputedFruitCount'] as num?)?.toInt(),
      conditionLabel: json['conditionLabel'] as String? ?? '-',
      note: json['note'] as String?,
      evidencePath: json['evidencePath'] as String?,
      receivedAt: DateTime.parse(json['receivedAt'] as String),
    );
  }
}

TraceEventType eventTypeForHandoverStatus(TraceHandoverStatus status) {
  switch (status) {
    case TraceHandoverStatus.proposed:
      return TraceEventType.handoverProposed;
    case TraceHandoverStatus.confirmed:
      return TraceEventType.handoverConfirmed;
    case TraceHandoverStatus.dispatched:
      return TraceEventType.handoverDispatched;
    case TraceHandoverStatus.received:
      return TraceEventType.handoverReceived;
    case TraceHandoverStatus.completed:
    case TraceHandoverStatus.resolved:
      return TraceEventType.handoverCompleted;
    case TraceHandoverStatus.cancelled:
    case TraceHandoverStatus.expired:
      return TraceEventType.handoverCancelled;
    case TraceHandoverStatus.disputed:
      return TraceEventType.receiptDisputed;
  }
}
