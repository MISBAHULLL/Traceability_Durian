import 'package:flutter/material.dart';

// [FE - Navigation Helper] Helper ini memusatkan logika navigasi seluruh
// layar pengepul agar transisi fade konsisten dengan layar lain di aplikasi
// (auth & petani) dan semantik khusus (logout) tidak tersebar di tiap
// call-site. Pola identik dengan FarmerRoutes.
/// Helper navigasi tipis untuk seluruh layar pengepul.
///
/// Membungkus [PageRouteBuilder] dengan transisi fade yang identik dengan
/// layar auth & petani (400 ms, [Curves.easeInOutCubic]) sehingga transisi
/// konsisten di seluruh aplikasi.
class CollectorRoutes {
  // Kelas ini hanya berisi metode statis; tidak perlu di-instantiate.
  CollectorRoutes._();

  /// Durasi dan kurva transisi — sama persis dengan layar lain.
  static const Duration _duration = Duration(milliseconds: 400);
  static const Curve _curve = Curves.easeInOutCubic;

  /// Buat [PageRouteBuilder] dengan transisi fade standar.
  static PageRouteBuilder<T> _fadeRoute<T>(Widget page) {
    return PageRouteBuilder<T>(
      transitionDuration: _duration,
      reverseTransitionDuration: _duration,
      pageBuilder: (_, _, _) => page,
      transitionsBuilder: (_, animation, _, child) {
        return FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: _curve),
          child: child,
        );
      },
    );
  }

  /// Push [page] ke atas stack navigasi saat ini.
  static Future<T?> push<T>(BuildContext context, Widget page) {
    return Navigator.push<T>(context, _fadeRoute<T>(page));
  }

  /// Ganti seluruh stack navigasi dengan [page] (dipakai logout → login).
  static void replaceAll(BuildContext context, Widget page) {
    Navigator.pushAndRemoveUntil<void>(
      context,
      _fadeRoute<void>(page),
      (_) => false,
    );
  }
}
