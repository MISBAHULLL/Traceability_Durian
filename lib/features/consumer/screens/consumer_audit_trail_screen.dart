import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_top_bar.dart';
import '../data/consumer_repository.dart';
import '../models/consumer_audit_entry.dart';

class ConsumerAuditTrailScreen extends StatefulWidget {
  const ConsumerAuditTrailScreen({super.key});

  @override
  State<ConsumerAuditTrailScreen> createState() =>
      _ConsumerAuditTrailScreenState();
}

class _ConsumerAuditTrailScreenState extends State<ConsumerAuditTrailScreen> {
  final _repo = ConsumerRepository.instance;
  final _searchController = TextEditingController();
  String _query = '';
  String _actor = 'Semua aktor';
  ConsumerAuditEventType? _type;
  ConsumerAuditPeriodFilter _period = ConsumerAuditPeriodFilter.all;

  @override
  void initState() {
    super.initState();
    _repo.addListener(_onRepoChanged);
    _searchController.addListener(() {
      setState(() => _query = _searchController.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _repo.removeListener(_onRepoChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onRepoChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final allEntries = _repo.auditEntries;
    final actors = [
      'Semua aktor',
      ...{
        for (final entry in allEntries)
          if (entry.actorName.trim().isNotEmpty) entry.actorName.trim(),
      },
    ];
    if (!actors.contains(_actor)) _actor = actors.first;

    final cutoff = _period.cutoff(DateTime.now());
    final entries = allEntries.where((entry) {
      if (_type != null && entry.type != _type) return false;
      if (_actor != 'Semua aktor' && entry.actorName != _actor) return false;
      if (cutoff != null && entry.occurredAt.isBefore(cutoff)) return false;
      return entry.matchesQuery(_query);
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            const AppTopBar(title: 'Audit Trail Konsumen'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                children: [
                  _AuditSummary(
                    visibleCount: entries.length,
                    totalCount: allEntries.length,
                  ),
                  const SizedBox(height: 14),
                  _SearchField(controller: _searchController),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _TypeDropdown(
                          value: _type,
                          onChanged: (value) => setState(() => _type = value),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _ActorDropdown(
                          value: _actor,
                          actors: actors,
                          onChanged: (value) =>
                              setState(() => _actor = value ?? actors.first),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _PeriodChips(
                    active: _period,
                    onChanged: (value) => setState(() => _period = value),
                  ),
                  const SizedBox(height: 18),
                  if (entries.isEmpty)
                    const _EmptyAuditState()
                  else
                    ...entries.map(
                      (entry) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _AuditCard(entry: entry),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AuditSummary extends StatelessWidget {
  const _AuditSummary({required this.visibleCount, required this.totalCount});

  final int visibleCount;
  final int totalCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.20)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.fact_check_outlined,
              color: AppColors.primary,
              size: 21,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$visibleCount dari $totalCount event',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: AppColors.black,
                  ),
                ),
                const SizedBox(height: 3),
                const Text(
                  'Scan, transaksi, pembayaran, penerimaan, dan penolakan.',
                  style: TextStyle(
                    fontSize: 11,
                    height: 1.35,
                    color: AppColors.placeholder,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      style: const TextStyle(fontSize: 14, color: AppColors.black),
      decoration: InputDecoration(
        hintText: 'Cari kode, produk, transaksi, aktor, atau catatan',
        hintStyle: const TextStyle(fontSize: 13, color: AppColors.placeholder),
        prefixIcon: const Icon(
          Icons.search_rounded,
          color: AppColors.placeholder,
          size: 22,
        ),
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class _TypeDropdown extends StatelessWidget {
  const _TypeDropdown({required this.value, required this.onChanged});

  final ConsumerAuditEventType? value;
  final ValueChanged<ConsumerAuditEventType?> onChanged;

  @override
  Widget build(BuildContext context) {
    return _FilterShell(
      child: DropdownButtonHideUnderline(
        child: DropdownButton<ConsumerAuditEventType?>(
          value: value,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded),
          items: [
            const DropdownMenuItem<ConsumerAuditEventType?>(
              value: null,
              child: Text('Semua tipe'),
            ),
            ...ConsumerAuditEventType.values.map(
              (type) => DropdownMenuItem<ConsumerAuditEventType?>(
                value: type,
                child: Text(type.label),
              ),
            ),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _ActorDropdown extends StatelessWidget {
  const _ActorDropdown({
    required this.value,
    required this.actors,
    required this.onChanged,
  });

  final String value;
  final List<String> actors;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return _FilterShell(
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded),
          items: actors
              .map(
                (actor) =>
                    DropdownMenuItem<String>(value: actor, child: Text(actor)),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _FilterShell extends StatelessWidget {
  const _FilterShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: DefaultTextStyle(
        style: const TextStyle(
          fontSize: 13,
          color: AppColors.black,
          fontWeight: FontWeight.w600,
        ),
        overflow: TextOverflow.ellipsis,
        child: child,
      ),
    );
  }
}

class _PeriodChips extends StatelessWidget {
  const _PeriodChips({required this.active, required this.onChanged});

  final ConsumerAuditPeriodFilter active;
  final ValueChanged<ConsumerAuditPeriodFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: ConsumerAuditPeriodFilter.values.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final item = ConsumerAuditPeriodFilter.values[index];
          final selected = item == active;
          return ChoiceChip(
            label: Text(item.label),
            selected: selected,
            onSelected: (_) => onChanged(item),
            selectedColor: AppColors.primary.withValues(alpha: 0.14),
            backgroundColor: AppColors.white,
            side: BorderSide(
              color: selected ? AppColors.primary : const Color(0xFFE5E7EB),
            ),
            labelStyle: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: selected ? AppColors.primary : AppColors.subtitle,
            ),
          );
        },
      ),
    );
  }
}

class _AuditCard extends StatelessWidget {
  const _AuditCard({required this.entry});

  final ConsumerAuditEntry entry;

  Color get _color {
    switch (entry.type) {
      case ConsumerAuditEventType.receiptAccepted:
      case ConsumerAuditEventType.paymentVerified:
      case ConsumerAuditEventType.orderCompleted:
        return AppColors.primary;
      case ConsumerAuditEventType.receiptRejected:
        return const Color(0xFFDC2626);
      case ConsumerAuditEventType.paymentConfirmed:
        return const Color(0xFFB45309);
      case ConsumerAuditEventType.scan:
      case ConsumerAuditEventType.transactionCreated:
        return const Color(0xFF2563EB);
    }
  }

  IconData get _icon {
    switch (entry.type) {
      case ConsumerAuditEventType.scan:
        return Icons.qr_code_scanner_rounded;
      case ConsumerAuditEventType.transactionCreated:
        return Icons.receipt_long_rounded;
      case ConsumerAuditEventType.paymentConfirmed:
        return Icons.payments_rounded;
      case ConsumerAuditEventType.paymentVerified:
        return Icons.verified_rounded;
      case ConsumerAuditEventType.receiptAccepted:
        return Icons.inventory_2_rounded;
      case ConsumerAuditEventType.receiptRejected:
        return Icons.block_rounded;
      case ConsumerAuditEventType.orderCompleted:
        return Icons.task_alt_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: _color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(_icon, color: _color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        entry.title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: AppColors.black,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        entry.type.label,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: _color,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${entry.actorName} / ${_formatDateTime(entry.occurredAt)}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.placeholder,
                  ),
                ),
                if (entry.description != null &&
                    entry.description!.trim().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    entry.description!,
                    style: const TextStyle(
                      fontSize: 12,
                      height: 1.35,
                      color: AppColors.subtitle,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    if (entry.referenceCode != null)
                      _MetaChip(label: 'Ref', value: entry.referenceCode!),
                    if (entry.batchCode != null)
                      _MetaChip(label: 'Kode', value: entry.batchCode!),
                    ...entry.metadata.entries.map(
                      (item) => _MetaChip(label: item.key, value: item.value),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}, $h:$m';
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$label: $value',
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: AppColors.subtitle,
        ),
      ),
    );
  }
}

class _EmptyAuditState extends StatelessWidget {
  const _EmptyAuditState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 34),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Text(
        'Tidak ada audit yang cocok dengan filter saat ini.',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 13,
          height: 1.4,
          color: AppColors.placeholder,
        ),
      ),
    );
  }
}
