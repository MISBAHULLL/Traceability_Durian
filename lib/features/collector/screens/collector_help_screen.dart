import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_top_bar.dart';

// [FE - Component Rendering] Screen bantuan pengepul berisi panduan statis
// untuk flow scan QR, verifikasi batch, stok, dan penolakan.
class CollectorHelpScreen extends StatelessWidget {
  const CollectorHelpScreen({super.key});

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
                    title: 'Scan QR Batch',
                    description:
                        'Masukkan kode batch atau URL QR dari petani untuk membuka form verifikasi.',
                  ),
                  _GuideStep(
                    number: '2',
                    title: 'Verifikasi Mutu',
                    description:
                        'Isi berat diterima, grade hasil sortir, dan catatan kualitas bila diperlukan.',
                  ),
                  _GuideStep(
                    number: '3',
                    title: 'Masuk Stok',
                    description:
                        'Batch yang lolos verifikasi otomatis muncul di menu Stok Saya.',
                  ),
                  _GuideStep(
                    number: '4',
                    title: 'Tolak Bila Tidak Layak',
                    description:
                        'Jika batch tidak sesuai, gunakan Tolak Batch dan isi alasan agar petani mendapat konteks.',
                    isLast: true,
                  ),
                  SizedBox(height: 28),
                  _SectionTitle('Pertanyaan Umum'),
                  SizedBox(height: 12),
                  _FaqItem(
                    question: 'Kenapa batch hilang setelah diverifikasi?',
                    answer:
                        'Batch tidak hilang. Statusnya berubah menjadi terverifikasi dan berpindah ke Stok Saya.',
                  ),
                  _FaqItem(
                    question: 'Apakah grade petani berubah?',
                    answer:
                        'Tidak. Grade awal petani tetap disimpan, sedangkan grade pengepul dicatat terpisah.',
                  ),
                  _FaqItem(
                    question: 'Apakah scan QR sudah memakai kamera?',
                    answer:
                        'Belum. Untuk FE prototype, scan QR masih berupa simulasi input kode batch.',
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
