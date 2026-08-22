import 'package:flutter/foundation.dart';

import '../../../core/storage/local_storage_service.dart';
import '../models/traceability_models.dart';

class TraceHandoverDraftItem {
  const TraceHandoverDraftItem({
    required this.batchCode,
    required this.quantity,
    required this.unit,
    this.fruitCount,
    this.note,
  });

  final String batchCode;
  final double quantity;
  final String unit;
  final int? fruitCount;
  final String? note;
}

class TraceLineageContribution {
  const TraceLineageContribution({
    required this.sourceBatchCode,
    required this.quantity,
    required this.unit,
    this.fruitCount,
    this.note,
  });

  final String sourceBatchCode;
  final double quantity;
  final String unit;
  final int? fruitCount;
  final String? note;
}

class TraceabilityRepository extends ChangeNotifier {
  TraceabilityRepository._() {
    _loadFromLocal();
  }

  static final TraceabilityRepository instance = TraceabilityRepository._();

  late List<TraceBatch> _batches;
  late List<TraceBatchEvent> _events;
  late List<TraceHandover> _handovers;
  late List<TraceHandoverItem> _handoverItems;
  late List<TraceHandoverReceipt> _handoverReceipts;
  late List<TraceBatchRelation> _relations;
  late List<TraceQuantityMovement> _movements;
  late int _eventCounter;
  late int _handoverCounter;
  late int _handoverItemCounter;
  late int _receiptCounter;
  late int _relationCounter;
  late int _movementCounter;
  late int _receivingBatchCounter;

  void _loadFromLocal() {
    _batches =
        LocalStorageService.loadJsonList(
          'traceability_batches',
        )?.map(TraceBatch.fromJson).toList() ??
        [];
    _events =
        LocalStorageService.loadJsonList(
          'traceability_events',
        )?.map(TraceBatchEvent.fromJson).toList() ??
        [];
    _handovers =
        LocalStorageService.loadJsonList(
          'traceability_handovers',
        )?.map(TraceHandover.fromJson).toList() ??
        [];
    _handoverItems =
        LocalStorageService.loadJsonList(
          'traceability_handover_items',
        )?.map(TraceHandoverItem.fromJson).toList() ??
        [];
    _handoverReceipts =
        LocalStorageService.loadJsonList(
          'traceability_handover_receipts',
        )?.map(TraceHandoverReceipt.fromJson).toList() ??
        [];
    _relations =
        LocalStorageService.loadJsonList(
          'traceability_relations',
        )?.map(TraceBatchRelation.fromJson).toList() ??
        [];
    _movements =
        LocalStorageService.loadJsonList(
          'traceability_movements',
        )?.map(TraceQuantityMovement.fromJson).toList() ??
        [];

    _eventCounter =
        LocalStorageService.loadInt('traceability_event_counter') ??
        _events.length;
    _handoverCounter =
        LocalStorageService.loadInt('traceability_handover_counter') ??
        _handovers.length;
    _handoverItemCounter =
        LocalStorageService.loadInt('traceability_handover_item_counter') ??
        _handoverItems.length;
    _receiptCounter =
        LocalStorageService.loadInt('traceability_receipt_counter') ??
        _handoverReceipts.length;
    _relationCounter =
        LocalStorageService.loadInt('traceability_relation_counter') ??
        _relations.length;
    _movementCounter =
        LocalStorageService.loadInt('traceability_movement_counter') ??
        _movements.length;
    _receivingBatchCounter =
        LocalStorageService.loadInt('traceability_receiving_batch_counter') ??
        _batches.length;
  }

  void _saveToLocal() {
    LocalStorageService.saveJsonList(
      'traceability_batches',
      _batches.map((item) => item.toJson()).toList(),
    );
    LocalStorageService.saveJsonList(
      'traceability_events',
      _events.map((item) => item.toJson()).toList(),
    );
    LocalStorageService.saveJsonList(
      'traceability_handovers',
      _handovers.map((item) => item.toJson()).toList(),
    );
    LocalStorageService.saveJsonList(
      'traceability_handover_items',
      _handoverItems.map((item) => item.toJson()).toList(),
    );
    LocalStorageService.saveJsonList(
      'traceability_handover_receipts',
      _handoverReceipts.map((item) => item.toJson()).toList(),
    );
    LocalStorageService.saveJsonList(
      'traceability_relations',
      _relations.map((item) => item.toJson()).toList(),
    );
    LocalStorageService.saveJsonList(
      'traceability_movements',
      _movements.map((item) => item.toJson()).toList(),
    );
    LocalStorageService.saveInt('traceability_event_counter', _eventCounter);
    LocalStorageService.saveInt(
      'traceability_handover_counter',
      _handoverCounter,
    );
    LocalStorageService.saveInt(
      'traceability_handover_item_counter',
      _handoverItemCounter,
    );
    LocalStorageService.saveInt(
      'traceability_receipt_counter',
      _receiptCounter,
    );
    LocalStorageService.saveInt(
      'traceability_relation_counter',
      _relationCounter,
    );
    LocalStorageService.saveInt(
      'traceability_movement_counter',
      _movementCounter,
    );
    LocalStorageService.saveInt(
      'traceability_receiving_batch_counter',
      _receivingBatchCounter,
    );
  }

