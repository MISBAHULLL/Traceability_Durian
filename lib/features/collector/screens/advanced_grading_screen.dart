import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_top_bar.dart';
import '../../../shared/widgets/primary_pill_button.dart';
import '../../../shared/widgets/top_notification_banner.dart';
import '../../farmer/models/harvest_batch.dart';
import '../data/collector_repository.dart';

const _pageBackground = Color(0xFFF4F6F3);
const _borderColor = Color(0xFFE1E6DF);
const _mutedSurface = Color(0xFFF8F9F7);

// [FE - Component Rendering] Layar ini memecah stok terverifikasi menjadi
// sub-batch grade lanjutan tanpa mencatat harga, pembayaran, atau gudang penuh.
class AdvancedGradingScreen extends StatefulWidget {
  const AdvancedGradingScreen({super.key, required this.batch});

  final HarvestBatch batch;

  @override
  State<AdvancedGradingScreen> createState() => _AdvancedGradingScreenState();
}

class _AdvancedGradingScreenState extends State<AdvancedGradingScreen> {
  final _repo = CollectorRepository.instance;
  final _notification = TopNotification();
  final _weightCtrls = <String, TextEditingController>{};
  final _fruitCtrls = <String, TextEditingController>{};
  late final List<String> _grades;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final defaults = ['AA', 'A', 'B', 'C', 'Reject'];
    final existing = widget.batch.gradeBreakdown
        .map((item) => item.grade.trim())
        .where((grade) => grade.isNotEmpty)
        .toList();
    _grades = [
      ...defaults,
      ...existing.where((grade) => !defaults.contains(grade)),
    ];

