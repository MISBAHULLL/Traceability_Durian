import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_top_bar.dart';
import '../data/umkm_repository.dart';
import '../models/umkm_audit_entry.dart';

class UmkmAuditTrailScreen extends StatefulWidget {
  const UmkmAuditTrailScreen({super.key});

  @override
  State<UmkmAuditTrailScreen> createState() => _UmkmAuditTrailScreenState();
}

class _UmkmAuditTrailScreenState extends State<UmkmAuditTrailScreen> {
  final _repo = UmkmRepository.instance;
  final _searchController = TextEditingController();
  String _query = '';
  String _actor = 'Semua aktor';
  UmkmAuditEventType? _type;
  UmkmAuditPeriodFilter _period = UmkmAuditPeriodFilter.all;

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

    final now = DateTime.now();
    final cutoff = _period.cutoff(now);
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
            const AppTopBar(title: 'Audit Trail UMKM'),
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
                  'Penerimaan, penolakan, produksi, mutasi bahan, dan penjualan.',
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
        hintText: 'Cari batch, produk, order, aktor, atau catatan',
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

  final UmkmAuditEventType? value;
  final ValueChanged<UmkmAuditEventType?> onChanged;

  @override
  Widget build(BuildContext context) {
    return _FilterShell(
      child: DropdownButtonHideUnderline(
        child: DropdownButton<UmkmAuditEventType?>(
          value: value,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded),
          items: [
            const DropdownMenuItem<UmkmAuditEventType?>(
              value: null,
              child: Text('Semua tipe'),
            ),
            ...UmkmAuditEventType.values.map(
              (type) => DropdownMenuItem<UmkmAuditEventType?>(
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
                (actor) => DropdownMenuItem<String>(
                  value: actor,
                  child: Text(
                    actor,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
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
      alignment: Alignment.center,
      child: DefaultTextStyle(
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppColors.black,
        ),
        child: child,
      ),
    );
  }
}

class _PeriodChips extends StatelessWidget {
  const _PeriodChips({required this.active, required this.onChanged});

  final UmkmAuditPeriodFilter active;
  final ValueChanged<UmkmAuditPeriodFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: UmkmAuditPeriodFilter.values.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final item = UmkmAuditPeriodFilter.values[index];
          final selected = item == active;
          return ChoiceChip(
            label: Text(item.label),
            selected: selected,
            showCheckmark: false,
            onSelected: (_) => onChanged(item),
            selectedColor: AppColors.primary,
            backgroundColor: AppColors.surface,
            labelStyle: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: selected ? AppColors.white : AppColors.black,
            ),
            side: BorderSide(
              color: selected ? AppColors.primary : const Color(0xFFE5E7EB),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(999),
            ),
          );
        },
      ),
    );
  }
}

class _AuditCard extends StatelessWidget {
  const _AuditCard({required this.entry});

  final UmkmAuditEntry entry;

  Color get _color {
    switch (entry.type) {
      case UmkmAuditEventType.receiptAccepted:
      case UmkmAuditEventType.production:
      case UmkmAuditEventType.sale:
        return AppColors.primary;
      case UmkmAuditEventType.receiptRejected:
        return const Color(0xFFDC2626);
      case UmkmAuditEventType.materialMovement:
        return const Color(0xFF1D4ED8);
      case UmkmAuditEventType.scan:
      case UmkmAuditEventType.order:
      case UmkmAuditEventType.traceEvent:
        return const Color(0xFF6B7280);
    }
  }

  IconData get _icon {
    switch (entry.type) {
      case UmkmAuditEventType.scan:
        return Icons.qr_code_scanner_rounded;
      case UmkmAuditEventType.receiptAccepted:
        return Icons.assignment_turned_in_outlined;
      case UmkmAuditEventType.receiptRejected:
        return Icons.cancel_outlined;
      case UmkmAuditEventType.production:
        return Icons.blender_outlined;
      case UmkmAuditEventType.materialMovement:
        return Icons.swap_vert_rounded;
      case UmkmAuditEventType.sale:
        return Icons.point_of_sale_rounded;
      case UmkmAuditEventType.order:
        return Icons.shopping_bag_outlined;
      case UmkmAuditEventType.traceEvent:
        return Icons.account_tree_outlined;
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
          SizedBox(
            width: 46,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _formatShortDate(entry.occurredAt),
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 11,
                    height: 1.15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.black,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _formatTime(entry.occurredAt),
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.placeholder,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: _color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(_icon, color: _color, size: 19),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        entry.title,
                        style: const TextStyle(
                          fontSize: 13,
                          height: 1.3,
                          fontWeight: FontWeight.w900,
                          color: AppColors.black,
                        ),
                      ),
                    ),
                    _TypePill(label: entry.type.label, color: _color),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  entry.actorName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.subtitle,
                  ),
                ),
                if (entry.description != null &&
                    entry.description!.trim().isNotEmpty) ...[
                  const SizedBox(height: 5),
                  Text(
                    entry.description!.trim(),
                    style: const TextStyle(
                      fontSize: 11,
                      height: 1.35,
                      color: AppColors.placeholder,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    if (entry.batchCode != null &&
                        entry.batchCode!.trim().isNotEmpty)
                      _MiniChip(label: entry.batchCode!.trim()),
                    if (entry.referenceCode != null &&
                        entry.referenceCode!.trim().isNotEmpty)
                      _MiniChip(label: entry.referenceCode!.trim()),
                    ...entry.metadata.entries
                        .take(3)
                        .map(
                          (item) =>
                              _MiniChip(label: '${item.key}: ${item.value}'),
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
}

class _TypePill extends StatelessWidget {
  const _TypePill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w900,
          color: color,
        ),
      ),
    );
  }
}

class _MiniChip extends StatelessWidget {
  const _MiniChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
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
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: const Text(
        'Tidak ada audit yang cocok dengan filter saat ini.',
        style: TextStyle(
          fontSize: 12,
          height: 1.45,
          fontWeight: FontWeight.w700,
          color: Color(0xFF92400E),
        ),
      ),
    );
  }
}

String _formatShortDate(DateTime date) {
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
  return '${date.day} ${months[date.month - 1]}';
}

String _formatTime(DateTime date) {
  final h = date.hour.toString().padLeft(2, '0');
  final m = date.minute.toString().padLeft(2, '0');
  return '$h:$m';
}
