enum TraceBatchRelationType {
  receivedFrom,
  splitFrom,
  gradedFrom,
  consolidatedFrom,
  processedFrom,
}

extension TraceBatchRelationTypeX on TraceBatchRelationType {
  String get label {
    switch (this) {
      case TraceBatchRelationType.receivedFrom:
        return 'Diterima Dari';
      case TraceBatchRelationType.splitFrom:
        return 'Split Dari';
      case TraceBatchRelationType.gradedFrom:
        return 'Grading Dari';
      case TraceBatchRelationType.consolidatedFrom:
        return 'Konsolidasi Dari';
      case TraceBatchRelationType.processedFrom:
        return 'Diproses Dari';
    }
  }
}

TraceBatchRelationType traceBatchRelationTypeFromJson(Object? value) {
  return TraceBatchRelationType.values.firstWhere(
    (type) => type.name == value,
    orElse: () => TraceBatchRelationType.receivedFrom,
  );
}

class TraceBatchRelation {
  const TraceBatchRelation({
    required this.id,
    required this.sourceBatchCode,
    required this.targetBatchCode,
    required this.type,
    required this.quantity,
    required this.unit,
    required this.createdAt,
    this.fruitCount,
    this.eventId,
    this.note,
  });

  final String id;
  final String sourceBatchCode;
  final String targetBatchCode;
  final TraceBatchRelationType type;
  final double quantity;
  final String unit;
  final int? fruitCount;
  final String? eventId;
  final String? note;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
    'id': id,
    'sourceBatchCode': sourceBatchCode,
    'targetBatchCode': targetBatchCode,
    'type': type.name,
    'quantity': quantity,
    'unit': unit,
    'fruitCount': fruitCount,
    'eventId': eventId,
    'note': note,
    'createdAt': createdAt.toIso8601String(),
  };

  factory TraceBatchRelation.fromJson(Map<String, dynamic> json) {
    return TraceBatchRelation(
      id: json['id'] as String,
      sourceBatchCode: json['sourceBatchCode'] as String,
      targetBatchCode: json['targetBatchCode'] as String,
      type: traceBatchRelationTypeFromJson(json['type']),
      quantity: (json['quantity'] as num).toDouble(),
      unit: json['unit'] as String? ?? 'kg',
      fruitCount: (json['fruitCount'] as num?)?.toInt(),
      eventId: json['eventId'] as String?,
      note: json['note'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
