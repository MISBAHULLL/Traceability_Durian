import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

// [FE - Component Rendering] Widget ini adalah top bar reusable yang
// memusatkan pola back+judul+aksi agar konsisten di seluruh layar petani
// tanpa duplikasi kode AppBar.
/// Top bar reusable dengan tombol back kiri, judul tengah, dan slot aksi kanan.
///
/// Mengekstrak pola `_TopAppBar` yang berulang di layar auth agar konsisten
/// di seluruh layar petani (Req 2.1, 3.1, 6.2, 8.2).
///
/// Contoh penggunaan:
/// ```dart
/// // Dengan tombol back default (pop)
/// AppTopBar(title: 'Tambah Batch Panen')
///
/// // Dengan callback back kustom
/// AppTopBar(title: 'Detail Batch', onBack: () => _handleBack())
///
/// // Tanpa tombol back (mis. layar root)
/// AppTopBar(title: 'Beranda', showBack: false)
///
/// // Dengan aksi di kanan
/// AppTopBar(
///   title: 'Profil',
///   actions: [IconButton(icon: Icon(Icons.edit), onPressed: _edit)],
/// )
/// ```
class AppTopBar extends StatelessWidget {
  const AppTopBar({
    super.key,
    required this.title,
    this.showBack = true,
    this.onBack,
    this.actions = const [],
  });

  /// Judul yang ditampilkan di tengah top bar.
  final String title;

  /// Apakah tombol back ditampilkan. Default `true`.
  final bool showBack;

  /// Callback saat tombol back ditekan.
  /// Jika `null` dan [showBack] `true`, memakai `Navigator.maybePop`.
  final VoidCallback? onBack;

  /// Widget aksi yang ditempatkan di sisi kanan (mis. `IconButton`).
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Tombol back di kiri
          if (showBack)
            Align(
              alignment: Alignment.centerLeft,
              child: GestureDetector(
                onTap: onBack ?? () => Navigator.maybePop(context),
                behavior: HitTestBehavior.opaque,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  child: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 22,
                    color: AppColors.black,
                  ),
                ),
              ),
            ),

          // Judul di tengah — diberi padding horizontal agar tidak bertabrakan
          // dengan tombol back (30 px) atau aksi kanan.
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: (showBack || actions.isNotEmpty) ? 40.0 : 0.0,
            ),
            child: Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.black,
              ),
            ),
          ),

          // Aksi di kanan
          if (actions.isNotEmpty)
            Align(
              alignment: Alignment.centerRight,
              child: Row(mainAxisSize: MainAxisSize.min, children: actions),
            ),
        ],
      ),
    );
  }
}
