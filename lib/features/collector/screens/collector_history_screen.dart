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
      body: Column(
        children: [
          const ColoredBox(
            color: AppColors.white,
            child: SafeArea(
              bottom: false,
              child: AppTopBar(title: 'Audit Trail Pengepul'),
            ),
          ),
          Expanded(
            child: SafeArea(
              top: false,
              child: Column(
                children: [
                  _AuditFilterPanel(
                    searchCtrl: _searchCtrl,
                    selectedType: _selectedType,
                    selectedActor: _selectedActor,
                    actors: actors,
                    period: _period,
                    totalCount: allEvents.length,
                    visibleCount: visibleEvents.length,
                    onTypeChanged: (value) =>
                        setState(() => _selectedType = value),
                    onActorChanged: (value) =>
                        setState(() => _selectedActor = value),
                    onPeriodChanged: (value) => setState(() => _period = value),
                    onClear: _clearFilters,
                  ),
                  Expanded(
                    child: visibleEvents.isEmpty
                        ? const _EmptyAuditState()
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                            itemCount: visibleEvents.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              return _AuditEventCard(
                                event: visibleEvents[index],
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
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
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.tune_rounded,
                  size: 19,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Filter Audit',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: AppColors.black,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$visibleCount dari $totalCount event ditampilkan',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.placeholder,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onClear,
                tooltip: 'Reset filter',
                visualDensity: VisualDensity.compact,
                icon: const Icon(
                  Icons.refresh_rounded,
                  size: 20,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 46,
            child: TextField(
              controller: searchCtrl,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                hintText: 'Cari kode batch, PGL, atau aktivitas',
                hintStyle: const TextStyle(
                  fontSize: 12,
                  color: AppColors.placeholder,
                ),
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                suffixIcon: searchCtrl.text.isEmpty
                    ? null
                    : IconButton(
                        onPressed: searchCtrl.clear,
                        tooltip: 'Hapus pencarian',
                        icon: const Icon(Icons.close_rounded, size: 18),
                      ),
                filled: true,
                fillColor: _pageBackground,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: _borderColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: _borderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(
                    color: AppColors.primaryContainer,
                    width: 1.5,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _FilterField(
                  label: 'Tipe event',
                  child: DropdownButtonFormField<CollectorAuditEventType?>(
                    key: ValueKey(selectedType),
                    initialValue: selectedType,
                    isExpanded: true,
                    icon: const Icon(Icons.keyboard_arrow_down_rounded),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('Semua tipe'),
                      ),
                      ...CollectorAuditEventType.values.map(
                        (type) => DropdownMenuItem(
                          value: type,
                          child: Text(
                            type.label,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                    onChanged: onTypeChanged,
                    decoration: _filterDecoration(),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.subtitle,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _FilterField(
                  label: 'Aktor',
                  child: DropdownButtonFormField<String?>(
                    key: ValueKey(selectedActor),
                    initialValue: selectedActor,
                    isExpanded: true,
                    icon: const Icon(Icons.keyboard_arrow_down_rounded),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('Semua aktor'),
                      ),
                      ...actors.map(
                        (actor) => DropdownMenuItem(
                          value: actor,
                          child: Text(actor, overflow: TextOverflow.ellipsis),
                        ),
                      ),
                    ],
                    onChanged: onActorChanged,
                    decoration: _filterDecoration(),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.subtitle,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Periode',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.placeholder,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: _AuditPeriod.values.map((item) {
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: item == _AuditPeriod.thirtyDays ? 0 : 6,
                  ),
                  child: _PeriodButton(
                    label: item.label,
                    selected: item == period,
                    onTap: () => onPeriodChanged(item),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  InputDecoration _filterDecoration() {
    return InputDecoration(
      filled: true,
      fillColor: _pageBackground,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: _borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: _borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.primaryContainer),
      ),
    );
  }
}

class _FilterField extends StatelessWidget {
  const _FilterField({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.placeholder,
          ),
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}

class _PeriodButton extends StatelessWidget {
  const _PeriodButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: Material(
        color: selected
            ? AppColors.primaryContainer.withValues(alpha: 0.10)
            : AppColors.white,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: selected ? AppColors.primary : _borderColor,
              ),
            ),
            child: Text(
              label,
              maxLines: 1,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: selected ? AppColors.primary : AppColors.subtitle,
              ),
            ),
          ),
        ),
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
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 13),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _AuditIcon(type: event.type, color: color),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              event.objectCode,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          _TypeBadge(label: event.type.label, color: color),
                        ],
                      ),
                      const SizedBox(height: 5),
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
                      const SizedBox(height: 12),
                      _AuditDetailLine(
                        icon: Icons.schedule_outlined,
                        value: _formatDateTime(event.occurredAt),
                      ),
                      const SizedBox(height: 7),
                      _AuditDetailLine(
                        icon: Icons.person_outline_rounded,
                        value: '${event.actorRole} - ${event.actorName}',
                      ),
                      if (event.locationLabel?.trim().isNotEmpty == true) ...[
                        const SizedBox(height: 7),
                        _AuditDetailLine(
                          icon: Icons.location_on_outlined,
                          value: event.locationLabel!.trim(),
                        ),
                      ],
                      if (event.statusLabel?.trim().isNotEmpty == true) ...[
                        const SizedBox(height: 7),
                        _AuditDetailLine(
                          icon: Icons.verified_outlined,
                          value: event.statusLabel!.trim(),
                          valueColor: color,
                        ),
                      ],
                    ],
                  ),
                ),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Detail aktivitas',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: AppColors.placeholder,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 7,
                    runSpacing: 7,
                    children: event.metadata.entries.map((entry) {
                      return _MetadataPill(
                        label: entry.key,
                        value: entry.value,
                      );
                    }).toList(),
                  ),
                ],
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

class _AuditDetailLine extends StatelessWidget {
  const _AuditDetailLine({
    required this.icon,
    required this.value,
    this.valueColor,
  });

  final IconData icon;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 15, color: AppColors.placeholder),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 11,
              height: 1.35,
              fontWeight: FontWeight.w600,
              color: valueColor ?? AppColors.subtitle,
            ),
          ),
        ),
      ],
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
      constraints: const BoxConstraints(minHeight: 30),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: _borderColor),
      ),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(
            fontSize: 10,
            height: 1.35,
            color: AppColors.subtitle,
          ),
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            TextSpan(
              text: value,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ],
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