  List<TraceBatch> get batches => List.unmodifiable(_batches);

  List<TraceBatchEvent> get events {
    final items = List<TraceBatchEvent>.from(_events);
    items.sort((a, b) => a.occurredAt.compareTo(b.occurredAt));
    return List.unmodifiable(items);
  }

  List<TraceHandover> get handovers {
    final items = List<TraceHandover>.from(_handovers);
    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return List.unmodifiable(items);
  }

  List<TraceHandoverItem> get handoverItems =>
      List.unmodifiable(_handoverItems);

  List<TraceHandoverReceipt> get handoverReceipts =>
      List.unmodifiable(_handoverReceipts);

  List<TraceBatchRelation> get relations => List.unmodifiable(_relations);

  List<TraceQuantityMovement> get movements => List.unmodifiable(_movements);

  TraceBatch? findBatch(String code) {
    try {
      return _batches.firstWhere((batch) => batch.code == code);
    } catch (_) {
      return null;
    }
  }

  List<TraceBatchEvent> eventsForBatch(String batchCode) {
    final items = _events
        .where((event) => event.batchCode == batchCode)
        .toList();
    items.sort((a, b) => a.occurredAt.compareTo(b.occurredAt));
    return List.unmodifiable(items);
  }

  List<TraceBatchRelation> parentsOf(String batchCode) {
    return List.unmodifiable(
      _relations.where((relation) => relation.targetBatchCode == batchCode),
    );
  }

  List<TraceBatchRelation> childrenOf(String batchCode) {
    return List.unmodifiable(
      _relations.where((relation) => relation.sourceBatchCode == batchCode),
    );
  }

  List<TraceQuantityMovement> movementsForBatch(String batchCode) {
    final items = _movements
        .where((movement) => movement.batchCode == batchCode)
        .toList();
    items.sort((a, b) => a.occurredAt.compareTo(b.occurredAt));
    return List.unmodifiable(items);
  }

  bool recordHarvestBatch({
    required String batchCode,
    required String farmerId,
    required String farmerName,
    required String variety,
    required double quantity,
    required String unit,
    required DateTime harvestDate,
    required String farmName,
    int? fruitCount,
    String? publicLocationLabel,
    Map<String, String> metadata = const {},
  }) {
    if (batchCode.trim().isEmpty || quantity <= 0) return false;

    final existingIndex = _batches.indexWhere(
      (batch) => batch.code == batchCode,
    );
    final createdAt = harvestDate;
    final batch = TraceBatch(
      code: batchCode,
      productName: 'Durian $variety',
      productForm: 'whole_fruit',
      currentHolderId: farmerId,
      currentHolderRole: TraceActorRole.farmer,
      currentHolderName: farmerName,
      originActorId: farmerId,
      originActorRole: TraceActorRole.farmer,
      originActorName: farmerName,
      quantityInitial: quantity,
      quantityCurrent: quantity,
      reservedQuantity: 0,
      unit: unit,
      fruitCountInitial: fruitCount,
      fruitCountCurrent: fruitCount,
      locationLabel: farmName,
      publicLocationLabel: publicLocationLabel ?? farmName,
      sourceReference: batchCode,
      createdAt: createdAt,
      status: TraceBatchStatus.active,
      metadata: metadata,
    );

    if (existingIndex == -1) {
      _batches.add(batch);
    } else {
      final existing = _batches[existingIndex];
      _batches[existingIndex] = existing.copyWith(
        productName: batch.productName,
        productForm: batch.productForm,
        locationLabel: batch.locationLabel,
        publicLocationLabel: batch.publicLocationLabel,
        metadata: batch.metadata,
      );
    }

    final hasHarvestEvent = _events.any(
      (event) =>
          event.batchCode == batchCode &&
          event.type == TraceEventType.harvestCreated,
    );
    if (!hasHarvestEvent) {
      final event = _createEvent(
        batchCode: batchCode,
        type: TraceEventType.harvestCreated,
        actorId: farmerId,
        actorRole: TraceActorRole.farmer,
        actorName: farmerName,
        title: 'Panen dicatat',
        description: '$batchCode dicatat dari $farmName.',
        occurredAt: createdAt,
        locationLabel: farmName,
        metadata: {
          'Varietas': variety,
          'Berat': '$quantity $unit',
          if (fruitCount != null) 'Jumlah': '$fruitCount butir',
          ...metadata,
        },
      );
      _events.add(event);
      _movements.add(
        _createMovement(
          batchCode: batchCode,
          type: TraceQuantityMovementType.created,
          quantity: quantity,
          unit: unit,
          fruitCount: fruitCount,
          eventId: event.id,
          occurredAt: createdAt,
          reason: 'Saldo awal panen',
        ),
      );
    }

    _saveToLocal();
    notifyListeners();
    return true;
  }

