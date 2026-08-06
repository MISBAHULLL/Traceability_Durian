import 'harvest_batch.dart';

// [DB - Model/Entity] Enum ini mengelompokkan notifikasi petani agar UI bisa
// membedakan permintaan, update trace, dan sengketa tanpa membaca teks bebas.
enum FarmerNotificationType { transactionRequest, statusUpdate, dispute }

// [DB - Model/Entity] Model view notifikasi petani pada fase FE-only; nanti
// dapat dipetakan langsung dari event notifikasi backend/blockchain.
class FarmerNotification {
  const FarmerNotification({
    required this.id,
    required this.batchCode,
    required this.title,
    required this.message,
    required this.createdAt,
    required this.type,
    required this.batchStatus,
    this.requiresAttention = false,
  });

  final String id;
  final String batchCode;
  final String title;
  final String message;
  final DateTime createdAt;
  final FarmerNotificationType type;
  final BatchStatus batchStatus;
  final bool requiresAttention;
}
