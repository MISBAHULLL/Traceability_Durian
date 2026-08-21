enum TraceQuantityMovementType {
  created,
  reserved,
  reservationReleased,
  acceptedOut,
  acceptedIn,
  rejected,
  disputed,
  loss,
  disposed,
  consumed,
}

extension TraceQuantityMovementTypeX on TraceQuantityMovementType {
  String get label {
    switch (this) {
      case TraceQuantityMovementType.created:
        return 'Saldo Awal';
      case TraceQuantityMovementType.reserved:
        return 'Reserve T1';
      case TraceQuantityMovementType.reservationReleased:
        return 'Reserve Dilepas';
      case TraceQuantityMovementType.acceptedOut:
        return 'Accepted Keluar';
      case TraceQuantityMovementType.acceptedIn:
        return 'Accepted Masuk';
      case TraceQuantityMovementType.rejected:
        return 'Ditolak';
      case TraceQuantityMovementType.disputed:
        return 'Dispute';
      case TraceQuantityMovementType.loss:
        return 'Loss';
      case TraceQuantityMovementType.disposed:
        return 'Disposal';
      case TraceQuantityMovementType.consumed:
        return 'Consumed';
    }
  }
}

TraceQuantityMovementType traceQuantityMovementTypeFromJson(Object? value) {
  return TraceQuantityMovementType.values.firstWhere(
    (type) => type.name == value,
    orElse: () => TraceQuantityMovementType.created,
  );
}

class TraceQuantityMovement {
  const TraceQuantityMovement({
    required this.id,
    required this.batchCode,
    required this.type,
    required this.quantity,
    required this.unit,
    required this.occurredAt,
    this.fruitCount,
    this.handoverId,
    this.handoverItemId,
    this.eventId,
    this.reason,
  });

  final String id;
  final String batchCode;
  final TraceQuantityMovementType type;
  final double quantity;
  final String unit;
  final int? fruitCount;
  final String? handoverId;
  final String? handoverItemId;
  final String? eventId;
  final String? reason;
  final DateTime occurredAt;

  Map<String, dynamic> toJson() => {
    'id': id,
    'batchCode': batchCode,
    'type': type.name,
    'quantity': quantity,
    'unit': unit,
    'fruitCount': fruitCount,
    'handoverId': handoverId,
    'handoverItemId': handoverItemId,
    'eventId': eventId,
    'reason': reason,
    'occurredAt': occurredAt.toIso8601String(),
  };

  factory TraceQuantityMovement.fromJson(Map<String, dynamic> json) {
    return TraceQuantityMovement(
      id: json['id'] as String,
      batchCode: json['batchCode'] as String,
      type: traceQuantityMovementTypeFromJson(json['type']),
      quantity: (json['quantity'] as num).toDouble(),
      unit: json['unit'] as String? ?? 'kg',
      fruitCount: (json['fruitCount'] as num?)?.toInt(),
      handoverId: json['handoverId'] as String?,
      handoverItemId: json['handoverItemId'] as String?,
      eventId: json['eventId'] as String?,
      reason: json['reason'] as String?,
      occurredAt: DateTime.parse(json['occurredAt'] as String),
    );
  }
}