  bool recordConsolidatedBatch({
    required String targetBatchCode,
    required String holderId,
    required TraceActorRole holderRole,
    required String holderName,
    required List<TraceLineageContribution> contributions,
    required String productName,
    required DateTime createdAt,
    String productForm = 'whole_fruit',
    String? locationLabel,
    TraceBatchRelationType relationType =
        TraceBatchRelationType.consolidatedFrom,
    Map<String, String> metadata = const {},
  }) {
    final cleanTargetCode = targetBatchCode.trim().toUpperCase();
    final cleanContributions = contributions
        .where(
          (item) => item.sourceBatchCode.trim().isNotEmpty && item.quantity > 0,
        )
        .toList();
    if (cleanTargetCode.isEmpty || cleanContributions.isEmpty) return false;
    if (cleanContributions.any(
      (item) => item.sourceBatchCode.trim().toUpperCase() == cleanTargetCode,
    )) {
      return false;
    }

    final hasSameRelations = _relations.any(
      (relation) => relation.targetBatchCode == cleanTargetCode,
    );
    if (hasSameRelations) return true;

    final sources = <TraceBatch>[];
    for (final contribution in cleanContributions) {
      final source = findBatch(
        contribution.sourceBatchCode.trim().toUpperCase(),
      );
      if (source == null || contribution.quantity > source.quantityCurrent) {
        return false;
      }
      sources.add(source);
    }

    final totalQuantity = cleanContributions.fold<double>(
      0,
      (total, item) => total + item.quantity,
    );
    final totalFruitCount = cleanContributions.fold<int>(
      0,
      (total, item) => total + (item.fruitCount ?? 0),
    );
    final firstSource = sources.first;
    final mixedOrigin = sources.length > 1;
    final originName = mixedOrigin
        ? 'Campuran ${sources.length} batch sumber'
        : firstSource.originActorName;
    final eventType = switch (relationType) {
      TraceBatchRelationType.splitFrom => TraceEventType.splitCreated,
      TraceBatchRelationType.gradedFrom => TraceEventType.gradingRecorded,
      TraceBatchRelationType.processedFrom => TraceEventType.processed,
      TraceBatchRelationType.consolidatedFrom => TraceEventType.consolidated,
      TraceBatchRelationType.receivedFrom => TraceEventType.handoverReceived,
    };

    final event = _createEvent(
      batchCode: cleanTargetCode,
      type: eventType,
      actorId: holderId,
      actorRole: holderRole,
      actorName: holderName,
      title: mixedOrigin ? 'Batch campuran dibuat' : 'Sub-batch dibuat',
      description:
          '$cleanTargetCode dibuat dari ${sources.length} batch sumber.',
      occurredAt: createdAt,
      locationLabel: locationLabel,
      metadata: {
        'Total': '$totalQuantity ${cleanContributions.first.unit}',
        if (totalFruitCount > 0) 'Jumlah': '$totalFruitCount butir',
        'Sumber': cleanContributions
            .map((item) => item.sourceBatchCode.trim().toUpperCase())
            .join(', '),
        ...metadata,
      },
    );
    _events.add(event);

    if (!_batches.any((batch) => batch.code == cleanTargetCode)) {
      _batches.add(
        TraceBatch(
          code: cleanTargetCode,
          productName: productName,
          productForm: productForm,
          currentHolderId: holderId,
          currentHolderRole: holderRole,
          currentHolderName: holderName,
          originActorId: mixedOrigin ? 'mixed' : firstSource.originActorId,
          originActorRole: mixedOrigin
              ? TraceActorRole.system
              : firstSource.originActorRole,
          originActorName: originName,
          quantityInitial: totalQuantity,
          quantityCurrent: totalQuantity,
          reservedQuantity: 0,
          unit: cleanContributions.first.unit,
          fruitCountInitial: totalFruitCount == 0 ? null : totalFruitCount,
          fruitCountCurrent: totalFruitCount == 0 ? null : totalFruitCount,
          locationLabel: locationLabel,
          publicLocationLabel: locationLabel,
          sourceReference: cleanContributions
              .map((item) => item.sourceBatchCode.trim().toUpperCase())
              .join(','),
          createdAt: createdAt,
          status: TraceBatchStatus.active,
          metadata: {
            'Lineage': mixedOrigin ? 'Campuran' : 'Sub-batch',
            ...metadata,
          },
        ),
      );
    }

    for (var i = 0; i < cleanContributions.length; i++) {
      final contribution = cleanContributions[i];
      final source = sources[i];
      _relations.add(
        TraceBatchRelation(
          id: _generateRelationId(),
          sourceBatchCode: source.code,
          targetBatchCode: cleanTargetCode,
          type: relationType,
          quantity: contribution.quantity,
          unit: contribution.unit,
          fruitCount: contribution.fruitCount,
          eventId: event.id,
          note: contribution.note,
          createdAt: createdAt,
        ),
      );
      _movements.add(
        _createMovement(
          batchCode: source.code,
          type: TraceQuantityMovementType.acceptedOut,
          quantity: contribution.quantity,
          unit: contribution.unit,
          fruitCount: contribution.fruitCount,
          eventId: event.id,
          occurredAt: createdAt,
          reason: 'Kontribusi ke $cleanTargetCode',
        ),
      );
    }
    _movements.add(
      _createMovement(
        batchCode: cleanTargetCode,
        type: TraceQuantityMovementType.acceptedIn,
        quantity: totalQuantity,
        unit: cleanContributions.first.unit,
        fruitCount: totalFruitCount == 0 ? null : totalFruitCount,
        eventId: event.id,
        occurredAt: createdAt,
        reason: 'Batch hasil konsolidasi',
      ),
    );

    for (var i = 0; i < sources.length; i++) {
      final source = sources[i];
      final sourceIndex = _batches.indexWhere(
        (batch) => batch.code == source.code,
      );
      if (sourceIndex == -1) continue;
      final remaining = source.quantityCurrent - cleanContributions[i].quantity;
      final remainingFruit = source.fruitCountCurrent == null
          ? null
          : source.fruitCountCurrent! - (cleanContributions[i].fruitCount ?? 0);
      _batches[sourceIndex] = source.copyWith(
        quantityCurrent: remaining < 0 ? 0 : remaining,
        fruitCountCurrent: remainingFruit == null
            ? null
            : (remainingFruit < 0 ? 0 : remainingFruit),
        status: remaining <= 0
            ? TraceBatchStatus.transformed
            : TraceBatchStatus.active,
      );
    }

    _saveToLocal();
    notifyListeners();
    return true;
  }

