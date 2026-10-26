// lib/vat/models/vat_payment_model.dart

class VatPaymentModel {
  final String? id;
  final String senderUserId;
  final String senderUserName;
  final String senderPhoneNumber;
  final String receiverPhoneNumber; // backend has it as `final` (hardcoded)
  final double amount;
  final String transactionId;
  final DateTime? sendingTime;
  final String vatId;

  VatPaymentModel({
    this.id,
    required this.senderUserId,
    required this.senderUserName,
    required this.senderPhoneNumber,
    this.receiverPhoneNumber = '+8801874648472',
    required this.amount,
    required this.transactionId,
    this.sendingTime,
    required this.vatId,
  });

  // ============ FROM JSON ============
  factory VatPaymentModel.fromJson(Map<String, dynamic> json) {
    return VatPaymentModel(
      id: json['id'] as String?,
      senderUserId: json['senderUserId'] as String? ?? '',
      senderUserName: json['senderUserName'] as String? ?? '',
      senderPhoneNumber: json['senderPhoneNumber'] as String? ?? '',
      receiverPhoneNumber:
          json['receiverPhoneNumber'] as String? ?? '+8801874648472',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      transactionId: json['transactionId'] as String? ?? '',
      sendingTime: json['sendingTime'] != null
          ? DateTime.tryParse(json['sendingTime'].toString())
          : null,
      vatId: json['vatId'] as String? ?? '',
    );
  }

  // ============ TO JSON ============
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'senderUserId': senderUserId,
      'senderUserName': senderUserName,
      'senderPhoneNumber': senderPhoneNumber,
      'amount': amount,
      'transactionId': transactionId,
      if (sendingTime != null) 'sendingTime': sendingTime!.toUtc().toIso8601String(),
      'vatId': vatId,
    };
  }

  // ============ COPY WITH ============
  VatPaymentModel copyWith({
    String? id,
    String? senderUserId,
    String? senderUserName,
    String? senderPhoneNumber,
    String? receiverPhoneNumber,
    double? amount,
    String? transactionId,
    DateTime? sendingTime,
    String? vatId,
  }) {
    return VatPaymentModel(
      id: id ?? this.id,
      senderUserId: senderUserId ?? this.senderUserId,
      senderUserName: senderUserName ?? this.senderUserName,
      senderPhoneNumber: senderPhoneNumber ?? this.senderPhoneNumber,
      receiverPhoneNumber: receiverPhoneNumber ?? this.receiverPhoneNumber,
      amount: amount ?? this.amount,
      transactionId: transactionId ?? this.transactionId,
      sendingTime: sendingTime ?? this.sendingTime,
      vatId: vatId ?? this.vatId,
    );
  }

  @override
  String toString() {
    return 'VatPaymentModel(id: $id, senderUserId: $senderUserId, '
        'senderUserName: $senderUserName, senderPhoneNumber: $senderPhoneNumber, '
        'receiverPhoneNumber: $receiverPhoneNumber, amount: $amount, '
        'transactionId: $transactionId, sendingTime: $sendingTime, vatId: $vatId)';
  }
}