import 'trace_actor.dart';

enum TraceBatchStatus {
  active,
  depleted,
  transformed,
  expired,
  disposed,
  blocked,
}

extension TraceBatchStatusX on TraceBatchStatus {
  String get label {
    switch (this) {
      case TraceBatchStatus.active:
        return 'Aktif';
      case TraceBatchStatus.depleted:
        return 'Habis';
      case TraceBatchStatus.transformed:
        return 'Diolah';
      case TraceBatchStatus.expired:
        return 'Kedaluwarsa';
      case TraceBatchStatus.disposed:
        return 'Dimusnahkan';
      case TraceBatchStatus.blocked:
        return 'Diblokir';
    }
  }
}

TraceBatchStatus traceBatchStatusFromJson(Object? value) {
  return TraceBatchStatus.values.firstWhere(
    (status) => status.name == value,
    orElse: () => TraceBatchStatus.active,
  );
}

class TraceBatch {
  const TraceBatch({
    required this.code,
    required this.productName,
    required this.productForm,
    required this.currentHolderId,
    required this.currentHolderRole,
    required this.currentHolderName,
    required this.originActorId,
    required this.originActorRole,
    required this.originActorName,
    required this.quantityInitial,
    required this.quantityCurrent,
    required this.reservedQuantity,
    required this.unit,
    required this.createdAt,
    required this.status,
    this.fruitCountInitial,
    this.fruitCountCurrent,
    this.locationLabel,
    this.publicLocationLabel,
    this.sourceReference,
    this.metadata = const {},
  });

  final String code;
  final String productName;
  final String productForm;
  final String currentHolderId;
  final TraceActorRole currentHolderRole;
  final String currentHolderName;
  final String originActorId;
  final TraceActorRole originActorRole;
  final String originActorName;
  final double quantityInitial;
  final double quantityCurrent;
  final double reservedQuantity;
  final String unit;
  final int? fruitCountInitial;
  final int? fruitCountCurrent;
  final String? locationLabel;
  final String? publicLocationLabel;
  final String? sourceReference;
  final DateTime createdAt;
  final TraceBatchStatus status;
  final Map<String, String> metadata;

  double get availableQuantity {
    final available = quantityCurrent - reservedQuantity;
    return available < 0 ? 0 : available;
  }

  bool get hasBalance => quantityCurrent > 0;

  TraceBatch copyWith({
    String? productName,
    String? productForm,
    String? currentHolderId,
    TraceActorRole? currentHolderRole,
    String? currentHolderName,
    double? quantityCurrent,
    double? reservedQuantity,
    int? fruitCountCurrent,
    String? locationLabel,
    String? publicLocationLabel,
    TraceBatchStatus? status,
    Map<String, String>? metadata,
  }) {
    return TraceBatch(
      code: code,
      productName: productName ?? this.productName,
      productForm: productForm ?? this.productForm,
      currentHolderId: currentHolderId ?? this.currentHolderId,
      currentHolderRole: currentHolderRole ?? this.currentHolderRole,
      currentHolderName: currentHolderName ?? this.currentHolderName,
      originActorId: originActorId,
      originActorRole: originActorRole,
      originActorName: originActorName,
      quantityInitial: quantityInitial,
      quantityCurrent: quantityCurrent ?? this.quantityCurrent,
      reservedQuantity: reservedQuantity ?? this.reservedQuantity,
      unit: unit,
      fruitCountInitial: fruitCountInitial,
      fruitCountCurrent: fruitCountCurrent ?? this.fruitCountCurrent,
      locationLabel: locationLabel ?? this.locationLabel,
      publicLocationLabel: publicLocationLabel ?? this.publicLocationLabel,
      sourceReference: sourceReference,
      createdAt: createdAt,
      status: status ?? this.status,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toJson() => {
    'code': code,
    'productName': productName,
    'productForm': productForm,
    'currentHolderId': currentHolderId,
    'currentHolderRole': currentHolderRole.name,
    'currentHolderName': currentHolderName,
    'originActorId': originActorId,
    'originActorRole': originActorRole.name,
    'originActorName': originActorName,
    'quantityInitial': quantityInitial,
    'quantityCurrent': quantityCurrent,
    'reservedQuantity': reservedQuantity,
    'unit': unit,
    'fruitCountInitial': fruitCountInitial,
    'fruitCountCurrent': fruitCountCurrent,
    'locationLabel': locationLabel,
    'publicLocationLabel': publicLocationLabel,
    'sourceReference': sourceReference,
    'createdAt': createdAt.toIso8601String(),
    'status': status.name,
    'metadata': metadata,
  };

  factory TraceBatch.fromJson(Map<String, dynamic> json) {
    final rawMetadata = json['metadata'];
    final metadata = rawMetadata is Map
        ? rawMetadata.map((key, value) => MapEntry('$key', '$value'))
        : <String, String>{};

    return TraceBatch(
      code: json['code'] as String,
      productName: json['productName'] as String? ?? 'Durian',
      productForm: json['productForm'] as String? ?? 'whole_fruit',
      currentHolderId: json['currentHolderId'] as String? ?? '',
      currentHolderRole: traceActorRoleFromJson(json['currentHolderRole']),
      currentHolderName: json['currentHolderName'] as String? ?? '-',
      originActorId: json['originActorId'] as String? ?? '',
      originActorRole: traceActorRoleFromJson(json['originActorRole']),
      originActorName: json['originActorName'] as String? ?? '-',
      quantityInitial: (json['quantityInitial'] as num).toDouble(),
      quantityCurrent: (json['quantityCurrent'] as num).toDouble(),
      reservedQuantity: (json['reservedQuantity'] as num?)?.toDouble() ?? 0,
      unit: json['unit'] as String? ?? 'kg',
      fruitCountInitial: (json['fruitCountInitial'] as num?)?.toInt(),
      fruitCountCurrent: (json['fruitCountCurrent'] as num?)?.toInt(),
      locationLabel: json['locationLabel'] as String?,
      publicLocationLabel: json['publicLocationLabel'] as String?,
      sourceReference: json['sourceReference'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      status: traceBatchStatusFromJson(json['status']),
      metadata: metadata,
    );
  }
}
