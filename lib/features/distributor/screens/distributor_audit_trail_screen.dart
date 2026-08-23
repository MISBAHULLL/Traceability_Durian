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
      backgroundColor: _pageBackground,
      body: SafeArea(
        child: Column(
          children: [
            const ColoredBox(
              color: AppColors.white,
              child: AppTopBar(title: 'Audit Trail'),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                children: [
                  _AuditSummary(
                    totalCount: allEvents.length,
                    visibleCount: events.length,
                    actorCount: actors.length,
                  ),
                  const SizedBox(height: 14),
                  _AuditFilterPanel(
                    searchController: _searchController,
                    actors: actors,
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
                    onPeriodChanged: (value) => setState(() => _period = value),
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
                  const SizedBox(height: 16),
                  _SectionHeader(title: 'Event Audit', count: events.length),
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
          ],
        ),
      ),
    );
  }
}

class _AuditSummary extends StatelessWidget {
  const _AuditSummary({
    required this.totalCount,
    required this.visibleCount,
    required this.actorCount,
  });

  final int totalCount;
  final int visibleCount;
  final int actorCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 88, 168, 53),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: _SummaryMetric(label: 'Total', value: '$totalCount'),
          ),
          Container(width: 1, height: 38, color: const Color(0xFF8BCB70)),
          Expanded(
            child: _SummaryMetric(label: 'Tampil', value: '$visibleCount'),
          ),
          Container(width: 1, height: 38, color: const Color(0xFF8BCB70)),
          Expanded(
            child: _SummaryMetric(label: 'Aktor', value: '$actorCount'),
          ),
        ],
      ),
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  const _SummaryMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: AppColors.white,
            ),
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: Color(0xFFEAF7E5)),
          ),
        ],
      ),
    );
  }
}

class _AuditFilterPanel extends StatelessWidget {
  const _AuditFilterPanel({
    required this.searchController,
    required this.actors,
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
    return Container(
      padding: const EdgeInsets.all(14),
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
              const Expanded(
                child: Text(
                  'Filter Audit',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: AppColors.black,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: onReset,
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Reset'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  textStyle: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: searchController,
            onChanged: onSearchChanged,
            textInputAction: TextInputAction.search,
            decoration:
                _filterDecoration(
                  'Cari kode batch/PGL, aksi, atau catatan',
                ).copyWith(
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
          const SizedBox(height: 10),
          DropdownButtonFormField<String?>(
            key: ValueKey('actor-${selectedActor ?? 'all'}'),
            initialValue: selectedActor,
            isExpanded: true,
            decoration: _filterDecoration('Aktor'),
            items: [
              const DropdownMenuItem<String?>(
                value: null,
                child: Text('Semua aktor'),
              ),
              ...actors.map(
                (actor) =>
                    DropdownMenuItem<String?>(value: actor, child: Text(actor)),
              ),
            ],
            onChanged: onActorChanged,
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<DistributorAuditEventType?>(
            key: ValueKey('type-${selectedType?.name ?? 'all'}'),
            initialValue: selectedType,
            isExpanded: true,
            decoration: _filterDecoration('Tipe Event'),
            items: [
              const DropdownMenuItem<DistributorAuditEventType?>(
                value: null,
                child: Text('Semua tipe'),
              ),
              ...DistributorAuditEventType.values.map(
                (type) => DropdownMenuItem<DistributorAuditEventType?>(
                  value: type,
                  child: Text(type.label),
                ),
              ),
            ],
            onChanged: onTypeChanged,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _AuditPeriod.values.map((period) {
              final selected = selectedPeriod == period;
              return ChoiceChip(
                label: Text(period.label),
                selected: selected,
                onSelected: (_) => onPeriodChanged(period),
                selectedColor: AppColors.primaryContainer.withValues(
                  alpha: 0.14,
                ),
                backgroundColor: _pageBackground,
                side: BorderSide(
                  color: selected ? AppColors.primary : _borderColor,
                ),
                labelStyle: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: selected ? AppColors.primary : AppColors.placeholder,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

InputDecoration _filterDecoration(String label) {
  return InputDecoration(
    labelText: label,
    filled: true,
    fillColor: _pageBackground,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: _borderColor),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: AppColors.primaryContainer, width: 2),
    ),
  );
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

class _AuditEventCard extends StatelessWidget {
  const _AuditEventCard({required this.event});

  final DistributorAuditEvent event;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  event.type.icon,
                  size: 21,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.action,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: AppColors.black,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      event.description,
                      style: const TextStyle(
                        fontSize: 11,
                        height: 1.35,
                        color: AppColors.placeholder,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _TypeBadge(label: event.type.label),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1, color: _borderColor),
          const SizedBox(height: 9),
          _InfoRow(label: 'Aktor', value: event.actorName),
          _InfoRow(label: 'Waktu', value: _formatDateTime(event.occurredAt)),
          _InfoRow(label: 'Objek', value: event.objectCode),
          if (event.metadata.isNotEmpty) ...[
            const SizedBox(height: 2),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: event.metadata.entries.map((entry) {
                return _MetadataChip(label: entry.key, value: entry.value);
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _TypeBadge extends StatelessWidget {
  const _TypeBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.primaryContainer.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w900,
          color: AppColors.primary,
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
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 58,
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
                fontWeight: FontWeight.w800,
                color: AppColors.subtitle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetadataChip extends StatelessWidget {
  const _MetadataChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
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
