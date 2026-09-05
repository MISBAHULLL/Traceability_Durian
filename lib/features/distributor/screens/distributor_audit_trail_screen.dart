import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_top_bar.dart';
import '../data/distributor_repository.dart';
import '../models/distributor_audit_event.dart';

const _pageBackground = Color(0xFFF4F6F3);
const _borderColor = Color(0xFFE1E6DF);

enum _AuditPeriod { all, today, last7Days, last30Days }

extension _AuditPeriodX on _AuditPeriod {
  String get label {
    switch (this) {
      case _AuditPeriod.all:
        return 'Semua';
      case _AuditPeriod.today:
        return 'Hari ini';
      case _AuditPeriod.last7Days:
        return '7 hari';
      case _AuditPeriod.last30Days:
        return '30 hari';
    }
  }

  bool matches(DateTime date) {
    final now = DateTime.now();
    switch (this) {
      case _AuditPeriod.all:
        return true;
      case _AuditPeriod.today:
        return date.year == now.year &&
            date.month == now.month &&
            date.day == now.day;
      case _AuditPeriod.last7Days:
        return date.isAfter(now.subtract(const Duration(days: 7)));
      case _AuditPeriod.last30Days:
        return date.isAfter(now.subtract(const Duration(days: 30)));
    }
  }
}

class DistributorAuditTrailScreen extends StatefulWidget {
  const DistributorAuditTrailScreen({super.key});

  @override
  State<DistributorAuditTrailScreen> createState() =>
      _DistributorAuditTrailScreenState();
}