    for (final grade in _grades) {
      final item = _existingBreakdown(grade);
      _weightCtrls[grade] = TextEditingController(
        text: item == null || item.weightKg <= 0
            ? ''
            : _formatWeight(item.weightKg),
      );
      _fruitCtrls[grade] = TextEditingController(
        text: item == null || item.fruitCount <= 0
            ? ''
            : item.fruitCount.toString(),
      );
    }
  }

  @override
  void dispose() {
    _notification.dispose();
    for (final controller in _weightCtrls.values) {
      controller.dispose();
    }
    for (final controller in _fruitCtrls.values) {
      controller.dispose();
    }
    super.dispose();
  }

  BatchGradeBreakdown? _existingBreakdown(String grade) {
    for (final item in widget.batch.gradeBreakdown) {
      if (item.grade.toUpperCase() == grade.toUpperCase()) return item;
    }
    return null;
  }

  double get _targetWeight {
    return widget.batch.receivedQuantity ?? widget.batch.quantity;
  }

  int get _targetFruit {
    return widget.batch.receivedFruitCount ?? widget.batch.fruitCount ?? 0;
  }

  String _formatWeight(double value) {
    return value % 1 == 0 ? value.toStringAsFixed(0) : value.toStringAsFixed(2);
  }

  double _parseWeight(String grade) {
    return double.tryParse(
          _weightCtrls[grade]!.text.trim().replaceAll(',', '.'),
        ) ??
        0;
  }

  int _parseFruit(String grade) {
    return int.tryParse(_fruitCtrls[grade]!.text.trim()) ?? 0;
  }

  List<BatchGradeBreakdown> _buildBreakdown() {
    return _grades.map((grade) {
      return BatchGradeBreakdown(
        grade: grade,
        weightKg: _parseWeight(grade),
        fruitCount: _parseFruit(grade),
      );
    }).toList();
  }

  Future<void> _handleSubmit() async {
    FocusScope.of(context).unfocus();

    final breakdown = _buildBreakdown();
    final activeBreakdown = breakdown.where((item) => item.hasValue).toList();
    if (activeBreakdown.isEmpty) {
      _notification.show(
        context,
        'Isi minimal satu pecahan grade lanjutan.',
        isError: true,
      );
      return;
    }

    final hasInvalid = activeBreakdown.any((item) {
      return item.weightKg <= 0 || item.fruitCount <= 0;
    });
    if (hasInvalid) {
      _notification.show(
        context,
        'Setiap grade terisi harus punya berat dan jumlah butir.',
        isError: true,
      );
      return;
    }

    final totalWeight = activeBreakdown.fold<double>(
      0,
      (sum, item) => sum + item.weightKg,
    );
    final totalFruit = activeBreakdown.fold<int>(
      0,
      (sum, item) => sum + item.fruitCount,
    );
    if ((totalWeight - _targetWeight).abs() > 0.01) {
      _notification.show(
        context,
        'Total berat grade harus ${_formatWeight(_targetWeight)} kg.',
        isError: true,
      );
      return;
    }
    if (totalFruit != _targetFruit) {
      _notification.show(
        context,
        'Total jumlah grade harus $_targetFruit butir.',
        isError: true,
      );
      return;
    }

    setState(() => _isSubmitting = true);
    await Future.delayed(const Duration(milliseconds: 350));
    if (!mounted) return;

    final ok = _repo.updateAdvancedGrading(
      code: widget.batch.code,
      gradeBreakdown: activeBreakdown,
    );
    setState(() => _isSubmitting = false);
    if (!ok) {
      _notification.show(
        context,
        'Grading lanjutan gagal disimpan. Pastikan batch masih aktif.',
        isError: true,
      );
      return;
    }

    _notification.show(context, 'Grading lanjutan berhasil disimpan.');
    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final totalWeight = _grades.fold<double>(
      0,
      (sum, grade) => sum + _parseWeight(grade),
    );
    final totalFruit = _grades.fold<int>(
      0,
      (sum, grade) => sum + _parseFruit(grade),
    );

    return Scaffold(
      backgroundColor: _pageBackground,
      body: SafeArea(
        child: Column(
          children: [
            const AppTopBar(title: 'Grading Lanjutan'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                children: [
                  _BatchHeader(batch: widget.batch),
                  const SizedBox(height: 12),
                  _BalanceSummary(
                    targetWeight: _targetWeight,
                    targetFruit: _targetFruit,
                    totalWeight: totalWeight,
                    totalFruit: totalFruit,
                    formatWeight: _formatWeight,
                  ),
                  const SizedBox(height: 12),
                  ..._grades.map((grade) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _GradeInputRow(
                        grade: grade,
                        weightCtrl: _weightCtrls[grade]!,
                        fruitCtrl: _fruitCtrls[grade]!,
                        onChanged: () => setState(() {}),
                      ),
                    );
                  }),
                ],
              ),
            ),
            SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                decoration: const BoxDecoration(
                  color: AppColors.white,
                  border: Border(top: BorderSide(color: _borderColor)),
                ),
                child: PrimaryPillButton(
                  label: 'SIMPAN GRADING',
                  isLoading: _isSubmitting,
                  onPressed: _handleSubmit,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BatchHeader extends StatelessWidget {
  const _BatchHeader({required this.batch});

  final HarvestBatch batch;

  String _formatWeight(double value) {
    return value % 1 == 0 ? value.toStringAsFixed(0) : value.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    final weight = batch.receivedQuantity ?? batch.quantity;
    final fruit = batch.receivedFruitCount ?? batch.fruitCount ?? 0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF4E6),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.fact_check_outlined,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  batch.code,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Durian ${batch.variety}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: AppColors.black,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${_formatWeight(weight)} kg / $fruit butir',
                  style: const TextStyle(
                    fontSize: 11,
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

class _BalanceSummary extends StatelessWidget {
  const _BalanceSummary({
    required this.targetWeight,
    required this.targetFruit,
    required this.totalWeight,
    required this.totalFruit,
    required this.formatWeight,
  });

  final double targetWeight;
  final int targetFruit;
  final double totalWeight;
  final int totalFruit;
  final String Function(double value) formatWeight;

  @override
  Widget build(BuildContext context) {
    final weightOk = (totalWeight - targetWeight).abs() <= 0.01;
    final fruitOk = totalFruit == targetFruit;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _borderColor),
      ),
      child: Row(
        children: [
          Expanded(
            child: _BalanceItem(
              label: 'Berat',
              value:
                  '${formatWeight(totalWeight)} / '
                  '${formatWeight(targetWeight)} kg',
              isValid: weightOk,
            ),
          ),
          Container(width: 1, height: 34, color: _borderColor),
          Expanded(
            child: _BalanceItem(
              label: 'Jumlah',
              value: '$totalFruit / $targetFruit butir',
              isValid: fruitOk,
            ),
          ),
        ],
      ),
    );
  }
}

class _BalanceItem extends StatelessWidget {
  const _BalanceItem({
    required this.label,
    required this.value,
    required this.isValid,
  });

  final String label;
  final String value;
  final bool isValid;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 10, color: AppColors.placeholder),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                isValid
                    ? Icons.check_circle_outline_rounded
                    : Icons.error_outline_rounded,
                size: 15,
                color: isValid ? AppColors.primary : const Color(0xFFC2410C),
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: isValid
                        ? AppColors.subtitle
                        : const Color(0xFFC2410C),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GradeInputRow extends StatelessWidget {
  const _GradeInputRow({
    required this.grade,
    required this.weightCtrl,
    required this.fruitCtrl,
    required this.onChanged,
  });

  final String grade;
  final TextEditingController weightCtrl;
  final TextEditingController fruitCtrl;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _mutedSurface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              grade,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: weightCtrl,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              onChanged: (_) => onChanged(),
              decoration: const InputDecoration(
                labelText: 'kg',
                isDense: true,
                border: OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: fruitCtrl,
              keyboardType: TextInputType.number,
              onChanged: (_) => onChanged(),
              decoration: const InputDecoration(
                labelText: 'butir',
                isDense: true,
                border: OutlineInputBorder(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
