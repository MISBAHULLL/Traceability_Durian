import 'package:flutter/material.dart';

/// Helper navigasi tipis untuk seluruh layar petani.
///
/// Membungkus [PageRouteBuilder] dengan transisi fade yang identik dengan
/// layar auth (400 ms, [Curves.easeInOutCubic]) sehingga Requirement 8.5
/// (transisi konsisten) terpenuhi secara otomatis di semua call-site.
///
/// Dua metode yang tersedia:
/// - [push] — navigasi biasa (push ke stack).
/// - [replaceAll] — ganti seluruh stack (dipakai logout → login dan
///   alur create → QR → Beranda agar tombol back tidak kembali ke form).
class FarmerRoutes {
  // Kelas ini hanya berisi metode statis; tidak perlu di-instantiate.
  FarmerRoutes._();

  /// Durasi dan kurva transisi — sama persis dengan auth screens.
  static const Duration _duration = Duration(milliseconds: 400);
  static const Curve _curve = Curves.easeInOutCubic;

  /// Buat [PageRouteBuilder] dengan transisi fade standar.
  static PageRouteBuilder<T> _fadeRoute<T>(Widget page) {
    return PageRouteBuilder<T>(
      transitionDuration: _duration,
      reverseTransitionDuration: _duration,
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, animation, __, child) {
        return FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: _curve),
          child: child,
        );
      },
    );
  }

  /// Push [page] ke atas stack navigasi saat ini.
  ///
  /// Mengembalikan [Future] yang selesai saat halaman di-pop, sama seperti
  /// [Navigator.push]. Berguna bila pemanggil perlu menunggu hasil (mis.
  /// kembali dari [CreateFarmScreen] untuk me-refresh dropdown).
  static Future<T?> push<T>(BuildContext context, Widget page) {
    return Navigator.push<T>(context, _fadeRoute<T>(page));
  }

  /// Ganti seluruh stack navigasi dengan [page].
  ///
  /// Dipakai untuk:
  /// - Logout → layar login (stack petani bersih, Req 6.4).
  /// - Setelah create batch → QR → Beranda (tombol back tidak kembali ke
  ///   form Tambah Batch, Req 4.6).
  static void replaceAll(BuildContext context, Widget page) {
    Navigator.pushAndRemoveUntil<void>(
      context,
      _fadeRoute<void>(page),
      (_) => false, // hapus semua route di bawahnya
    );
  }
}