  bool recordReceiptVariance({
    required String batchCode,
    required String actorId,
    required TraceActorRole actorRole,
    required String actorName,
    required double expectedQuantity,
    required double receivedQuantity,
    required String unit,
    required String conditionLabel,
    int? expectedFruitCount,
    int? receivedFruitCount,
    String? locationLabel,
    String? relatedObjectId,
    String? note,
  }) {
    final cleanBatchCode = batchCode.trim().toUpperCase();
    if (cleanBatchCode.isEmpty ||
        expectedQuantity < 0 ||
        receivedQuantity < 0) {
      return false;
    }
    if (relatedObjectId != null &&
        _events.any(
          (event) =>
              event.relatedObjectId == relatedObjectId &&
              (event.type == TraceEventType.receiptDisputed ||
                  event.type == TraceEventType.handoverReceived),
        )) {
      return true;
    }

    final weightDiff = receivedQuantity - expectedQuantity;
    final fruitDiff = receivedFruitCount == null || expectedFruitCount == null
        ? 0
        : receivedFruitCount - expectedFruitCount;
    final hasDiscrepancy = weightDiff.abs() > 0.01 || fruitDiff != 0;
    final now = DateTime.now();
    final event = _createEvent(
      batchCode: cleanBatchCode,
      type: hasDiscrepancy
          ? TraceEventType.receiptDisputed
          : TraceEventType.handoverReceived,
      actorId: actorId,
      actorRole: actorRole,
      actorName: actorName,
      title: hasDiscrepancy ? 'Audit selisih penerimaan' : 'Penerimaan sesuai',
      description: hasDiscrepancy
          ? 'Penerimaan $cleanBatchCode memiliki selisih berat/jumlah.'
          : 'Penerimaan $cleanBatchCode sesuai dengan catatan pengirim.',
      occurredAt: now,
      locationLabel: locationLabel,
      relatedObjectId: relatedObjectId,
      metadata: {
        'Kondisi': conditionLabel,
        'Berat dikirim': '$expectedQuantity $unit',
        'Berat diterima': '$receivedQuantity $unit',
        'Selisih berat': '$weightDiff $unit',
        if (expectedFruitCount != null) 'Jumlah dikirim': '$expectedFruitCount',
        if (receivedFruitCount != null)
          'Jumlah diterima': '$receivedFruitCount',
        if (expectedFruitCount != null && receivedFruitCount != null)
          'Selisih jumlah': '$fruitDiff',
        if (note != null && note.trim().isNotEmpty) 'Catatan': note.trim(),
      },
    );
    _events.add(event);

    final batchIndex = _batches.indexWhere(
      (batch) => batch.code == cleanBatchCode,
    );
    if (weightDiff < -0.01) {
      _movements.add(
        _createMovement(
          batchCode: cleanBatchCode,
          type: TraceQuantityMovementType.loss,
          quantity: weightDiff.abs(),
          unit: unit,
          fruitCount: fruitDiff < 0 ? fruitDiff.abs() : null,
          eventId: event.id,
          occurredAt: now,
          reason: note,
        ),
      );
      if (batchIndex != -1) {
        final batch = _batches[batchIndex];
        final remaining = batch.quantityCurrent - weightDiff.abs();
        _batches[batchIndex] = batch.copyWith(
          quantityCurrent: remaining < 0 ? 0 : remaining,
          fruitCountCurrent: batch.fruitCountCurrent == null || fruitDiff >= 0
              ? batch.fruitCountCurrent
              : (batch.fruitCountCurrent! - fruitDiff.abs()).clamp(0, 1 << 31),
          status: remaining <= 0
              ? TraceBatchStatus.depleted
              : TraceBatchStatus.active,
        );
      }
    } else if (weightDiff > 0.01 || fruitDiff > 0) {
      _movements.add(
        _createMovement(
          batchCode: cleanBatchCode,
          type: TraceQuantityMovementType.disputed,
          quantity: weightDiff > 0 ? weightDiff : 0,
          unit: unit,
          fruitCount: fruitDiff > 0 ? fruitDiff : null,
          eventId: event.id,
          occurredAt: now,
          reason: note,
        ),
      );
    }

    _saveToLocal();
    notifyListeners();
    return true;
  }

