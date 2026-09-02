import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_top_bar.dart';

/// Bantuan konsumen.
class ConsumerHelpScreen extends StatelessWidget {
  const ConsumerHelpScreen({super.key});

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
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                children: const [
                  _SectionTitle('Cara Menggunakan'),
                  SizedBox(height: 12),
                  _GuideStep(
                    number: '1',
                    title: 'Cari Produk',
                    description:
                        'Gunakan pencarian atau kategori untuk menemukan produk UMKM durian yang kamu inginkan.',
                  ),
                  _GuideStep(
                    number: '2',
                    title: 'Buka Produk',
                    description:
                        'Tap kartu produk untuk membuka jejak trace dan melihat informasi asalnya.',
                  ),
                  _GuideStep(
                    number: '3',
                    title: 'Cek Trace',
                    description:
                        'Lihat detail batch, status perjalanan, dan catatan kualitas produk.',
                  ),
                  _GuideStep(
                    number: '4',
                    title: 'Simpan Referensi',
                    description:
                        'Simpan produk yang menarik untuk ditinjau lagi saat kamu ingin membeli.',
                    isLast: true,
                  ),
                  SizedBox(height: 28),
                  _SectionTitle('Pertanyaan Umum'),
                  SizedBox(height: 12),
                  _FaqItem(
                    question: 'Apakah konsumen bisa melihat asal produk?',
                    answer:
                        'Bisa. Setiap produk terhubung ke halaman trace publik yang menampilkan riwayatnya.',
                  ),
                  _FaqItem(
                    question: 'Apakah produk sudah dari UMKM?',
                    answer:
                        'Ya, beranda konsumen menampilkan daftar produk UMKM sebagai katalog awal.',
                  ),
                  _FaqItem(
                    question: 'Apakah bisa langsung beli sekarang?',
                    answer:
                        'Belum. Saat ini flow masih fokus ke UI katalog dan traceability, checkout menyusul.',
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
          Text(
            question,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: AppColors.black,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            answer,
            style: const TextStyle(
              fontSize: 13,
              height: 1.45,
              color: AppColors.placeholder,
            ),
          ),
        ],
      ),
    );
  }
}
