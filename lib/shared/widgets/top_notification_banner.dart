import 'package:flutter/material.dart';

/// Banner notifikasi yang muncul dari atas layar dengan animasi
/// slide-down + fade. Auto-dismiss setelah 3 detik atau tap untuk menutup.
///
/// Dipakai bersama oleh seluruh screen (login, register, beranda) agar
/// gaya notifikasi konsisten. Tampilkan lewat helper [TopNotification.show].
class TopNotificationBanner extends StatefulWidget {
  const TopNotificationBanner({
    super.key,
    required this.message,
    required this.isError,
    required this.onDismiss,
  });

  final String message;
  final bool isError;
  final VoidCallback onDismiss;

  @override
  State<TopNotificationBanner> createState() => _TopNotificationBannerState();
}

class _TopNotificationBannerState extends State<TopNotificationBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<Offset> _slide;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);

    _ctrl.forward();
    Future.delayed(const Duration(seconds: 3), _dismiss);
  }

  void _dismiss() async {
    if (!mounted) return;
    await _ctrl.reverse();
    widget.onDismiss();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final bgColor =
        widget.isError ? const Color(0xFFFFDAD6) : const Color(0xFFDCF5DC);
    final textColor =
        widget.isError ? const Color(0xFF7F1D1D) : const Color(0xFF14532D);
    final iconColor =
        widget.isError ? const Color(0xFFB91C1C) : const Color(0xFF16A34A);

    return Positioned(
      top: topPadding + 12,
      left: 24,
      right: 24,
      child: SlideTransition(
        position: _slide,
        child: FadeTransition(
          opacity: _fade,
          child: GestureDetector(
            onTap: _dismiss,
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.10),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(
                      widget.isError
                          ? Icons.error_outline_rounded
                          : Icons.check_circle_outline_rounded,
                      color: iconColor,
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        widget.message,
                        style: TextStyle(
                          color: textColor,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          height: 1.4,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.close_rounded,
                      color: textColor.withValues(alpha: 0.6),
                      size: 18,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Helper untuk menampilkan [TopNotificationBanner] lewat [Overlay].
///
/// Memastikan hanya ada satu banner aktif pada satu waktu per pemanggil.
/// Pemanggil bertanggung jawab menyimpan instance dan memanggil [dispose]
/// saat State-nya dibuang.
class TopNotification {
  OverlayEntry? _entry;

  /// Menampilkan banner. Banner sebelumnya (jika ada) akan dihapus dulu.
  void show(
    BuildContext context,
    String message, {
    bool isError = false,
  }) {
    _entry?.remove();
    _entry = null;

    final overlay = Overlay.of(context);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => TopNotificationBanner(
        message: message,
        isError: isError,
        onDismiss: () {
          entry.remove();
          if (_entry == entry) _entry = null;
        },
      ),
    );

    _entry = entry;
    overlay.insert(entry);
  }

  /// Hapus banner yang masih tampil. Panggil di dispose() State pemanggil.
  void dispose() {
    _entry?.remove();
    _entry = null;
  }
}
