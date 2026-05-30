import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

// [FE - Component Rendering] Widget generik ini memusatkan gaya dropdown
// bergaya prototype agar semua form petani memiliki tampilan konsisten,
// termasuk dukungan empty-state untuk kasus kebun belum ada.
/// Dropdown berlabel bergaya prototype: border tipis, chevron, placeholder abu.
///
/// Widget generik `<T>` yang dipakai di form Tambah Batch (Req 2.2) dan
/// form Buat Kebun. Mendukung empty-state kustom saat `items` kosong (Req 2.3).
///
/// Contoh penggunaan — dropdown biasa:
/// ```dart
/// LabeledDropdownField<String>(
///   label: 'Pilih Varietas Durian',
///   hint: 'Pilih varietas',
///   value: _variety,
///   items: FarmerMasterData.varieties,
///   itemLabel: (v) => v,
///   onChanged: (v) => setState(() => _variety = v),
/// )
/// ```
///
/// Contoh dengan empty-state (Req 2.3 — dropdown kebun kosong):
/// ```dart
/// LabeledDropdownField<Farm>(
///   label: 'Pilih Lokasi Kebun Durian',
///   hint: 'Pilih kebun',
///   value: _selectedFarm,
///   items: repo.farms,
///   itemLabel: (f) => f.name,
///   onChanged: (f) => setState(() => _selectedFarm = f),
///   emptyState: _FarmEmptyState(onCreateFarm: _goToCreateFarm),
/// )
/// ```
class LabeledDropdownField<T> extends StatelessWidget {
  const LabeledDropdownField({
    super.key,
    required this.label,
    required this.hint,
    required this.items,
    required this.itemLabel,
    required this.onChanged,
    this.value,
    this.emptyState,
  });

  /// Label yang ditampilkan di atas dropdown.
  final String label;

  /// Teks placeholder saat belum ada pilihan.
  final String hint;

  /// Nilai yang sedang dipilih. `null` berarti belum ada pilihan.
  final T? value;

  /// Daftar item yang tersedia sebagai opsi.
  final List<T> items;

  /// Fungsi untuk mengubah item `T` menjadi teks yang ditampilkan.
  final String Function(T item) itemLabel;

  /// Callback saat pengguna memilih item.
  final ValueChanged<T?> onChanged;

  /// Widget yang ditampilkan sebagai pengganti dropdown saat `items` kosong.
  /// Dipakai untuk Req 2.3 (ajakan buat kebun saat belum ada kebun).
  final Widget? emptyState;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.subtitle,
          ),
        ),
        const SizedBox(height: 6),

        // Konten: empty-state atau dropdown
        if (items.isEmpty && emptyState != null)
          emptyState!
        else
          _DropdownContainer(
            hint: hint,
            value: value,
            items: items,
            itemLabel: itemLabel,
            onChanged: onChanged,
          ),
      ],
    );
  }
}

/// Container bergaya prototype yang membungkus `DropdownButton`.
class _DropdownContainer<T> extends StatelessWidget {
  const _DropdownContainer({
    required this.hint,
    required this.value,
    required this.items,
    required this.itemLabel,
    required this.onChanged,
  });

  final String hint;
  final T? value;
  final List<T> items;
  final String Function(T) itemLabel;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          icon: const Padding(
            padding: EdgeInsets.only(right: 12),
            child: Icon(
              Icons.keyboard_arrow_down_rounded,
              color: AppColors.placeholder,
              size: 22,
            ),
          ),
          hint: Padding(
            padding: const EdgeInsets.only(left: 14),
            child: Text(
              hint,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.placeholder,
              ),
            ),
          ),
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.black,
          ),
          dropdownColor: AppColors.white,
          borderRadius: BorderRadius.circular(10),
          onChanged: onChanged,
          items: items.map((item) {
            return DropdownMenuItem<T>(
              value: item,
              child: Padding(
                padding: const EdgeInsets.only(left: 14),
                child: Text(
                  itemLabel(item),
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.black,
                  ),
                ),
              ),
            );
          }).toList(),
          // Tampilkan nilai terpilih dengan padding konsisten
          selectedItemBuilder: (context) {
            return items.map((item) {
              return Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(left: 14),
                  child: Text(
                    itemLabel(item),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.black,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              );
            }).toList();
          },
        ),
      ),
    );
  }
}
