enum ConsumerAuditEventType {
  scan,
  transactionCreated,
  paymentConfirmed,
  paymentVerified,
  receiptAccepted,
  receiptRejected,
  orderCompleted,
}

extension ConsumerAuditEventTypeLabel on ConsumerAuditEventType {
  String get label {
    switch (this) {
      case ConsumerAuditEventType.scan:
        return 'Scan';
      case ConsumerAuditEventType.transactionCreated:
        return 'Transaksi';
      case ConsumerAuditEventType.paymentConfirmed:
        return 'Konfirmasi Bayar';
      case ConsumerAuditEventType.paymentVerified:
        return 'Verifikasi Bayar';
      case ConsumerAuditEventType.receiptAccepted:
        return 'Penerimaan';
      case ConsumerAuditEventType.receiptRejected:
        return 'Penolakan';
      case ConsumerAuditEventType.orderCompleted:
        return 'Order Selesai';
    }
  }
}

ConsumerAuditEventType consumerAuditEventTypeFromJson(Object? value) {
  return ConsumerAuditEventType.values.firstWhere(
    (type) => type.name == value,
    orElse: () => ConsumerAuditEventType.transactionCreated,
  );
}

enum ConsumerAuditPeriodFilter { all, today, sevenDays, thirtyDays }

extension ConsumerAuditPeriodFilterLabel on ConsumerAuditPeriodFilter {
  String get label {
    switch (this) {
      case ConsumerAuditPeriodFilter.all:
        return 'Semua';
      case ConsumerAuditPeriodFilter.today:
        return 'Hari ini';
      case ConsumerAuditPeriodFilter.sevenDays:
        return '7 hari';
      case ConsumerAuditPeriodFilter.thirtyDays:
        return '30 hari';
    }
  }

  DateTime? cutoff(DateTime now) {
    switch (this) {
      case ConsumerAuditPeriodFilter.all:
        return null;
      case ConsumerAuditPeriodFilter.today:
        return DateTime(now.year, now.month, now.day);
      case ConsumerAuditPeriodFilter.sevenDays:
        return now.subtract(const Duration(days: 7));
      case ConsumerAuditPeriodFilter.thirtyDays:
        return now.subtract(const Duration(days: 30));
    }
  }
}

class ConsumerAuditEntry {
  const ConsumerAuditEntry({
    required this.id,
    required this.type,
    required this.title,
    required this.actorName,
    required this.occurredAt,
    this.referenceCode,
    this.batchCode,
    this.description,
    this.metadata = const {},
  });

  final String id;
  final ConsumerAuditEventType type;
  final String title;
  final String actorName;
  final DateTime occurredAt;
  final String? referenceCode;
  final String? batchCode;
  final String? description;
  final Map<String, String> metadata;

  bool matchesQuery(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    final haystack = [
      id,
      type.label,
      title,
      actorName,
      referenceCode,
      batchCode,
      description,
      ...metadata.entries.map((entry) => '${entry.key} ${entry.value}'),
    ].whereType<String>().join(' ').toLowerCase();
    return haystack.contains(q);
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'title': title,
    'actorName': actorName,
    'occurredAt': occurredAt.toIso8601String(),
    'referenceCode': referenceCode,
    'batchCode': batchCode,
    'description': description,
    'metadata': metadata,
  };

  factory ConsumerAuditEntry.fromJson(Map<String, dynamic> json) {
    final rawMetadata = json['metadata'];
    return ConsumerAuditEntry(
      id: json['id'] as String? ?? '',
      type: consumerAuditEventTypeFromJson(json['type']),
      title: json['title'] as String? ?? 'Aktivitas konsumen',
      actorName: json['actorName'] as String? ?? 'Konsumen',
      occurredAt:
          DateTime.tryParse(json['occurredAt'] as String? ?? '') ??
          DateTime.now(),
      referenceCode: json['referenceCode'] as String?,
      batchCode: json['batchCode'] as String?,
      description: json['description'] as String?,
      metadata: rawMetadata is Map
          ? rawMetadata.map(
              (key, value) => MapEntry(key.toString(), value.toString()),
            )
          : const {},
    );
  }
}