  bool recordWarehouseTransfer({
    required String batchCode,
    required String actorId,
    required TraceActorRole actorRole,
    required String actorName,
    required String fromLocationLabel,
    required String toLocationLabel,
    required double quantity,
    required String unit,
    required String reason,
    int? fruitCount,
    String? relatedObjectId,
  }) {
    final cleanBatchCode = batchCode.trim().toUpperCase();
    final cleanReason = reason.trim();
    if (cleanBatchCode.isEmpty ||
        quantity <= 0 ||
        fromLocationLabel.trim().isEmpty ||
        toLocationLabel.trim().isEmpty ||
        cleanReason.isEmpty) {
      return false;
    }
    if (relatedObjectId != null &&
        _events.any(
          (event) =>
              event.relatedObjectId == relatedObjectId &&
              event.type == TraceEventType.warehouseTransferred,
        )) {
      return true;
    }

    final now = DateTime.now();
    final event = _createEvent(
      batchCode: cleanBatchCode,
      type: TraceEventType.warehouseTransferred,
      actorId: actorId,
      actorRole: actorRole,
      actorName: actorName,
      title: 'Transfer gudang',
      description:
          '$cleanBatchCode dipindahkan dari $fromLocationLabel ke $toLocationLabel.',
      occurredAt: now,
      locationLabel: toLocationLabel,
      relatedObjectId: relatedObjectId,
      metadata: {
        'Gudang asal': fromLocationLabel,
        'Gudang tujuan': toLocationLabel,
        'Jumlah dipindah': '$quantity $unit',
        if (fruitCount != null) 'Jumlah buah': '$fruitCount butir',
        'Alasan': cleanReason,
      },
    );
    _events.add(event);
    _movements.add(
      _createMovement(
        batchCode: cleanBatchCode,
        type: TraceQuantityMovementType.transferred,
        quantity: quantity,
        unit: unit,
        fruitCount: fruitCount,
        eventId: event.id,
        occurredAt: now,
        reason: '$fromLocationLabel -> $toLocationLabel. $cleanReason',
      ),
    );

    final batchIndex = _batches.indexWhere(
      (batch) => batch.code == cleanBatchCode,
    );
    if (batchIndex != -1) {
      final batch = _batches[batchIndex];
      _batches[batchIndex] = batch.copyWith(locationLabel: toLocationLabel);
    }

    _saveToLocal();
    notifyListeners();
    return true;
  }

  TraceHandover? createHandoverProposal({
    required String senderId,
    required TraceActorRole senderRole,
    required String senderName,
    required String receiverId,
    required TraceActorRole receiverRole,
    required String receiverName,
    required List<TraceHandoverDraftItem> items,
    TraceHandoverType type = TraceHandoverType.normal,
    String? sourceLocationLabel,
    String? destinationLocationLabel,
    Map<String, String> metadata = const {},
  }) {
    if (senderId.trim().isEmpty ||
        receiverId.trim().isEmpty ||
        items.isEmpty ||
        !_isValidDirection(senderRole, receiverRole)) {
      return null;
    }

    for (final item in items) {
      final batch = findBatch(item.batchCode);
      if (batch == null ||
          batch.currentHolderId != senderId ||
          batch.currentHolderRole != senderRole ||
          item.quantity <= 0 ||
          item.quantity > batch.availableQuantity) {
        return null;
      }
    }

    final now = DateTime.now();
    final handover = TraceHandover(
      id: _generateHandoverId(),
      senderId: senderId,
      senderRole: senderRole,
      senderName: senderName,
      receiverId: receiverId,
      receiverRole: receiverRole,
      receiverName: receiverName,
      status: TraceHandoverStatus.proposed,
      type: type,
      createdAt: now,
      sourceLocationLabel: sourceLocationLabel,
      destinationLocationLabel: destinationLocationLabel,
      metadata: metadata,
    );
    _handovers.add(handover);

    for (final draft in items) {
      final item = TraceHandoverItem(
        id: _generateHandoverItemId(),
        handoverId: handover.id,
        sourceBatchCode: draft.batchCode,
        proposedQuantity: draft.quantity,
        unit: draft.unit,
        proposedFruitCount: draft.fruitCount,
        note: draft.note,
      );
      _handoverItems.add(item);
      _events.add(
        _createEvent(
          batchCode: item.sourceBatchCode,
          type: TraceEventType.handoverProposed,
          actorId: senderId,
          actorRole: senderRole,
          actorName: senderName,
          title: 'T1 handover dibuat',
          description:
              '${item.sourceBatchCode} diajukan ke ${receiverRole.label} $receiverName.',
          occurredAt: now,
          locationLabel: sourceLocationLabel,
          relatedObjectId: handover.id,
          metadata: {
            'Handover': handover.id,
            'Receiver': receiverName,
            'Quantity': '${item.proposedQuantity} ${item.unit}',
            if (item.proposedFruitCount != null)
              'Jumlah': '${item.proposedFruitCount} butir',
          },
        ),
      );
    }

    _saveToLocal();
    notifyListeners();
    return handover;
  }

