import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_top_bar.dart';
import '../../../shared/widgets/primary_pill_button.dart';
import '../data/farmer_repository.dart';
import '../farmer_routes.dart';
import '../models/farm.dart';
import 'create_farm_screen.dart';

// [FE - Component Rendering] Screen ini menampilkan daftar kebun petani
// dan mendukung dua mode: manajemen biasa dan selectMode untuk memilih
// kebun dari form Tambah Batch.
/// Layar daftar kebun milik petani (Req 5.1, 5.2).
///
/// Parameter [selectMode] bernilai `true` bila layar ini dibuka dari
/// Tambah Batch untuk memilih kebun — dalam mode ini, mengetuk kartu kebun
/// akan meng-pop layar dan mengembalikan [Farm] yang dipilih.
///
/// Bila [selectMode] `false` (default), layar berfungsi sebagai manajemen
/// kebun biasa tanpa mengembalikan nilai.
class FarmManagementScreen extends StatefulWidget {
  const FarmManagementScreen({super.key, this.selectMode = false});

  /// Jika `true`, mengetuk kartu kebun akan pop dan mengembalikan [Farm].
  final bool selectMode;

  @override
  State<FarmManagementScreen> createState() => _FarmManagementScreenState();
}

class _FarmManagementScreenState extends State<FarmManagementScreen> {
  final _repo = FarmerRepository.instance;

  @override
  void initState() {
    super.initState();
    _repo.addListener(_onRepoChanged);
  }

  @override
  void dispose() {
    _repo.removeListener(_onRepoChanged);
    super.dispose();
  }

  void _onRepoChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _goToCreateFarm() async {
    await FarmerRoutes.push(context, const CreateFarmScreen());
    // Listener _onRepoChanged sudah menangani refresh otomatis.
  }

  @override
  Widget build(BuildContext context) {
    final farms = _repo.farms;

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar (Req 8.2)
            AppTopBar(
              title: 'Kelola Kebun',
              actions: widget.selectMode
                  ? [
                      Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: TextButton(
                          onPressed: () => Navigator.maybePop(context),
                          child: const Text(
                            'Batal',
                            style: TextStyle(
                              color: AppColors.primaryContainer,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ]
                  : const [],
            ),

            // Konten utama
            Expanded(
              child: farms.isEmpty
                  ? _EmptyState(onCreateFarm: _goToCreateFarm)
                  : _FarmList(
                      farms: farms,
                      selectMode: widget.selectMode,
                      onCreateFarm: _goToCreateFarm,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Daftar kebun
// ─────────────────────────────────────────────────────────────────────────────

class _FarmList extends StatelessWidget {
  const _FarmList({
    required this.farms,
    required this.selectMode,
    required this.onCreateFarm,
  });

  final List<Farm> farms;
  final bool selectMode;
  final VoidCallback onCreateFarm;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            itemCount: farms.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              return _FarmCard(
                farm: farms[index],
                selectMode: selectMode,
              );
            },
          ),
        ),
        // Tombol "Tambah Kebun" di bawah daftar
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: PrimaryPillButton(
            label: 'TAMBAH KEBUN',
            onPressed: onCreateFarm,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Kartu kebun
// ─────────────────────────────────────────────────────────────────────────────

// [FE - Component Rendering] _FarmCard menampilkan info satu kebun dan
// mendukung selectMode — bila aktif, tap kartu akan pop dan mengembalikan
// Farm yang dipilih ke pemanggil (AddBatchScreen).
class _FarmCard extends StatelessWidget {
  const _FarmCard({required this.farm, required this.selectMode});

  final Farm farm;
  final bool selectMode;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: selectMode ? () => Navigator.pop(context, farm) : null,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selectMode
                ? AppColors.primaryContainer
                : const Color(0xFFE5E7EB),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ikon kebun
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primaryContainer.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.grass_rounded,
                color: AppColors.primaryContainer,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),

            // Info kebun
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    farm.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${farm.village}, ${farm.district}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.placeholder,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${farm.city}, ${farm.province}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.placeholder,
                    ),
                  ),
                  if (farm.latitude != null && farm.longitude != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 13,
                          color: AppColors.primaryContainer,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          '${farm.latitude!.toStringAsFixed(4)}, '
                          '${farm.longitude!.toStringAsFixed(4)}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.primaryContainer,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            // Chevron bila selectMode
            if (selectMode)
              const Padding(
                padding: EdgeInsets.only(left: 8, top: 2),
                child: Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.primaryContainer,
                  size: 22,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty state (Req 5.2)
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onCreateFarm});

  final VoidCallback onCreateFarm;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 0, 32, 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.primaryContainer.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.grass_rounded,
              size: 40,
              color: AppColors.primaryContainer,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Belum Ada Kebun',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.black,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Anda belum memiliki kebun durian.\nBuat kebun pertama Anda sekarang.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.placeholder,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),
          PrimaryPillButton(
            label: 'BUAT KEBUN',
            onPressed: onCreateFarm,
          ),
        ],
      ),
    );
  }
}
