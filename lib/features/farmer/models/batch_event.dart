import 'harvest_batch.dart';

// [DB - Model/Entity] Model ini merepresentasikan satu kejadian pada
// timeline riwayat batch — dipakai BatchDetailScreen untuk menampilkan
// kronologi perjalanan batch di rantai pasok.
/// Satu kejadian pada timeline riwayat sebuah batch panen.
///
/// Dipakai oleh [BatchDetailScreen] untuk menampilkan timeline kronologis
/// (Req 3.6).
class BatchEvent {
  const BatchEvent({
    required this.title,
    required this.actorLabel,
    required this.timestamp,
    required this.status,
  });

  /// Judul kejadian, contoh: "Batch Dibuat", "Terverifikasi Pengepul".
  final String title;

  /// Label aktor yang melakukan aksi, contoh: "Petani — Risqi Maulana".
  final String actorLabel;

  /// Waktu kejadian berlangsung.
  final DateTime timestamp;

  /// Status batch yang berlaku pada kejadian ini.
  final BatchStatus status;
}