  bool confirmHandover(String handoverId) {
    final index = _handovers.indexWhere(
      (handover) =>
          handover.id == handoverId &&
          handover.status == TraceHandoverStatus.proposed,
    );
    if (index == -1) return false;

    final handover = _handovers[index];
    final items = _handoverItems
        .where((item) => item.handoverId == handover.id)
        .toList();
    if (items.isEmpty) return false;

    for (final item in items) {
      final batch = findBatch(item.sourceBatchCode);
      if (batch == null || item.proposedQuantity > batch.availableQuantity) {
        return false;
      }
    }

    final now = DateTime.now();
    for (final item in items) {
      final batchIndex = _batches.indexWhere(
        (batch) => batch.code == item.sourceBatchCode,
      );
      final batch = _batches[batchIndex];
      final event = _createEvent(
        batchCode: batch.code,
        type: TraceEventType.handoverConfirmed,
        actorId: handover.receiverId,
        actorRole: handover.receiverRole,
        actorName: handover.receiverName,
        title: 'T1 handover dikonfirmasi',
        description:
            '${handover.receiverName} mengonfirmasi reserve ${item.proposedQuantity} ${item.unit}.',
        occurredAt: now,
        locationLabel: handover.destinationLocationLabel,
        relatedObjectId: handover.id,
        metadata: {'Handover': handover.id},
      );
      _events.add(event);
      _movements.add(
        _createMovement(
          batchCode: batch.code,
          type: TraceQuantityMovementType.reserved,
          quantity: item.proposedQuantity,
          unit: item.unit,
          fruitCount: item.proposedFruitCount,
          handoverId: handover.id,
          handoverItemId: item.id,
          eventId: event.id,
          occurredAt: now,
          reason: 'Reserve T1 handover',
        ),
      );
      _batches[batchIndex] = batch.copyWith(
        reservedQuantity: batch.reservedQuantity + item.proposedQuantity,
      );
    }

    _handovers[index] = handover.copyWith(
      status: TraceHandoverStatus.confirmed,
      confirmedAt: now,
    );
    _saveToLocal();
    notifyListeners();
    return true;
  }