class _DistributorAuditTrailScreenState
    extends State<DistributorAuditTrailScreen> {
  final _repo = DistributorRepository.instance;
  late final TextEditingController _searchController;
  String _searchQuery = '';
  String? _actorFilter;
  DistributorAuditEventType? _typeFilter;
  _AuditPeriod _period = _AuditPeriod.all;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _repo.addListener(_onRepoChanged);
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

  List<DistributorAuditEvent> _filteredEvents() {
    final query = _searchQuery.trim().toLowerCase();
    return _repo.auditEvents.where((event) {
      final actorMatches =
          _actorFilter == null || event.actorName == _actorFilter;
      final typeMatches = _typeFilter == null || event.type == _typeFilter;
      final searchMatches = query.isEmpty || _eventMatchesQuery(event, query);
      return actorMatches &&
          typeMatches &&
          _period.matches(event.occurredAt) &&
          searchMatches;
    }).toList();
  }

  bool _eventMatchesQuery(DistributorAuditEvent event, String query) {
    final metadataText = event.metadata.entries
        .map((entry) => '${entry.key} ${entry.value}')
        .join(' ');
    final searchable = [
      event.objectCode,
      event.action,
      event.description,
      event.actorName,
      event.type.label,
      metadataText,
    ].join(' ').toLowerCase();
    return searchable.contains(query);
  }

  @override
  Widget build(BuildContext context) {
    final allEvents = _repo.auditEvents;
    final events = _filteredEvents();
    final actors = _repo.auditActors;

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            const ColoredBox(
              color: AppColors.white,
              child: AppTopBar(title: 'Audit Trail'),
            ),
            Expanded(
              child: ColoredBox(
                color: _pageBackground,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                  children: [
                    _AuditFilterPanel(
                      searchController: _searchController,
                      actors: actors,
                      totalCount: allEvents.length,
                      visibleCount: events.length,
                      searchQuery: _searchQuery,
                      selectedActor: _actorFilter,
                      selectedType: _typeFilter,
                      selectedPeriod: _period,
                      onSearchChanged: (value) =>
                          setState(() => _searchQuery = value),
                      onActorChanged: (value) =>
                          setState(() => _actorFilter = value),
                      onTypeChanged: (value) =>
                          setState(() => _typeFilter = value),
                      onPeriodChanged: (value) =>
                          setState(() => _period = value),
                      onReset: () {
                        setState(() {
                          _searchController.clear();
                          _searchQuery = '';
                          _actorFilter = null;
                          _typeFilter = null;
                          _period = _AuditPeriod.all;
                        });
                      },
                    ),
                    const SizedBox(height: 14),
                    _SectionHeader(
                      title: 'Riwayat Aktivitas',
                      count: events.length,
                    ),
                    const SizedBox(height: 8),
                    if (events.isEmpty)
                      const _EmptyAuditState()
                    else
                      ...events.map(
                        (event) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _AuditEventCard(event: event),
                        ),
                      ),
                  ],
                ),
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
    required this.searchController,
    required this.actors,
    required this.totalCount,
    required this.visibleCount,
    required this.searchQuery,
    required this.selectedActor,
    required this.selectedType,
    required this.selectedPeriod,
    required this.onSearchChanged,
    required this.onActorChanged,
    required this.onTypeChanged,
    required this.onPeriodChanged,
    required this.onReset,
  });

  final TextEditingController searchController;
  final List<String> actors;
  final int totalCount;
  final int visibleCount;
  final String searchQuery;
  final String? selectedActor;
  final DistributorAuditEventType? selectedType;
  final _AuditPeriod selectedPeriod;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String?> onActorChanged;
  final ValueChanged<DistributorAuditEventType?> onTypeChanged;
  final ValueChanged<_AuditPeriod> onPeriodChanged;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final hasActiveFilter =
        searchQuery.trim().isNotEmpty ||
        selectedActor != null ||
        selectedType != null ||
        selectedPeriod != _AuditPeriod.all;
    return Container(
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
                  color: AppColors.primary.withValues(alpha: 0.10),
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
                        fontSize: 10,
                        color: AppColors.placeholder,
                      ),
                    ),
                  ],
                ),
              ),
              if (hasActiveFilter)
                IconButton(
                  onPressed: onReset,
                  tooltip: 'Reset filter',
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(
                    Icons.restart_alt_rounded,
                    size: 19,
                    color: AppColors.primary,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 44,
            child: TextField(
              controller: searchController,
              onChanged: onSearchChanged,
              textInputAction: TextInputAction.search,
              style: const TextStyle(fontSize: 12),
              decoration: _filterDecoration().copyWith(
                hintText: 'Cari kode batch, transaksi, atau aktivitas',
                hintStyle: const TextStyle(
                  fontSize: 11,
                  color: AppColors.placeholder,
                ),
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                suffixIcon: searchQuery.trim().isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Bersihkan pencarian',
                        icon: const Icon(Icons.close_rounded, size: 18),
                        onPressed: () {
                          searchController.clear();
                          onSearchChanged('');
                        },
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
                  label: 'Aktor',
                  child: DropdownButtonFormField<String?>(
                    key: ValueKey('actor-${selectedActor ?? 'all'}'),
                    initialValue: selectedActor,
                    isExpanded: true,
                    icon: const Icon(Icons.keyboard_arrow_down_rounded),
                    decoration: _filterDecoration(),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('Semua aktor'),
                      ),
                      ...actors.map(
                        (actor) => DropdownMenuItem<String?>(
                          value: actor,
                          child: Text(
                            actor,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                    onChanged: onActorChanged,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.subtitle,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _FilterField(
                  label: 'Tipe event',
                  child: DropdownButtonFormField<DistributorAuditEventType?>(
                    key: ValueKey('type-${selectedType?.name ?? 'all'}'),
                    initialValue: selectedType,
                    isExpanded: true,
                    icon: const Icon(Icons.keyboard_arrow_down_rounded),
                    decoration: _filterDecoration(),
                    items: [
                      const DropdownMenuItem<DistributorAuditEventType?>(
                        value: null,
                        child: Text('Semua tipe'),
                      ),
                      ...DistributorAuditEventType.values.map(
                        (type) => DropdownMenuItem<DistributorAuditEventType?>(
                          value: type,
                          child: Text(
                            type.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                    onChanged: onTypeChanged,
                    style: const TextStyle(
                      fontSize: 11,
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
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.placeholder,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: _AuditPeriod.values.map((period) {
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: period == _AuditPeriod.last30Days ? 0 : 6,
                  ),
                  child: _PeriodButton(
                    label: period.label,
                    selected: selectedPeriod == period,
                    onTap: () => onPeriodChanged(period),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
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
      borderSide: const BorderSide(
        color: AppColors.primaryContainer,
        width: 1.5,
      ),
    ),
  );
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
            fontSize: 10,
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
      height: 34,
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
                fontSize: 10,
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

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.count});

  final String title;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: AppColors.black,
            ),
          ),
        ),
        Text(
          '$count event',
          style: const TextStyle(fontSize: 11, color: AppColors.placeholder),
        ),
      ],
    );
  }
}

class _AuditEventCard extends StatefulWidget {
  const _AuditEventCard({required this.event});

  final DistributorAuditEvent event;

  @override
  State<_AuditEventCard> createState() => _AuditEventCardState();
}

class _AuditEventCardState extends State<_AuditEventCard> {
  bool _showDetails = false;

  @override
  Widget build(BuildContext context) {
    final event = widget.event;
    final color = _eventColor(event.type);
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
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(event.type.icon, size: 21, color: color),
                ),
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
                              event.action,
                              style: const TextStyle(
                                fontSize: 13,
                                height: 1.3,
                                fontWeight: FontWeight.w900,
                                color: AppColors.black,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          _TypeBadge(label: event.type.label, color: color),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        event.objectCode,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: color,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Text(
                        event.description,
                        style: const TextStyle(
                          fontSize: 11,
                          height: 1.4,
                          color: AppColors.subtitle,
                        ),
                      ),
                      const SizedBox(height: 11),
                      _EventInfoLine(
                        icon: Icons.schedule_outlined,
                        value: _formatDateTime(event.occurredAt),
                      ),
                      const SizedBox(height: 6),
                      _EventInfoLine(
                        icon: Icons.person_outline_rounded,
                        value: '${event.actorRole} - ${event.actorName}',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (event.metadata.isNotEmpty)
            Container(
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: _borderColor)),
              ),
              child: Column(
                children: [
                  Material(
                    color: const Color(0xFFF8F9F7),
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(8),
                    ),
                    child: InkWell(
                      onTap: () {
                        setState(() => _showDetails = !_showDetails);
                      },
                      borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(8),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.subject_rounded,
                              size: 16,
                              color: AppColors.placeholder,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Detail event (${event.metadata.length})',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.subtitle,
                                ),
                              ),
                            ),
                            AnimatedRotation(
                              turns: _showDetails ? 0.5 : 0,
                              duration: const Duration(milliseconds: 180),
                              child: const Icon(
                                Icons.keyboard_arrow_down_rounded,
                                size: 19,
                                color: AppColors.placeholder,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (_showDetails)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(14, 10, 14, 13),
                      color: const Color(0xFFF8F9F7),
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: event.metadata.entries.map((entry) {
                          return _MetadataChip(
                            label: entry.key,
                            value: entry.value,
                          );
                        }).toList(),
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
          fontWeight: FontWeight.w900,
          color: color,
        ),
      ),
    );
  }
}

class _EventInfoLine extends StatelessWidget {
  const _EventInfoLine({required this.icon, required this.value});

  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: AppColors.placeholder),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 10,
              height: 1.35,
              fontWeight: FontWeight.w600,
              color: AppColors.placeholder,
            ),
          ),
        ),
      ],
    );
  }
}

Color _eventColor(DistributorAuditEventType type) {
  return switch (type) {
    DistributorAuditEventType.scan => const Color(0xFF2E7D32),
    DistributorAuditEventType.acquisition => const Color(0xFF2563EB),
    DistributorAuditEventType.receipt => const Color(0xFF0F766E),
    DistributorAuditEventType.rejection => const Color(0xFFC83B3B),
    DistributorAuditEventType.warehouse => const Color(0xFFB45309),
    DistributorAuditEventType.transfer => const Color(0xFF475569),
    DistributorAuditEventType.sale => const Color(0xFF7C3AED),
    DistributorAuditEventType.profile => const Color(0xFF0369A1),
    DistributorAuditEventType.session => const Color(0xFF64748B),
  };
}

class _MetadataChip extends StatelessWidget {
  const _MetadataChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.sizeOf(context).width - 64,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: _pageBackground,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: _borderColor),
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 28),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _borderColor),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.manage_search_outlined,
            size: 38,
            color: AppColors.placeholder,
          ),
          SizedBox(height: 10),
          Text(
            'Tidak ada event sesuai filter.',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: AppColors.placeholder,
            ),
          ),
        ],
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
