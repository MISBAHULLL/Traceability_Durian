enum UmkmMaterialInventoryStatus { tersedia, habis }

extension UmkmMaterialInventoryStatusLabel on UmkmMaterialInventoryStatus {
  String get label {
    switch (this) {
      case UmkmMaterialInventoryStatus.tersedia:
        return 'Tersedia';
      case UmkmMaterialInventoryStatus.habis:
        return 'Habis';
    }
  }
}

enum UmkmMaterialMovementType { received, usedForProduction, waste, adjustment }

extension UmkmMaterialMovementTypeLabel on UmkmMaterialMovementType {
  String get label {
    switch (this) {
      case UmkmMaterialMovementType.received:
        return 'Stok Masuk';
      case UmkmMaterialMovementType.usedForProduction:
        return 'Dipakai Produksi';
      case UmkmMaterialMovementType.waste:
        return 'Waste';
      case UmkmMaterialMovementType.adjustment:
        return 'Penyesuaian';
    }
  }
}

class UmkmMaterialInventory {
  const UmkmMaterialInventory({
    required this.id,
    required this.traceCode,
    required this.publicTraceCode,
    required this.sourceTraceCodes,
    required this.productName,
    required this.supplierName,
    required this.receivedQuantity,
    required this.availableQuantity,
    required this.unit,
    required this.status,
    required this.receivedAt,
    this.relatedPurchaseId,
    this.note,
  });

  final String id;
  final String traceCode;
  final String publicTraceCode;
  final List<String> sourceTraceCodes;
  final String productName;
  final String supplierName;
  final double receivedQuantity;
  final double availableQuantity;
  final String unit;
  final UmkmMaterialInventoryStatus status;
  final DateTime receivedAt;
  final String? relatedPurchaseId;
  final String? note;

  double get usedQuantity {
    final used = receivedQuantity - availableQuantity;
    return used < 0 ? 0 : used;
  }

  bool get isAvailable =>
      availableQuantity > 0 && status == UmkmMaterialInventoryStatus.tersedia;

  UmkmMaterialInventory copyWith({
    double? receivedQuantity,
    double? availableQuantity,
    UmkmMaterialInventoryStatus? status,
    String? note,
  }) {
    return UmkmMaterialInventory(
      id: id,
      traceCode: traceCode,
      publicTraceCode: publicTraceCode,
      sourceTraceCodes: sourceTraceCodes,
      productName: productName,
      supplierName: supplierName,
      receivedQuantity: receivedQuantity ?? this.receivedQuantity,
      availableQuantity: availableQuantity ?? this.availableQuantity,
      unit: unit,
      status: status ?? this.status,
      receivedAt: receivedAt,
      relatedPurchaseId: relatedPurchaseId,
      note: note ?? this.note,
    );
  }
}

class UmkmMaterialMovement {
  const UmkmMaterialMovement({
    required this.id,
    required this.inventoryId,
    required this.traceCode,
    required this.type,
    required this.quantity,
    required this.unit,
    required this.occurredAt,
    required this.actorName,
    this.relatedObjectId,
    this.note,
  });

  final String id;
  final String inventoryId;
  final String traceCode;
  final UmkmMaterialMovementType type;
  final double quantity;
  final String unit;
  final DateTime occurredAt;
  final String actorName;
  final String? relatedObjectId;
  final String? note;
}