  TraceHandoverReceipt? receiveHandoverItem({
    required String handoverItemId,
    required double acceptedQuantity,
    required double rejectedQuantity,
    required double disputedQuantity,
    required String conditionLabel,
    int? acceptedFruitCount,
    int? rejectedFruitCount,
    int? disputedFruitCount,
    String? note,
    String? evidencePath,
  }) {
    final item = _findHandoverItem(handoverItemId);
    if (item == null ||
        acceptedQuantity < 0 ||
        rejectedQuantity < 0 ||
        disputedQuantity < 0 ||
        acceptedQuantity + rejectedQuantity + disputedQuantity >
            item.proposedQuantity) {
      return null;
    }

    final handoverIndex = _handovers.indexWhere(
      (handover) =>
          handover.id == item.handoverId &&
          (handover.status == TraceHandoverStatus.confirmed ||
              handover.status == TraceHandoverStatus.dispatched),
    );
    if (handoverIndex == -1) return null;
    if (_handoverReceipts.any((receipt) => receipt.handoverItemId == item.id)) {
      return null;
    }

    final sourceIndex = _batches.indexWhere(
      (batch) => batch.code == item.sourceBatchCode,
    );
    if (sourceIndex == -1) return null;

    final source = _batches[sourceIndex];
    if (acceptedQuantity > source.quantityCurrent ||
        item.proposedQuantity > source.reservedQuantity) {
      return null;
    }

    final handover = _handovers[handoverIndex];
    final now = DateTime.now();
    final receiverBatchCode = _generateReceivingBatchCode(
      handover.receiverRole,
    );
    final event = _createEvent(
      batchCode: source.code,
      type: TraceEventType.handoverReceived,
      actorId: handover.receiverId,
      actorRole: handover.receiverRole,
      actorName: handover.receiverName,
      title: 'T2 handover diterima',
      description:
          '${handover.receiverName} menerima $acceptedQuantity ${item.unit} dari ${source.code}.',
      occurredAt: now,
      locationLabel: handover.destinationLocationLabel,
      relatedObjectId: handover.id,
      metadata: {
        'Handover': handover.id,
        'Kondisi': conditionLabel,
        'Accepted': '$acceptedQuantity ${item.unit}',
        'Rejected': '$rejectedQuantity ${item.unit}',
        'Disputed': '$disputedQuantity ${item.unit}',
      },
    );
    _events.add(event);

    final receiverBatch = TraceBatch(
      code: receiverBatchCode,
      productName: source.productName,
      productForm: source.productForm,
      currentHolderId: handover.receiverId,
      currentHolderRole: handover.receiverRole,
      currentHolderName: handover.receiverName,
      originActorId: source.originActorId,
      originActorRole: source.originActorRole,
      originActorName: source.originActorName,
      quantityInitial: acceptedQuantity,
      quantityCurrent: acceptedQuantity,
      reservedQuantity: 0,
      unit: item.unit,
      fruitCountInitial: acceptedFruitCount,
      fruitCountCurrent: acceptedFruitCount,
      locationLabel: handover.destinationLocationLabel,
      publicLocationLabel: handover.destinationLocationLabel,
      sourceReference: source.code,
      createdAt: now,
      status: acceptedQuantity > 0
          ? TraceBatchStatus.active
          : TraceBatchStatus.depleted,
      metadata: {'Received from': source.code},
    );
    _batches.add(receiverBatch);

    final receipt = TraceHandoverReceipt(
      id: _generateReceiptId(),
      handoverItemId: item.id,
      sourceBatchCode: source.code,
      receiverBatchCode: receiverBatchCode,
      acceptedQuantity: acceptedQuantity,
      rejectedQuantity: rejectedQuantity,
      disputedQuantity: disputedQuantity,
      unit: item.unit,
      acceptedFruitCount: acceptedFruitCount,
      rejectedFruitCount: rejectedFruitCount,
      disputedFruitCount: disputedFruitCount,
      conditionLabel: conditionLabel,
      note: note,
      evidencePath: evidencePath,
      receivedAt: now,
    );
    _handoverReceipts.add(receipt);

    _relations.add(
      TraceBatchRelation(
        id: _generateRelationId(),
        sourceBatchCode: source.code,
        targetBatchCode: receiverBatchCode,
        type: TraceBatchRelationType.receivedFrom,
        quantity: acceptedQuantity,
        unit: item.unit,
        fruitCount: acceptedFruitCount,
        eventId: event.id,
        note: note,
        createdAt: now,
      ),
    );

    _movements.addAll([
      _createMovement(
        batchCode: source.code,
        type: TraceQuantityMovementType.reservationReleased,
        quantity: item.proposedQuantity,
        unit: item.unit,
        fruitCount: item.proposedFruitCount,
        handoverId: handover.id,
        handoverItemId: item.id,
        eventId: event.id,
        occurredAt: now,
        reason: 'T2 receipt selesai',
      ),
      _createMovement(
        batchCode: source.code,
        type: TraceQuantityMovementType.acceptedOut,
        quantity: acceptedQuantity,
        unit: item.unit,
        fruitCount: acceptedFruitCount,
        handoverId: handover.id,
        handoverItemId: item.id,
        eventId: event.id,
        occurredAt: now,
        reason: 'Accepted keluar ke penerima',
      ),
      _createMovement(
        batchCode: receiverBatchCode,
        type: TraceQuantityMovementType.acceptedIn,
        quantity: acceptedQuantity,
        unit: item.unit,
        fruitCount: acceptedFruitCount,
        handoverId: handover.id,
        handoverItemId: item.id,
        eventId: event.id,
        occurredAt: now,
        reason: 'Accepted masuk dari pengirim',
      ),
    ]);

    if (rejectedQuantity > 0) {
      _movements.add(
        _createMovement(
          batchCode: source.code,
          type: TraceQuantityMovementType.rejected,
          quantity: rejectedQuantity,
          unit: item.unit,
          fruitCount: rejectedFruitCount,
          handoverId: handover.id,
          handoverItemId: item.id,
          eventId: event.id,
          occurredAt: now,
          reason: note,
        ),
      );
    }
    if (disputedQuantity > 0) {
      _movements.add(
        _createMovement(
          batchCode: source.code,
          type: TraceQuantityMovementType.disputed,
          quantity: disputedQuantity,
          unit: item.unit,
          fruitCount: disputedFruitCount,
          handoverId: handover.id,
          handoverItemId: item.id,
          eventId: event.id,
          occurredAt: now,
          reason: note,
        ),
      );
    }

    final remainingCurrent = source.quantityCurrent - acceptedQuantity;
    _batches[sourceIndex] = source.copyWith(
      quantityCurrent: remainingCurrent < 0 ? 0 : remainingCurrent,
      reservedQuantity: source.reservedQuantity - item.proposedQuantity,
      status: remainingCurrent <= 0
          ? TraceBatchStatus.depleted
          : TraceBatchStatus.active,
    );

    final allItems = _handoverItems
        .where((candidate) => candidate.handoverId == handover.id)
        .toList();
    final allReceived = allItems.every(
      (candidate) => _handoverReceipts.any(
        (receipt) => receipt.handoverItemId == candidate.id,
      ),
    );
    _handovers[handoverIndex] = handover.copyWith(
      status: allReceived
          ? TraceHandoverStatus.completed
          : TraceHandoverStatus.received,
      completedAt: allReceived ? now : null,
    );

    _saveToLocal();
    notifyListeners();
    return receipt;
  }

