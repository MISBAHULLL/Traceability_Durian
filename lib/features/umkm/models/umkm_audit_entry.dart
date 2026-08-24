enum UmkmAuditEventType {
  scan,
  receiptAccepted,
  receiptRejected,
  production,
  materialMovement,
  sale,
  order,
  traceEvent,
}

extension UmkmAuditEventTypeLabel on UmkmAuditEventType {
  String get label {
    switch (this) {
      case UmkmAuditEventType.scan:
        return 'Scan';
      case UmkmAuditEventType.receiptAccepted:
        return 'Penerimaan';
      case UmkmAuditEventType.receiptRejected:
        return 'Penolakan';
      case UmkmAuditEventType.production:
        return 'Produksi';
      case UmkmAuditEventType.materialMovement:
        return 'Mutasi Bahan';
      case UmkmAuditEventType.sale:
        return 'Penjualan';
      case UmkmAuditEventType.order:
        return 'Order';
      case UmkmAuditEventType.traceEvent:
        return 'Trace Event';
    }
  }
}

enum UmkmAuditPeriodFilter { all, today, sevenDays, thirtyDays }

extension UmkmAuditPeriodFilterLabel on UmkmAuditPeriodFilter {
  String get label {
    switch (this) {
      case UmkmAuditPeriodFilter.all:
        return 'Semua';
      case UmkmAuditPeriodFilter.today:
        return 'Hari ini';
      case UmkmAuditPeriodFilter.sevenDays:
        return '7 hari';
      case UmkmAuditPeriodFilter.thirtyDays:
        return '30 hari';
    }
  }

  DateTime? cutoff(DateTime now) {
    switch (this) {
      case UmkmAuditPeriodFilter.all:
        return null;
      case UmkmAuditPeriodFilter.today:
        return DateTime(now.year, now.month, now.day);
      case UmkmAuditPeriodFilter.sevenDays:
        return now.subtract(const Duration(days: 7));
      case UmkmAuditPeriodFilter.thirtyDays:
        return now.subtract(const Duration(days: 30));
    }
  }
}

class UmkmAuditEntry {
  const UmkmAuditEntry({
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
  final UmkmAuditEventType type;
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
}
