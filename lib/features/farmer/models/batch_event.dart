import 'harvest_batch.dart';

enum BatchEventType {
  batchCreated,
  qrCreated,
  qrScanned,
  batchVerified,
  batchRejected,
  batchSent,
  batchReceived,
  batchProcessed,
  batchSold,
}

BatchEventType batchEventTypeFromJson(Object? value) {
  if (value == null) return BatchEventType.batchCreated;
  final name = value.toString();
  for (final type in BatchEventType.values) {
    if (type.name == name) return type;
  }
  return BatchEventType.batchCreated;
}

// [DB - Model/Entity] Model ini merepresentasikan satu kejadian nyata pada
// timeline riwayat batch. Trace publik membaca list event ini, bukan menebak
// perjalanan hanya dari status terakhir batch.
/// Satu kejadian pada timeline riwayat sebuah batch panen.
class BatchEvent {
  const BatchEvent({
    this.id,
    this.batchCode,
    this.type = BatchEventType.batchCreated,
    required this.title,
    required this.actorLabel,
    required this.timestamp,
    required this.status,
    this.description,
    this.locationLabel,
    this.metadata = const {},
  });

  final String? id;
  final String? batchCode;
  final BatchEventType type;
  final String title;
  final String actorLabel;
  final DateTime timestamp;
  final BatchStatus status;
  final String? description;
  final String? locationLabel;
  final Map<String, String> metadata;

  Map<String, dynamic> toJson() => {
    'id': id,
    'batchCode': batchCode,
    'type': type.name,
    'title': title,
    'actorLabel': actorLabel,
    'timestamp': timestamp.toIso8601String(),
    'status': status.name,
    'description': description,
    'locationLabel': locationLabel,
    'metadata': metadata,
  };

  factory BatchEvent.fromJson(Map<String, dynamic> json) {
    return BatchEvent(
      id: json['id'] as String?,
      batchCode: json['batchCode'] as String?,
      type: batchEventTypeFromJson(json['type']),
      title: json['title'] as String,
      actorLabel: json['actorLabel'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      status: BatchStatus.values.firstWhere(
        (item) => item.name == json['status'],
        orElse: () => BatchStatus.created,
      ),
      description: json['description'] as String?,
      locationLabel: json['locationLabel'] as String?,
      metadata: ((json['metadata'] as Map?) ?? const {}).map(
        (key, value) => MapEntry(key.toString(), value.toString()),
      ),
    );
  }
}
