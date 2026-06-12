import 'package:flutter/material.dart';

/// Helper navigasi untuk layar UMKM.
class UmkmRoutes {
  UmkmRoutes._();

  static const Duration _duration = Duration(milliseconds: 400);
  static const Curve _curve = Curves.easeInOutCubic;

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

  static Future<T?> push<T>(BuildContext context, Widget page) {
    return Navigator.push<T>(context, _fadeRoute<T>(page));
  }

  static void replaceAll(BuildContext context, Widget page) {
    Navigator.pushAndRemoveUntil<void>(
      context,
      _fadeRoute<void>(page),
      (_) => false,
    );
  }
}
