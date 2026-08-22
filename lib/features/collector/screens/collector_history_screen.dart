import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_top_bar.dart';
import '../data/collector_repository.dart';
import '../models/collector_audit_event.dart';

const _pageBackground = Color(0xFFF4F6F3);
const _borderColor = Color(0xFFE1E6DF);

enum _AuditPeriod { all, today, sevenDays, thirtyDays }

extension _AuditPeriodX on _AuditPeriod {
  String get label {
    switch (this) {
      case _AuditPeriod.all:
        return 'Semua';
      case _AuditPeriod.today:
        return 'Hari ini';
      case _AuditPeriod.sevenDays:
        return '7 hari';
      case _AuditPeriod.thirtyDays:
        return '30 hari';
    }
  }

  bool matches(DateTime value) {
    final now = DateTime.now();
    switch (this) {
      case _AuditPeriod.all:
        return true;
      case _AuditPeriod.today:
        return value.year == now.year &&
            value.month == now.month &&
            value.day == now.day;
      case _AuditPeriod.sevenDays:
        return !value.isBefore(now.subtract(const Duration(days: 7)));
      case _AuditPeriod.thirtyDays:
        return !value.isBefore(now.subtract(const Duration(days: 30)));
    }
  }
}

// [FE - Component Rendering] Audit trail formal pengepul. Semua aksi utama
// ditampilkan dalam satu timeline agar bisa difilter berdasarkan aktor,
// periode, tipe event, kode batch/PGL, dan kategori aksi.
class CollectorHistoryScreen extends StatefulWidget {
  const CollectorHistoryScreen({super.key});

  @override
  State<CollectorHistoryScreen> createState() => _CollectorHistoryScreenState();
}

class _CollectorHistoryScreenState extends State<CollectorHistoryScreen> {
  final _repo = CollectorRepository.instance;
  final _searchCtrl = TextEditingController();

  CollectorAuditEventType? _selectedType;
  String? _selectedActor;
  _AuditPeriod _period = _AuditPeriod.all;

  @override
  void initState() {
    super.initState();
    _repo.addListener(_onRepoChanged);
    _searchCtrl.addListener(_onRepoChanged);
  }