  TraceHandoverItem? _findHandoverItem(String id) {
    try {
      return _handoverItems.firstWhere((item) => item.id == id);
    } catch (_) {
      return null;
    }
  }

  bool _isValidDirection(TraceActorRole sender, TraceActorRole receiver) {
    switch (sender) {
      case TraceActorRole.farmer:
        return {
          TraceActorRole.collector,
          TraceActorRole.distributor,
          TraceActorRole.umkm,
          TraceActorRole.consumer,
        }.contains(receiver);
      case TraceActorRole.collector:
        return {
          TraceActorRole.collector,
          TraceActorRole.distributor,
          TraceActorRole.umkm,
          TraceActorRole.consumer,
        }.contains(receiver);
      case TraceActorRole.distributor:
        return {
          TraceActorRole.distributor,
          TraceActorRole.umkm,
          TraceActorRole.consumer,
        }.contains(receiver);
      case TraceActorRole.umkm:
        return receiver == TraceActorRole.consumer;
      case TraceActorRole.consumer:
      case TraceActorRole.admin:
      case TraceActorRole.system:
        return false;
    }
  }

  TraceBatchEvent _createEvent({
    required String batchCode,
    required TraceEventType type,
    required String actorId,
    required TraceActorRole actorRole,
    required String actorName,
    required String title,
    required String description,
    required DateTime occurredAt,
    String? locationLabel,
    String? relatedObjectId,
    Map<String, String> metadata = const {},
  }) {
    _eventCounter++;
    return TraceBatchEvent(
      id: 'EVT-${_eventCounter.toString().padLeft(8, '0')}',
      batchCode: batchCode,
      type: type,
      actorId: actorId,
      actorRole: actorRole,
      actorName: actorName,
      title: title,
      description: description,
      occurredAt: occurredAt,
      locationLabel: locationLabel,
      relatedObjectId: relatedObjectId,
      metadata: metadata,
    );
  }

  TraceQuantityMovement _createMovement({
    required String batchCode,
    required TraceQuantityMovementType type,
    required double quantity,
    required String unit,
    required DateTime occurredAt,
    int? fruitCount,
    String? handoverId,
    String? handoverItemId,
    String? eventId,
    String? reason,
  }) {
    _movementCounter++;
    return TraceQuantityMovement(
      id: 'QMV-${_movementCounter.toString().padLeft(8, '0')}',
      batchCode: batchCode,
      type: type,
      quantity: quantity,
      unit: unit,
      fruitCount: fruitCount,
      handoverId: handoverId,
      handoverItemId: handoverItemId,
      eventId: eventId,
      reason: reason,
      occurredAt: occurredAt,
    );
  }

  String _generateHandoverId() {
    _handoverCounter++;
    final year = DateTime.now().year;
    final seq = _handoverCounter.toString().padLeft(6, '0');
    return 'HOV-$year-$seq';
  }

  String _generateHandoverItemId() {
    _handoverItemCounter++;
    return 'HOI-${_handoverItemCounter.toString().padLeft(8, '0')}';
  }

  String _generateReceiptId() {
    _receiptCounter++;
    return 'HRC-${_receiptCounter.toString().padLeft(8, '0')}';
  }

  String _generateRelationId() {
    _relationCounter++;
    return 'REL-${_relationCounter.toString().padLeft(8, '0')}';
  }

  String _generateReceivingBatchCode(TraceActorRole role) {
    _receivingBatchCounter++;
    final year = DateTime.now().year;
    final seq = _receivingBatchCounter.toString().padLeft(6, '0');
    final prefix = switch (role) {
      TraceActorRole.collector => 'PGL',
      TraceActorRole.distributor => 'DST',
      TraceActorRole.umkm => 'UMK',
      TraceActorRole.consumer => 'CNS',
      TraceActorRole.farmer => 'DRN',
      TraceActorRole.admin || TraceActorRole.system => 'TRC',
    };
    return '$prefix-$year-$seq';
  }
}
