import 'package:flutter/material.dart';

// [FE - Navigation Helper] Helper ini memusatkan logika navigasi seluruh
// layar petani agar transisi fade konsisten dan semantik khusus (logout,
// back-to-home setelah create) tidak tersebar di tiap call-site.
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

  // [FE - Navigation Helper] Buat route dengan transisi fade standar —
  // dipanggil oleh push() dan replaceAll() agar kurva/durasi selalu sama.
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

  // [FE - Navigation Helper] Navigasi push biasa — dipakai untuk membuka
  // layar detail, form, QR, dan profil dari Beranda.
  /// Push [page] ke atas stack navigasi saat ini.
  ///
  /// Mengembalikan [Future] yang selesai saat halaman di-pop, sama seperti
  /// [Navigator.push]. Berguna bila pemanggil perlu menunggu hasil (mis.
  /// kembali dari [CreateFarmScreen] untuk me-refresh dropdown).
  static Future<T?> push<T>(BuildContext context, Widget page) {
    return Navigator.push<T>(context, _fadeRoute<T>(page));
  }

  // [FE - Navigation Helper] Ganti seluruh stack — dipakai untuk logout
  // dan alur create→QR→Beranda agar tombol back tidak kembali ke form.
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