  @override
  void dispose() {
    _repo.removeListener(_onRepoChanged);
    _searchCtrl.removeListener(_onRepoChanged);
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onRepoChanged() {
    if (mounted) setState(() {});
  }

  List<CollectorAuditEvent> _filteredEvents(List<CollectorAuditEvent> events) {
    final query = _searchCtrl.text.trim().toLowerCase();
    return events.where((event) {
      final matchesQuery =
          query.isEmpty ||
          event.objectCode.toLowerCase().contains(query) ||
          event.action.toLowerCase().contains(query) ||
          event.description.toLowerCase().contains(query) ||
          event.metadata.values.any(
            (value) => value.toLowerCase().contains(query),
          );
      final matchesType = _selectedType == null || event.type == _selectedType;
      final matchesActor =
          _selectedActor == null || event.actorName == _selectedActor;
      final matchesPeriod = _period.matches(event.occurredAt);
      return matchesQuery && matchesType && matchesActor && matchesPeriod;
    }).toList();
  }

  void _clearFilters() {
    _searchCtrl.clear();
    setState(() {
      _selectedType = null;
      _selectedActor = null;
      _period = _AuditPeriod.all;
    });
  }

  @override
  Widget build(BuildContext context) {
    final allEvents = _repo.auditEvents;
    final actors = allEvents.map((event) => event.actorName).toSet().toList()
      ..sort();
    final visibleEvents = _filteredEvents(allEvents);

    return Scaffold(
      backgroundColor: _pageBackground,
      body: SafeArea(
        child: Column(
          children: [
            const ColoredBox(
              color: AppColors.white,
              child: AppTopBar(title: 'Audit Trail Pengepul'),
            ),
            _AuditFilterPanel(
              searchCtrl: _searchCtrl,
              selectedType: _selectedType,
              selectedActor: _selectedActor,
              actors: actors,
              period: _period,
              totalCount: allEvents.length,
              visibleCount: visibleEvents.length,
              onTypeChanged: (value) => setState(() => _selectedType = value),
              onActorChanged: (value) => setState(() => _selectedActor = value),
              onPeriodChanged: (value) => setState(() => _period = value),
              onClear: _clearFilters,
            ),
            Expanded(
              child: visibleEvents.isEmpty
                  ? const _EmptyAuditState()
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
                      itemCount: visibleEvents.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        return _AuditEventCard(event: visibleEvents[index]);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AuditFilterPanel extends StatelessWidget {
  const _AuditFilterPanel({
    required this.searchCtrl,
    required this.selectedType,
    required this.selectedActor,
    required this.actors,
    required this.period,
    required this.totalCount,
    required this.visibleCount,
    required this.onTypeChanged,
    required this.onActorChanged,
    required this.onPeriodChanged,
    required this.onClear,
  });

  final TextEditingController searchCtrl;
  final CollectorAuditEventType? selectedType;
  final String? selectedActor;
  final List<String> actors;
  final _AuditPeriod period;
  final int totalCount;
  final int visibleCount;
  final ValueChanged<CollectorAuditEventType?> onTypeChanged;
  final ValueChanged<String?> onActorChanged;
  final ValueChanged<_AuditPeriod> onPeriodChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '$visibleCount dari $totalCount event',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppColors.subtitle,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: onClear,
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Reset'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: searchCtrl,
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(
              hintText: 'Cari kode batch/PGL, aksi, atau catatan',
              prefixIcon: const Icon(Icons.search_rounded, size: 20),
              filled: true,
              fillColor: _pageBackground,
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: _borderColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: _borderColor),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<CollectorAuditEventType?>(
                  initialValue: selectedType,
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('Semua tipe'),
                    ),
                    ...CollectorAuditEventType.values.map(
                      (type) => DropdownMenuItem(
                        value: type,
                        child: Text(type.label),
                      ),
                    ),
                  ],
                  onChanged: onTypeChanged,
                  decoration: _filterDecoration('Tipe event'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: DropdownButtonFormField<String?>(
                  initialValue: selectedActor,
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('Semua aktor'),
                    ),
                    ...actors.map(
                      (actor) =>
                          DropdownMenuItem(value: actor, child: Text(actor)),
                    ),
                  ],
                  onChanged: onActorChanged,
                  decoration: _filterDecoration('Aktor'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _AuditPeriod.values.map((item) {
                final selected = item == period;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    selected: selected,
                    label: Text(item.label),
                    onSelected: (_) => onPeriodChanged(item),
                    selectedColor: const Color(0xFFEAF4E6),
                    backgroundColor: AppColors.white,
                    side: BorderSide(
                      color: selected ? AppColors.primary : _borderColor,
                    ),
                    labelStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: selected ? AppColors.primary : AppColors.subtitle,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _filterDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: _pageBackground,
      isDense: true,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: _borderColor),
      ),
    );
  }
}

class _AuditEventCard extends StatelessWidget {
  const _AuditEventCard({required this.event});

  final CollectorAuditEvent event;

  @override
  Widget build(BuildContext context) {
    final color = _colorForType(event.type);
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _AuditIcon(type: event.type, color: color),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.objectCode,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        event.action,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: AppColors.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        event.description,
                        style: const TextStyle(
                          fontSize: 12,
                          height: 1.35,
                          color: AppColors.subtitle,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _TypeBadge(label: event.type.label, color: color),
              ],
            ),
          ),
          const Divider(height: 1, color: _borderColor),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 11, 14, 12),
            child: Column(
              children: [
                _InfoRow(
                  label: 'Waktu',
                  value: _formatDateTime(event.occurredAt),
                ),
                _InfoRow(
                  label: 'Aktor',
                  value: '${event.actorRole} - ${event.actorName}',
                ),
                if (event.locationLabel?.trim().isNotEmpty == true)
                  _InfoRow(label: 'Lokasi', value: event.locationLabel!.trim()),
                if (event.statusLabel?.trim().isNotEmpty == true)
                  _InfoRow(label: 'Status', value: event.statusLabel!.trim()),
              ],
            ),
          ),
          if (event.metadata.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
              decoration: const BoxDecoration(
                color: Color(0xFFF8F9F7),
                border: Border(top: BorderSide(color: _borderColor)),
              ),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: event.metadata.entries.map((entry) {
                  return _MetadataPill(label: entry.key, value: entry.value);
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Color _colorForType(CollectorAuditEventType type) {
    switch (type) {
      case CollectorAuditEventType.purchase:
        return const Color(0xFF1D6FA4);
      case CollectorAuditEventType.receipt:
        return AppColors.primary;
      case CollectorAuditEventType.rejection:
        return const Color(0xFFC83B3B);
      case CollectorAuditEventType.grading:
        return const Color(0xFF7C3AED);
      case CollectorAuditEventType.shipment:
        return const Color(0xFF0F766E);
      case CollectorAuditEventType.incoming:
        return const Color(0xFF2563EB);
      case CollectorAuditEventType.warehouse:
        return const Color(0xFFB45309);
      case CollectorAuditEventType.transfer:
        return const Color(0xFF475569);
    }
  }
}

class _AuditIcon extends StatelessWidget {
  const _AuditIcon({required this.type, required this.color});

  final CollectorAuditEventType type;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final icon = switch (type) {
      CollectorAuditEventType.purchase => Icons.qr_code_scanner_rounded,
      CollectorAuditEventType.receipt => Icons.fact_check_outlined,
      CollectorAuditEventType.rejection => Icons.close_rounded,
      CollectorAuditEventType.grading => Icons.grading_outlined,
      CollectorAuditEventType.shipment => Icons.local_shipping_outlined,
      CollectorAuditEventType.incoming => Icons.move_to_inbox_outlined,
      CollectorAuditEventType.warehouse => Icons.warehouse_outlined,
      CollectorAuditEventType.transfer => Icons.swap_horiz_rounded,
    };
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, size: 21, color: color),
    );
  }
}

class _TypeBadge extends StatelessWidget {
  const _TypeBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 82,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.placeholder,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 11,
                height: 1.35,
                fontWeight: FontWeight.w700,
                color: AppColors.subtitle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetadataPill extends StatelessWidget {
  const _MetadataPill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _borderColor),
      ),
      child: Text(
        '$label: $value',
        style: const TextStyle(
          fontSize: 11,
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
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(28),
        child: Text(
          'Tidak ada event audit yang cocok dengan filter.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: AppColors.placeholder),
        ),
      ),
    );
  }
}

String _formatDateTime(DateTime date) {
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
  final hour = date.hour.toString().padLeft(2, '0');
  final minute = date.minute.toString().padLeft(2, '0');
  return '${date.day} ${months[date.month - 1]} ${date.year}, $hour:$minute';
}
