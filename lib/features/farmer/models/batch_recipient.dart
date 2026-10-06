import 'harvest_batch.dart';

class BatchRecipient {
  const BatchRecipient({
    required this.userId,
    required this.accountId,
    required this.fullName,
    required this.role,
    this.address = '',
  });

  final int userId;
  final String accountId;
  final String fullName;
  final BatchReceiverRole role;
  final String address;

  factory BatchRecipient.fromJson(Map<String, dynamic> json) {
    final userId = int.tryParse('${json['id'] ?? json['user_id'] ?? ''}');
    final roleName = (json['recipient_role'] ?? json['role'] ?? '').toString();
    final role = batchReceiverRoleFromJson(roleName);
    if (userId == null || role == null) {
      throw const FormatException('Data akun penerima tidak valid.');
    }

    final firstName = (json['first_name'] ?? '').toString().trim();
    final lastName = (json['last_name'] ?? '').toString().trim();
    final fullName =
        (json['full_name'] ?? json['name'] ?? '$firstName $lastName').trim();
    if (fullName.isEmpty) {
      throw const FormatException('Nama akun penerima tidak tersedia.');
    }

    return BatchRecipient(
      userId: userId,
      accountId: (json['public_id'] ?? json['account_id'] ?? userId).toString(),
      fullName: fullName,
      role: role,
      address: (json['address'] ?? '').toString(),
    );
  }

  String get dropdownLabel => '$fullName • ID $accountId (${role.label})';
}
