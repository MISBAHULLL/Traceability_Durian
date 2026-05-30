import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_top_bar.dart';

// [FE - Component Rendering] Screen ini menampilkan panduan & FAQ statis
// untuk petani — diakses dari navigation drawer Beranda. Konten masih
// hardcoded; dapat diganti dengan CMS/remote content di masa depan.
/// Layar Bantuan & Panduan untuk role Petani.
///
/// Berisi langkah penggunaan fitur utama dan pertanyaan yang sering muncul
/// seputar ketertelusuran (traceability) batch durian.
class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            const AppTopBar(title: 'Bantuan & Panduan'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                children: const [
                  // ── Panduan langkah ──────────────────────────────────────
                  _SectionTitle('Cara Menggunakan Aplikasi'),
                  SizedBox(height: 12),
                  _GuideStep(
                    number: '1',
                    title: 'Buat Kebun',
                    description:
                        'Buka Profil → Kelola Kebun, lalu tambahkan kebun '
                        'durian Anda beserta lokasinya.',
                  ),
                  _GuideStep(
                    number: '2',
                    title: 'Tambah Batch Panen',
                    description:
                        'Dari Beranda, tekan "Tambah Batch Panen", pilih '
                        'kebun, isi varietas, grade, tanggal, dan jumlah panen.',
                  ),
                  _GuideStep(
                    number: '3',
                    title: 'Dapatkan QR Code',
                    description:
                        'Setelah batch dibuat, QR Code otomatis dihasilkan. '
                        'Tempelkan pada kemasan agar batch dapat ditelusuri.',
                  ),
                  _GuideStep(
                    number: '4',
                    title: 'Pantau Status',
                    description:
                        'Status batch (Menunggu Verifikasi, Terverifikasi, '
                        'dll) diperbarui mengikuti perjalanan di rantai pasok.',
                    isLast: true,
                  ),

                  SizedBox(height: 28),

                  // ── FAQ ──────────────────────────────────────────────────
                  _SectionTitle('Pertanyaan Umum'),
                  SizedBox(height: 12),
                  _FaqItem(
                    question: 'Apa arti status "Menunggu Verifikasi"?',
                    answer:
                        'Batch sudah Anda buat tetapi belum diverifikasi oleh '
                        'pengepul. Setelah diverifikasi, status berubah '
                        'menjadi "Terverifikasi".',
                  ),
                  _FaqItem(
                    question: 'Bisakah saya mengubah data batch?',
                    answer:
                        'Data batch hanya dapat diubah selama berstatus Draft. '
                        'Setelah dikirim (status Dibuat), data tidak dapat '
                        'diubah demi menjaga keaslian rekam jejak.',
                  ),
                  _FaqItem(
                    question: 'Untuk apa QR Code batch?',
                    answer:
                        'QR Code memuat tautan telusur publik sehingga pembeli '
                        'atau aktor berikutnya dapat memindai dan melihat asal '
                        'durian Anda.',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sub-widgets
// ─────────────────────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w800,
        color: AppColors.black,
      ),
    );
  }
}

/// Satu langkah panduan dengan nomor bulat dan garis penghubung.
class _GuideStep extends StatelessWidget {
  const _GuideStep({
    required this.number,
    required this.title,
    required this.description,
    this.isLast = false,
  });

  final String number;
  final String title;
  final String description;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: const BoxDecoration(
                  color: AppColors.primaryContainer,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  number,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.white,
                  ),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: const Color(0xFFE5E7EB),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.black,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.placeholder,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Satu item FAQ (pertanyaan + jawaban).
class _FaqItem extends StatelessWidget {
  const _FaqItem({required this.question, required this.answer});

  final String question;
  final String answer;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.help_outline_rounded,
                size: 18,
                color: AppColors.primaryContainer,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  question,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.black,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            answer,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.placeholder,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}
