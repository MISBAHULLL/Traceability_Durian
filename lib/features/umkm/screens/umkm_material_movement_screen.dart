import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_top_bar.dart';
import '../data/umkm_repository.dart';
import '../models/umkm_material_inventory.dart';

class UmkmMaterialMovementScreen extends StatefulWidget {
  const UmkmMaterialMovementScreen({super.key});

  @override
  State<UmkmMaterialMovementScreen> createState() =>
      _UmkmMaterialMovementScreenState();
}

class _UmkmMaterialMovementScreenState
    extends State<UmkmMaterialMovementScreen> {
  final _repo = UmkmRepository.instance;
  final _searchController = TextEditingController();
  String _query = '';
  UmkmMaterialMovementType? _activeType;

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
    final inventoriesById = {
      for (final inventory in _repo.materialInventories)
        inventory.id: inventory,
    };
    final inventoriesByCode = {
      for (final inventory in _repo.materialInventories)
        inventory.traceCode: inventory,
    };
    final movements = _repo.materialMovements.where((movement) {
      if (_activeType != null && movement.type != _activeType) return false;
      if (_query.isEmpty) return true;
      final inventory =
          inventoriesById[movement.inventoryId] ??
          inventoriesByCode[movement.traceCode];
      final haystack = [
        movement.traceCode,
        movement.type.label,
        movement.actorName,
        movement.relatedObjectId,
        movement.note,
        inventory?.productName,
        inventory?.supplierName,
      ].whereType<String>().join(' ').toLowerCase();
      return haystack.contains(_query);
    }).toList();
    movements.sort((a, b) => b.occurredAt.compareTo(a.occurredAt));

    final totalIn = _sumByTypes(_repo.materialMovements, {
      UmkmMaterialMovementType.received,
    });
    final totalOut = _sumByTypes(_repo.materialMovements, {
      UmkmMaterialMovementType.usedForProduction,
      UmkmMaterialMovementType.waste,
    });

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            const AppTopBar(title: 'Mutasi Bahan Baku'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                children: [
                  _SummaryBand(
                    movementCount: _repo.materialMovements.length,
                    totalInKg: totalIn,
                    totalOutKg: totalOut,
                  ),
                  const SizedBox(height: 16),
                  _SearchField(controller: _searchController),
                  const SizedBox(height: 12),
                  _MovementTypeChips(
                    activeType: _activeType,
                    onChanged: (type) => setState(() => _activeType = type),
                  ),
                  const SizedBox(height: 18),
                  if (movements.isEmpty)
                    const _EmptyMovementState()
                  else
                    ...movements.map(
                      (movement) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _MovementCard(
                          movement: movement,
                          inventory:
                              inventoriesById[movement.inventoryId] ??
                              inventoriesByCode[movement.traceCode],
                        ),
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

  double _sumByTypes(
    List<UmkmMaterialMovement> movements,
    Set<UmkmMaterialMovementType> types,
  ) {
    return movements
        .where((movement) => types.contains(movement.type))
        .fold<double>(0, (total, movement) => total + movement.quantity);
  }
}

class _SummaryBand extends StatelessWidget {
  const _SummaryBand({
    required this.movementCount,
    required this.totalInKg,
    required this.totalOutKg,
  });

  final int movementCount;
  final double totalInKg;
  final double totalOutKg;

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
          Expanded(
            child: _SummaryItem(
              label: 'Mutasi',
              value: '$movementCount',
              icon: Icons.history_rounded,
            ),
          ),
          Expanded(
            child: _SummaryItem(
              label: 'Masuk',
              value: _formatWeight(totalInKg),
              icon: Icons.call_received_rounded,
            ),
          ),
          Expanded(
            child: _SummaryItem(
              label: 'Keluar',
              value: _formatWeight(totalOutKg),
              icon: Icons.call_made_rounded,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  const _SummaryItem({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(height: 8),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w900,
            color: AppColors.black,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.placeholder),
        ),
      ],
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
        hintText: 'Cari kode batch, produk, atau catatan',
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

class _MovementTypeChips extends StatelessWidget {
  const _MovementTypeChips({required this.activeType, required this.onChanged});

  final UmkmMaterialMovementType? activeType;
  final ValueChanged<UmkmMaterialMovementType?> onChanged;

  @override
  Widget build(BuildContext context) {
    final items = <UmkmMaterialMovementType?>[
      null,
      ...UmkmMaterialMovementType.values,
    ];
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final type = items[index];
          final selected = activeType == type;
          final label = type == null ? 'Semua' : type.label;
          return ChoiceChip(
            label: Text(label),
            selected: selected,
            onSelected: (_) => onChanged(type),
            showCheckmark: false,
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

class _MovementCard extends StatelessWidget {
  const _MovementCard({required this.movement, required this.inventory});

  final UmkmMaterialMovement movement;
  final UmkmMaterialInventory? inventory;

  Color get _color {
    switch (movement.type) {
      case UmkmMaterialMovementType.received:
        return AppColors.primary;
      case UmkmMaterialMovementType.usedForProduction:
        return const Color(0xFF1D4ED8);
      case UmkmMaterialMovementType.waste:
        return const Color(0xFFB45309);
      case UmkmMaterialMovementType.adjustment:
        return const Color(0xFF6B21A8);
    }
  }

  IconData get _icon {
    switch (movement.type) {
      case UmkmMaterialMovementType.received:
        return Icons.add_circle_outline_rounded;
      case UmkmMaterialMovementType.usedForProduction:
        return Icons.restaurant_menu_rounded;
      case UmkmMaterialMovementType.waste:
        return Icons.report_problem_outlined;
      case UmkmMaterialMovementType.adjustment:
        return Icons.tune_rounded;
    }
  }

  String get _signedQuantity {
    final sign = switch (movement.type) {
      UmkmMaterialMovementType.received => '+',
      UmkmMaterialMovementType.adjustment => '',
      _ => '-',
    };
    return '$sign${_formatWeight(movement.quantity, unit: movement.unit)}';
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
              color: _color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(_icon, color: _color, size: 21),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        movement.type.label,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: AppColors.black,
                        ),
                      ),
                    ),
                    Text(
                      _signedQuantity,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: _color,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  movement.traceCode,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  inventory == null
                      ? 'Inventory bahan baku'
                      : '${inventory!.productName} / ${inventory!.supplierName}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1.35,
                    color: AppColors.subtitle,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _SmallInfoChip(
                      icon: Icons.schedule_rounded,
                      label: _formatDateTime(movement.occurredAt),
                    ),
                    if (movement.relatedObjectId != null &&
                        movement.relatedObjectId!.trim().isNotEmpty)
                      _SmallInfoChip(
                        icon: Icons.link_rounded,
                        label: movement.relatedObjectId!.trim(),
                      ),
                  ],
                ),
                if (movement.note != null &&
                    movement.note!.trim().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    movement.note!.trim(),
                    style: const TextStyle(
                      fontSize: 11,
                      height: 1.35,
                      color: AppColors.placeholder,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SmallInfoChip extends StatelessWidget {
  const _SmallInfoChip({required this.icon, required this.label});

  final IconData icon;
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
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.placeholder),
          const SizedBox(width: 4),
          Flexible(
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
          ),
        ],
      ),
    );
  }
}

class _EmptyMovementState extends StatelessWidget {
  const _EmptyMovementState();

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
        'Belum ada mutasi formal. Setelah UMKM menerima stok atau membuat produk dari bahan baku traceable, riwayatnya akan tampil di sini.',
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

String _formatDateTime(DateTime date) {
  final d = date.day.toString().padLeft(2, '0');
  final m = date.month.toString().padLeft(2, '0');
  final h = date.hour.toString().padLeft(2, '0');
  final min = date.minute.toString().padLeft(2, '0');
  return '$d/$m/${date.year} $h:$min';
}

String _formatWeight(double value, {String unit = 'kg'}) {
  final text = value % 1 == 0
      ? value.toStringAsFixed(0)
      : value.toStringAsFixed(1);
  return '$text $unit';
}
